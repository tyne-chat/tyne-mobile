package com.fluxer

/**
 * Fork: the bookkeeping that decides when a background push session ends (tyne-chat/tyne#474).
 *
 * The push engine is kept between pushes. Each push opens a short session (a foreground service
 * and a wake lock) and is counted here when it arrives. Dart reports how many pushes its isolate
 * has handled, and the session closes only once that count has caught up. Both counts only grow
 * within one engine, so a report for the first push of a burst cannot end the session while a
 * later one is still being handled.
 */
internal class ForkPushSessionLedger {
    private var delivered = 0

    /** A push was handed to the background engine, or is about to be. */
    @Synchronized
    fun onDelivered() {
        delivered += 1
    }

    /** A push counted by [onDelivered] went to the main app's engine instead. */
    @Synchronized
    fun undoDelivered() {
        if (delivered > 0) {
            delivered -= 1
        }
    }

    /**
     * Whether Dart's report that it has [handled] pushes ends the session. `null` is a report
     * without a count, which ends it, as before this change.
     */
    @Synchronized
    fun shouldClose(handled: Int?): Boolean = handled == null || handled >= delivered

    @Synchronized
    fun delivered(): Int = delivered

    /** The engine was discarded; its successor's Dart counts from zero. */
    @Synchronized
    fun reset() {
        delivered = 0
    }

    companion object {
        /**
         * Whether a closing session also discards the engine: when the main app's engine is
         * running or started during the session (it handles pushes then), or when the session
         * timed out (Dart is stuck).
         */
        fun shouldDiscardOnClose(
            mainEngineRunning: Boolean,
            mainEngineStartedDuringSession: Boolean,
            timedOut: Boolean,
        ): Boolean = mainEngineRunning || mainEngineStartedDuringSession || timedOut
    }
}
