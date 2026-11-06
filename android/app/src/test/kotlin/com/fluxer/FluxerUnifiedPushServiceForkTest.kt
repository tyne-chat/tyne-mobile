package com.fluxer

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngine
import java.io.File
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

// Fork: tests for when FluxerUnifiedPushService destroys the push engine (tyne-chat/tyne#474).
// Destroying it while the app's engine exists hung the app at its launch screen on 2026-11-02, so
// once the app's engine has started the push engine is kept. These drive the service's own
// session ending with a stand-in engine. A real FlutterEngine needs Flutter's native library: the
// stand-in is allocated without running FlutterEngine's constructor and only records destroy().
// The service keeps its state in private companion fields, set and reset here through reflection.
// Robolectric 4.14 runs SDKs up to 35, below the app's target.
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class FluxerUnifiedPushServiceForkTest {
    private lateinit var wakeLock: PowerManager.WakeLock

    @Before
    fun startClean() {
        resetService()
        val power = RuntimeEnvironment.getApplication().getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "fork-test").apply {
            setReferenceCounted(false)
        }
    }

    @After
    fun cleanUp() = resetService()

    @Test
    fun withoutAnAppEngineTheEndOfASessionDestroysThePushEngine() {
        val engine = openSessionWith(standInEngine())

        FluxerUnifiedPushService.closeBackgroundSessionIfIdle(0)

        assertTrue(engine.destroyed)
        assertNull(state("backgroundEngine"))
        assertFalse(wakeLock.isHeld)
    }

    @Test
    fun onceTheAppEngineHasStartedTheEndOfASessionKeepsThePushEngine() {
        val engine = openSessionWith(standInEngine())
        FluxerUnifiedPushService.forkBeforeAppEngine()

        FluxerUnifiedPushService.closeBackgroundSessionIfIdle(0)

        assertFalse(engine.destroyed)
        assertSame(engine, state("backgroundEngine"))
        assertFalse(state("backgroundSessionOpen") as Boolean)
        assertFalse("the session's wake lock is released", wakeLock.isHeld)
    }

    @Test
    fun aKeptEngineKeepsCountingThePushesItWasGiven() {
        openSessionWith(standInEngine())
        FluxerUnifiedPushService.forkBeforeAppEngine()
        ledger().onAccepted()
        ledger().onAccepted()

        FluxerUnifiedPushService.closeBackgroundSessionIfIdle(2)

        // Dart's handled count runs over the kept engine's whole life, so the ledger does too.
        assertFalse(FluxerUnifiedPushService.canCloseBackgroundSession(1))
        assertTrue(FluxerUnifiedPushService.canCloseBackgroundSession(2))
    }

    @Test
    fun theAppEngineStartingDestroysAnIdlePushEngine() {
        val engine = standInEngine()
        setState("backgroundEngine", engine)
        setState("dartBackgroundReady", true)

        FluxerUnifiedPushService.forkBeforeAppEngine()

        assertTrue(engine.destroyed)
        assertNull(state("backgroundEngine"))
        assertFalse(state("dartBackgroundReady") as Boolean)
    }

    @Test
    fun theAppEngineStartingLeavesAPushEngineThatIsInTheMiddleOfASession() {
        val engine = openSessionWith(standInEngine())

        FluxerUnifiedPushService.forkBeforeAppEngine()

        assertFalse(engine.destroyed)
        assertSame(engine, state("backgroundEngine"))
        assertTrue(wakeLock.isHeld)
    }

    // MainActivity's own engine cannot start here, so this reads its source: the push engine must be
    // dealt with before super.onCreate, where the activity's engine registers its plugins.
    @Test
    fun mainActivityHandsOverBeforeItsEngineRegistersPlugins() {
        val onCreate = File("src/main/kotlin/com/fluxer/MainActivity.kt").readText()
            .substringAfter("override fun onCreate(")
        val handOver = onCreate.indexOf("FluxerUnifiedPushService.forkBeforeAppEngine()")
        val superOnCreate = onCreate.indexOf("super.onCreate(")

        assertTrue("MainActivity.onCreate calls forkBeforeAppEngine", handOver >= 0)
        assertTrue("before super.onCreate", handOver < superOnCreate)
    }

    private fun openSessionWith(engine: RecordingEngine): RecordingEngine {
        wakeLock.acquire(30_000)
        setState("wakeLock", wakeLock)
        setState("backgroundEngine", engine)
        setState("backgroundSessionOpen", true)
        setState("dartBackgroundReady", true)
        return engine
    }

    private fun resetService() {
        setState("backgroundEngine", null)
        setState("wakeLock", null)
        setState("backgroundSessionOpen", false)
        setState("dartBackgroundReady", false)
        setState("serviceStartRequested", false)
        setState("activeService", null)
        setState("forkAppEngineStarted", false)
        ledger().reset()
        (state("pendingMessages") as ArrayDeque<*>).clear()
    }

    private fun ledger(): UnifiedPushDeliveryLedger = state("ledger") as UnifiedPushDeliveryLedger

    // The companion's private properties are static fields of the service class.
    private fun state(name: String): Any? =
        FluxerUnifiedPushService::class.java.getDeclaredField(name).apply { isAccessible = true }.get(null)

    private fun setState(name: String, value: Any?) {
        FluxerUnifiedPushService::class.java.getDeclaredField(name).apply { isAccessible = true }.set(null, value)
    }

    private fun standInEngine(): RecordingEngine {
        val unsafe = Class.forName("sun.misc.Unsafe").getDeclaredField("theUnsafe")
            .apply { isAccessible = true }
            .get(null)
        return unsafe.javaClass.getMethod("allocateInstance", Class::class.java)
            .invoke(unsafe, RecordingEngine::class.java) as RecordingEngine
    }

    // Never constructed: standInEngine allocates it without running any constructor.
    private class RecordingEngine(context: Context) : FlutterEngine(context) {
        var destroyed = false

        override fun destroy() {
            destroyed = true
        }
    }
}
