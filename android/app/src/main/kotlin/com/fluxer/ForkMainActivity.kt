package com.fluxer

import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowInsets
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.engine.FlutterEngine

/**
 * Fork: [MainActivity]'s base class, which holds the fork's hooks into the activity, so that
 * upstream's `MainActivity.kt` carries one fork line, the class it extends (tyne-chat/tyne#845).
 * Upstream changes that file more than any other Android file, most often at the top of its
 * lifecycle methods, where the fork's lines used to be: they stopped six rebases in the 30 days to
 * 2026-11-20.
 *
 * Each hook runs where it ran inside [MainActivity]: `onCreate` calls `super` straight after its own
 * checks, and `configureFlutterEngine` calls it first.
 */
open class ForkMainActivity : AudioServiceFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // An idle push engine goes before this activity's engine registers plugins (tyne-chat/tyne#474).
        FluxerUnifiedPushService.forkBeforeAppEngine()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppInstallBridge(applicationContext).register(flutterEngine)
    }

    override fun onDestroy() {
        window?.decorView?.removeCallbacks(insetResync)
        super.onDestroy()
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

    private companion object {
        const val INSETS_TAG = "FluxerInsets"
        const val INSET_RESYNC_DELAY_MS = 500L
    }
}
