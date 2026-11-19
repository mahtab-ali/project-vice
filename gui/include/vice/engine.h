// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Project Vice: what the app adds around a stream session. Measurement,
// tuning switches, stick tuning, replay capture and Wi-Fi details live here,
// fed by a handful of hooks in upstream's session and renderer code.

#ifndef VICE_ENGINE_H
#define VICE_ENGINE_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantMap>

#include <chiaki/audioreceiver.h>
#include <chiaki/controller.h>
#include <chiaki/ffmpegdecoder.h>
#include <chiaki/session.h>

// ---- hooks called from streamsession.cpp ----------------------------------------
// Takes over delivery of encoded video to the decoder, to time it and keep a replay buffer
void viceSessionCreated(ChiakiSession *session, ChiakiFfmpegDecoder *decoder);
// Lets the replay buffer see the encoded audio on its way to the decoder
void viceWrapAudioSink(ChiakiAudioSink *sink);
void viceSessionDestroyed(ChiakiSession *session);
// Deadzone and response curve, applied to a controller state about to be sent
void viceApplyStickTuning(ChiakiControllerState *state);

// ---- hooks called from qmlmainwindow.cpp -----------------------------------------
// A decoded frame reached the renderer
void viceFrameDelivered();
// A video frame was drawn; render_us is the time the draw call took
void viceFrameRendered(qint64 render_us);

/**
 * The one object QML talks to, registered as the singleton vice.backend/Engine.
 * A statistic is NaN until it has been measured; nothing here is estimated.
 */
class ViceEngine : public QObject
{
	Q_OBJECT

	// Tuning. Each is its own switch so it can be measured on and off.
	Q_PROPERTY(bool lowDelayDecoder READ lowDelayDecoder WRITE setLowDelayDecoder NOTIFY tuningChanged)
	Q_PROPERTY(bool qosTagging READ qosTagging WRITE setQosTagging NOTIFY tuningChanged)
	Q_PROPERTY(bool threadPriority READ threadPriority WRITE setThreadPriority NOTIFY tuningChanged)
	// Windows only: 1 ms timers and Wi-Fi streaming mode for the length of a session
	Q_PROPERTY(bool systemTuning READ systemTuning WRITE setSystemTuning NOTIFY tuningChanged)
	Q_PROPERTY(bool systemTuningSupported READ systemTuningSupported CONSTANT)
	// Turns every switch above off without changing them. Used for the "stock" half of a benchmark.
	Q_PROPERTY(bool stockMode READ stockMode WRITE setStockMode NOTIFY tuningChanged)

	// Sticks: deadzone as a fraction of travel (0 to 0.5), curve 0 linear, 1 smooth, 2 precise
	Q_PROPERTY(double leftDeadzone READ leftDeadzone WRITE setLeftDeadzone NOTIFY sticksChanged)
	Q_PROPERTY(double rightDeadzone READ rightDeadzone WRITE setRightDeadzone NOTIFY sticksChanged)
	Q_PROPERTY(int stickCurve READ stickCurve WRITE setStickCurve NOTIFY sticksChanged)

	// Statistics of the running session, refreshed twice a second
	Q_PROPERTY(double fps READ fps NOTIFY statsChanged)
	Q_PROPERTY(double decodeMs READ decodeMs NOTIFY statsChanged)
	Q_PROPERTY(double renderMs READ renderMs NOTIFY statsChanged)
	// From an encoded frame arriving to that frame being drawn: the client's share of the delay
	Q_PROPERTY(double pipelineMs READ pipelineMs NOTIFY statsChanged)
	// Frames that arrived more than twice the usual interval after the one before, in the last minute
	Q_PROPERTY(int stuttersPerMinute READ stuttersPerMinute NOTIFY statsChanged)
	// Times in the last minute that nothing arrived from the console for three frame times or more
	Q_PROPERTY(int stallsPerMinute READ stallsPerMinute NOTIFY statsChanged)
	// Round trip to the console, measured once while connecting
	Q_PROPERTY(double rttMs READ rttMs NOTIFY statsChanged)
	// From a controller change reaching the engine to its packet being sent
	Q_PROPERTY(double inputMs READ inputMs NOTIFY statsChanged)

