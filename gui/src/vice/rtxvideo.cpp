// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// RTX Video Super Resolution without NVIDIA's SDK.
//
// The graphics driver implements it inside Direct3D 11's video processor, which is part of
// Windows: a frame is handed to the processor with NVIDIA's "super resolution" stream
// extension switched on, and comes back enlarged. This is the route media players take.
// Nothing of NVIDIA's is linked or shipped; on a driver without the feature the call is
// refused and the frame is left to the app's own scalers.
//
// Cost: the stream is decoded with Direct3D 11 instead of Vulkan, and the enlarged frame is
// read back to memory for the Vulkan renderer. The time taken is logged ("vice.rtx").
//
// Measured on an RTX 5060 laptop, 1080p to 1440p, on one still screen: edge sharpness 352
// with it on against 197 with the same path and the driver's part off, and 259 for the app's
// own Quality scaler; about 7 ms a frame and 42% GPU load against 19%.
//
// The driver obeys only when "RTX Video Enhancement: Super Resolution" is on in the NVIDIA
// app (System, Video). With it off the request is accepted and nothing happens, and nothing
// reports that: the picture is then softer than the app's own scaler.

#include "vice/engine.h"

#include <QLoggingCategory>
#include <QMutex>

Q_LOGGING_CATEGORY(viceRtxLog, "vice.rtx", QtInfoMsg)

#if defined(_WIN32)

#include <d3d11.h>
#include <dxgi.h>
#include <atomic>
#include <map>
#include <utility>

extern "C" {
#include <libavutil/frame.h>
#include <libavutil/hwcontext.h>
#include <libavutil/hwcontext_d3d11va.h>
#include <libavutil/pixdesc.h>
}

#include <chiaki/time.h>

namespace {

// The driver's private stream extension, as used by Chromium, VLC and mpv
const GUID nvidia_ppe = { 0xd43ce1b3, 0x1f4b, 0x48ac, { 0xba, 0xee, 0xc3, 0xc2, 0x53, 0x75, 0xe6, 0xf7 } };
struct NvidiaStreamExtension
{
	UINT version;
	UINT method;
	UINT enable;
};
const UINT nvidia_version_1 = 0x1;
const UINT nvidia_method_super_resolution = 0x2;

template <typename T> void release(T *&p)
{
	if(p)
	{
		p->Release();
		p = nullptr;
	}
}

struct Processor
{
	QMutex mutex;
	ID3D11Device *device = nullptr; // not owned: FFmpeg's
	int in_w = 0, in_h = 0, out_w = 0, out_h = 0;
	ID3D11VideoProcessorEnumerator *enumerator = nullptr;
	ID3D11VideoProcessor *processor = nullptr;
	ID3D11Texture2D *target = nullptr;
	ID3D11VideoProcessorOutputView *target_view = nullptr;
	ID3D11Texture2D *staging = nullptr;
	std::map<std::pair<ID3D11Texture2D *, UINT>, ID3D11VideoProcessorInputView *> inputs;
	bool refused = false;     // this driver or size cannot do it: stop trying
	bool extension_on = false;
	qint64 spent_us = 0;
	int frames = 0;

