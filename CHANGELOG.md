# Changelog

## 1.1.0

**A bare `collect-activity --since 24h` works now.**

The root defaults to the current directory when neither `--root` nor `COLLECT_ACTIVITY_ROOT`
is set — the README's own first example used to refuse to run. Run it from the folder that
holds your projects, or set the env var once to run it from anywhere. Precedence:
`--root` > `COLLECT_ACTIVITY_ROOT` > cwd.

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
  version, so one command readies both tools — and, when Claude Code or Cursor is present,
  the `activity-report` agent skill: run the bundle for any window (a day, a sprint, a month),
  read it project by project, and organize the findings — shipped / in flight / decided,
  cross-project themes, loose ends ranked for pickup.
- Git side as before: per-repo commits (message, stat, patch with lockfiles excluded),
  uncommitted state, stashes, recent branches; nested repos and submodules included;
  `--author mine` filters to the repo's local identity.
- Session headings now carry the real chat title, source and id; `--subagents` opts
  subagent/background runs in (they are hidden by default, matching `transcripts`).
- The root is explicit now — `--root` or `COLLECT_ACTIVITY_ROOT` — instead of a
  hardcoded personal default.
- `test-bundle.sh` runs the whole pipeline against a fixture root and a fixture
  transcript store.
