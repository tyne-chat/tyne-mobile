package com.fluxer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

// Fork: a reply typed in a notification is posted without the app's persona selection, so it asks
// the server to send it as the persona selected in the channel, or the one a tag in the text names
// (tyne-chat/tyne#343). The text goes as typed: the server takes the tag out.
class NotificationReplyForkTest {
    @Test
    fun asksTheServerForTheSelectedPersona() {
        val body = notificationReplyBody("F: hello", "message-1", replyMention = true)

        assertTrue(body.startsWith("{\"use_persona_selection\":true,"))
        assertEquals(1, Regex("\"use_persona_selection\"").findAll(body).count())
        assertTrue(body.contains("\"content\":\"F: hello\""))
    }

    @Test
    fun theRequestCarriesIt() {
        val request = buildNotificationReplyRequest(
            account = NotificationReplyAccount("token", "https://api.example/v1"),
            channelId = "c",
            messageId = "m",
            content = "hi",
            replyMention = true,
        )

        assertTrue(request?.body?.startsWith("{\"use_persona_selection\":true,") == true)
    }
}
