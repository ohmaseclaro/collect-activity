#!/usr/bin/env bash
# End-to-end bundle check. Builds a throwaway project root (one touched git project, one quiet
# one) and a fake transcript store the real `transcripts` CLI reads via TRANSCRIPTS_HOME, then
# asserts what the bundle is supposed to contain. Never touches your real repos or sessions.
#   ./test-bundle.sh          (needs transcripts >= 1.11.0 on PATH)
set -u
cd "$(dirname "$0")"
CA="$PWD/collect-activity"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ROOT="$WORK/root"
FIXHOME="$WORK/home"
OUT="$WORK/bundle"

# --- a touched project: one commit by "me", one by someone else, one dirty file
DEMO="$ROOT/demo"
mkdir -p "$DEMO"
git -C "$DEMO" init -q
git -C "$DEMO" config user.email "me@example.com"
git -C "$DEMO" config user.name "Me Myself"
echo "hello" > "$DEMO/feature.txt"
git -C "$DEMO" add -A && git -C "$DEMO" commit -qm "add greeting feature"
echo "other" > "$DEMO/other.txt"
git -C "$DEMO" add -A
git -C "$DEMO" -c user.email=other@example.com -c user.name=Other commit -qm "someone elses commit"
echo "wip" > "$DEMO/wip.txt"

# --- a quiet project: exists, but nothing touched inside the window
QUIET="$ROOT/quiet"
mkdir -p "$QUIET"
echo "old" > "$QUIET/old.txt"
touch -t 202001010000 "$QUIET/old.txt"

# --- a fake Claude Code session that ran in the demo project
DEMO_REAL="$(cd "$DEMO" && pwd -P)"     # transcripts realpath-normalizes cwd; match it
PROJ="$FIXHOME/.claude/projects/-fixture-demo"
mkdir -p "$PROJ"
NOW_ISO="$(python3 -c 'from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))')"
msg() { # msg ROLE TEXT TIMESTAMP
  python3 -c 'import json,sys
print(json.dumps({"type": sys.argv[1], "timestamp": sys.argv[3], "cwd": sys.argv[4],
                  "message": {"role": sys.argv[1], "content": sys.argv[2]}}))' \
    "$@" "$DEMO_REAL" >> "$PROJ/cccccccc-1111-2222-3333-444444444444.jsonl"
}
msg user "please add the PINEAPPLE greeting feature" "$NOW_ISO"
msg assistant "done, greeting feature added and committed" "$NOW_ISO"
msg user "this OLDNEEDLE message is from long before the window" "2020-01-01T00:00:00Z"

PASS=0 FAIL=0
ok() { # ok LABEL EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"
  else FAIL=$((FAIL + 1)); printf '  FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"; fi
}
has() { grep -qs -- "$2" "$1" && echo yes || echo no; }

echo "bundle checks (fixture: $WORK)"
TRANSCRIPTS_HOME="$FIXHOME" "$CA" --since 1h --root "$ROOT" --out "$OUT" >/dev/null 2>&1

ok "manifest written"                        yes "$([ -f "$OUT/manifest.json" ] && echo yes || echo no)"
ok "touched project is in the manifest"      yes "$(has "$OUT/manifest.json" '"name": "demo"')"
ok "quiet project is not"                    no  "$(has "$OUT/manifest.json" '"name": "quiet"')"
ok "my commit is in commits.md"              yes "$(has "$OUT/projects/demo/commits.md" "add greeting feature")"
ok "other author filtered out by default"    no  "$(has "$OUT/projects/demo/commits.md" "someone elses commit")"
ok "dirty file shows in worktree.md"         yes "$(has "$OUT/projects/demo/worktree.md" "wip.txt")"
ok "touched file listed in files.md"         yes "$(has "$OUT/projects/demo/files.md" "feature.txt")"
ok "in-window transcript message captured"   yes "$(has "$OUT/projects/demo/transcripts.md" "PINEAPPLE")"
ok "out-of-window message trimmed"           no  "$(has "$OUT/projects/demo/transcripts.md" "OLDNEEDLE")"

# --author all lifts the identity filter
OUT2="$WORK/bundle2"
TRANSCRIPTS_HOME="$FIXHOME" "$CA" --since 1h --root "$ROOT" --out "$OUT2" --author all >/dev/null 2>&1
ok "--author all includes the other commit"  yes "$(has "$OUT2/projects/demo/commits.md" "someone elses commit")"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
