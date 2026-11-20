// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "vice/engine.h"

#include <chiaki/thread.h>
#include <chiaki/time.h>

#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QMutex>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>
#include <QtConcurrent>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <deque>
#include <limits>
#include <vector>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
}

namespace {

const double not_measured = std::numeric_limits<double>::quiet_NaN();
const qint64 replay_length_us = 30 * 1000000LL;
// A stream with no complete picture for a long time must not grow without limit
const qint64 replay_max_bytes = 256 * 1024 * 1024LL;

qint64 nowUs() { return static_cast<qint64>(chiaki_time_now_monotonic_us()); }

struct Timed { qint64 at; double value; };
struct Packet { QByteArray data; qint64 us; bool key; };

struct State
{
	QMutex mutex;
	ChiakiSession *session = nullptr;
	bool socket_tagged = false;

	// audio on its way to the decoder
	ChiakiAudioSink audio_next = {};
	ChiakiAudioHeader audio_header = {};
	bool audio_header_known = false;

	// timing
	std::atomic<qint64> last_sample_us{0};
	std::atomic<qint64> pending_arrival_us{0};
	qint64 last_delivery_us = 0;
	qint64 last_drawn_us = 0;
	std::deque<qint64> deliveries;
	// Sizes of the last frames as they arrived, to tell repeated pictures by
	std::deque<size_t> frame_sizes;
	std::deque<qint64> stutters;
	std::deque<qint64> stalls;
	std::deque<Timed> decode, render, pipeline;

	// a measured run
	bool run_active = false;
	qint64 run_start_us = 0;
	qint64 run_frames = 0;
	qint64 run_stutters = 0;
	std::vector<double> run_pipeline, run_decode, run_render;

