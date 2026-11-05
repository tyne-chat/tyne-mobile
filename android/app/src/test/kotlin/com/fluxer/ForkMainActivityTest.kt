package com.fluxer

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Test

// Fork: guards for ForkMainActivity.kt (tyne-chat/tyne#845), the base class that holds the fork's
// hooks so that upstream's MainActivity.kt carries one fork line. An activity with a Flutter
// fragment needs Flutter's native library, so these only check the wiring; the behaviour of each
// hook is checked on a device (android/AGENTS.md, "Tests").
class ForkMainActivityTest {
    @Test
    fun mainActivityExtendsIt() {
        assertSame(ForkMainActivity::class.java, MainActivity::class.java.superclass)
    }

    @Test
    fun itIsAudioServicesActivity() {
        assertSame(AudioServiceFragmentActivity::class.java, ForkMainActivity::class.java.superclass)
    }

    @Test
    fun itHoldsTheForksHooks() {
        val declaredBy = { name: String, types: Array<Class<*>> ->
            ForkMainActivity::class.java.getDeclaredMethod(name, *types).declaringClass
        }
        // The push engine hook (tyne-chat/tyne#474), before the activity's engine starts.
        assertEquals(ForkMainActivity::class.java, declaredBy("onCreate", arrayOf(Bundle::class.java)))
        // The APK installer's bridge.
        assertEquals(
            ForkMainActivity::class.java,
            declaredBy("configureFlutterEngine", arrayOf(FlutterEngine::class.java)),
        )
        // The keyboard inset fix.
        assertEquals(
            ForkMainActivity::class.java,
            declaredBy("onWindowFocusChanged", arrayOf(Boolean::class.javaPrimitiveType!!)),
        )
        assertEquals(ForkMainActivity::class.java, declaredBy("onDestroy", arrayOf()))
    }

    @Test
    fun mainActivityLeavesFocusChangesToIt() {
        // An override in MainActivity that skipped super would switch the inset fix off.
        val overrides = MainActivity::class.java.declaredMethods.map { it.name }
        assertFalse("onWindowFocusChanged" in overrides)
    }
}
