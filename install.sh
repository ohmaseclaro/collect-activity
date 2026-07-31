#!/usr/bin/env sh
# collect-activity installer.
#
#   curl -fsSL https://raw.githubusercontent.com/ohmaseclaro/collect-activity/main/install.sh | sh
#
# Installs the `collect-activity` CLI into ~/.local/bin — and the `transcripts` CLI it reads
# agent sessions through (github.com/ohmaseclaro/transcripts), whenever that one is missing or
# too old, by running its own installer. If Claude Code or Cursor is present, also installs the
# `activity-report` agent skill, so your agent reaches for the bundle when you ask "what did I
# work on?". One command, everything ready.
#
# Knobs (env):
#   COLLECT_ACTIVITY_BIN=~/bin      where to put the CLI       (default ~/.local/bin)
#   COLLECT_ACTIVITY_REF=v1.0.0     branch/tag to install      (default main)
#   COLLECT_ACTIVITY_REPO=you/fork  source repo                (default ohmaseclaro/collect-activity)
#   COLLECT_ACTIVITY_NO_SKILL=1     CLI only, skip the agent skill
#   TRANSCRIPTS_*                   forwarded to the transcripts installer
set -eu

REPO="${COLLECT_ACTIVITY_REPO:-ohmaseclaro/collect-activity}"
REF="${COLLECT_ACTIVITY_REF:-main}"
BASE="https://raw.githubusercontent.com/$REPO/$REF"
BIN="${COLLECT_ACTIVITY_BIN:-$HOME/.local/bin}"
SKILL="activity-report"
NEED_TRANSCRIPTS="1.11.0"

say()  { printf '%s\n' "$*"; }
die()  { printf 'installer: %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 is required (macOS: xcode-select --install)"
command -v git     >/dev/null 2>&1 || die "git is required"
command -v curl    >/dev/null 2>&1 || die "curl is required"

fetch() { # fetch REMOTE_PATH LOCAL_PATH — atomic: download to a temp file, then move
  tmp="$2.part.$$"
  curl -fsSL "$BASE/$1" -o "$tmp" || { rm -f "$tmp"; die "download failed: $BASE/$1"; }
  [ -s "$tmp" ] || { rm -f "$tmp"; die "empty download: $BASE/$1"; }
  mv -f "$tmp" "$2"
}

# ---------------------------------------------------------------------------- CLI
mkdir -p "$BIN"
fetch collect-activity "$BIN/collect-activity"
chmod +x "$BIN/collect-activity"
say "✔ installed $BIN/collect-activity"

# ---------------------------------------------------------------------------- agent skill
if [ "${COLLECT_ACTIVITY_NO_SKILL:-0}" != "1" ]; then
  installed_skill=0
  for root in "$HOME/.claude/skills" "$HOME/.cursor/skills"; do
    parent="$(dirname "$root")"
    [ -d "$parent" ] || continue          # that agent isn't installed here
    mkdir -p "$root/$SKILL"
    fetch "skill/$SKILL/SKILL.md" "$root/$SKILL/SKILL.md"
    say "✔ installed skill $root/$SKILL"
    installed_skill=1
  done
  [ "$installed_skill" = 1 ] || say "·  no ~/.claude or ~/.cursor found — skipped the agent skill"
fi

# ---------------------------------------------------------------------------- transcripts
# collect-activity refuses to run without transcripts >= $NEED_TRANSCRIPTS, so make sure it is
# here before the first run, not when it fails. Its installer is idempotent.
have=""
command -v transcripts >/dev/null 2>&1 && have="$(transcripts --version 2>/dev/null | awk '{print $2}')"
# a fresh install may not have ~/.local/bin on PATH yet in this shell
[ -z "$have" ] && [ -x "$BIN/transcripts" ] && have="$("$BIN/transcripts" --version 2>/dev/null | awk '{print $2}')"

if [ -n "$have" ] && [ "$(printf '%s\n%s\n' "$NEED_TRANSCRIPTS" "$have" | sort -V | head -n1)" = "$NEED_TRANSCRIPTS" ]; then
  say "✔ transcripts $have already installed"
else
  say "→ installing transcripts (required, >= $NEED_TRANSCRIPTS)"
  curl -fsSL "https://raw.githubusercontent.com/${TRANSCRIPTS_REPO:-ohmaseclaro/transcripts}/${TRANSCRIPTS_REF:-main}/install.sh" | sh
fi

# ---------------------------------------------------------------------------- PATH
case ":$PATH:" in
  *":$BIN:"*) ;;
  *)
    printf '!  %s is not on your PATH. Add it:\n' "$BIN" >&2
    printf '\n    echo '\''export PATH="%s:$PATH"'\'' >> ~/.zshrc && exec zsh\n\n' "$BIN"
    ;;
esac

say ""
say "Run it:  cd ~/code && collect-activity --since 24h    # projects = subdirs of where you stand"
say "         (or: export COLLECT_ACTIVITY_ROOT=~/code once, then run it from anywhere)"