	// replay
	std::deque<Packet> video, audio;
	qint64 video_bytes = 0;
	QByteArray video_header;
	AVCodecID codec = AV_CODEC_ID_NONE;
	int width = 0, height = 0;
};

State g;

double median(std::vector<double> values)
{
	if(values.empty())
		return not_measured;
	auto mid = values.begin() + values.size() / 2;
	std::nth_element(values.begin(), mid, values.end());
	return *mid;
}

double percentile(std::vector<double> values, double p)
{
	if(values.empty())
		return not_measured;
	size_t index = std::min(values.size() - 1, static_cast<size_t>(std::floor(p * values.size())));
	std::nth_element(values.begin(), values.begin() + index, values.end());
	return values[index];
}

double medianOf(const std::deque<Timed> &samples)
{
	std::vector<double> values;
	values.reserve(samples.size());
	for(const Timed &s : samples)
		values.push_back(s.value);
	return median(std::move(values));
}

void prune(std::deque<Timed> &samples, qint64 older_than)
{
	while(!samples.empty() && samples.front().at < older_than)
		samples.pop_front();
}

// ---- replay buffer ---------------------------------------------------------------

enum { HasParameterSets = 1, IsKeyframe = 2, HasPicture = 4 };

// Looks at the NAL units at the start of an Annex B buffer, up to the first picture
int classify(const uint8_t *p, size_t n, AVCodecID codec)
{
	int out = 0;
	for(size_t i = 0; i + 4 < n; i++)
	{
		if(p[i] != 0 || p[i + 1] != 0)
			continue;
		size_t start;
		if(p[i + 2] == 1)
			start = i + 3;
		else if(p[i + 2] == 0 && p[i + 3] == 1)
			start = i + 4;
		else
			continue;
		if(start >= n)
			break;
		if(codec == AV_CODEC_ID_HEVC)
		{
			int type = (p[start] >> 1) & 0x3f;
			if(type >= 32 && type <= 34)
				out |= HasParameterSets;
			else if(type >= 16 && type <= 23)
				return out | IsKeyframe | HasPicture;
			else if(type < 16)
				return out | HasPicture;
		}
		else
		{
			int type = p[start] & 0x1f;
			if(type == 7 || type == 8)
				out |= HasParameterSets;
			else if(type == 5)
				return out | IsKeyframe | HasPicture;
			else if(type == 1)
				return out | HasPicture;
		}
		i = start;
	}
	return out;
}

// Caller holds g.mutex
void trimReplay(qint64 now)
{
	const qint64 keep_from = now - replay_length_us;
	// Keep from the newest complete picture that is at least 30 s old, so the buffer always starts decodable
	int cut = -1;
	for(int i = static_cast<int>(g.video.size()) - 1; i >= 0; i--)
	{
		if(g.video[i].key && g.video[i].us <= keep_from)
		{
			cut = i;
			break;
		}
	}
	for(int i = 0; i < cut; i++)
	{
		g.video_bytes -= g.video.front().data.size();
		g.video.pop_front();
	}
	while(g.video_bytes > replay_max_bytes && !g.video.empty())
	{
		g.video_bytes -= g.video.front().data.size();
		g.video.pop_front();
	}
	const qint64 audio_from = g.video.empty() ? keep_from : g.video.front().us;
	while(!g.audio.empty() && g.audio.front().us < audio_from)
		g.audio.pop_front();
}

void clearReplay()
{
	g.video.clear();
	g.audio.clear();
	g.video_bytes = 0;
}

QString writeReplay(const std::vector<Packet> &video, const std::vector<Packet> &audio, const QByteArray &header,
		AVCodecID codec, int width, int height, const ChiakiAudioHeader &audio_header, const QString &path)
{
	AVFormatContext *oc = nullptr;
	const QByteArray path_utf8 = path.toUtf8();
	if(avformat_alloc_output_context2(&oc, nullptr, "mp4", path_utf8.constData()) < 0 || !oc)
		return QObject::tr("The video file could not be set up.");

	QString problem;
	AVPacket *pkt = av_packet_alloc();
	AVStream *vs = avformat_new_stream(oc, nullptr);
	AVStream *as = nullptr;
	const qint64 start_us = video.front().us;

	vs->codecpar->codec_type = AVMEDIA_TYPE_VIDEO;
	vs->codecpar->codec_id = codec;
	vs->codecpar->width = width;
	vs->codecpar->height = height;
	if(codec == AV_CODEC_ID_HEVC)
		vs->codecpar->codec_tag = MKTAG('h', 'v', 'c', '1');
	vs->codecpar->extradata = static_cast<uint8_t *>(av_mallocz(header.size() + AV_INPUT_BUFFER_PADDING_SIZE));
	memcpy(vs->codecpar->extradata, header.constData(), header.size());
	vs->codecpar->extradata_size = header.size();
	vs->time_base = AVRational{1, 90000};

	if(!audio.empty() && audio_header.rate && audio_header.channels)
	{
		as = avformat_new_stream(oc, nullptr);
		as->codecpar->codec_type = AVMEDIA_TYPE_AUDIO;
		as->codecpar->codec_id = AV_CODEC_ID_OPUS;
		as->codecpar->sample_rate = audio_header.rate;
		av_channel_layout_default(&as->codecpar->ch_layout, audio_header.channels);
		// The identification header an Opus track carries: version, channels, pre-skip, input rate, gain, mapping
		uint8_t head[19] = { 'O', 'p', 'u', 's', 'H', 'e', 'a', 'd', 1, audio_header.channels, 0, 0,
			static_cast<uint8_t>(audio_header.rate & 0xff), static_cast<uint8_t>((audio_header.rate >> 8) & 0xff),
			static_cast<uint8_t>((audio_header.rate >> 16) & 0xff), static_cast<uint8_t>((audio_header.rate >> 24) & 0xff), 0, 0, 0 };
		as->codecpar->extradata = static_cast<uint8_t *>(av_mallocz(sizeof(head) + AV_INPUT_BUFFER_PADDING_SIZE));
		memcpy(as->codecpar->extradata, head, sizeof(head));
		as->codecpar->extradata_size = sizeof(head);
		as->codecpar->frame_size = audio_header.frame_size;
		as->time_base = AVRational{1, static_cast<int>(audio_header.rate)};
	}

	if(avio_open(&oc->pb, path_utf8.constData(), AVIO_FLAG_WRITE) < 0)
	{
		problem = QObject::tr("The file could not be created.");
		goto done;
	}
	if(avformat_write_header(oc, nullptr) < 0)
	{
		problem = QObject::tr("This stream could not be written as an MP4.");
		goto close;
	}

	{
		// Both lists are in arrival order; write them merged by time
		size_t vi = 0, ai = 0;
		int64_t last_video_dts = -1;
		int64_t audio_samples = 0;
		bool audio_started = false;
		const int64_t frame_samples = audio_header.frame_size ? audio_header.frame_size : 480;
		while(vi < video.size() || (as && ai < audio.size()))
		{
			const bool take_video = vi < video.size() && (!as || ai >= audio.size() || video[vi].us <= audio[ai].us);
			if(take_video)
			{
				const Packet &p = video[vi];
				int64_t dts = av_rescale_q(p.us - start_us, AVRational{1, 1000000}, vs->time_base);
				if(dts <= last_video_dts)
					dts = last_video_dts + 1;
				int64_t next = vi + 1 < video.size() ? av_rescale_q(video[vi + 1].us - start_us, AVRational{1, 1000000}, vs->time_base) : dts + 1500;
				av_new_packet(pkt, p.data.size());
				memcpy(pkt->data, p.data.constData(), p.data.size());
				pkt->stream_index = vs->index;
				pkt->pts = pkt->dts = dts;
				pkt->duration = std::max<int64_t>(1, next - dts);
				if(p.key)
					pkt->flags |= AV_PKT_FLAG_KEY;
				last_video_dts = dts;
				vi++;
			}
			else
			{
				const Packet &p = audio[ai];
				if(!audio_started)
				{
					// Place the first audio frame where it arrived, then count frames so its timing is even
					audio_samples = av_rescale_q(std::max<qint64>(0, p.us - start_us), AVRational{1, 1000000}, as->time_base);
					audio_started = true;
				}
				av_new_packet(pkt, p.data.size());
				memcpy(pkt->data, p.data.constData(), p.data.size());
				pkt->stream_index = as->index;
				pkt->pts = pkt->dts = audio_samples;
				pkt->duration = frame_samples;
				pkt->flags |= AV_PKT_FLAG_KEY;
				audio_samples += frame_samples;
				ai++;
			}
			const int r = av_interleaved_write_frame(oc, pkt);
			av_packet_unref(pkt);
			if(r < 0)
			{
				problem = QObject::tr("Writing the video failed part way.");
				break;
			}
		}
	}
	if(av_write_trailer(oc) < 0 && problem.isEmpty())
		problem = QObject::tr("The video file could not be finished.");
close:
	avio_closep(&oc->pb);
done:
	av_packet_free(&pkt);
	avformat_free_context(oc);
	if(!problem.isEmpty())
		QFile::remove(path);
	return problem;
}

// ---- callbacks on the stream's threads ------------------------------------------

bool videoSample(uint8_t *buf, size_t buf_size, int32_t frames_lost, bool frame_recovered, void *user)
{
	const qint64 now = nowUs();
	ViceEngine *engine = ViceEngine::instance();
	ChiakiFfmpegDecoder *decoder = static_cast<ChiakiFfmpegDecoder *>(user);

	if(!g.socket_tagged)
	{
		g.socket_tagged = true;
		if(engine->effective(engine->qosTagging()) && g.session)
			vicePlatformTagSocket(g.session->stream_connection.takion.sock);
	}

	// A stall: nothing arrived for three frame times or more. That is the link pausing
	// (Wi-Fi leaving the channel, a congested hop), before this computer has done anything.
	const qint64 before = g.last_sample_us.exchange(now);
	const unsigned int stream_fps = g.session ? g.session->connect_info.video_profile.max_fps : 0;
	if(before > 0 && stream_fps > 0 && (now - before) * stream_fps > 2500000)
	{
		QMutexLocker locker(&g.mutex);
		g.stalls.push_back(now);
	}

	// Kept for the game's own frame rate (see the stats update)
	{
		QMutexLocker locker(&g.mutex);
		g.frame_sizes.push_back(buf_size);
		if(g.frame_sizes.size() > 120)
			g.frame_sizes.pop_front();
	}

	if(engine->replayEnabled() && decoder->av_codec)
	{
		const AVCodecID codec = decoder->av_codec->id;
		const int kind = classify(buf, buf_size, codec);
		QMutexLocker locker(&g.mutex);
		g.codec = codec;
		if((kind & HasParameterSets) && !(kind & HasPicture))
		{
			// The stream's description on its own: needed to open the file later, not a picture
			g.video_header = QByteArray(reinterpret_cast<const char *>(buf), static_cast<qsizetype>(buf_size));
		}
		else if(kind & HasPicture)
		{
			g.video.push_back(Packet{QByteArray(reinterpret_cast<const char *>(buf), static_cast<qsizetype>(buf_size)), now, (kind & IsKeyframe) != 0});
			g.video_bytes += static_cast<qint64>(buf_size);
			trimReplay(now);
		}
	}

	const bool ok = chiaki_ffmpeg_decoder_video_sample_cb(buf, buf_size, frames_lost, frame_recovered, user);
	if(decoder->codec_context && decoder->codec_context->width > 0)
	{
		g.width = decoder->codec_context->width;
		g.height = decoder->codec_context->height;
	}
	return ok;
}

void audioHeader(ChiakiAudioHeader *header, void *)
{
	{
		QMutexLocker locker(&g.mutex);
		g.audio_header = *header;
		g.audio_header_known = true;
	}
	if(g.audio_next.header_cb)
		g.audio_next.header_cb(header, g.audio_next.user);
}

void audioFrame(uint8_t *buf, size_t buf_size, void *)
{
	if(ViceEngine::instance()->replayEnabled())
	{
		QMutexLocker locker(&g.mutex);
		g.audio.push_back(Packet{QByteArray(reinterpret_cast<const char *>(buf), static_cast<qsizetype>(buf_size)), nowUs(), true});
	}
	if(g.audio_next.frame_cb)
		g.audio_next.frame_cb(buf, buf_size, g.audio_next.user);
}

void threadStarted(ChiakiThreadName name, void *)
{
	ViceEngine *engine = ViceEngine::instance();
	if(!engine->effective(engine->threadPriority()))
		return;
	// The threads a frame or a button press passes through
	if(name == CHIAKI_THREAD_NAME_TAKION || name == CHIAKI_THREAD_NAME_TAKION_SEND || name == CHIAKI_THREAD_NAME_FEEDBACK)
		vicePlatformRaiseCurrentThread();
}

} // namespace

