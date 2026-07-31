# collect-activity

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![requires: python3 · git](https://img.shields.io/badge/requires-python3%20%C2%B7%20git-informational)
![platform: macOS · Linux](https://img.shields.io/badge/platform-macOS%20%C2%B7%20Linux-lightgrey)

Everything you did in a time window — git commits, uncommitted diffs, files touched, and what you told your AI agents — bundled as one markdown file per concern per project, plus a `manifest.json`.

```
collect-activity --since 24h --root ~/code

/tmp/collect-activity-<window>/
├── manifest.json                     what was found, where each file is, warnings
└── projects/
    ├── api/
    │   ├── files.md                  files touched, newest first
    │   ├── commits.md                every commit: message, stat, patch
    │   ├── worktree.md               branch, status, staged/unstaged diffs, stashes
    │   └── transcripts.md            agent sessions distilled to intent + prose
    └── web/ …
```

The split is deliberate: bundles are written for a reader with a context budget — a model generating your standup report, or a human catching up. It opens one project at a time instead of swallowing every diff and transcript at once.

One self-contained bash script with an embedded Python core, same shape as its sibling [`transcripts`](https://github.com/ohmaseclaro/transcripts). No dependencies beyond `python3`, `git`, and `transcripts` itself.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ohmaseclaro/collect-activity/main/install.sh | sh
```

That installs `collect-activity` into `~/.local/bin` — **and installs [`transcripts`](https://github.com/ohmaseclaro/transcripts) from GitHub when it is missing or too old**, so both tools are ready before the first run. If Claude Code or Cursor is present, it also installs the [`activity-report`](skill/activity-report/SKILL.md) agent skill — so your agent runs the bundle and organizes the findings when you ask for a standup, a weekly review, or *"what should I pick up next?"*. Prefer to read before you pipe? [`install.sh`](install.sh) is under 90 lines. Or by hand:

```sh
git clone https://github.com/ohmaseclaro/collect-activity.git
./collect-activity/collect-activity --install    # symlinks into ~/.local/bin, adds it to PATH
```

Installer knobs: `COLLECT_ACTIVITY_BIN` (install dir), `COLLECT_ACTIVITY_REF` (branch/tag), `COLLECT_ACTIVITY_NO_SKILL=1` (CLI only), `TRANSCRIPTS_*` (forwarded to the transcripts installer).

## Privacy

This tool is entirely local. It reads your repos and the transcript stores your agents already wrote to disk (through `transcripts`), and writes a bundle directory where you tell it to. Nothing is uploaded, and there is no network code in it — `install.sh` is the only file that touches the network.

A bundle contains your diffs and your agent conversations. Treat it, and anything you generate from it, like the code and chats it came from.

## What it collects

| Concern | Source |
|---------|--------|
| projects touched | file mtimes under `--root` (build output and dependency caches pruned — their mtimes track builds, not work) |
| commits | `git log --all` per repo, nested repos and submodules included; message, `--stat`, and patch, with lockfile/minified/generated diffs excluded from patch bodies |
| work in progress | `git status`, staged + unstaged diffs, stashes, recently active branches |
| agent sessions | the [`transcripts`](https://github.com/ohmaseclaro/transcripts) CLI — Claude Code, Claude Cowork, Cursor app, cursor-agent CLI. It owns store discovery, project attribution (`--dir`) and message extraction (`--details --json`); this tool only trims to the window and formats |

By default only **your** commits are included (the repo's local `user.email`/`user.name`); the manifest says how many other-author commits were skipped. `--author all` lifts the filter.

## Usage

```sh
collect-activity --since 24h                  # everything you touched today
collect-activity --since 3d --root ~/code     # explicit root
collect-activity --since "2026-07-22 15:35" --until "2026-07-23 15:35"
collect-activity --projects api,web           # just these projects, skip change detection
collect-activity --author all                 # everyone's commits, not just yours
collect-activity --subagents                  # include subagent/background agent runs
collect-activity --out ./bundle               # default: <tmpdir>/collect-activity-<window>
```

`--since` takes a duration (`24h`, `3d`, `90m`, `1w`) or an absolute time (`2026-07-22 15:35`); `--until` defaults to now. The root — whose immediate subdirectories are the projects — is `--root`, else `COLLECT_ACTIVITY_ROOT`, else the current directory: `cd` into the folder that holds your projects and a bare `collect-activity --since 24h` just works. Set `export COLLECT_ACTIVITY_ROOT=~/code` once to run it from anywhere.

Sizing knobs: `--max-patch-lines` (400), `--max-transcript-chars` (24000) and `--max-files` (300) bound each commit patch, each session, and the per-project file list.

### Transcript distillation

A raw agent session is mostly tool output. `transcripts --details --json` already strips tool calls, tool results, thinking blocks and image payloads; what lands in `transcripts.md` is the user's turns and the agent's prose — intent and narration, typically 20–40× smaller than the raw file. Messages are trimmed to the window (Cursor messages carry no timestamps and are kept whole), each turn is capped — user turns get more room, they carry the intent — and the middle of an oversized session is elided, never the ends.

### The manifest

`manifest.json` is the index a reading model starts from: the window, per-project counts (files changed, commits, dirty repos, sessions), the relative path of every bundle file, and any warnings raised while collecting. Projects with no bundle file for a concern have `null` there — no file, nothing found.

## Diagnostics

```sh
collect-activity --version
collect-activity --help
transcripts --doctor      # when sessions are missing, start with what transcripts can see
```

## Development

The whole tool is one file: [`collect-activity`](collect-activity). Bash handles arguments and dependency checks; an embedded Python heredoc does the collecting, distilling and rendering.

```sh
./test-bundle.sh          # end-to-end: fixture repo + fixture transcripts → assert the bundle
bash -n collect-activity  # syntax check
```

`test-bundle.sh` builds a throwaway project root and a fake transcript store (via `TRANSCRIPTS_HOME`), so it never touches your real repos or sessions.

Bug reports and PRs welcome — [open an issue](https://github.com/ohmaseclaro/collect-activity/issues).

## License

[MIT](LICENSE)
