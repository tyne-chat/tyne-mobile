package com.fluxer

import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.PluginRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

// Fork: tests for ForkPushEngine.kt (tyne-chat/tyne#210). The engine itself needs Flutter's native
// library, so these cover the registry it hands to GeneratedPluginRegistrant; a device check covers
// the rest (no media session and no second engine after a push).
class ForkPushEngineTest {
    @Test
    fun leavesOutAudioServiceAndNothingElse() {
        assertEquals(
            setOf<Class<out FlutterPlugin>>(AudioServicePlugin::class.java),
            PUSH_ENGINE_LEFT_OUT_PLUGINS,
        )
    }

    @Test
    fun ignoresALeftOutPlugin() {
        val delegate = RecordingPluginRegistry()
        val registry = PluginRegistryWithout(delegate, setOf(LeftOutPlugin::class.java))

        registry.add(LeftOutPlugin())

        assertTrue(delegate.plugins.isEmpty())
        assertFalse(registry.has(LeftOutPlugin::class.java))
    }

    @Test
    fun passesOtherPluginsOn() {
        val delegate = RecordingPluginRegistry()
        val registry = PluginRegistryWithout(delegate, setOf(LeftOutPlugin::class.java))
        val kept = KeptPlugin()

        registry.add(kept)

        assertEquals(listOf<FlutterPlugin>(kept), delegate.plugins)
        assertTrue(registry.has(KeptPlugin::class.java))
        assertSame(kept, registry.get(KeptPlugin::class.java))
    }

    @Test
    fun filtersASetOfPlugins() {
        val delegate = RecordingPluginRegistry()
        val registry = PluginRegistryWithout(delegate, setOf(LeftOutPlugin::class.java))
        val kept = KeptPlugin()

        registry.add(mutableSetOf(LeftOutPlugin(), kept))

        assertEquals(listOf<FlutterPlugin>(kept), delegate.plugins)
    }

    @Test
    fun leavesOutSubclassesToo() {
        val delegate = RecordingPluginRegistry()
        val registry = PluginRegistryWithout(delegate, setOf(LeftOutPlugin::class.java))

        registry.add(LeftOutSubclassPlugin())

        assertTrue(delegate.plugins.isEmpty())
    }

    @Test
    fun passesRemovalsOn() {
        val delegate = RecordingPluginRegistry()
        val registry = PluginRegistryWithout(delegate, setOf(LeftOutPlugin::class.java))
        registry.add(KeptPlugin())
        registry.add(OtherKeptPlugin())

        registry.remove(KeptPlugin::class.java)
        assertEquals(listOf(OtherKeptPlugin::class.java), delegate.plugins.map { it.javaClass })

        registry.removeAll()
        assertTrue(delegate.plugins.isEmpty())
    }

    private open class LeftOutPlugin : FlutterPlugin {
        override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

        override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit
    }

    private class LeftOutSubclassPlugin : LeftOutPlugin()

    private class KeptPlugin : FlutterPlugin {
        override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

        override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit
    }

    private class OtherKeptPlugin : FlutterPlugin {
        override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

        override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit
    }

    /** Records what reaches the engine's own registry. */
    private class RecordingPluginRegistry : PluginRegistry {
        val plugins = mutableListOf<FlutterPlugin>()

        override fun add(plugin: FlutterPlugin) {
            plugins.add(plugin)
        }

        override fun add(plugins: MutableSet<FlutterPlugin>) {
            plugins.forEach { add(it) }
        }

        override fun has(pluginClass: Class<out FlutterPlugin>): Boolean =
            plugins.any { it.javaClass == pluginClass }

        override fun get(pluginClass: Class<out FlutterPlugin>): FlutterPlugin? =
            plugins.firstOrNull { it.javaClass == pluginClass }

        override fun remove(pluginClass: Class<out FlutterPlugin>) {
            plugins.removeAll { it.javaClass == pluginClass }
        }

        override fun remove(pluginClasses: MutableSet<Class<out FlutterPlugin>>) {
            pluginClasses.forEach { remove(it) }
        }

        override fun removeAll() {
            plugins.clear()
        }
    }
}
