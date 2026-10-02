# MobileFlow

A native iPad app for end-of-day photo offload to three external SSDs, based on
[PhotoTravelWorkflow](https://github.com/TerryOtt/PhotoTravelWorkflow).

Status: planning. No app implementation exists yet.

## Target setup

- 11-inch iPad Pro M5 running the app.
- Element 5 Hub connecting two camera card readers and three external SSDs.
- Two 10 Gbps USB SSDs and one Thunderbolt SSD.
- The iPad and laptop are not photo backup destinations.

## Intended workflow

Select two source folders and three destination folders, optionally select a GPX
track, then tap **Go**.

The app will copy photographs to all three SSDs, read back and verify each copy,
compare the second camera card, and produce geotagged XMP sidecars. Progress and
errors will be visible for each destination. Success requires all three copies
to pass verification; corroboration and geotagging results will be reported
explicitly.

Preserve the existing workflow's date-based organization, deterministic naming,
SHA-256 verification, and manifests where practical. Source cards must never be
modified. Interrupted runs and disconnected drives must be recoverable without
presenting partial files as completed backups.

## Initial technical direction

Use SwiftUI for the native interface and evaluate reuse of PhotoTravelWorkflow's
Rust engine. Replace Windows-specific storage access with an iPadOS layer that
uses user-selected folders.

The first milestone is a hardware proof of concept: one source folder to one
external SSD. Validate folder access, durable writes, read-back verification,
throughput, interruption, and recovery before expanding to the full workflow.

The completion guarantee remains a design question until the iPadOS storage
layer is validated. A hash read served from cache must not be represented as
proof that bytes were read back from physical media. Background operation and
drive-release behavior also require validation on the actual setup.

## Development and project board

Portable engine work can be developed and tested on Windows. Building and signing
the native iPad app requires an Apple toolchain on a supported macOS host, which
can be a local Mac or a remote build host. Build access, signing, and device
installation are early project milestones.

The machine-local localswim board lives at
`C:\Projects\localswim-state-store\MobileFlow\mobileflow-localswim.json` and initially
uses [http://127.0.0.1:8806/](http://127.0.0.1:8806/). Its JSON is outside this public
repository.

Before opening the board, start or reuse its service and required JSON monitor:

```powershell
& D:\Projects\MobileFlow\scripts\Start-Board.ps1 -ThreadId $env:CODEX_THREAD_ID
```

Run this from a Codex session with the tools and shared monitor described in
`AGENTS.md`. The launcher requires an active Codex thread UUID and keeps the
monitor targeted at that thread. Board reads and writes use `localswim-cli`.
