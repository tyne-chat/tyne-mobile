package com.fluxer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.unifiedpush.android.connector.FailedReason
import org.unifiedpush.android.connector.data.PushEndpoint
import org.unifiedpush.android.connector.data.PushMessage
import org.unifiedpush.flutter.connector.PLUGIN_ARG_ENDPOINT_KEY_AUTH
import org.unifiedpush.flutter.connector.PLUGIN_ARG_ENDPOINT_KEY_PUBKEY
import org.unifiedpush.flutter.connector.PLUGIN_ARG_ENDPOINT_TEMP
import org.unifiedpush.flutter.connector.PLUGIN_ARG_ENDPOINT_URL
import org.unifiedpush.flutter.connector.PLUGIN_ARG_INSTANCE
import org.unifiedpush.flutter.connector.PLUGIN_ARG_MESSAGE_CONTENT
import org.unifiedpush.flutter.connector.PLUGIN_ARG_MESSAGE_DECRYPTED
import org.unifiedpush.flutter.connector.PLUGIN_ARG_REASON
import org.unifiedpush.flutter.connector.PLUGIN_CALL_MESSAGE
import org.unifiedpush.flutter.connector.PLUGIN_CALL_NEW_ENDPOINT
import org.unifiedpush.flutter.connector.PLUGIN_CALL_REGISTRATION_FAILED
import org.unifiedpush.flutter.connector.PLUGIN_CALL_TEMP_UNAVAILABLE
import org.unifiedpush.flutter.connector.PLUGIN_CALL_UNREGISTERED
import org.unifiedpush.flutter.connector.PLUGIN_CHANNEL
import org.unifiedpush.flutter.connector.Plugin
import org.unifiedpush.flutter.connector.UnifiedPushService

class FluxerUnifiedPushService : UnifiedPushService() {
    private var bindCount = 0
    private var stopWhenUnbound = false

    override fun onCreate() {
        if (!mainEngineRunning) {
            if (backgroundEngine == null) {
                openBackgroundSession()
                startPushForeground()
                try {
                    getEngine(this)
                } catch (error: Exception) {
                    closeBackgroundSession()
                    throw error
                }
            } else if (backgroundSessionOpen) {
                // Fork: only for a push session, which stops it again (tyne-chat/tyne#474).
                startPushForeground()
            }
            ensurePluginOnBackgroundEngine()
        }
        super.onCreate()
    }

    override fun onBind(intent: Intent?): IBinder? {
        bindCount += 1
        return super.onBind(intent)
    }

    override fun onUnbind(intent: Intent?): Boolean {
        bindCount = maxOf(bindCount - 1, 0)
        if (stopWhenUnbound && bindCount == 0 && !backgroundSessionOpen) {
            stopWhenUnbound = false
            stopSelf()
        }
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        if (activeService === this) {
            foregroundActive = false
            activeService = null
        }
        // Fork: tyne-chat/tyne#474.
        forkNoteServiceDestroyed()
        super.onDestroy()
    }

