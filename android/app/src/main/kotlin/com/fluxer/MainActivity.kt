package com.fluxer

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import com.hiennv.flutter_callkit_incoming.CallkitEventCallback
import com.hiennv.flutter_callkit_incoming.FlutterCallkitIncomingPlugin
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceFragmentActivity() {
    private val imeEditingShortcutBridge = ImeEditingShortcutBridge()
    private val appLockBridge = AppLockBridge(this)

    private val callkitEventCallback = object : CallkitEventCallback {
        override fun onCallEvent(
            event: CallkitEventCallback.CallEvent,
            callData: Bundle,
        ) {}
    }

    private var restoredFromSavedState = false

    override fun onCreate(savedInstanceState: Bundle?) {
        if (deferOAuthDeepLinkToBrowser(intent)) {
            return
        }
        restoredFromSavedState = savedInstanceState != null
        // Fork: an idle push engine goes before this activity's engine registers plugins (tyne-chat/tyne#474).
        FluxerUnifiedPushService.forkBeforeAppEngine()
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view ->
                view.animate()
                    .alpha(0f)
                    .setDuration(200L)
                    .withEndAction { view.remove() }
                    .start()
            }
        }
        FlutterCallkitIncomingPlugin.registerEventCallback(callkitEventCallback)
    }

    override fun onNewIntent(intent: Intent) {
        if (deferOAuthDeepLinkToBrowser(intent)) {
            return
        }
        super.onNewIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        MainEngineState.onActivityStarted()
    }

    override fun onPause() {
        appLockBridge.onPause()
        super.onPause()
    }

    override fun onStop() {
        MainEngineState.onActivityStopped()
        super.onStop()
    }

    override fun onDestroy() {
        window?.decorView?.removeCallbacks(insetResync)
        FlutterCallkitIncomingPlugin.unregisterEventCallback(callkitEventCallback)
        super.onDestroy()
    }

    override fun createFlutterFragment(): FlutterFragment {
        return FlutterFragment.CachedEngineFragmentBuilder(
            MainFlutterFragment::class.java,
            requireNotNull(cachedEngineId),
        )
            .renderMode(renderMode)
            .transparencyMode(
                if (backgroundMode == FlutterActivityLaunchConfigs.BackgroundMode.opaque) {
                    TransparencyMode.opaque
                } else {
                    TransparencyMode.transparent
                },
            )
            .handleDeeplinking(shouldHandleDeeplinking())
            .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
            .destroyEngineWithFragment(shouldDestroyEngineWithHost())
            .shouldDelayFirstAndroidViewDraw(renderMode == RenderMode.surface)
            .shouldAutomaticallyHandleOnBackPressed(true)
            .build()
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (imeEditingShortcutBridge.dispatch(event)) {
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            scheduleInsetResync()
        }
    }

    // Flutter's ImeSyncDeferringInsetsCallback swallows window insets while it
    // believes an IME animation is running and only re-dispatches them in
    // onEnd. Switching tasks during the keyboard show animation can cancel the
    // animation without that final dispatch, leaving Flutter laid out for a
    // keyboard that is gone (composer stuck up, blank band below). Calling the
    // view's own onApplyWindowInsets bypasses that listener.
    private val insetResync = Runnable { resyncFlutterInsets() }

    private fun scheduleInsetResync() {
        val decor = window?.decorView ?: return
        decor.removeCallbacks(insetResync)
        decor.postDelayed(insetResync, INSET_RESYNC_DELAY_MS)
    }

    private fun resyncFlutterInsets() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            // The deferring callback is only installed on API 30+.
            return
        }
        val flutterView = findViewById<View>(FlutterFragment.FLUTTER_VIEW_ID) ?: return
        val insets = flutterView.rootWindowInsets ?: return
        val imeVisible = insets.isVisible(WindowInsets.Type.ime())
        val imeBottom = insets.getInsets(WindowInsets.Type.ime()).bottom
        Log.d(INSETS_TAG, "focus resync imeVisible=$imeVisible imeBottom=$imeBottom")
        if (imeVisible) {
            // A live keyboard may still be animating in; leave it to the engine.
            return
        }
        flutterView.onApplyWindowInsets(insets)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val engineReused = MainEngineKeepAlive.isTracking(flutterEngine)
        MainEngineKeepAlive.attach(this, flutterEngine)
        // Fork: registered first, away from the end of the list where upstream adds its bridges.
        AppInstallBridge(applicationContext).register(flutterEngine)
        BrowserLaunchBridge(applicationContext).register(flutterEngine)
        PhysicalKeyboardBridge(applicationContext).register(flutterEngine)
        VoiceTaskRemovedBridge(applicationContext).also { bridge ->
            bridge.register(flutterEngine)
            VoiceTaskRemovedRegistry.bridge = bridge
        }
        AppRestartBridge(this).register(flutterEngine)
        appLockBridge.register(flutterEngine)
        PlayAgeRangeBridge(this).register(flutterEngine)
        UploadKeepAliveBridge(applicationContext).register(flutterEngine)
        imeEditingShortcutBridge.register(flutterEngine)
        MeasureReporting.register(flutterEngine, application)
        val launchIntent = intent
        if (
            engineReused &&
            !restoredFromSavedState &&
            launchIntent != null &&
            NotificationLaunchIntent.isFreshTap(launchIntent.action, launchIntent.flags)
        ) {
            flutterEngine.activityControlSurface.onNewIntent(launchIntent)
        }
    }

    private fun deferOAuthDeepLinkToBrowser(intent: Intent?): Boolean {
        val browserUri = resolveOAuthBrowserUri(intent?.data) ?: return false
        val browserIntent = Intent(Intent.ACTION_VIEW, browserUri).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(browserIntent)
        finish()
        return true
    }

    private fun resolveOAuthBrowserUri(uri: Uri?): Uri? {
        if (uri == null) {
            return null
        }
        val path = uri.path ?: return null
        if (!path.startsWith(OAUTH_PATH_PREFIX)) {
            return null
        }
        return when (uri.scheme) {
            "https" -> {
                if (uri.host in OFFICIAL_APP_LINK_HOSTS) uri else null
            }
            else -> null
        }
    }

    private companion object {
        const val OAUTH_PATH_PREFIX = "/oauth2/"
        const val INSETS_TAG = "FluxerInsets"
        const val INSET_RESYNC_DELAY_MS = 500L

        val OFFICIAL_APP_LINK_HOSTS = setOf(
            "web.fluxer.app",
            "web.canary.fluxer.app",
            "web.fluxer.com",
            "web.canary.fluxer.com",
            "fluxer.gg",
        )
    }
}
