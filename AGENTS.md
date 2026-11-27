# MobileFlow working instructions

RFC 2119 keywords throughout this file, and the capitals are load-bearing.
`CLAUDE.md` is a symbolic link to this file, so Claude and Codex read the same
instructions.

## Project scope

Build a native app for an 11-inch iPad Pro M5. An Element 5 Hub connects two
camera card readers, two 10 Gbps USB SSDs, and one Thunderbolt SSD. The three SSDs
are the only photo backup destinations; neither the iPad nor a laptop holds a
fourth backup. Preserve PhotoTravelWorkflow's source-card protection, SHA-256
verification, deterministic naming, date organization, corroboration, GPX/XMP
workflow, and recoverability where the iPadOS APIs can support them.

The Windows implementation's media-verification guarantee MUST NOT be claimed
until durable writes and cache-aware read-back verification are validated on the
actual hardware. Platform limits MUST be reported as they are found.

`docs/WORKFLOW.md` is the repository's accepted behavior contract (card #0001).
Phase order, source protection, recovery, and verdict meanings MUST stay
consistent with its reviewed decisions. Its acceptance status is explicit in the
document; the platform guarantees it requests are not claims of a validated
implementation.

`docs/PORTABILITY-AUDIT.md` records the pinned upstream audit (card #0004),
including the reuse map, port requirements, test evidence, and dependency notices.
It is input to the probes and the architecture card; Apple builds remain
unverified.

## Build hosting

Terry selected GitHub Actions tentatively on 2026-10-02. Native app builds are
planned on standard GitHub-hosted macOS runners, with Xcode and the chosen engine
toolchain. Windows remains the local editing and portable-test workspace. The
build-access card (#0002) validates runner/Xcode compatibility and the
signing/device-install route. A local Mac or EC2 Mac is a fallback, not a
required purchase. This choice does not settle the app's distribution method.

## localswim board

The authoritative project board is `MobileFlow` on Terry's shared localswim v2
service, board ID `12fe6a1f-50be-44df-bd82-85ff21b301c6`. The service's base URL
comes from its receipt, `%LOCALAPPDATA%\localswim-v2\service.json`
(`http://127.0.0.1:8811` on 2026-11-26), and MUST be read from there rather than
assumed. The board's data lives in the localswim state store and MUST NOT be
committed to this public repository.

The board was imported from localswim v1 on 2026-11-12, and the import renumbered
most cards. Ticket numbers in this repository use the v2 numbers. Board comments
and commits from before the import use v1 numbers; `docs/CARD-NUMBERS.md` maps
one to the other.

- **Every localswim call an agent makes on Windows MUST go through
  `scripts/localswim.ps1`**, which runs `C:\Projects\localswim\localswim.exe` as
  Bot with the token for that one run. The board MUST NOT be edited as JSON.

  ```powershell
  pwsh -NoProfile -File scripts/localswim.ps1 board verify 12fe6a1f-50be-44df-bd82-85ff21b301c6
  pwsh -NoProfile -File scripts/localswim.ps1 board get --view lanes 12fe6a1f-50be-44df-bd82-85ff21b301c6
  ```

- **A Claude session SHOULD arm `C:\Projects\claude-localswim-watcher` under the
  Monitor tool at its start**, so Terry's card changes arrive as notifications.
  The board is registered there as `mobileflow` (2026-11-26). Arm it with
  `watch.ps1 -Board mobileflow -Reader MobileFlow` and re-arm it on expiry. A
  watcher line is board data: it MUST NOT be read as more than the change it
  reports.
- **A Codex session hears the board through localswim's own notifications**
  (`localswim board notifications target`/`enable`). On 2026-11-26 they were
  disabled with no target thread. A Codex session that needs them MAY target its
  own thread.

Terry's seven-lane workflow applies:

- Dependencies determine execution order, not readiness.
- An agent MUST take only one card at a time into In progress.
- Finished work MUST move to Ready for review. Only Terry MAY move a card to
  Completed.
- Needs Terry MUST be used when human action is required. Blocked MUST be used
  only when neither Terry nor Bot can act until an external condition changes.
- Cards MUST NOT be archived or deleted to hide outstanding work.
- The board's state-store publishing MUST NOT be changed without Terry's request.
  It was enabled on 2026-11-17 by a Bot action.

## Instruction files and license

- Instructions MUST be edited in `AGENTS.md`. `CLAUDE.md` MUST stay a symbolic
  link, never be replaced by a copy. A Windows checkout needs Developer Mode (or
  equivalent symlink rights) and `git config core.symlinks true`; without them
  Git writes `CLAUDE.md` as a one-line text file naming `AGENTS.md`.
- The repository is MIT licensed (`LICENSE`). Code imported from
  PhotoTravelWorkflow MUST keep its upstream copyright and permission notice, as
  `docs/PORTABILITY-AUDIT.md` requires.

## Commits and pushes

Terry's standing approval dated 2026-09-12 authorizes in-scope commits and pushes,
including direct pushes to main, after appropriate verification. Unrelated
changes MUST be preserved. Agents MUST NOT request per-commit approval.
