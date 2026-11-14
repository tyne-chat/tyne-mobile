package com.fluxer

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceFragmentActivity

/**
 * Fork: [MainActivity]'s base class. It is audio_service's activity, except that it never restores
 * its Flutter fragment from saved state (tyne-chat/tyne#634).
 *
 * Android ends Tyne's process in the background and keeps the task; opening Tyne again then
 * recreates the activity with its saved state, and the fragment manager restores the Flutter
 * fragment into the container whose view id the old process saved. Flutter takes that id, like the
 * Flutter view's, from `View.generateViewId()` in a static initialiser, so it depends on which
 * class a process loads first. A process started from the launcher loads the activity first. A
 * process started by a push registers the plugins first, and passkeys_android's plugin class
 * extends `FlutterActivity`, which takes the first id. When the saving and the restoring process
 * differ in that, the restored fragment finds no container, the fragment manager attaches its view
 * to nothing without complaint, and Tyne shows a black window with the app running behind it.
 *
 * Nothing is lost by starting fresh. After the process ended, the engine and the app in it are new
 * anyway; while the process lives, the engine is audio_service's cached one and the new fragment
 * attaches to it as a restored one would. The app keeps no state in the activity's saved state (no
 * Flutter state restoration). [MainActivity] still reads the real saved state itself, to tell a
 * restored activity from a fresh tap on a notification.
 */
open class ForkFreshStartActivity : AudioServiceFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(null)
    }
}
