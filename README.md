# noctalia-kwallet-secrets

A Noctalia plugin source holding **KWallet Secrets**. The plugin lives in its
own top-level directory, laid out the way
[community-plugins](https://github.com/noctalia-dev/community-plugins) expects,
so it can be installed straight from here or submitted upstream unchanged.

| Plugin | ID | What it does |
| --- | --- | --- |
| [kwallet-secrets](kwallet-secrets/) | `grassyloki/kwallet-secrets` | Answers NetworkManager's agent-owned Wi-Fi, VPN and WireGuard secret requests from KWallet instead of prompting. |

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
```

That directory has to stay at the repo root and has to be named after the part
of its `id` after the `/` -- that is how both `plugins source add ... git` and
the upstream repo find it. Everything tracked here is either the plugin or this
README, so a clone is exactly what gets published.

## Publishing upstream

Submitting to [community-plugins](https://github.com/noctalia-dev/community-plugins)
is driven by a script kept outside version control, in an untracked
`.publishing/` directory on the maintainer's machine -- the PR body and its
notes are workflow scratch, not something someone installing the plugin should
have to clone.

What it does, for anyone reproducing the flow by hand:

- Works in a fork checkout of community-plugins, a sibling directory at
  `~/Projects/noctalia-community-plugins`.
- Resets a branch to `upstream/main`, then extracts the plugin with
  `git archive HEAD kwallet-secrets` -- never a filesystem copy, which would
  drag in ignored build artifacts such as `__pycache__/*.pyc` that this repo
  excludes but the upstream one does not.
- Refuses to stage anything outside `kwallet-secrets/` (CI generates
  `catalog.toml`), refuses to stage a generated file, and refuses to publish at
  all when the plugin directory has uncommitted work, since it publishes `HEAD`.
- Validates the PR body against upstream's own `enforce-pr-template.py`, which
  matches every checklist line as an exact substring of the whitespace-collapsed
  body -- a paraphrased line fails CI even while the PR is still a draft.
- Opens the pull request, or edits the existing one rather than opening a
  second.

Updating a released plugin is the same flow: bump `version` in `plugin.toml`
first, and tick the "Update to an existing plugin" box in the PR body.

## License

MIT. See [kwallet-secrets/LICENSE](kwallet-secrets/LICENSE).