// ---- hooks ------------------------------------------------------------------------

void viceSessionCreated(ChiakiSession *session, ChiakiFfmpegDecoder *decoder)
{
	ViceEngine *engine = ViceEngine::instance();
	{
		QMutexLocker locker(&g.mutex);
		g.session = session;
		g.socket_tagged = false;
		g.last_delivery_us = 0;
		g.last_drawn_us = 0;
		g.deliveries.clear();
		g.frame_sizes.clear();
		g.stutters.clear();
		g.stalls.clear();
		g.decode.clear();
		g.render.clear();
		g.pipeline.clear();
		g.video_header.clear();
		g.audio_header_known = false;
		clearReplay();
	}
	g.last_sample_us.store(0);
	g.pending_arrival_us.store(0);
	vicePlatformSessionBegin(engine->effective(engine->systemTuning()));
	chiaki_session_set_video_sample_cb(session, videoSample, decoder);
	QMetaObject::invokeMethod(engine, [engine]() { emit engine->statsChanged(); }, Qt::QueuedConnection);
}

void viceWrapAudioSink(ChiakiAudioSink *sink)
{
	g.audio_next = *sink;
	sink->header_cb = audioHeader;
	sink->frame_cb = audioFrame;
}

void viceSessionDestroyed(ChiakiSession *session)
{
	QMutexLocker locker(&g.mutex);
	if(g.session != session)
		return;
	g.session = nullptr;
	g.audio_next = {};
	clearReplay();
	locker.unlock();
	vicePlatformSessionEnd();
	viceRtxVideoSessionEnd();
}

