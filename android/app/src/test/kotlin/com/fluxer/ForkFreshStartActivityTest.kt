package com.fluxer

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Test

// Fork: guards for ForkFreshStartActivity.kt (tyne-chat/tyne#634). An activity with a Flutter
// fragment needs Flutter's native library, so these only check that the pieces are still wired as
// the fix needs them; a device check covers the behaviour (after `adb shell am kill` and a push,
// opening Tyne shows the app, not a black window).
class ForkFreshStartActivityTest {
    @Test
    fun mainActivityStartsFresh() {
        assertSame(ForkFreshStartActivity::class.java, MainActivity::class.java.superclass)
    }

    @Test
    fun itIsStillAudioServicesActivity() {
        assertSame(
            AudioServiceFragmentActivity::class.java,
            ForkFreshStartActivity::class.java.superclass,
        )
    }

    @Test
    fun itTakesOverOnCreate() {
        val onCreate = ForkFreshStartActivity::class.java.getDeclaredMethod("onCreate", Bundle::class.java)
        assertEquals(ForkFreshStartActivity::class.java, onCreate.declaringClass)
    }
}