    override fun getEngine(context: Context): FlutterEngine {
        val cached = backgroundEngine
        if (cached != null) {
            return cached
        }
        val appContext = context.applicationContext ?: context
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)
        // Fork: without audio_service, so a push does not start the full app (tyne-chat/tyne#210).
        val engine = ForkPushEngine(appContext)
        try {
            GeneratedPluginRegistrant.registerWith(engine)
            FluxerUnifiedPushBackgroundBridge.registerWith(engine)
            engine.localizationPlugin.sendLocalesToFlutter(
                appContext.resources.configuration,
            )
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
                listOf("--unifiedpush-bg"),
            )
        } catch (error: Exception) {
            engine.destroy()
            throw error
        }
        backgroundEngine = engine
        return engine
    }

    override fun onMessage(message: PushMessage, instance: String) {
        // Fork: every push goes through forkAcceptPush, on any thread (tyne-chat/tyne#474).
        if (forkAcceptPush(message, instance)) {
            return
        }
        if (deliverToBackgroundEngineIfActive(PLUGIN_CALL_MESSAGE, messagePayload(message, instance))) {
            return
        }
        super.onMessage(message, instance)
    }

    override fun onNewEndpoint(endpoint: PushEndpoint, instance: String) {
        if (
            deliverToBackgroundEngineIfActive(
                PLUGIN_CALL_NEW_ENDPOINT,
                endpointPayload(endpoint, instance),
            )
        ) {
            return
        }
        super.onNewEndpoint(endpoint, instance)
    }

    override fun onRegistrationFailed(reason: FailedReason, instance: String) {
        if (
            deliverToBackgroundEngineIfActive(
                PLUGIN_CALL_REGISTRATION_FAILED,
                mapOf(
                    PLUGIN_ARG_INSTANCE to instance,
                    PLUGIN_ARG_REASON to reason.name,
                ),
            )
        ) {
            return
        }
        super.onRegistrationFailed(reason, instance)
    }

    override fun onUnregistered(instance: String) {
        if (
            deliverToBackgroundEngineIfActive(
                PLUGIN_CALL_UNREGISTERED,
                mapOf(PLUGIN_ARG_INSTANCE to instance),
            )
        ) {
            return
        }
        super.onUnregistered(instance)
    }

    override fun onTempUnavailable(instance: String) {
        if (
            deliverToBackgroundEngineIfActive(
                PLUGIN_CALL_TEMP_UNAVAILABLE,
                mapOf(PLUGIN_ARG_INSTANCE to instance),
            )
        ) {
            return
        }
        super.onTempUnavailable(instance)
    }

    private fun deliverToBackgroundEngineIfActive(
        method: String,
        data: Map<String, Any?>,
    ): Boolean {
        // Fork: an idle kept engine has no listener for these; leave them for the app (tyne-chat/tyne#474).
        if (mainEngineRunning || backgroundEngine == null || !backgroundSessionOpen) {
            return false
        }
        enqueueOrDeliverFlutterEvent(method, data)
        return true
    }

    private fun startPushForeground() {
        activeService = this
        if (foregroundActive) {
            return
        }
        val type =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            } else {
                0
            }
        val started =
            runCatching {
                ServiceCompat.startForeground(
                    this,
                    FOREGROUND_NOTIFICATION_ID,
                    buildForegroundNotification(),
                    type,
                )
            }
        if (started.isSuccess) {
            foregroundActive = true
        }
        holdCpu(applicationContext)
    }

    private fun stopPushForeground() {
        if (!foregroundActive) {
            return
        }
        foregroundActive = false
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
    }

    private fun buildForegroundNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager?.getNotificationChannel(FOREGROUND_CHANNEL_ID) == null
        ) {
            manager?.createNotificationChannel(
                NotificationChannel(
                    FOREGROUND_CHANNEL_ID,
                    FOREGROUND_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_MIN,
                ),
            )
        }
        return NotificationCompat.Builder(this, FOREGROUND_CHANNEL_ID)
            .setSmallIcon(R.drawable.fluxer_logo_monochrome)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun holdCpu(context: Context?) {
        val appContext = context?.applicationContext ?: return
        val lock =
            wakeLock
                ?: (appContext.getSystemService(POWER_SERVICE) as PowerManager)
                    .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "fluxer:unifiedpush")
                    .also {
                        it.setReferenceCounted(false)
                        wakeLock = it
                    }
        if (!lock.isHeld) {
            lock.acquire()
        }
        handler.removeCallbacks(releaseCpu)
        handler.postDelayed(releaseCpu, CPU_HOLD_MS)
    }

    private fun requestStop() {
        if (bindCount == 0) {
            stopSelf()
            if (activeService === this) {
                activeService = null
            }
            return
        }
        stopWhenUnbound = true
    }

    companion object {
        private const val CPU_HOLD_MS = 30_000L
        private const val FOREGROUND_NOTIFICATION_ID = 0x75706e
        private const val FOREGROUND_CHANNEL_ID = "fluxer_unified_push"
        private const val FOREGROUND_CHANNEL_NAME = "Notifications"

        private val handler = Handler(Looper.getMainLooper())
        private val releaseCpu = Runnable {
            val lock = wakeLock
            if (lock != null && lock.isHeld) {
                lock.release()
            }
        }
        // Fork: a session that times out also discards the engine (tyne-chat/tyne#474).
        private val closeSession = Runnable {
            forkSessionTimedOut = true
            closeBackgroundSession()
        }
        private var backgroundEngine: FlutterEngine? = null
        private var wakeLock: PowerManager.WakeLock? = null
        private var mainEngineRunning = false
        private var foregroundActive = false
        private var backgroundSessionOpen = false
        private var dartBackgroundReady = false
        private val pendingFlutterEvents = ArrayDeque<UnifiedPushFlutterEvent>()
        private var activeService: FluxerUnifiedPushService? = null

        fun noteMainEngineStarted() {
            mainEngineRunning = true
            // Fork: tyne-chat/tyne#474.
            forkOnMainEngineStarted()
            handler.postDelayed(
                {
                    if (mainEngineRunning) {
                        discardBackgroundEngine()
                    }
                },
                CPU_HOLD_MS,
            )
        }

        fun noteMainEngineStopped() {
            mainEngineRunning = false
            discardBackgroundEngine()
        }

        fun onDartBackgroundReady() {
            val batch = ArrayList<UnifiedPushFlutterEvent>()
            synchronized(pendingFlutterEvents) {
                dartBackgroundReady = true
                while (pendingFlutterEvents.isNotEmpty()) {
                    batch.add(pendingFlutterEvents.removeFirst())
                }
            }
            for (event in batch) {
                deliverFlutterEvent(event.method, event.data)
            }
        }

        // Fork: Dart reports how many pushes it has handled (tyne-chat/tyne#474).
        fun onDartBackgroundFinished(handled: Int? = null) {
            if (!forkSessionLedger.shouldClose(handled)) {
                return
            }
            closeBackgroundSession()
        }

        private fun openBackgroundSession() {
            if (backgroundSessionOpen) {
                return
            }
            backgroundSessionOpen = true
            // Fork: tyne-chat/tyne#474.
            forkSessionGeneration = forkMainEngineGeneration
            handler.removeCallbacks(closeSession)
            handler.postDelayed(closeSession, CPU_HOLD_MS)
        }

        private fun closeBackgroundSession() {
            if (!backgroundSessionOpen) {
                return
            }
            backgroundSessionOpen = false
            handler.removeCallbacks(closeSession)
            val service = activeService
            service?.stopPushForeground()
            // Fork: keep the engine for the next push, release the CPU now (tyne-chat/tyne#474).
            forkOnSessionClose()
            service?.requestStop()
        }

        private fun enqueueOrDeliverFlutterEvent(
            method: String,
            data: Map<String, Any?>,
        ) {
            synchronized(pendingFlutterEvents) {
                if (!dartBackgroundReady) {
                    pendingFlutterEvents.addLast(UnifiedPushFlutterEvent(method, data))
                    return
                }
            }
            deliverFlutterEvent(method, data)
        }

        private fun deliverFlutterEvent(
            method: String,
            data: Map<String, Any?>,
        ) {
            val engine = backgroundEngine ?: return
            handler.post {
                if (backgroundEngine !== engine) {
                    return@post
                }
                MethodChannel(engine.dartExecutor.binaryMessenger, PLUGIN_CHANNEL)
                    .invokeMethod(method, data)
            }
        }

        private fun ensurePluginOnBackgroundEngine() {
            val engine = backgroundEngine ?: return
            val registry = engine.plugins
            if (registry.get(Plugin::class.java) == null) {
                registry.add(Plugin())
            }
        }

        private fun discardBackgroundEngine() {
            if (backgroundSessionOpen) {
                return
            }
            // Fork: never while the app's engine exists; see forkAppEngineAlive (tyne-chat/tyne#474).
            if (forkAppEngineAlive()) {
                forkDetachPushPlugin()
                return
            }
            val engine = backgroundEngine ?: return
            backgroundEngine = null
            // Fork: tyne-chat/tyne#474.
            forkSessionLedger.reset()
            dartBackgroundReady = false
            synchronized(pendingFlutterEvents) {
                pendingFlutterEvents.clear()
            }
            engine.destroy()
        }

        private fun messagePayload(
            message: PushMessage,
            instance: String,
        ): Map<String, Any?> =
            mapOf(
                PLUGIN_ARG_INSTANCE to instance,
                PLUGIN_ARG_MESSAGE_CONTENT to message.content,
                PLUGIN_ARG_MESSAGE_DECRYPTED to message.decrypted,
            )

        private fun endpointPayload(
            endpoint: PushEndpoint,
            instance: String,
        ): Map<String, Any?> =
            mapOf(
                PLUGIN_ARG_INSTANCE to instance,
                PLUGIN_ARG_ENDPOINT_URL to endpoint.url,
                PLUGIN_ARG_ENDPOINT_KEY_PUBKEY to endpoint.pubKeySet?.pubKey,
                PLUGIN_ARG_ENDPOINT_KEY_AUTH to endpoint.pubKeySet?.auth,
                PLUGIN_ARG_ENDPOINT_TEMP to endpoint.temporary,
            )

        // Fork (tyne-chat/tyne#474): push session state and helpers.
        //
        // The UnifiedPush connector (3.3.5) unbinds from this service 5 s after its first event but
        // never resets its `connected` flag. From then on it calls onMessage on that first, destroyed
        // instance, on its own thread, and no new instance (so no onCreate, no engine) ever follows.
        // So forkAcceptPush counts each push and holds the CPU at once, and does the rest on the main
        // thread: a started service carries the foreground service, the engine is kept between
        // pushes, and a session ends once Dart has handled every push it was given.
        private const val FORK_TAG = "FluxerPushSession"
        private val forkSessionLedger = ForkPushSessionLedger()
        private val forkWakeLockGuard = Any()

        @Volatile
        private var forkWakeLock: PowerManager.WakeLock? = null
        private var forkSessionTimedOut = false
        private var forkMainEngineGeneration = 0
        private var forkSessionGeneration = 0
        private var forkStartedService: FluxerUnifiedPushService? = null
        private var forkServiceStartPending = false

        /** Holds the CPU for up to [CPU_HOLD_MS] from now; each call restarts that limit. */
        private fun forkHoldCpu(context: Context) {
            val lock =
                forkWakeLock
                    ?: synchronized(forkWakeLockGuard) {
                        forkWakeLock
                            ?: (context.applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager)
                                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "fluxer:unifiedpush-session")
                                .also {
                                    it.setReferenceCounted(false)
                                    forkWakeLock = it
                                }
                    }
            lock.acquire(CPU_HOLD_MS)
        }

        /** Releases this block's wake lock and upstream's at once. */
        private fun forkReleaseCpu() {
            val lock = forkWakeLock
            if (lock != null && lock.isHeld) {
                lock.release()
            }
            handler.removeCallbacks(releaseCpu)
            releaseCpu.run()
        }

        private fun forkOnSessionClose() {
            forkReleaseCpu()
            val discard =
                ForkPushSessionLedger.shouldDiscardOnClose(
                    mainEngineRunning,
                    forkMainEngineGeneration != forkSessionGeneration,
                    forkSessionTimedOut,
                )
            android.util.Log.d(
                FORK_TAG,
                "session closed: delivered=${forkSessionLedger.delivered()} " +
                    "timedOut=$forkSessionTimedOut discardEngine=$discard",
            )
            forkSessionTimedOut = false
            if (discard) {
                discardBackgroundEngine()
            }
        }

        /**
         * The main app's engine handles pushes from now on. A push engine still alive here (a
         * session was open when the app started) loses its UnifiedPush plugin: that plugin would
         * otherwise take pushes meant for the app while the app's own plugin starts, and make the
         * app's plugin skip what is waiting in `Plugin.calls`. The engine itself stays until the app
         * stops (see [forkAppEngineAlive]).
         */
        private fun forkOnMainEngineStarted() {
            forkMainEngineGeneration += 1
            forkDetachPushPlugin()
        }

        /**
         * Called by `MainActivity.onCreate` before its engine exists. An idle push engine is
         * destroyed now, while that is still safe; during a session it stays (and loses its plugin
         * once the app's engine starts).
         */
        fun forkBeforeAppEngine() {
            discardBackgroundEngine()
        }

        /**
         * Whether an app engine exists: the activity's (`mainEngineRunning`) or the one audio_service
         * keeps in [io.flutter.embedding.engine.FlutterEngineCache], which also plays audio without
         * an activity. While one does, the push engine must not be destroyed:
         * shared_preferences_android (2.5.4) keeps a single process-wide registration per name, which
         * every engine's attach overwrites and any engine's detach removes, so destroying the push
         * engine would leave the app's engine without preferences (on 2026-11-02 that stopped the
         * app at its launch screen).
         */
        private fun forkAppEngineAlive(): Boolean =
            mainEngineRunning ||
                io.flutter.embedding.engine.FlutterEngineCache.getInstance()
                    .contains(com.ryanheise.audioservice.AudioServicePlugin.getFlutterEngineId())

        private fun forkDetachPushPlugin() {
            val registry = backgroundEngine?.plugins ?: return
            if (registry.has(Plugin::class.java)) {
                registry.remove(Plugin::class.java)
                android.util.Log.d(FORK_TAG, "app engine alive: push plugin detached, engine kept")
            }
        }
    }

    // Fork (tyne-chat/tyne#474): see the companion's fork block.

    /**
     * Counts the push and holds the CPU on the caller's thread (the connector's, after its first
     * event), before the connector releases its own wake lock, then hands the push on from the main
     * thread: to the main app's engine through the plugin when the app is running, else to a push
     * session. Always returns `true`. `this` may be an instance Android has already destroyed; only
     * its application context and the companion's state are used.
     */
    private fun forkAcceptPush(message: PushMessage, instance: String): Boolean {
        val appContext = applicationContext
        forkSessionLedger.onDelivered()
        forkHoldCpu(appContext)
        android.util.Log.d(FORK_TAG, "push received on thread ${Thread.currentThread().name}")
        handler.post {
            if (mainEngineRunning) {
                forkSessionLedger.undoDelivered()
                super@FluxerUnifiedPushService.onMessage(message, instance)
                if (!backgroundSessionOpen) {
                    forkReleaseCpu()
                }
                return@post
            }
            if (!forkBeginPushSession(appContext)) {
                forkSessionLedger.undoDelivered()
                super@FluxerUnifiedPushService.onMessage(message, instance)
                return@post
            }
            enqueueOrDeliverFlutterEvent(PLUGIN_CALL_MESSAGE, messagePayload(message, instance))
        }
        return true
    }

    /**
     * Opens or extends a push session on the main thread: a started service in the foreground and a
     * running engine. Returns `false` if no engine could be started.
     */
    private fun forkBeginPushSession(appContext: Context): Boolean {
        if (backgroundSessionOpen) {
            handler.removeCallbacks(closeSession)
            handler.postDelayed(closeSession, CPU_HOLD_MS)
        } else {
            openBackgroundSession()
        }
        forkHoldCpu(appContext)
        val live = activeService
        if (live != null) {
            live.stopWhenUnbound = false
            live.startPushForeground()
        }
        // A service the connector only bound is destroyed when it unbinds, foreground or not, so
        // the session needs a started one. onStartCommand puts it in the foreground.
        if ((forkStartedService == null || live == null) && !forkServiceStartPending) {
            val started =
                runCatching {
                    androidx.core.content.ContextCompat.startForegroundService(
                        appContext,
                        Intent(appContext, FluxerUnifiedPushService::class.java),
                    )
                }
            forkServiceStartPending = started.isSuccess
            started.exceptionOrNull()?.let {
                android.util.Log.w(FORK_TAG, "service start refused; no foreground service", it)
            }
        }
        val startingEngine = backgroundEngine == null
        if (startingEngine) {
            try {
                getEngine(appContext)
                ensurePluginOnBackgroundEngine()
            } catch (error: Exception) {
                android.util.Log.w(FORK_TAG, "engine start failed", error)
                closeBackgroundSession()
                return false
            }
        }
        android.util.Log.d(
            FORK_TAG,
            "session open: engine ${if (startingEngine) "started" else "kept"}, " +
                "delivered=${forkSessionLedger.delivered()}",
        )
        return true
    }

    /**
     * A start from [forkBeginPushSession] must reach the foreground within seconds, also when its
     * session has already ended (a push Dart drops at once), or Android ends the process. So this
     * always enters the foreground, then leaves it again if no session is open.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        forkServiceStartPending = false
        forkStartedService = this
        if (activeService !== this) {
            // The flag belongs to an instance that no longer exists.
            foregroundActive = false
        }
        startPushForeground()
        if (!backgroundSessionOpen) {
            stopPushForeground()
            requestStop()
            forkReleaseCpu()
        }
        return START_NOT_STICKY
    }

    private fun forkNoteServiceDestroyed() {
        if (forkStartedService === this) {
            forkStartedService = null
            forkServiceStartPending = false
        }
    }
}