void viceFrameDelivered()
{
	const qint64 now = nowUs();
	const qint64 arrival = g.last_sample_us.load();
	QMutexLocker locker(&g.mutex);
	if(!g.session)
		return;
	if(arrival > 0 && now >= arrival)
	{
		const double decode_ms = (now - arrival) / 1000.0;
		g.decode.push_back(Timed{now, decode_ms});
		if(g.run_active)
			g.run_decode.push_back(decode_ms);
	}
	g.pending_arrival_us.store(arrival);

	g.last_delivery_us = now;
	g.deliveries.push_back(now);
	while(g.deliveries.size() > 2 && g.deliveries.front() < now - 2000000)
		g.deliveries.pop_front();
	if(g.run_active)
		g.run_frames++;
}

void viceFrameRendered(qint64 render_us)
{
	const qint64 now = nowUs();
	const qint64 arrival = g.pending_arrival_us.exchange(0);
	QMutexLocker locker(&g.mutex);
	if(!g.session)
		return;
	const double render_ms = render_us / 1000.0;
	g.render.push_back(Timed{now, render_ms});
	if(g.run_active)
		g.run_render.push_back(render_ms);
	// Counted once per frame: a frame drawn again for the interface does not have a new arrival
	if(arrival > 0 && now >= arrival)
	{
		const double pipeline_ms = (now - arrival) / 1000.0;
		g.pipeline.push_back(Timed{now, pipeline_ms});
		if(g.run_active)
			g.run_pipeline.push_back(pipeline_ms);

		// A stutter: the picture stood still for three frame times or more. Draws land on display
		// refreshes, so gaps come in whole frame times; 2.5 sits between two and three. A single
		// repeated refresh (two frame times) is the stream and the display drifting past each
		// other, and happens a few times a second without anything being wrong.
		// The frame time comes from the rate frames have been arriving at over the last two seconds.
		if(g.last_drawn_us > 0 && g.deliveries.size() >= 30)
		{
			const double frame_time = static_cast<double>(g.deliveries.back() - g.deliveries.front()) / (g.deliveries.size() - 1);
			if(frame_time > 0 && (now - g.last_drawn_us) > frame_time * 2.5)
			{
				g.stutters.push_back(now);
				if(g.run_active)
					g.run_stutters++;
			}
		}
		g.last_drawn_us = now;
	}
}

