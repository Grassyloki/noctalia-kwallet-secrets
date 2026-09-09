# Publishing notes — noctalia-dev/community-plugins

`PR-BODY.md` is the PR body, fed verbatim to `gh pr create --body-file`.
Keep the `<!-- noctalia-pr-template:v1 -->` marker on line 1 — the bot converts
a ready PR that loses the template structure back to Draft (it never closes it).
Two boxes are left UNCHECKED on purpose.

CHECKLIST WORDING IS MATCHED VERBATIM

`.github/workflows/scripts/enforce-pr-template.py` looks for each checklist line
as an exact substring of the whitespace-collapsed body. A paraphrased line is
reported as "the checklist entry: ..." and fails CI even while the PR is a draft,
which is what happened on the first run of PR #683 (the README and thumbnail
lines had been shortened). Line wrapping is safe; changed words are not.
`check-pr-body.py` runs that same upstream code against PR-BODY.md and is a
preflight in publish.sh, so copy wording from the fork's PULL_REQUEST_TEMPLATE.md
rather than retyping it.

Unchecked boxes are fine while the PR is a draft; the "checked checklist entry"
errors only appear under --ready.

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
