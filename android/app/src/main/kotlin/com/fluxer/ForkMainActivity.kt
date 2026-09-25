package com.fluxer

import com.ryanheise.audioservice.AudioServiceFragmentActivity
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
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppInstallBridge(applicationContext).register(flutterEngine)
    }
}