void viceApplyStickTuning(ChiakiControllerState *state)
{
	ViceEngine *engine = ViceEngine::instance();
	const double exponent = engine->stickCurve() == 1 ? 1.5 : engine->stickCurve() == 2 ? 2.0 : 1.0;
	auto tune = [exponent](int16_t *x, int16_t *y, double deadzone) {
		if(deadzone <= 0.0 && exponent == 1.0)
			return;
		const double fx = *x / 32767.0, fy = *y / 32767.0;
		const double magnitude = std::min(1.0, std::sqrt(fx * fx + fy * fy));
		if(magnitude <= deadzone || magnitude <= 0.0)
		{
			*x = 0;
			*y = 0;
			return;
		}
		// Travel past the deadzone is stretched back to the full range, then shaped
		const double shaped = std::pow((magnitude - deadzone) / (1.0 - deadzone), exponent);
		const double factor = shaped / magnitude;
		*x = static_cast<int16_t>(std::clamp(fx * factor, -1.0, 1.0) * 32767.0);
		*y = static_cast<int16_t>(std::clamp(fy * factor, -1.0, 1.0) * 32767.0);
	};
	tune(&state->left_x, &state->left_y, engine->leftDeadzone());
	tune(&state->right_x, &state->right_y, engine->rightDeadzone());

	// A controller with no touchpad: View stands in for the touchpad click, which nearly
	// every game uses; View and Menu together are Create, which few need mid-game.
	if(engine->viewAsTouchpad() && (state->buttons & CHIAKI_CONTROLLER_BUTTON_SHARE))
	{
		if(state->buttons & CHIAKI_CONTROLLER_BUTTON_OPTIONS)
			state->buttons &= ~static_cast<uint32_t>(CHIAKI_CONTROLLER_BUTTON_OPTIONS);
		else
			state->buttons = (state->buttons & ~static_cast<uint32_t>(CHIAKI_CONTROLLER_BUTTON_SHARE)) | CHIAKI_CONTROLLER_BUTTON_TOUCHPAD;
	}
}

// ---- the QML object ---------------------------------------------------------------

ViceEngine *ViceEngine::instance()
{
	static ViceEngine *engine = new ViceEngine();
	return engine;
}