	void drop()
	{
		for(auto &entry : inputs)
			entry.second->Release();
		inputs.clear();
		release(staging);
		release(target_view);
		release(target);
		release(processor);
		release(enumerator);
		in_w = in_h = out_w = out_h = 0;
		device = nullptr;
	}
};

Processor g;

bool setup(AVD3D11VADeviceContext *hw, int in_w, int in_h, int out_w, int out_h)
{
	g.drop();

	D3D11_VIDEO_PROCESSOR_CONTENT_DESC content = {};
	content.InputFrameFormat = D3D11_VIDEO_FRAME_FORMAT_PROGRESSIVE;
	content.InputFrameRate = { 60, 1 };
	content.InputWidth = static_cast<UINT>(in_w);
	content.InputHeight = static_cast<UINT>(in_h);
	content.OutputFrameRate = { 60, 1 };
	content.OutputWidth = static_cast<UINT>(out_w);
	content.OutputHeight = static_cast<UINT>(out_h);
	content.Usage = D3D11_VIDEO_USAGE_PLAYBACK_NORMAL;
	if(FAILED(hw->video_device->CreateVideoProcessorEnumerator(&content, &g.enumerator))
		|| FAILED(hw->video_device->CreateVideoProcessor(g.enumerator, 0, &g.processor)))
	{
		qCWarning(viceRtxLog) << "No Direct3D 11 video processor for" << in_w << "x" << in_h << "to" << out_w << "x" << out_h;
		return false;
	}

	D3D11_TEXTURE2D_DESC desc = {};
	desc.Width = static_cast<UINT>(out_w);
	desc.Height = static_cast<UINT>(out_h);
	desc.MipLevels = 1;
	desc.ArraySize = 1;
	desc.Format = DXGI_FORMAT_NV12;
	desc.SampleDesc.Count = 1;
	desc.Usage = D3D11_USAGE_DEFAULT;
	desc.BindFlags = D3D11_BIND_RENDER_TARGET;
	HRESULT step = hw->device->CreateTexture2D(&desc, nullptr, &g.target);
	if(FAILED(step))
	{
		qCWarning(viceRtxLog).nospace() << "No output texture for the video processor (0x" << Qt::hex << static_cast<quint32>(step) << ")";
		return false;
	}
	D3D11_VIDEO_PROCESSOR_OUTPUT_VIEW_DESC view = {};
	view.ViewDimension = D3D11_VPOV_DIMENSION_TEXTURE2D;
	step = hw->video_device->CreateVideoProcessorOutputView(g.target, g.enumerator, &view, &g.target_view);
	if(FAILED(step))
	{
		qCWarning(viceRtxLog).nospace() << "No output view for the video processor (0x" << Qt::hex << static_cast<quint32>(step) << ")";
		return false;
	}
	desc.Usage = D3D11_USAGE_STAGING;
	desc.BindFlags = 0;
	desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
	step = hw->device->CreateTexture2D(&desc, nullptr, &g.staging);
	if(FAILED(step))
	{
		qCWarning(viceRtxLog).nospace() << "No read-back texture (0x" << Qt::hex << static_cast<quint32>(step) << ")";
		return false;
	}

	// The same colours out as in (BT.709, limited range): only the size changes here
	D3D11_VIDEO_PROCESSOR_COLOR_SPACE colour = {};
	colour.YCbCr_Matrix = 1;
	colour.Nominal_Range = D3D11_VIDEO_PROCESSOR_NOMINAL_RANGE_16_235;
	hw->video_context->VideoProcessorSetStreamColorSpace(g.processor, 0, &colour);
	hw->video_context->VideoProcessorSetOutputColorSpace(g.processor, &colour);
	hw->video_context->VideoProcessorSetStreamFrameFormat(g.processor, 0, D3D11_VIDEO_FRAME_FORMAT_PROGRESSIVE);
	hw->video_context->VideoProcessorSetStreamAutoProcessingMode(g.processor, 0, FALSE);
	RECT in_rect = { 0, 0, in_w, in_h }, out_rect = { 0, 0, out_w, out_h };
	hw->video_context->VideoProcessorSetStreamSourceRect(g.processor, 0, TRUE, &in_rect);
	hw->video_context->VideoProcessorSetStreamDestRect(g.processor, 0, TRUE, &out_rect);
	hw->video_context->VideoProcessorSetOutputTargetRect(g.processor, TRUE, &out_rect);

	// VICE_RTX_PLAIN=1 runs the same path with the driver's enhancement off: the video
	// processor's ordinary scaling, to compare against
	const bool plain = qEnvironmentVariableIntValue("VICE_RTX_PLAIN") == 1;
	NvidiaStreamExtension extension = { nvidia_version_1, nvidia_method_super_resolution, plain ? 0u : 1u };
	const HRESULT hr = hw->video_context->VideoProcessorSetStreamExtension(g.processor, 0, &nvidia_ppe, sizeof(extension), &extension);
	g.extension_on = SUCCEEDED(hr);
	if(g.extension_on)
		qCInfo(viceRtxLog) << (plain ? "Video processor scaling without RTX (VICE_RTX_PLAIN):" : "RTX Video Super Resolution on:") << in_w << "x" << in_h << "to" << out_w << "x" << out_h;
	else
		qCWarning(viceRtxLog).nospace() << "The graphics driver refused RTX Video Super Resolution (0x" << Qt::hex << static_cast<quint32>(hr) << "); the app's own scaler is used";

	g.device = hw->device;
	g.in_w = in_w;
	g.in_h = in_h;
	g.out_w = out_w;
	g.out_h = out_h;
	g.spent_us = 0;
	g.frames = 0;
	return g.extension_on;
}

} // namespace