	// Replay: the last seconds of the stream as it arrived, kept in memory
	Q_PROPERTY(bool replayEnabled READ replayEnabled WRITE setReplayEnabled NOTIFY replayChanged)
	Q_PROPERTY(double replaySeconds READ replaySeconds NOTIFY statsChanged)
	Q_PROPERTY(bool replaySaving READ replaySaving NOTIFY replayChanged)

	// Wi-Fi of this computer: "2.4", "5", "6" or "" when not on Wi-Fi or not known; signal 0 to 100 or -1
	Q_PROPERTY(QString wifiBand READ wifiBand NOTIFY wifiChanged)
	Q_PROPERTY(int wifiSignal READ wifiSignal NOTIFY wifiChanged)

	public:
		static ViceEngine *instance();

		bool lowDelayDecoder() const { return low_delay; }
		void setLowDelayDecoder(bool on);
		bool qosTagging() const { return qos; }
		void setQosTagging(bool on);
		bool threadPriority() const { return thread_priority; }
		void setThreadPriority(bool on);
		bool systemTuning() const { return system_tuning; }
		void setSystemTuning(bool on);
		bool systemTuningSupported() const;
		bool stockMode() const { return stock; }
		void setStockMode(bool on);

		double leftDeadzone() const { return left_deadzone; }
		void setLeftDeadzone(double v);
		double rightDeadzone() const { return right_deadzone; }
		void setRightDeadzone(double v);
		int stickCurve() const { return stick_curve; }
		void setStickCurve(int v);

		double fps() const { return stat_fps; }
		double decodeMs() const { return stat_decode; }
		double renderMs() const { return stat_render; }
		double pipelineMs() const { return stat_pipeline; }
		int stuttersPerMinute() const { return stat_stutters; }
		int stallsPerMinute() const { return stat_stalls; }
		double rttMs() const { return stat_rtt; }
		double inputMs() const { return stat_input; }

		bool replayEnabled() const { return replay_enabled; }
		void setReplayEnabled(bool on);
		double replaySeconds() const { return stat_replay_seconds; }
		bool replaySaving() const { return replay_saving; }

		QString wifiBand() const { return wifi_band; }
		int wifiSignal() const { return wifi_signal; }

		// Starts and ends a measured run. endRun returns what was measured:
		// seconds, frames, fps, pipelineMedian, pipelineP99, decodeMedian, renderMedian, stutters, stuttersPerMinute
		Q_INVOKABLE void beginRun();
		Q_INVOKABLE QVariantMap endRun();
		// Writes the buffered stream to an MP4 in the user's videos folder; answers with replaySaved or replayFailed
		Q_INVOKABLE void saveReplay();
		Q_INVOKABLE void refreshWifi();
		// Shows a saved file in the system's file manager
		Q_INVOKABLE void revealFile(const QString &path);

		// Used by the hooks
		bool effective(bool setting) const { return setting && !stock; }

	signals:
		void tuningChanged();
		void sticksChanged();
		void statsChanged();
		void replayChanged();
		void wifiChanged();
		void replaySaved(const QString &path, double seconds);
		void replayFailed(const QString &reason);

	private:
		explicit ViceEngine(QObject *parent = nullptr);
		void applyTuning();
		void refreshStats();
		void save(const char *key, const QVariant &value);

		bool low_delay = true, qos = true, thread_priority = true, system_tuning = true, stock = false;
		double left_deadzone = 0.0, right_deadzone = 0.0;
		int stick_curve = 0;
		double stat_fps, stat_decode, stat_render, stat_pipeline, stat_rtt, stat_input, stat_replay_seconds = 0;
		int stat_stutters = 0, stat_stalls = 0;
		// Off unless asked for: it makes the console send a full picture every 15 seconds
		bool replay_enabled = false, replay_saving = false;
		QString wifi_band;
		int wifi_signal = -1;
		QTimer stats_timer;
		QTimer keyframe_timer;
};

// Platform pieces, in engine_platform.cpp / wifi_mac.mm
void vicePlatformRaiseCurrentThread();
void vicePlatformTagSocket(chiaki_socket_t sock);
void vicePlatformSessionBegin(bool system_tuning);
void vicePlatformSessionEnd();
bool vicePlatformSystemTuningSupported();
// band: "2.4", "5", "6" or empty; signal 0..100 or -1. Returns false when not on Wi-Fi or unknown.
bool vicePlatformWifi(QString *band, int *signal);

#endif // VICE_ENGINE_H