ViceEngine::ViceEngine(QObject *parent) : QObject(parent),
	stat_fps(not_measured), stat_decode(not_measured), stat_render(not_measured),
	stat_pipeline(not_measured), stat_rtt(not_measured), stat_input(not_measured)
{
	QSettings s;
	s.beginGroup(QStringLiteral("vice_engine"));
	low_delay = s.value(QStringLiteral("low_delay_decoder"), true).toBool();
	qos = s.value(QStringLiteral("qos_tagging"), true).toBool();
	thread_priority = s.value(QStringLiteral("thread_priority"), true).toBool();
	system_tuning = s.value(QStringLiteral("system_tuning"), true).toBool();
	replay_enabled = s.value(QStringLiteral("replay_enabled"), false).toBool();
	rtx_vsr = s.value(QStringLiteral("rtx_vsr"), false).toBool();
	left_deadzone = std::clamp(s.value(QStringLiteral("left_deadzone"), 0.0).toDouble(), 0.0, 0.5);
	right_deadzone = std::clamp(s.value(QStringLiteral("right_deadzone"), 0.0).toDouble(), 0.0, 0.5);
	stick_curve = std::clamp(s.value(QStringLiteral("stick_curve"), 0).toInt(), 0, 2);
	s.endGroup();

	chiaki_thread_set_affinity_cb(threadStarted, nullptr);
	applyTuning();

	stats_timer.setInterval(500);
	connect(&stats_timer, &QTimer::timeout, this, &ViceEngine::refreshStats);
	stats_timer.start();

	// The console sends one complete picture when the stream starts and then only changes.
	// A replay has to start from a complete picture, so while capture is on one is asked
	// for at this interval. That is the cost of having a replay ready.
	keyframe_timer.setInterval(15000);
	connect(&keyframe_timer, &QTimer::timeout, this, [this]() {
		QMutexLocker locker(&g.mutex);
		if(g.session && replay_enabled && !g.video.empty())
			chiaki_session_request_idr(g.session);
	});
	keyframe_timer.start();
}

void ViceEngine::save(const char *key, const QVariant &value)
{
	QSettings s;
	s.setValue(QStringLiteral("vice_engine/") + QLatin1String(key), value);
}

void ViceEngine::applyTuning()
{
	// Read when a decoder is created, so this takes effect from the next connection
	chiaki_ffmpeg_decoder_set_low_delay(effective(low_delay));
}

void ViceEngine::setLowDelayDecoder(bool on)
{
	if(low_delay == on)
		return;
	low_delay = on;
	save("low_delay_decoder", on);
	applyTuning();
	emit tuningChanged();
}

void ViceEngine::setQosTagging(bool on)
{
	if(qos == on)
		return;
	qos = on;
	save("qos_tagging", on);
	emit tuningChanged();
}

void ViceEngine::setThreadPriority(bool on)
{
	if(thread_priority == on)
		return;
	thread_priority = on;
	save("thread_priority", on);
	emit tuningChanged();
}

void ViceEngine::setSystemTuning(bool on)
{
	if(system_tuning == on)
		return;
	system_tuning = on;
	save("system_tuning", on);
	emit tuningChanged();
}

bool ViceEngine::systemTuningSupported() const
{
	return vicePlatformSystemTuningSupported();
}

void ViceEngine::setStockMode(bool on)
{
	if(stock == on)
		return;
	stock = on;
	applyTuning();
	emit tuningChanged();
}

void ViceEngine::setLeftDeadzone(double v)
{
	v = std::clamp(v, 0.0, 0.5);
	if(left_deadzone == v)
		return;
	left_deadzone = v;
	save("left_deadzone", v);
	emit sticksChanged();
}

void ViceEngine::setRightDeadzone(double v)
{
	v = std::clamp(v, 0.0, 0.5);
	if(right_deadzone == v)
		return;
	right_deadzone = v;
	save("right_deadzone", v);
	emit sticksChanged();
}

void ViceEngine::setViewAsTouchpad(bool on)
{
	if(view_as_touchpad.exchange(on) != on)
		emit sticksChanged();
}

void ViceEngine::setStickCurve(int v)
{
	v = std::clamp(v, 0, 2);
	if(stick_curve == v)
		return;
	stick_curve = v;
	save("stick_curve", v);
	emit sticksChanged();
}

void ViceEngine::setRtxSuperResolution(bool on)
{
	if(rtx_vsr.exchange(on) == on)
		return;
	save("rtx_vsr", on);
	emit tuningChanged();
}

bool ViceEngine::rtxPossible() const
{
	return viceRtxVideoPossible();
}