AVFrame *viceRtxVideoProcess(const AVFrame *frame, int window_w, int window_h)
{
	// Says once per reason why a frame was passed on untouched, so the log explains itself
	static std::atomic<int> said{0};
	auto skip = [](int bit, const char *why) -> AVFrame * {
		if(!(said.fetch_or(bit) & bit))
			qCInfo(viceRtxLog) << "RTX Video Super Resolution not applied:" << why;
		return nullptr;
	};
	if(!ViceEngine::instance()->rtxSuperResolution())
		return nullptr;
	if(!frame || window_w <= 0 || window_h <= 0)
		return skip(1, "no frame or no window size yet");
	if(frame->format != AV_PIX_FMT_D3D11 || !frame->hw_frames_ctx)
		return skip(2, av_get_pix_fmt_name(static_cast<AVPixelFormat>(frame->format)) ? av_get_pix_fmt_name(static_cast<AVPixelFormat>(frame->format)) : "frame is not from the Direct3D 11 decoder");
	auto *frames = reinterpret_cast<AVHWFramesContext *>(frame->hw_frames_ctx->data);
	// 10-bit (HDR) streams are left alone: the read-back below is written for 8-bit
	if(frames->sw_format != AV_PIX_FMT_NV12)
		return skip(4, "the stream is not 8-bit");
	auto *hw = static_cast<AVD3D11VADeviceContext *>(frames->device_ctx->hwctx);
	if(!hw || !hw->device || !hw->video_device || !hw->video_context)
		return skip(8, "the decoder has no video device");

	// The picture's shape, as large as the window allows; nothing to do unless that is larger
	const double scale = std::min(static_cast<double>(window_w) / frame->width, static_cast<double>(window_h) / frame->height);
	if(scale < 1.05)
		return skip(16, "the window is no larger than the stream");
	const int out_w = std::min(3840, static_cast<int>(frame->width * scale + 0.5)) & ~1;
	const int out_h = std::min(2160, static_cast<int>(frame->height * scale + 0.5)) & ~1;

	QMutexLocker locker(&g.mutex);
	if(g.refused && g.device == hw->device && g.in_w == frame->width && g.in_h == frame->height && g.out_w == out_w && g.out_h == out_h)
		return nullptr;

	const qint64 begin_us = static_cast<qint64>(chiaki_time_now_monotonic_us());
	AVFrame *out = nullptr;
	hw->lock(hw->lock_ctx);
	do
	{
		if(g.device != hw->device || g.in_w != frame->width || g.in_h != frame->height || g.out_w != out_w || g.out_h != out_h)
		{
			g.refused = !setup(hw, frame->width, frame->height, out_w, out_h);
			if(g.refused)
			{
				// Remember what was refused, so it is not tried again for every frame
				g.device = hw->device;
				g.in_w = frame->width;
				g.in_h = frame->height;
				g.out_w = out_w;
				g.out_h = out_h;
				break;
			}
		}

		auto *texture = reinterpret_cast<ID3D11Texture2D *>(frame->data[0]);
		const UINT slice = static_cast<UINT>(reinterpret_cast<intptr_t>(frame->data[1]));
		const auto key = std::make_pair(texture, slice);
		ID3D11VideoProcessorInputView *input = nullptr;
		const auto found = g.inputs.find(key);
		if(found != g.inputs.end())
			input = found->second;
		else
		{
			D3D11_VIDEO_PROCESSOR_INPUT_VIEW_DESC view = {};
			view.ViewDimension = D3D11_VPIV_DIMENSION_TEXTURE2D;
			view.Texture2D.ArraySlice = slice;
			if(FAILED(hw->video_device->CreateVideoProcessorInputView(texture, g.enumerator, &view, &input)))
			{
				qCWarning(viceRtxLog) << "The decoder's frames cannot be read by the video processor; RTX Video is off for this session";
				g.refused = true;
				break;
			}
			g.inputs[key] = input;
		}

		D3D11_VIDEO_PROCESSOR_STREAM stream = {};
		stream.Enable = TRUE;
		stream.pInputSurface = input;
		const HRESULT blt = hw->video_context->VideoProcessorBlt(g.processor, g.target_view, 0, 1, &stream);
		if(FAILED(blt))
		{
			qCWarning(viceRtxLog).nospace() << "The video processor failed on a frame (0x" << Qt::hex << static_cast<quint32>(blt) << "); RTX Video is off for this session";
			g.refused = true;
			break;
		}

		hw->device_context->CopyResource(g.staging, g.target);
		D3D11_MAPPED_SUBRESOURCE mapped = {};
		if(FAILED(hw->device_context->Map(g.staging, 0, D3D11_MAP_READ, 0, &mapped)))
		{
			qCWarning(viceRtxLog) << "The enlarged frame could not be read back; RTX Video is off for this session";
			g.refused = true;
			break;
		}
		out = av_frame_alloc();
		if(out)
		{
			out->format = AV_PIX_FMT_NV12;
			out->width = out_w;
			out->height = out_h;
			if(av_frame_get_buffer(out, 0) < 0)
				av_frame_free(&out);
		}
		if(out)
		{
			const auto *source = static_cast<const uint8_t *>(mapped.pData);
			for(int y = 0; y < out_h; y++)
				memcpy(out->data[0] + static_cast<ptrdiff_t>(y) * out->linesize[0], source + static_cast<size_t>(y) * mapped.RowPitch, static_cast<size_t>(out_w));
			const uint8_t *chroma = source + static_cast<size_t>(out_h) * mapped.RowPitch;
			for(int y = 0; y < out_h / 2; y++)
				memcpy(out->data[1] + static_cast<ptrdiff_t>(y) * out->linesize[1], chroma + static_cast<size_t>(y) * mapped.RowPitch, static_cast<size_t>(out_w));
			av_frame_copy_props(out, frame);
		}
		hw->device_context->Unmap(g.staging, 0);
	} while(false);
	hw->unlock(hw->lock_ctx);

	if(out)
	{
		g.spent_us += static_cast<qint64>(chiaki_time_now_monotonic_us()) - begin_us;
		if(++g.frames == 600)
		{
			qCInfo(viceRtxLog).nospace() << "RTX Video Super Resolution: " << (g.spent_us / 600) / 1000.0 << " ms a frame over the last 600 (" << g.in_w << "x" << g.in_h << " to " << g.out_w << "x" << g.out_h << ")";
			g.spent_us = 0;
			g.frames = 0;
		}
	}
	return out;
}

