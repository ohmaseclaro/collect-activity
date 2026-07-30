# Changelog

## 1.0.0

**First public release.**

Started life as a private `collect_activity.py` that carried its own transcript parsers — a
Claude JSONL reader, a Cursor SQLite fallback, and slug-based project attribution. All of that
is deleted: agent sessions now come from the [`transcripts`](https://github.com/ohmaseclaro/transcripts)
CLI (`--dir` for attribution, `--details --json` for messages), which reads every store on the
machine — Claude Code, Claude Cowork, Cursor app, cursor-agent CLI — and already dedupes synced
sessions and resolves real chat-window titles.

- One self-contained bash script with an embedded Python core, same shape as `transcripts`.
- `install.sh` installs `transcripts` from GitHub when missing or older than the required
  version, so one command readies both tools.
- Git side as before: per-repo commits (message, stat, patch with lockfiles excluded),
  uncommitted state, stashes, recent branches; nested repos and submodules included;
  `--author mine` filters to the repo's local identity.
- Session headings now carry the real chat title, source and id; `--subagents` opts
  subagent/background runs in (they are hidden by default, matching `transcripts`).
- The root is explicit now — `--root` or `COLLECT_ACTIVITY_ROOT` — instead of a
  hardcoded personal default.
- `test-bundle.sh` runs the whole pipeline against a fixture root and a fixture
  transcript store.