void ViceEngine::setReplayEnabled(bool on)
{
	if(replay_enabled == on)
		return;
	replay_enabled = on;
	save("replay_enabled", on);
	if(!on)
	{
		QMutexLocker locker(&g.mutex);
		clearReplay();
	}
	emit replayChanged();
}

void ViceEngine::refreshStats()
{
	const qint64 now = nowUs();
	QMutexLocker locker(&g.mutex);
	if(!g.session)
	{
		if(std::isnan(stat_fps) && std::isnan(stat_rtt) && stat_replay_seconds == 0)
			return;
		stat_fps = stat_unique_fps = stat_decode = stat_render = stat_pipeline = stat_rtt = stat_input = not_measured;
		stat_stutters = stat_stalls = 0;
		stat_replay_seconds = 0;
		locker.unlock();
		emit statsChanged();
		return;
	}

	while(!g.deliveries.empty() && g.deliveries.front() < now - 2000000)
		g.deliveries.pop_front();
	while(!g.stutters.empty() && g.stutters.front() < now - 60000000)
		g.stutters.pop_front();
	while(!g.stalls.empty() && g.stalls.front() < now - 60000000)
		g.stalls.pop_front();
	prune(g.decode, now - 5000000);
	prune(g.render, now - 5000000);
	prune(g.pipeline, now - 5000000);

	// Frames in the last two seconds; nothing until the first frame has come
	stat_fps = g.last_delivery_us > 0 ? g.deliveries.size() / 2.0 : not_measured;
	// The game's own frame rate. A game drawing 30 pictures a second in a 60 fps stream has each
	// one sent twice. The console's encoder does not make the repeat tiny (it spends a little on
	// sharpening it), but it is reliably much smaller than the new pictures either side of it.
	// So: the share of recent frames that sit well below both neighbours. Measured on a PS5,
	// repeats came to about 40% of their neighbours' size, frame after frame.
	if(g.last_delivery_us > 0 && g.frame_sizes.size() >= 62)
	{
		const size_t end = g.frame_sizes.size() - 1, begin = end - 60;
		int repeats = 0;
		for(size_t i = begin; i < end; i++)
		{
			const double around = (static_cast<double>(g.frame_sizes[i - 1]) + static_cast<double>(g.frame_sizes[i + 1])) / 2.0;
			if(static_cast<double>(g.frame_sizes[i]) < around * 0.8)
				repeats++;
		}
		const double share = repeats / 60.0;
		// Every other frame a repeat is the common case; quiet scenes blur a few of them, so it is held at half
		stat_unique_fps = share >= 0.4 ? stat_fps / 2.0 : stat_fps * (1.0 - share);
	}
	else
		stat_unique_fps = g.last_delivery_us > 0 ? stat_fps : not_measured;
	stat_decode = medianOf(g.decode);
	stat_render = medianOf(g.render);
	stat_pipeline = medianOf(g.pipeline);
	stat_stutters = static_cast<int>(g.stutters.size());
	stat_stalls = static_cast<int>(g.stalls.size());
	stat_rtt = g.session->rtt_us > 0 ? g.session->rtt_us / 1000.0 : not_measured;
	const ChiakiStreamConnection *connection = &g.session->stream_connection;
	stat_input = connection->feedback_sender_active && connection->feedback_sender.input_latency_us > 0
		? connection->feedback_sender.input_latency_us / 1000.0 : not_measured;

	// What a save would hold: from the first complete picture in the buffer to now
	stat_replay_seconds = 0;
	for(const Packet &p : g.video)
	{
		if(p.key)
		{
			stat_replay_seconds = std::min(30.0, (g.video.back().us - p.us) / 1000000.0);
			break;
		}
	}
	locker.unlock();
	emit statsChanged();
}

void ViceEngine::beginRun()
{
	QMutexLocker locker(&g.mutex);
	g.run_active = true;
	g.run_start_us = nowUs();
	g.run_frames = 0;
	g.run_stutters = 0;
	g.run_pipeline.clear();
	g.run_decode.clear();
	g.run_render.clear();
}

