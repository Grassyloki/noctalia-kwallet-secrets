# Publishing notes — noctalia-dev/community-plugins

`PR-BODY.md` is the PR body, fed verbatim to `gh pr create --body-file`.
Keep the `<!-- noctalia-pr-template:v1 -->` marker on line 1 — the bot closes
PRs that lose the template structure. Two boxes are left UNCHECKED on purpose.

BEFORE MARKING READY FOR REVIEW

1. Thumbnail. The committed thumbnail.webp is a hand-built 960x540 card, not
   output from https://assets.noctalia.dev/plugins/thumbnail-generator.html, so
   that checkbox is false as it stands. Either regenerate it there (drop in a
   screenshot of the journal output, title "KWallet Secrets", tag "Service",
   pick an accent) and replace the file, or leave the PR as Draft and say so.

2. Translations checkbox. Only translations/en.json ships, so there is no
   non-English translation to attest to; the box is vacuously true. Say so in a
   comment if a reviewer queries it.

3. plugin_api = 28. The docs say Noctalia supports levels 3 through 29 and that
   29 is unreleased, so 28 is the current released tip, and the repo README says
   to use the current documented level for a new plugin. The checklist words the
   same field as "the oldest API level this plugin requires", which pulls the
   other way: the manifest uses no level-gated feature (no string_map, no
   keyboard_focus, persistent, capture_keys, or actions) and the runtime calls
   are all foundational, so it also runs at plugin_api 13, which was verified on
   Noctalia 5.0.0-beta.10. If a reviewer prefers the true floor, lowering it is
   a one-line change that widens compatibility.