// A laptop with two graphics chips hands Direct3D the integrated one by default, whose driver
// accepts NVIDIA's request and does nothing with it. The decoder is made on the NVIDIA card.
AVBufferRef *viceRtxVideoDevice()
{
	if(!ViceEngine::instance()->rtxSuperResolution())
		return nullptr;
	IDXGIFactory1 *factory = nullptr;
	if(FAILED(CreateDXGIFactory1(__uuidof(IDXGIFactory1), reinterpret_cast<void **>(&factory))) || !factory)
		return nullptr;
	int found = -1;
	QString name;
	IDXGIAdapter1 *adapter = nullptr;
	for(UINT i = 0; found < 0 && factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND; i++)
	{
		DXGI_ADAPTER_DESC1 desc = {};
		if(SUCCEEDED(adapter->GetDesc1(&desc)) && desc.VendorId == 0x10DE && !(desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE))
		{
			found = static_cast<int>(i);
			name = QString::fromWCharArray(desc.Description);
		}
		adapter->Release();
	}
	factory->Release();
	if(found < 0)
	{
		qCWarning(viceRtxLog) << "No NVIDIA graphics card found: RTX Video Super Resolution cannot be used";
		return nullptr;
	}
	AVBufferRef *device = nullptr;
	if(av_hwdevice_ctx_create(&device, AV_HWDEVICE_TYPE_D3D11VA, QByteArray::number(found).constData(), nullptr, 0) < 0)
	{
		qCWarning(viceRtxLog) << "Could not start Direct3D 11 decoding on" << name;
		return nullptr;
	}
	qCInfo(viceRtxLog) << "Decoding on" << name << "for RTX Video Super Resolution";
	return device;
}

void viceRtxVideoSessionEnd()
{
	QMutexLocker locker(&g.mutex);
	g.drop();
	g.refused = false;
}

bool viceRtxVideoPossible()
{
	return true;
}

#else

struct AVFrame;
struct AVBufferRef;

AVFrame *viceRtxVideoProcess(const AVFrame *, int, int)
{
	return nullptr;
}

AVBufferRef *viceRtxVideoDevice()
{
	return nullptr;
}

void viceRtxVideoSessionEnd()
{
}

bool viceRtxVideoPossible()
{
	return false;
}

#endif
