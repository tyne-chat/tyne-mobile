package com.fluxer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class AppInstallBridgeTest {
    private val installedCerts = setOf("aa")

    @Test
    fun acceptsSamePackageSignedWithSameKey() {
        assertNull(updateArchiveRejection("chat.tyne.app", installedCerts, "chat.tyne.app", setOf("aa")))
    }

    @Test
    fun rejectsUnreadableArchive() {
        assertNotNull(updateArchiveRejection("chat.tyne.app", installedCerts, null, emptySet()))
    }

    @Test
    fun rejectsDifferentPackage() {
        assertEquals(
            "The APK is for a different app (com.example.other)",
            updateArchiveRejection("chat.tyne.app", installedCerts, "com.example.other", setOf("aa")),
        )
    }

    @Test
    fun rejectsSamePackageSignedWithDifferentKey() {
        assertNotNull(updateArchiveRejection("chat.tyne.app", installedCerts, "chat.tyne.app", setOf("bb")))
        assertNotNull(updateArchiveRejection("chat.tyne.app", installedCerts, "chat.tyne.app", setOf("aa", "bb")))
    }

    @Test
    fun leavesUnreadableCertificatesToTheSystemInstaller() {
        assertNull(updateArchiveRejection("chat.tyne.app", installedCerts, "chat.tyne.app", emptySet()))
        assertNull(updateArchiveRejection("chat.tyne.app", emptySet(), "chat.tyne.app", setOf("aa")))
    }

    @Test
    fun acceptsOnlyApksDirectlyInTheUpdatesFolder() {
        val updates = File("/data/user/0/chat.tyne.app/cache/updates")
        assertTrue(isUpdateArchivePath(File(updates, "tyne-update.apk"), updates))
        assertFalse(isUpdateArchivePath(File(updates, "tyne-update.apk.part"), updates))
        assertFalse(isUpdateArchivePath(File(updates, "../tyne-update.apk"), updates))
        assertFalse(isUpdateArchivePath(File(updates, "nested/tyne-update.apk"), updates))
        assertFalse(isUpdateArchivePath(File("/data/user/0/chat.tyne.app/files/x.apk"), updates))
    }
}
