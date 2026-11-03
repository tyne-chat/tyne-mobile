package com.fluxer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

// Fork: tests for ForkPushSessionLedger.kt (tyne-chat/tyne#474). The service around it needs a
// device; a device check covers that (see android/AGENTS.md, "Background pushes").
class ForkPushSessionLedgerTest {
    @Test
    fun closesOnlyWhenEveryDeliveredPushIsHandled() {
        val ledger = ForkPushSessionLedger()
        ledger.onDelivered()
        ledger.onDelivered()

        assertFalse(ledger.shouldClose(1))
        assertTrue(ledger.shouldClose(2))
    }

    @Test
    fun aReportForTheFirstPushOfABurstDoesNotCloseTheSession() {
        val ledger = ForkPushSessionLedger()
        ledger.onDelivered()
        ledger.onDelivered()

        assertFalse(ledger.shouldClose(1))
        ledger.onDelivered()
        assertFalse(ledger.shouldClose(2))
        assertTrue(ledger.shouldClose(3))
    }

    @Test
    fun aReportWithoutACountCloses() {
        val ledger = ForkPushSessionLedger()
        ledger.onDelivered()

        assertTrue(ledger.shouldClose(null))
    }

    @Test
    fun nothingDeliveredClosesOnAReportOfNothing() {
        assertTrue(ForkPushSessionLedger().shouldClose(0))
    }

    @Test
    fun undoingAPushThatWentToTheMainAppDoesNotGoBelowZero() {
        val ledger = ForkPushSessionLedger()
        ledger.onDelivered()
        ledger.undoDelivered()
        ledger.undoDelivered()

        assertEquals(0, ledger.delivered())
    }

    @Test
    fun resetStartsCountingAgain() {
        val ledger = ForkPushSessionLedger()
        ledger.onDelivered()
        ledger.onDelivered()
        ledger.reset()
        ledger.onDelivered()

        assertTrue(ledger.shouldClose(1))
    }

    @Test
    fun discardsOnCloseOnlyForTheMainAppOrATimeout() {
        assertFalse(ForkPushSessionLedger.shouldDiscardOnClose(false, false, false))
        assertTrue(ForkPushSessionLedger.shouldDiscardOnClose(true, false, false))
        assertTrue(ForkPushSessionLedger.shouldDiscardOnClose(false, true, false))
        assertTrue(ForkPushSessionLedger.shouldDiscardOnClose(false, false, true))
    }
}
