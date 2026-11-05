package com.fluxer

import android.content.Context
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.PluginRegistry
import kotlinx.coroutines.ExperimentalCoroutinesApi
import org.unifiedpush.flutter.connector.Plugin

/**
 * Fork: the engine [FluxerUnifiedPushService] handles a push in when Tyne is not running
 * (tyne-chat/tyne#210).
 *
 * Upstream's `FlutterEngine(context)` registers every plugin in its constructor. audio_service's
 * plugin then connects to its media service from whichever engine it is attached to, and that
 * service starts the full app in a second engine of its own, with no screen. So every push that
 * found Tyne not running paid for a second app start-up (database, gateway, requests), in an engine
 * where `MainActivity`'s channels, Measure's among them, do not exist: Measure could not start, and
 * the crash-report prompt took the push process's death for a crash.
 *
 * This engine registers no plugin by itself, so upstream's explicit
 * `GeneratedPluginRegistrant.registerWith` is the only registration (it used to run twice), and it
 * leaves audio_service out of it. The push engine's Dart (`main` with `--unifiedpush-bg`) does not
 * use audio_service; the full app, started by `MainActivity`, still gets it in its own engine.
 */
// `false` turns automatic plugin registration off. It must stay off: that registration runs inside
// FlutterEngine's constructor and calls getPlugins(), before forkPlugins below exists.
internal class ForkPushEngine(context: Context) :
    FlutterEngine(context, null, false) {
    private val forkPlugins: PluginRegistry =
        PluginRegistryWithout(super.getPlugins(), PUSH_ENGINE_LEFT_OUT_PLUGINS)

    init {
        clearPluginReplay()
    }

    override fun getPlugins(): PluginRegistry = forkPlugins
}

/**
 * Empties the UnifiedPush plugin's replay of recent calls (tyne-chat/tyne#474). A new push engine's
 * plugin replays them when no other engine is listening, and they are pushes the main app already
 * handled while it ran: the push engine would show them again as notifications. Pushes for this
 * engine reach it directly, not through that replay.
 */
@OptIn(ExperimentalCoroutinesApi::class)
private fun clearPluginReplay() {
    Plugin.calls.resetReplayCache()
}

/** Plugins the push engine leaves out. */
internal val PUSH_ENGINE_LEFT_OUT_PLUGINS: Set<Class<out FlutterPlugin>> =
    setOf(AudioServicePlugin::class.java)

/** A [PluginRegistry] that ignores additions of [leftOut] plugins and passes the rest on. */
internal class PluginRegistryWithout(
    private val delegate: PluginRegistry,
    private val leftOut: Set<Class<out FlutterPlugin>>,
) : PluginRegistry by delegate {
    override fun add(plugin: FlutterPlugin) {
        if (isLeftOut(plugin)) {
            return
        }
        delegate.add(plugin)
    }

    override fun add(plugins: MutableSet<FlutterPlugin>) {
        delegate.add(plugins.filterNotTo(mutableSetOf()) { isLeftOut(it) })
    }

    private fun isLeftOut(plugin: FlutterPlugin): Boolean =
        leftOut.any { it.isInstance(plugin) }
}
