package com.fluxer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.unifiedpush.android.connector.data.PushMessage
import org.unifiedpush.flutter.connector.UnifiedPushService

class FluxerUnifiedPushService : UnifiedPushService() {
    private var lastStartId = 0

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        lastStartId = startId
        activeService = this
        startPushForeground()
        if (!backgroundSessionOpen) {
            stopPushWork()
        }
        return START_NOT_STICKY
    }

    override fun onTimeout(startId: Int, fgsType: Int) {
        closeBackgroundSession()
    }

    override fun onDestroy() {
        if (activeService === this) {
            activeService = null
            serviceStartRequested = false
        }
        super.onDestroy()
    }

    override fun getEngine(context: Context): FlutterEngine = beginBackgroundWork(context)

    override fun onMessage(message: PushMessage, instance: String) {
        if (MainEngineState.visible) {
            super.onMessage(message, instance)
            return
        }
        val appContext = applicationContext
        val payload = messagePayload(message, instance)
        handler.post { acceptBackgroundMessage(appContext, payload) }
    }

    private fun startPushForeground() {
        val type =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            } else {
                0
            }
        runCatching {
            ServiceCompat.startForeground(
                this,
                FOREGROUND_NOTIFICATION_ID,
                buildForegroundNotification(),
                type,
            )
        }.onFailure { error ->
            FluxerNativeMeasure.reportHandled(
                error,
                source = "unified_push",
                context = "start foreground",
            )
        }
    }

    private fun stopPushWork() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf(lastStartId)
    }

    private fun buildForegroundNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(
                NotificationChannel(
                    FOREGROUND_CHANNEL_ID,
                    FOREGROUND_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_MIN,
                ).apply {
                    setShowBadge(false)
                },
            )
        }
        return NotificationCompat.Builder(this, FOREGROUND_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_fluxer)
            .setColor(PUSH_ACCENT_COLOR)
            .setContentTitle(FOREGROUND_NOTIFICATION_TITLE)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_DEFERRED)
            .setShowWhen(false)
            .setLocalOnly(true)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val SESSION_MS = 30_000L
        private const val FOREGROUND_NOTIFICATION_ID = 0x75706e
        private const val FOREGROUND_CHANNEL_ID = "fluxer_unified_push"
        private const val FOREGROUND_CHANNEL_NAME = "Background sync"
        private const val FOREGROUND_NOTIFICATION_TITLE = "Checking for new messages"

        private val handler = Handler(Looper.getMainLooper())
        private val closeSession = Runnable { closeBackgroundSession() }
        private val ledger = UnifiedPushDeliveryLedger()
        private val pendingMessages = ArrayDeque<Map<String, Any?>>()
        private var backgroundEngine: FlutterEngine? = null
        private var wakeLock: PowerManager.WakeLock? = null
        private var backgroundSessionOpen = false
        private var dartBackgroundReady = false
        private var serviceStartRequested = false
        private var activeService: FluxerUnifiedPushService? = null

        fun onDartBackgroundReady() {
            dartBackgroundReady = true
            while (pendingMessages.isNotEmpty()) {
                sendMessageToDart(pendingMessages.removeFirst())
            }
        }

        fun canCloseBackgroundSession(handled: Int): Boolean = ledger.canClose(handled)

        fun closeBackgroundSessionIfIdle(handled: Int) {
            if (ledger.canClose(handled)) {
                closeBackgroundSession()
            }
        }

        private fun acceptBackgroundMessage(context: Context, payload: Map<String, Any?>) {
            try {
                beginBackgroundWork(context)
            } catch (error: Exception) {
                FluxerNativeMeasure.reportHandled(
                    error,
                    source = "unified_push",
                    context = "start background engine",
                )
                return
            }
            ledger.onAccepted()
            if (dartBackgroundReady) {
                sendMessageToDart(payload)
            } else {
                pendingMessages.addLast(payload)
            }
        }

        private fun beginBackgroundWork(context: Context): FlutterEngine {
            val appContext = context.applicationContext ?: context
            backgroundSessionOpen = true
            handler.removeCallbacks(closeSession)
            handler.postDelayed(closeSession, SESSION_MS)
            holdCpu(appContext)
            requestServiceStart(appContext)
            try {
                return backgroundEngine ?: createBackgroundEngine(appContext).also {
                    backgroundEngine = it
                }
            } catch (error: Exception) {
                closeBackgroundSession()
                throw error
            }
        }

        private fun requestServiceStart(context: Context) {
            if (serviceStartRequested) {
                return
            }
            serviceStartRequested =
                runCatching {
                    ContextCompat.startForegroundService(
                        context,
                        Intent(context, FluxerUnifiedPushService::class.java),
                    )
                }.isSuccess
        }

        private fun createBackgroundEngine(context: Context): FlutterEngine {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
            // Fork: without audio_service, so a push does not start the full app (tyne-chat/tyne#210).
            val engine = ForkPushEngine(context)
            try {
                GeneratedPluginRegistrant.registerWith(engine)
                FluxerUnifiedPushBackgroundBridge.registerWith(engine)
                engine.localizationPlugin.sendLocalesToFlutter(context.resources.configuration)
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault(),
                    listOf("--unifiedpush-bg"),
                )
            } catch (error: Exception) {
                engine.destroy()
                throw error
            }
            return engine
        }

        private fun holdCpu(context: Context) {
            val lock =
                wakeLock
                    ?: (context.getSystemService(POWER_SERVICE) as PowerManager)
                        .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "fluxer:unifiedpush")
                        .also {
                            it.setReferenceCounted(false)
                            wakeLock = it
                        }
            lock.acquire(SESSION_MS)
        }

        private fun closeBackgroundSession() {
            if (!backgroundSessionOpen) {
                return
            }
            backgroundSessionOpen = false
            handler.removeCallbacks(closeSession)
            // Fork: the push engine is kept while the app's engine exists (tyne-chat/tyne#474).
            if (forkEndSessionKeepingEngine()) return
            ledger.reset()
            pendingMessages.clear()
            dartBackgroundReady = false
            val engine = backgroundEngine
            backgroundEngine = null
            engine?.destroy()
            serviceStartRequested = false
            activeService?.stopPushWork()
            wakeLock?.takeIf { it.isHeld }?.release()
        }

        private fun sendMessageToDart(payload: Map<String, Any?>) {
            val engine = backgroundEngine ?: return
            MethodChannel(
                engine.dartExecutor.binaryMessenger,
                FluxerUnifiedPushBackgroundBridge.CHANNEL_NAME,
            ).invokeMethod(FluxerUnifiedPushBackgroundBridge.METHOD_MESSAGE, payload)
        }

        private fun messagePayload(
            message: PushMessage,
            instance: String,
        ): Map<String, Any?> =
            mapOf(
                FluxerUnifiedPushBackgroundBridge.ARG_INSTANCE to instance,
                FluxerUnifiedPushBackgroundBridge.ARG_CONTENT to message.content,
                FluxerUnifiedPushBackgroundBridge.ARG_DECRYPTED to message.decrypted,
            )

        // Fork: never destroy the push engine while the app's engine exists (tyne-chat/tyne#474).
        // shared_preferences_android keeps one process-wide registration that every engine's
        // attach overwrites and any engine's detach removes: destroying the push engine then
        // left the app without preferences, stuck at its launch screen (2026-11-02, build 170).
        // The app's engine is the activity's, or audio_service's cached one, which can outlive
        // the activity, so once one has started the push engine is kept for good. Between
        // sessions it sits idle, and the next session reuses it.

        /** Set before the app's first engine registers its plugins (`MainActivity.onCreate`). */
        private var forkAppEngineStarted = false

        /**
         * Called by `MainActivity.onCreate` before its engine registers plugins. An idle push engine
         * is destroyed now, while that is still safe; one in the middle of a session stays.
         */
        fun forkBeforeAppEngine() {
            val engine = backgroundEngine
            if (!backgroundSessionOpen && engine != null) {
                ledger.reset()
                pendingMessages.clear()
                dartBackgroundReady = false
                backgroundEngine = null
                engine.destroy()
            }
            forkAppEngineStarted = true
        }

        /**
         * The end of [closeBackgroundSession] once an app engine has started: the session's
         * foreground service and wake lock go, the engine (and its Dart side, still ready) stays.
         * The ledger is not reset: the kept engine's Dart side counts the pushes it handled over
         * its whole life (`UnifiedPushBackgroundWork.handled`), so the ledger counts the pushes it
         * accepted over the same span, and pushes still queued for it stay queued. Returns false
         * when upstream's ending, which destroys the engine, is safe.
         */
        private fun forkEndSessionKeepingEngine(): Boolean {
            if (!forkAppEngineStarted || backgroundEngine == null) {
                return false
            }
            serviceStartRequested = false
            activeService?.stopPushWork()
            wakeLock?.takeIf { it.isHeld }?.release()
            return true
        }
    }
}
