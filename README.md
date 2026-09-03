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

## License

MIT. See [kwallet-secrets/LICENSE](kwallet-secrets/LICENSE).
