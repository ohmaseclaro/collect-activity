---
name: activity-report
description: >
  Report what the user worked on over a time window by running the `collect-activity` CLI,
  which bundles git commits, uncommitted diffs, files touched, and AI-agent transcripts per
  project. Use this whenever the user asks what they worked on, got done, or should pick up
  next — "daily report", "what did I do yesterday", "standup notes", "catch me up",
  "summarize my week", "where did I leave off", "what's still unfinished" — including requests
  for a specific period, even when they don't say the word "report".
---

# Activity report

This machine has `collect-activity` (usually on PATH at `~/.local/bin/collect-activity`;
https://github.com/ohmaseclaro/collect-activity). One run collects everything a work report
needs — git commits with patches, uncommitted state, files touched, and agent sessions from
Claude Code / Claude Cowork / Cursor, distilled to intent + prose — and writes it as one
markdown file per concern per project, plus a `manifest.json`. Use it instead of hand-mining
repos and transcript stores: it already prunes build noise, filters to the user's own commits,
and attributes agent sessions to the right project.

Run `collect-activity --help` for the full flag list.

## Workflow

### 1. Collect

```sh
collect-activity --since 24h                  # "what did I do today/yesterday"
collect-activity --since 1w                   # "summarize my week"
collect-activity --since "2026-07-22 15:35" --until "2026-07-23 09:00"
```

The project root (its immediate subdirectories are the projects) comes from
`COLLECT_ACTIVITY_ROOT` or `--root`. If neither is set, the tool says so — ask the user where
their projects live rather than guessing. Useful extras: `--projects api,web` to scope,
`--author all` when the user asks about team activity, `--subagents` to include
background/subagent runs.

The run prints the bundle directory and a suggested `report-<window>.md` filename.

### 2. Read the bundle — one project at a time

Start with `manifest.json`: the window, warnings, and a per-project inventory (files changed,
commits, dirty repos, transcript sessions) with the relative path of every bundle file — `null`
means nothing was found for that concern. It tells you what is worth opening before you open
anything.

Then, per project, read in this order:

1. `commits.md` — what actually shipped: message, stat, patch.
2. `worktree.md` — what is still in progress: status, staged/unstaged diffs, stashes. **This is
   where "unfinished" lives; cross-check against commits before calling anything done.**
3. `transcripts.md` — the *why*: what the user asked their agents for, in their own words, and
   what the agents said they did. The end of a session is usually where work was left off.
4. `files.md` — fallback signal for projects with no repo or no commits.

Do not read every file of every project into context at once — the bundle is split precisely
so you can process one project, summarize it, and move to the next.

### 3. Write the report

Organize by project, most active first. For each: what was done (from commits), what is in
flight (from worktree + how transcript sessions ended), and anything decided or discovered
worth remembering (from transcripts). Close with a short "pick up next" list — dirty worktrees,
stashes, and sessions that ended mid-task are the strongest candidates. Surface any `warnings`
from the manifest instead of silently ignoring gaps.

## Notes

- Commits are filtered to the repo's own `user.email`/`user.name` by default; the manifest
  records how many other-author commits were skipped.
- No transcript sessions for a project that clearly had agent work → run `transcripts --doctor`
  to see what the transcript reader can see.
- Bundles land under the system temp dir by default; pass `--out` to keep one.
- A bundle contains diffs and private conversations — treat any report generated from it with
  the same care as the code and chats themselves.
