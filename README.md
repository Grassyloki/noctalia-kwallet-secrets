# noctalia-kwallet-secrets

A Noctalia plugin source holding **KWallet Secrets**. The plugin lives in its
own top-level directory, laid out the way
[community-plugins](https://github.com/noctalia-dev/community-plugins) expects,
so it can be installed straight from here or submitted upstream unchanged.

| Plugin | ID | What it does |
| --- | --- | --- |
| [kwallet-secrets](kwallet-secrets/) | `grassyloki/kwallet-secrets` | Answers NetworkManager's agent-owned Wi-Fi secret requests from KWallet instead of prompting. |

## Using it

Add this repo as a plugin source, then enable what you want:

```sh
noctalia msg plugins source add grassyloki git https://github.com/Grassyloki/noctalia-kwallet-secrets
noctalia msg plugins enable grassyloki/kwallet-secrets
```

To hack on a checkout instead, register it as a `path` source and re-export
after manifest changes:

```sh
noctalia msg plugins source add dev path ~/Projects/noctalia-kwallet-secrets
noctalia msg plugins update dev
```

`.luau` edits hot-reload; `plugin.toml` changes need the `update`.

## Layout

```
kwallet-secrets/     the plugin, one top-level directory as community-plugins requires
.publishing/         everything about getting it upstream; ignored by the plugin loader
  PR-BODY.md         the pull request body, used verbatim by gh
  NOTES.md           what to settle before taking the PR out of draft
  publish.sh         fork -> branch -> copy -> commit -> push -> open/update the PR
```

The plugin directory has to stay at the repo root and has to be named after the
part of its `id` after the `/` -- that is how both `plugins source add ... git`
and the upstream repo find it. Anything else lives in a dot-directory so the
loader skips it.

## Publishing upstream

```sh
.publishing/publish.sh            # opens the PR as a draft
.publishing/publish.sh --ready    # opens it ready for review
```

The script is idempotent: it refreshes the branch from `upstream/main`, replaces
the plugin directory wholesale, refuses to touch anything outside it (CI owns
`catalog.toml`), and edits the existing PR instead of opening a second one. The
fork checkout it works in is `~/Projects/noctalia-community-plugins`.

Updating a released plugin is the same command -- bump `version` in
`plugin.toml` first, and tick the "Update to an existing plugin" box in
`.publishing/PR-BODY.md`.

## License

MIT. See [kwallet-secrets/LICENSE](kwallet-secrets/LICENSE).
