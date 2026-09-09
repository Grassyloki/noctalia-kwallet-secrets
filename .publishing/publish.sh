#!/usr/bin/env bash
# Publishes the plugin directory from this source repo to the community-plugins
# fork and opens (or updates) the upstream pull request. Idempotent: re-running
# refreshes the branch from upstream main and force-pushes the same branch.
set -euo pipefail

# ---- configuration -----------------------------------------------------------
PLUGIN_DIR="kwallet-secrets"                                        # top-level plugin dir in this repo, e.g. kwallet-secrets
UPSTREAM_REPO="noctalia-dev/community-plugins"                      # upstream repo the PR targets
UPSTREAM_BRANCH="main"                                              # upstream base branch
FORK_PATH="$HOME/Projects/noctalia-community-plugins"               # local clone of your fork, e.g. ~/Projects/noctalia-community-plugins
PR_BRANCH="add-kwallet-secrets"                                     # branch pushed to the fork
PR_TITLE="Add grassyloki/kwallet-secrets"                           # pull request title
DRAFT="true"                                                        # true = open as draft; pass --ready to override

SOURCE_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"      # this repo's root, derived from the script location
PR_BODY="$SOURCE_REPO/.publishing/PR-BODY.md"                       # PR body file, fed verbatim to gh pr create

# ---- output helpers ----------------------------------------------------------
C='\033[0;36m'; Y='\033[0;33m'; G='\033[0;32m'; R='\033[0;31m'; P='\033[0;35m'; N='\033[0m'
info()  { printf "${C}%s${N}\n" "$*"; }
warn()  { printf "${Y}%s${N}\n" "$*"; }
ok()    { printf "${G}%s${N}\n" "$*"; }
fail()  { printf "${R}%s${N}\n" "$*" >&2; exit 1; }
var()   { printf "${P}  %-16s %s${N}\n" "$1" "$2"; }

# ---- argument parsing --------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --ready) DRAFT="false" ;;                                       # open the PR ready for review instead of draft
    -h|--help) sed -n '2,5p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) fail "unknown argument: $arg (only --ready is accepted)" ;;
  esac
done

info "Configuration"
var "SOURCE_REPO" "$SOURCE_REPO"
var "PLUGIN_DIR" "$PLUGIN_DIR"
var "UPSTREAM_REPO" "$UPSTREAM_REPO"
var "UPSTREAM_BRANCH" "$UPSTREAM_BRANCH"
var "FORK_PATH" "$FORK_PATH"
var "PR_BRANCH" "$PR_BRANCH"
var "PR_TITLE" "$PR_TITLE"
var "PR_BODY" "$PR_BODY"
var "DRAFT" "$DRAFT"
echo

# ---- manifest helpers --------------------------------------------------------
# Reads a top-level plugin.toml key. Stops at the first [[table]] so that the
# entry blocks' own keys (e.g. [[service]] id = "service") are never matched.
manifest() { sed -n "/^\\[/q; s/^$1 *= *\"\\(.*\\)\"/\\1/p" "$SOURCE_REPO/$PLUGIN_DIR/plugin.toml"; }

# ---- preflight ---------------------------------------------------------------
command -v gh >/dev/null || fail "gh is not installed"
gh auth status >/dev/null 2>&1 || fail "gh is not authenticated -- run: gh auth login"
[[ -d "$SOURCE_REPO/$PLUGIN_DIR" ]] || fail "plugin directory not found: $SOURCE_REPO/$PLUGIN_DIR"
[[ -f "$PR_BODY" ]] || fail "PR body not found: $PR_BODY"

# The directory name must match the part of the manifest id after the slash.
manifest_id="$(manifest id)"
[[ "${manifest_id#*/}" == "$PLUGIN_DIR" ]] \
  || fail "directory '$PLUGIN_DIR' does not match plugin.toml id '$manifest_id'"
version="$(manifest version)"
info "Publishing $manifest_id v$version"

# Upstream requires these four files in every plugin directory.
for f in plugin.toml README.md thumbnail.webp translations/en.json; do
  [[ -f "$SOURCE_REPO/$PLUGIN_DIR/$f" ]] || fail "missing required file: $PLUGIN_DIR/$f"
done

