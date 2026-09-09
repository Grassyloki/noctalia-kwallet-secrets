<!-- noctalia-pr-template:v1 -->

## Plugin

- **Id:** `grassyloki/kwallet-secrets`
- [x] New plugin
- [ ] Update to an existing plugin (version bumped in `plugin.toml`)

## What it does

NetworkManager keeps no copy of an agent-owned Wi-Fi password (`psk-flags=1`)
and asks a registered secret agent for it at connect time. On a Plasma desktop
that agent is plasma-nm, which reads the password out of KWallet. On a Noctalia
session the only agent is the shell's own, which has no persistent store and can
only prompt - so every profile plasma-nm ever saved asks for a password that is
already sitting in the wallet.

This plugin registers a second NetworkManager secret agent that answers those
requests out of KWallet's `Network Management` folder, keyed
`{uuid};802-11-wireless-security`. A user with a pile of imported plasma-nm
profiles gets them all connecting silently again, with no kded6 and no plasma-nm
running.

A wallet miss returns the `NoSecrets` error, so NetworkManager falls through to
the next agent and Noctalia's own prompt still handles networks the wallet has
never seen. `REQUEST_NEW` also returns `NoSecrets`, so a password that has
actually changed prompts instead of retrying a stale one.

## External dependencies

- `python3` (with `python-dbus` and `python-gobject`) - the secret agent itself.
  It speaks D-Bus to NetworkManager on the system bus and to KWallet on the
  session bus. No pip, no virtualenv, no vendored code.
- `kwalletd6` - provides the `org.kde.KWallet` interface the passwords live
  behind. `ksecretd` serves the same wallet file over the Secret Service API but
  does not implement that interface, so it is not a substitute.
- `pkill` (procps-ng) - stops the helper when a setting changes.
- `systemd-cat` (systemd) - routes the helper's stdout/stderr into the journal
  under the tag `noctalia-kwallet-secrets`, so it writes no log file of its own.

All four are declared in `dependencies` in `plugin.toml` and documented under
Requirements in the README.

The service also runs `grep` against `/proc/net/unix`, `id -u`, and `setsid`,
which are undeclared because they ship with coreutils and util-linux
everywhere. Those, `pkill`, `systemd-cat`, and the helper itself are the
complete set of processes the plugin ever spawns. It writes no files of its own
and makes no network calls; the only thing it ever writes is wallet content,
through KWallet's own D-Bus API, in response to a NetworkManager save or
delete.

## Testing

Run against a real NetworkManager profile set: 61 saved Wi-Fi profiles, 33 of
them agent-owned, 37 PSK entries plus one 802-1x entry in the wallet.

- Registration: `journalctl -b -t NetworkManager | grep 'agent registered'` shows
  `io.github.grassyloki.kwalletSecrets`, and it re-registers after the process is
  killed and after NetworkManager restarts.
- Live connect to an agent-owned WPA3 network: NetworkManager logged
  `access point 'WAN2-DIRECT' has security, but secrets are required`, the plugin
  logged `hit WAN2-DIRECT (...) 802-11-wireless-security -> 1 key(s) [psk]`, and
  the connection came up with no prompt.
- Fall-through paths verified against the live wallet: unknown UUID, the
  `REQUEST_NEW` flag, a `vpn` setting, and `802-1x` while `handle_8021x` is off
  all return `NoSecrets`; `802-1x` returns the password once the setting is on.
- Settings: toggling `handle_8021x` and `debug_logging` restarts the helper with
  the new flags. Supervision restarts the helper within 30s of it dying, and a
  duplicate copy exits on its single-instance lock rather than double-registering.
- QMap codec round-trips non-ASCII values.
- **Noctalia version tested against:** 5.0.0-beta.10
- **Plugin API level:** 28

- [x] Tested on Niri
- [ ] Tested on Hyprland
- [ ] Tested on Sway
- [ ] Tested on another compositor:

## Screenshots / Videos

No visual surface - the plugin is a single `[[service]]` with no widget, panel,
or shortcut. What it produces is journal output:

```
noctalia-kwallet-secrets: INFO registered with NetworkManager as io.github.grassyloki.kwalletSecrets
noctalia-kwallet-secrets: INFO hit WAN2-DIRECT (6fec006a-...) 802-11-wireless-security -> 1 key(s) [psk]
NetworkManager: <info> device (wlan0): Activation: (wifi) connection 'WAN2-DIRECT' has security, and secrets exist. No new secrets needed.
```

## Checklist

- [x] The directory name matches the part of `id` after the `/` in `plugin.toml` exactly.
- [x] It ships `plugin.toml`, `README.md`, `thumbnail.webp`, and `translations/en.json`.
- [x] `README.md` follows the [README template](https://github.com/noctalia-dev/community-plugins/blob/main/README_TEMPLATE.md), documents every entry id and dependency, and includes exact panel IPC commands and launcher prefixes where applicable.
- [ ] `thumbnail.webp` is present and relevant; for a new plugin I created it with the [thumbnail generator](https://assets.noctalia.dev/plugins/thumbnail-generator.html), and for an update I regenerated it with the generator if the visual identity or user-facing appearance changed.
- [x] `version` follows semver and is bumped in this PR; `plugin_api` is the oldest API level this plugin requires.
- [x] Every non-English translation in this PR uses a locale supported by Noctalia core, and I can read, write, and understand that language well enough to review and maintain it (no unreviewed machine/LLM translations).
- [x] I did not edit `catalog.toml`; CI generates it.
- [x] This PR touches exactly one plugin directory.

## Code review attestation

- [x] The code is readable and not obfuscated, minified, or generated.
- [x] It does not download and execute remote code.
- [x] Every network call, filesystem write, and spawned process is something the description above accounts for.
- [x] I have the right to publish this code under the `license` declared in `plugin.toml`.

