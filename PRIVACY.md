# Privacy Policy

*Tyne apps and the HyperSystem.xyz server. Last updated: 21 November 2026.*

Tyne is a chat app built on the open-source Fluxer client. By default it connects to
**HyperSystem.xyz** (`temple.hypersystem.xyz`), a small community server that runs on a
single machine in its operator's home in the United States. This policy explains what the
Tyne apps and the HyperSystem.xyz server collect, why, how long it is kept, and what you can do
about it.

HyperSystem.xyz is a hobby project, not a company. Nobody here sells, rents or shares your data
for advertising, and there are no ads or trackers.

If you use Tyne with a different server, that server's operators decide what it stores; their
privacy policy applies to it, not this one.

Questions or requests: **support@tyne.chat**.

## 1. The Tyne apps

The apps (iOS, Android, desktop and web) talk to the server you sign in to, and to nothing else of
ours except the optional crash reports below. They contain no analytics, usage tracking or
advertising code.

**Crash reports (optional, off by default).** The mobile app can send crash and error reports and
performance data to our own crash-report server, which runs on the same machine as
HyperSystem.xyz. It does so only if you turn it on: the app asks after a crash, and you can turn it
on or off at any time under Settings → Advanced → "Send crash and performance reports". This
applies whichever server you use Tyne with. A report includes the device model, operating system
and app version, which screens were open, how long the app's requests took, error messages, and
the IP address it was sent from with an approximate country. Reports are not linked to your
account and are deleted after 30 days.

A few things go through other companies because the platforms require it:

- **Notifications.** To deliver notifications, the server sends them through Apple's Push
  Notification service (iPhone and iPad) or through the push service your Android phone uses
  (Google's or another UnifiedPush provider). Those services see a device token and when a
  notification is sent. Notification contents are encrypted before they leave the server.
- **App stores and TestFlight.** If you install Tyne through Apple's TestFlight, Apple may share
  crash reports and any feedback you choose to send with us, under Apple's own privacy policy.
- **Embedded content.** Some links show content from other sites, such as a YouTube video.
  If you play it, that site receives your request directly.

## 2. What the HyperSystem.xyz server stores

**Account information.** Your email address, username, password (stored only as a strong
one-way hash), and anything you add to your profile or personas: display names, avatars, bios and
similar. HyperSystem.xyz does not ask for your date of birth.

**Your content.** Messages, files, images, reactions, the servers and channels you create or
join, and your settings. Messages are **not end-to-end encrypted**: they are encrypted while
travelling between your device and the server, but they are stored readable on the server, so
the people who run HyperSystem.xyz can technically access them. We only look at content when we
need to: to handle a report, to fix a problem, or when the law requires it.

**Security and technical records.**
- The IP address and device details (such as app version and operating system) of each
  signed-in session, and the IP address your account was last active from.
- Records of file uploads, including the IP address they came from.
- Records of server moderation actions (audit logs).
- Basic reports about how voice and video calls connected, which may include your IP
  address and an approximate country.
- Bans, which can include an IP address or email address.
- Server logs: the records the server's programs write as they run, such as which requests
  were made and how they ended, errors, and sessions being signed out. They can include your
  user id, part of a session identifier, your app or browser version and the addresses
  requested, but not your IP address.

We use these to keep accounts and the server secure, to stop abuse and to fix problems.

**What we do not keep.** Our server logs do not record IP addresses, and we do not use your data
for analytics, profiling or advertising. We do not ask for your date of birth or phone number,
and we do not collect payment information.

## 3. Who else is involved

- **Email.** Emails such as sign-in verification and password resets are sent through our mail
  server.
- **GIF search.** When you search for GIFs, the search goes through our server to Klipy, the
  GIF provider. Klipy sees the search, not who made it.
- **Link previews and images.** When a message contains a link, our server fetches the page to
  show a preview, and images from other sites are loaded through our server. Other sites see our
  server, not you.
- **Calls.** Voice and video calls run on our own server. Some one-to-one calls may connect your
  device directly to the other person's device, which lets them see your IP address.
- **Backups.** Nightly backups of the server are kept on a separate disk at home and, encrypted
  before they leave the house, on Proton Drive, which cannot read them. Backups are deleted after
  30 days.

We do not share your data with anyone else unless you ask us to, or the law requires us to.

## 4. How long things are kept

| What | How long |
| --- | --- |
| Account, profile and content | Until you delete them or your account |
| Session records (IP address, device) | While you are signed in, plus 30 days after the session ends |
| IP address your account was last active from | Replaced each time you are active; deleted with your account |
| File upload records | 30 days |
| Server audit logs | 45 days |
| Server logs | 30 days |
| Crash reports from the mobile app (if you turned them on) | 30 days |
| Call connection reports | 180 days |
| Notification registrations | Until you sign out of the device, or 90 days after the device was last seen |
| Reports you submit about messages | Up to 1 year |
| Bans | Until the ban is lifted |
| Backups | Up to 30 days |

When you delete a message, file or your account, it is removed from the live server straight away,
and from backups within 30 days. Server logs and crash reports are not searched and edited when
you delete something; they are deleted as a whole when they reach 30 days.

## 5. Your choices and rights

- **See and correct your data.** Most of it is in the app's settings and your profile.
- **Export your data.** You can request a copy of your account data from the app's privacy
  settings, or by email.
- **Delete your account.** From the app's account settings, or by emailing us. This deletes your
  account and personal information. Messages you sent in servers or group chats may stay visible
  to others, attributed to a deleted user, unless you delete them first.
- **Notifications.** Turn them off at any time in the app or in your device settings.

Email **support@tyne.chat** for any request, preferably from the address on your account. We will
reply within 30 days. Depending on where you live, you may also have the right to complain to your
local data protection authority.

## 6. Minimum age

You must be at least 18 years old, and an adult where you live, to use HyperSystem.xyz. We do not
knowingly let anyone younger have an account or collect information about them; if you believe
someone under that age has an account, tell us and we will delete it.

## 7. Security

Connections to the server are encrypted, passwords are stored only as hashes, and off-site backups
are encrypted. No system is perfectly secure; if something goes wrong that affects your data, we
will tell affected users as soon as we can.

## 8. Changes

We will post changes here, update the date at the top, and announce significant changes on the
server. The history of this file is public on GitHub.
