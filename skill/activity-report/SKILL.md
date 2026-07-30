---
name: activity-report
description: >
  Organize what the user worked on over any time window — a day, a week, a sprint, since a
  date — into an insightful report, using the `collect-activity` CLI, which bundles git
  commits, uncommitted diffs, files touched, and AI-agent transcripts per project. Use this
  whenever the user wants their work summarized, reviewed, or organized: "daily report",
  "standup notes", "what did I do yesterday / this week / this month", "summarize my sprint",
  "catch me up", "what's still unfinished", "what should I pick up next", "help me prep my
  retro" — whatever the period, even when they don't say the word "report". For finding or
  reading one specific past conversation, use the find-and-read-transcripts skill instead.
---

# Activity report

This machine has `collect-activity` (usually on PATH at `~/.local/bin/collect-activity`;
https://github.com/ohmaseclaro/collect-activity). One run collects the raw material a work
review needs — git commits with patches, uncommitted state, files touched, and agent sessions
from Claude Code / Claude Cowork / Cursor, distilled to intent + prose — and writes it as one
markdown file per concern per project, plus a `manifest.json`. Use it instead of hand-mining
repos and transcript stores: it already prunes build noise, filters to the user's own commits,
and attributes agent sessions to the right project.

**The collection is the easy half. The value of this skill is the organizing**: turning a
window's worth of scattered commits and conversations into a picture the user can act on —
what moved, what stalled, what was decided, what to do next.

Run `collect-activity --help` for the full flag list.

## Workflow

### 1. Collect — any window

```sh
collect-activity --since 24h                  # a day
collect-activity --since 1w                   # a week
collect-activity --since "2026-07-01"         # the month so far
collect-activity --since "2026-07-14" --until "2026-07-28"    # a sprint
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

### 3. Organize the findings

Raw chronology is not a report. Structure the window so it answers something:

- **Per project**: shipped (commits) · in flight (worktree + how sessions ended) · decided or
  discovered (transcripts — decisions, dead ends ruled out, surprises worth remembering).
- **Across projects**: the themes — where the time actually went, work that spans repos,
  anything started in one project that blocks another.
- **Loose ends, explicitly**: dirty worktrees, stashes, sessions that ended mid-task, commits
  whose transcript shows a follow-up that never happened. These become the "pick up next" list.
- **Shape it to the ask**: standup wants yesterday/today/blockers in a few lines; a weekly or
  sprint review wants progress against intent and what slipped; a retro wants decisions,
  friction and surprises; a planning session wants the loose-end list ranked. Longer windows
  deserve trend observations (what kept getting interrupted, what finally landed), not just a
  longer list.

Surface any `warnings` from the manifest instead of silently ignoring gaps.

## Notes

- Commits are filtered to the repo's own `user.email`/`user.name` by default; the manifest
  records how many other-author commits were skipped.
- This skill reports over a window. When the user is after one specific past conversation
  ("find the chat where…", "continue where we left off"), that is the find-and-read-transcripts
  skill and the `transcripts` CLI, not a bundle run.
- No transcript sessions for a project that clearly had agent work → run `transcripts --doctor`
  to see what the transcript reader can see.
- Bundles land under the system temp dir by default; pass `--out` to keep one.
- A bundle contains diffs and private conversations — treat any report generated from it with
  the same care as the code and chats themselves.