QVariantMap ViceEngine::endRun()
{
	QMutexLocker locker(&g.mutex);
	QVariantMap out;
	if(!g.run_active)
		return out;
	g.run_active = false;
	const double seconds = (nowUs() - g.run_start_us) / 1000000.0;
	out[QStringLiteral("seconds")] = seconds;
	out[QStringLiteral("frames")] = static_cast<qlonglong>(g.run_frames);
	out[QStringLiteral("fps")] = seconds > 0 ? g.run_frames / seconds : 0.0;
	out[QStringLiteral("stutters")] = static_cast<qlonglong>(g.run_stutters);
	out[QStringLiteral("stuttersPerMinute")] = seconds > 0 ? g.run_stutters * 60.0 / seconds : 0.0;
	// A measurement that was never taken is left out rather than reported as zero
	if(!g.run_pipeline.empty())
	{
		out[QStringLiteral("pipelineMedian")] = median(g.run_pipeline);
		out[QStringLiteral("pipelineP99")] = percentile(g.run_pipeline, 0.99);
	}
	if(!g.run_decode.empty())
		out[QStringLiteral("decodeMedian")] = median(g.run_decode);
	if(!g.run_render.empty())
		out[QStringLiteral("renderMedian")] = median(g.run_render);
	return out;
}

void ViceEngine::saveReplay()
{
	if(replay_saving)
		return;

	std::vector<Packet> video, audio;
	QByteArray header;
	AVCodecID codec;
	int width, height;
	ChiakiAudioHeader audio_header;
	{
		QMutexLocker locker(&g.mutex);
		const qint64 newest = g.video.empty() ? 0 : g.video.back().us;
		// Start at the newest complete picture that still covers the last 30 s; failing that, the oldest there is
		int start = -1;
		for(int i = 0; i < static_cast<int>(g.video.size()); i++)
		{
			if(!g.video[i].key)
				continue;
			if(start >= 0 && g.video[i].us > newest - replay_length_us)
				break;
			start = i;
		}
		if(start < 0 || g.video_header.isEmpty() || g.width <= 0)
		{
			locker.unlock();
			emit replayFailed(tr("Nothing to save yet. The stream has not sent a complete picture to start from."));
			return;
		}
		video.assign(g.video.begin() + start, g.video.end());
		for(const Packet &p : g.audio)
		{
			if(p.us >= video.front().us)
				audio.push_back(p);
		}
		header = g.video_header;
		codec = g.codec;
		width = g.width;
		height = g.height;
		audio_header = g.audio_header_known ? g.audio_header : ChiakiAudioHeader{};
	}

	QString folder = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
	if(folder.isEmpty())
		folder = QDir::homePath();
	folder += QStringLiteral("/Project Vice");
	if(!QDir().mkpath(folder))
	{
		emit replayFailed(tr("The folder %1 could not be created.").arg(folder));
		return;
	}
	const QString path = folder + QStringLiteral("/Replay ") + QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH.mm.ss")) + QStringLiteral(".mp4");
	const double seconds = (video.back().us - video.front().us) / 1000000.0;

	replay_saving = true;
	emit replayChanged();
	(void)QtConcurrent::run([this, video = std::move(video), audio = std::move(audio), header, codec, width, height, audio_header, path, seconds]() {
		const QString problem = writeReplay(video, audio, header, codec, width, height, audio_header, path);
		QMetaObject::invokeMethod(this, [this, problem, path, seconds]() {
			replay_saving = false;
			emit replayChanged();
			// Success only once the file is really there
			if(problem.isEmpty() && QFileInfo::exists(path))
				emit replaySaved(path, seconds);
			else
				emit replayFailed(problem.isEmpty() ? tr("The file was not written.") : problem);
		}, Qt::QueuedConnection);
	});
}

void ViceEngine::refreshWifi()
{
	QString band;
	int signal = -1;
	if(!vicePlatformWifi(&band, &signal))
	{
		band.clear();
		signal = -1;
	}
	if(band == wifi_band && signal == wifi_signal)
		return;
	wifi_band = band;
	wifi_signal = signal;
	emit wifiChanged();
}

void ViceEngine::revealFile(const QString &path)
{
#if defined(Q_OS_MACOS)
	QProcess::startDetached(QStringLiteral("open"), { QStringLiteral("-R"), path });
#elif defined(Q_OS_WIN)
	QProcess::startDetached(QStringLiteral("explorer"), { QStringLiteral("/select,") + QDir::toNativeSeparators(path) });
#else
	QDesktopServices::openUrl(QUrl::fromLocalFile(QFileInfo(path).absolutePath()));
#endif
}
