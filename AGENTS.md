# MobileFlow working instructions

## Project scope

Build a native app for an 11-inch iPad Pro M5. An Element 5 Hub connects two
camera card readers, two 10 Gbps USB SSDs, and one Thunderbolt SSD. The three SSDs
are the only photo backup destinations; neither the iPad nor a laptop holds a
fourth backup. Preserve PhotoTravelWorkflow's source-card protection, SHA-256
verification, deterministic naming, date organization, corroboration, GPX/XMP
workflow, and recoverability where the iPadOS APIs can support them.

Validate durable writes and cache-aware read-back verification on the actual
hardware before claiming the Windows implementation's media-verification
guarantee. Report any platform limits honestly.

## Build hosting

Terry selected GitHub Actions tentatively on 2026-10-02. Plan native app builds
on standard GitHub-hosted macOS runners, with Xcode and the chosen engine
toolchain. Windows remains the local editing and portable-test workspace.
Validate runner/Xcode compatibility and the signing/device-install route in the
early build-access card. A local Mac or EC2 Mac is a fallback, not a required
purchase. This choice does not settle the app's distribution method.

## localswim board and required JSON monitor

The authoritative project board is:

`C:\Projects\localswim-state-store\MobileFlow\mobileflow-localswim.json`

Its initial port is 8806. Read the board's current `port` at launch rather than
assuming that number never changes. The board is machine-local and must never
be committed to the public MobileFlow repository.

Whenever launching or opening this board, MUST ensure its JSON write monitor is
running and targeted at the active Codex thread. Run the checked launcher first:

```powershell
& D:\Projects\MobileFlow\scripts\Start-Board.ps1 -ThreadId $env:CODEX_THREAD_ID
```

The launcher reuses a healthy MobileFlow service, starts a missing service with
`Start-Process -WindowStyle Hidden`, then launches or retargets the shared monitor
from `C:\Projects\FGA\architecture-design\scripts\watch_localswim.py` using
`uv run --frozen python`. It uses dedicated MobileFlow status, target, lock, and
log paths under `C:\Temp`; never reuse the FGA or localswim inception paths.
It requires `localswim`, `localswim-cli`, `uv`, and `codex` on PATH and inherits
`PYTHONIOENCODING=utf-8` and `UV_CACHE_DIR=C:\Temp\localswim-uv-cache`.

Check `C:\Temp\MobileFlow-localswim-monitor-status.json` for a running monitor
and `C:\Temp\MobileFlow-localswim-monitor-target.json` for the active thread.
Monitor messages are advisory next-turn alerts after a 15-second quiet window;
inspect their bounded activity through `localswim-cli`. The shared monitor
suppresses writes proven to be bot-only and does not log card prose.

Read and mutate the board through the supported CLI, never direct JSON edits:

```powershell
localswim-cli C:\Projects\localswim-state-store\MobileFlow\mobileflow-localswim.json board verify
localswim-cli C:\Projects\localswim-state-store\MobileFlow\mobileflow-localswim.json card next 5 --lane ready_for_work
```

Use Terry's seven-lane workflow. Dependencies determine execution order, not
readiness. Take one card at a time into In progress. Move finished work to Ready
for review; only Terry may move it to Completed. Use Needs Terry for required
human action, and Blocked only when neither Terry nor Bot can act until an
external condition changes. Do not archive or delete cards to hide outstanding
work. Leave automatic state-store pushing disabled unless Terry requests it.

## Commits and pushes

Terry's standing approval dated 2026-09-12 authorizes in-scope commits and pushes,
including direct pushes to main, after appropriate verification. Preserve
unrelated changes. Do not request per-commit approval.