# CI matches checklist lines against the PR template verbatim, so check the body
# before touching git. Needs the fork checkout, so it is re-run after the fetch.
check_body() {
  local args=(); if [[ "$DRAFT" != "true" ]]; then args=(--ready); fi
  "$SOURCE_REPO/.publishing/check-pr-body.py" "${args[@]}" \
    || fail "fix PR-BODY.md before publishing (see .publishing/NOTES.md)"
}
check_body

# The source repo should be clean, so the fork gets a committed state.
if ! git -C "$SOURCE_REPO" diff --quiet || ! git -C "$SOURCE_REPO" diff --cached --quiet; then
  warn "source repo has uncommitted changes -- they will still be copied"
fi

# ---- fork checkout -----------------------------------------------------------
if [[ ! -d "$FORK_PATH/.git" ]]; then
  info "Forking and cloning $UPSTREAM_REPO -> $FORK_PATH"
  gh repo fork "$UPSTREAM_REPO" --clone=false >/dev/null                  # --remote is rejected when a repo argument is given
  gh repo clone "$(gh api user --jq .login)/${UPSTREAM_REPO#*/}" "$FORK_PATH" -- --origin origin
  # gh adds an upstream remote itself; only add it when it is missing.
  git -C "$FORK_PATH" remote get-url upstream >/dev/null 2>&1 \
    || git -C "$FORK_PATH" remote add upstream "https://github.com/$UPSTREAM_REPO.git"
else
  info "Reusing fork checkout at $FORK_PATH"
fi

info "Refreshing branch from upstream/$UPSTREAM_BRANCH"
git -C "$FORK_PATH" fetch upstream "$UPSTREAM_BRANCH" --quiet
git -C "$FORK_PATH" checkout -B "$PR_BRANCH" "upstream/$UPSTREAM_BRANCH" --quiet

# ---- copy the plugin ---------------------------------------------------------
check_body   # again, now that the fork holds the current enforce-pr-template.py

info "Copying $PLUGIN_DIR into the fork"
rm -rf "${FORK_PATH:?}/$PLUGIN_DIR"                                  # replace wholesale so deletions propagate
cp -r "$SOURCE_REPO/$PLUGIN_DIR" "$FORK_PATH/$PLUGIN_DIR"
git -C "$FORK_PATH" add "$PLUGIN_DIR"

# CI generates catalog.toml; a PR must never touch it or anything outside the plugin.
stray="$(git -C "$FORK_PATH" diff --cached --name-only | grep -v "^$PLUGIN_DIR/" || true)"
[[ -z "$stray" ]] || fail "PR would touch files outside $PLUGIN_DIR/:"$'\n'"$stray"

if git -C "$FORK_PATH" diff --cached --quiet; then
  warn "no changes -- the fork already matches this plugin version"
else
  git -C "$FORK_PATH" commit --quiet -m "Add $manifest_id $version" \
    -m "$(manifest description)"
  ok "committed"
fi

info "Pushing $PR_BRANCH to the fork"
git -C "$FORK_PATH" push --force-with-lease -u origin "$PR_BRANCH" --quiet

# ---- pull request ------------------------------------------------------------
existing="$(gh pr list --repo "$UPSTREAM_REPO" --head "$PR_BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null || true)"
if [[ -n "$existing" ]]; then
  info "Updating existing PR #$existing"
  gh pr edit "$existing" --repo "$UPSTREAM_REPO" --title "$PR_TITLE" --body-file "$PR_BODY"
  ok "updated: $(gh pr view "$existing" --repo "$UPSTREAM_REPO" --json url --jq .url)"
else
  info "Opening a new pull request"
  draft_flag=()
  if [[ "$DRAFT" == "true" ]]; then draft_flag=(--draft); fi
  gh pr create --repo "$UPSTREAM_REPO" \
    --base "$UPSTREAM_BRANCH" --head "$(gh api user --jq .login):$PR_BRANCH" \
    --title "$PR_TITLE" --body-file "$PR_BODY" "${draft_flag[@]}"
  ok "pull request opened"
fi

if [[ "$DRAFT" == "true" ]]; then
  warn "Opened as a draft -- see .publishing/NOTES.md, then: gh pr ready <number> --repo $UPSTREAM_REPO"
fi
exit 0
