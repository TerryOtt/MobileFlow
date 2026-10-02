# Three-SSD workflow and completion contract

Status: accepted by Terry through localswim card #0001, Completed on 2026-10-02.
This document specifies intended behavior; it is not evidence that an iPad build
has achieved it. Platform-dependent guarantees remain subject to the board's
hardware probes.

## Goal and supported setup

At the end of a shooting session, select two camera-card folders and three SSD
folders, tap **Go**, and receive three independently usable photo backups with
a clear result. The target is the 11-inch iPad Pro M5 connected to an Element 5
Hub, two card readers, two 10 Gbps USB SSDs, and one Thunderbolt SSD.

The initial input contract is Canon EOS R5 uncompressed CR3 still photographs,
written to both camera cards. Other cameras, RAW formats, JPEGs, videos,
single-card operation, and fewer than three destinations require separate scope
decisions. Unexpected non-CR3 files are reported as outside the supported photo
set, not silently included in a success claim or removed.

All three SSDs are backups, with the same photo set and planned paths. None is
the editing copy. Neither a laptop nor the iPad's internal storage is a fourth
photo destination or a staging area for photographs. Bounded in-memory buffers
are allowed; local settings, permission bookmarks, recovery metadata, and
diagnostic reports are allowed.

The primary time metric is launch to three verified photo copies. The secondary
metric is launch to the end of corroboration, geotagging, and final reporting.
The existing dinner window of 60-90 minutes is a target to measure on the real
rig, not a promise derived from Thunderbolt or SSD ratings. Work after the photo
milestone must not delay that milestone merely to make total runtime look shorter.

## Operator interaction

The main screen exposes two source selectors, three destination selectors,
optional GPX selection, and **Go**. Labels identify the selected locations and
their current availability. A remembered selection never authorizes substituting
a different device when the original location is missing or inaccessible.

Starting a job performs preflight and then runs the supported phases. It does
not require a second routine confirmation after a valid setup. If GPX is omitted,
the setup explicitly shows **No GPS track** so the absence is intentional.
Preflight failures explain which location or input needs attention.

The app shows each destination's copying and verification state independently.
It distinguishes written bytes, verified bytes, and the current phase. Progress
updates keep the interface responsive; speed and ETA are displayed only when
measurement supports them. Status must be understandable without color alone.

The operator can cancel. App suspension, screen lock, OS termination, and loss of
a device are interruption cases, not evidence that the work completed. The
supported foreground/background behavior will be established by the lifecycle
probe before the app promises unattended operation.

## Requirements that every phase must preserve

| ID | Requirement |
| --- | --- |
| R1 | Never write, rename, delete, repair, or format anything on either source card. Source access and speed measurement are read-only. |
| R2 | Use exactly three independent external SSDs. Three directories or partitions on one physical drive do not meet the requirement. |
| R3 | Reject source/destination overlap, nested aliases, duplicate destinations, unavailable access, and insufficient capacity before copying. |
| R4 | Never silently overwrite an existing verified photograph, discard a disputed version, or replace a missing selected device with another one. |
| R5 | Use SHA-256 content fingerprints and the same deterministic relative photo paths on all three SSDs. Filename or size equality alone is not verification. |
| R6 | A partial write never receives the final photo filename. Only recognized application-owned temporary artifacts may be cleaned up automatically. |
| R7 | Record only verification that actually succeeded, and preserve the evidence needed to resume without trusting stale state or interrupted writes. |
| R8 | Keep photo verification, second-card corroboration, geotagging, and physical disconnect readiness as separate results. |
| R9 | Claim no storage, cache, durability, identity, background, or eject guarantee beyond the supported APIs and hardware evidence. |
| R10 | An interrupted or failed phase cannot produce a clean whole-run result. Preserve completed copies and explain what remains. |

If physical independence cannot be established reliably on iPadOS, the app cannot
silently treat three selected folders as three proved backups. Card #0012 must
define the supported identity method and any operator-assisted fallback for
review. The same rule applies to uncertainty about overlaps or free capacity.

## Phase order

| Phase | Required work | Result and gate |
| --- | --- | --- |
| 1. Source inventory | Enumerate supported files on both cards, pairing by card-relative path; compare paths and sizes. Select and record the ingest source using read-only measurement or the validated selection policy. | A deterministic photo inventory. Missing files, unequal sizes, read failures, or an empty supported set stop the run before destination writes. Equal listings do not yet prove equal contents. |
| 2. Destination and run preflight | Check three destinations, identity/overlap, permissions, free space, existing manifests, naming conflicts, and recovery metadata. Validate a selected GPX input sufficiently to identify malformed input. | A safe run plan and explicit GPS mode. Destination probe writes are confined to application-owned temporary files on destinations. Required capacity includes planned photos and temporary/metadata overhead with documented headroom. |
| 3. Copy and photo verification | Stream from the recorded ingest source, compute SHA-256, obtain capture metadata, write to all three SSDs through bounded queues, finalize safely, and read every required photo copy back. Hash-check prior files before counting them as existing matches. | Per-file/per-destination evidence. The photo milestone requires every expected photo on all three SSDs, successful read-back, required persistence evidence, and committed recovery/manifest records. |
| 4. Second-card corroboration | Read the corresponding secondary-card content and compare it to the canonical ingest fingerprints. Re-read both cards when a disagreement needs confirmation. | Matched, transient disagreement, confirmed disagreement, or incomplete/read failure. Any unresolved disagreement prevents a clean final result. |
| 5. GPX and XMP | When requested, correlate capture times with supported GPX data and produce Lightroom-compatible sidecars identically on all three SSDs using safe writes. | Separate tagged, unmatched, skipped, conflict, and failed counts. **No GPS track** is a valid explicitly selected mode. |
| 6. Finalize and disconnect guidance | Persist the run summary and per-SSD archive metadata, finish/close all app-owned operations, and perform only the supported release procedure. | A final report describing photo, card, GPS, and disconnect states independently. No automatic eject claim is inherited from Windows. |

Copying to one SSD must not require rereading the same source photograph once per
destination. Buffers and queues remain bounded. A slow SSD can limit throughput,
but cannot cause other destination progress or a three-copy verdict to be invented.
If a destination fails mid-run, preserve completed work; neither continuing useful
work nor stopping promptly permits the run to claim three successful backups.

## Photo layout and repeated offloads

Derive date folders from capture time resolved to UTC, never from the iPad's local
timezone, filesystem modification time, or the date the offload was started.
Preserve the upstream normal naming rule:

```text
YYYY/YYYY-MM-DD/HHmmZ_<camera-sequence>.CR3
```

For example, `_50A0001.CR3` captured at `2026-08-03T14:22:37Z` becomes
`2026/2026-08-03/1422Z_0001.CR3`. A genuine collision uses the upstream numbered
suffix form, such as `1422Z_0001_001.CR3`. Allocate names from a deterministic
inventory and compatible prior manifests, not worker completion order. All
destinations must agree on the path for the same photograph.

An unreadable or missing capture-time/UTC metadata value must not lose a readable
photo. Preserve its bytes on all three SSDs under an application-owned
`_unfiled/<run-id>/` location, retaining enough source-relative identity to avoid
basename collisions. Record why it could not be filed. Such a run can preserve
all photo bytes but still requires attention and cannot receive a clean result.
Unreadable photo bytes are a copy failure, not an unfiled success.

Multiple sessions in one UTC date folder are normal. Camera file counters may
reset between sessions. A rerun may reuse a prior copy only after its bytes are
validated against the expected fingerprint and understood metadata. Same name
and size do not authorize a skip. Conflicting archive contents or naming plans
stop or require a later explicit resolution procedure; automatic overwrite is
not the default.

Each SSD carries a self-describing versioned manifest that permits independent
photo verification without the iPad's journal or the other SSDs. Preserve the
upstream stable photo fields where compatible; schema compatibility and exact
serialization are card #0028's implementation decision. Destination-specific
metadata may differ, while the photo paths, sizes, and SHA-256 values agree.
Sidecar consistency is reported separately from the stable photo verification
record because sidecars can be deliberately regenerated from corrected tracks.

## Second-card disagreement

Pair card entries by their relative source paths. Path/size disagreement at
preflight stops before copying; equal-size content disagreement may only be
detected after the photo milestone.

A discrepancy must report the affected file, both fingerprints, and whether it
persisted on re-read. Re-reads must also be compared with the original ingest
fingerprint: agreement between two later reads does not validate already-landed
bytes if the source itself changed. A transient event with later agreement to
the canonical bytes remains visible in the report.

Accepted MobileFlow baseline: retain the sources and already-verified SSD copies,
stop the affected follow-on work, and report **Needs attention** on a confirmed
disagreement. Do not silently choose which version is correct, delete archive
files, or place disputed photo bytes in the iPad's storage. A future recovery
feature may preserve both versions on the external SSDs, but needs its own
explicit layout and verification contract.

This is an intentional adaptation accepted with card #0001. Upstream's default
corroboration
path quarantines both versions outside the normal archive and removes the
disputed photo from all normal destinations; its `--fail-on-source-mismatch`
option instead stops without deletion. MobileFlow starts from the latter safety
behavior because its storage topology has no laptop backup/quarantine location.

## GPS behavior

Use supported capture metadata and GPX timestamps resolved to UTC. Preserve
upstream time and distance gap limits unless a separate decision changes them.
Never extrapolate outside a track, interpolate across a recording-segment break,
invent missing altitude, or adjust the camera clock automatically to obtain a
match. Report unmatched frames and evidence of a possible clock offset.

Write XMP without modifying RAW files. Corresponding sidecars on the three SSDs
must have identical bytes for the same selected track and settings. Preserve
existing sidecars by default; incompatible or differing existing sidecars are a
named conflict, not permission to overwrite them. An intentional regeneration
operation can be scoped separately.

GPS failure does not erase the verified-photo milestone. It does prevent a clean
result for a run that requested GPS work, and produces **Needs attention** with
the counts and remaining action. A track that cannot locate some frames reports
those frames as unmatched rather than inventing positions.

## Verification and verdict meanings

Content equality, persistent storage, and permission to unplug answer different
questions. The report must state the proven assurance level rather than treating
an immediate hash read from a cache as proof of physical-media persistence.
Card #0007 must establish the write-flush and read-back strategy; card #0012
must establish safe disconnect guidance. Until those probes pass, a prototype
may report **Copied and hash-checked** but cannot advertise the production
verified-photo or safe-removal guarantee.

| Result | Exact meaning | Operator action |
| --- | --- | --- |
| Preflight stopped | No photo offload started; one or more required inputs or destinations failed checks. Temporary destination probes may have run. | Correct the named setup problem and run again. |
| Photo copies verified | All expected photo bytes are on all three SSDs at the validated assurance level, with durable verification records. Card comparison, GPS work, or finalization may still be active. | The initial photo-copy exposure window has closed; wait for final results and disconnect guidance. Keep both source cards unchanged. |
| Complete | All three photo copies passed, both source cards corroborated, requested metadata work finished without unresolved exceptions, and final records were committed. | Follow the separately reported disconnect procedure. This word alone does not mean a drive was ejected. |
| Needs attention | Photo bytes may be fully protected, but a confirmed card disagreement, unfiled frame, transient-read warning, requested GPS miss/conflict/failure, or finalization problem needs review. | Read the named issue, retain both source cards, and resolve or rerun as directed. |
| Interrupted / incomplete | Cancellation, suspension, termination, disconnect, or I/O failure left required work unverified or unfinished. | Restore access to the original locations and resume after validation. Do not treat written bytes as verified copies. |

Disconnect readiness is a separate per-device field. **Released / safe to
disconnect** is reserved for the tested supported procedure and its evidence.
Otherwise show **Disconnect readiness not established** or the concrete required
OS action, as established by card #0012. Closing file handles alone must not be
reported as an eject. No card-formatting permission is inferred from an early
milestone, an attention result, or a physical-release result.

An empty source set yields **No photos found**, not a successful zero-byte
backup. A source or destination that changes after preflight invalidates the
affected plan/results and requires revalidation. If later evidence contradicts
an earlier milestone, preserve the audit history and show the current attention
or incomplete result; the earlier badge cannot hide it.

## Recovery contract

Resume starts by resolving the same selected sources/destinations, checking
identity and inventory, and reading understood journal/manifest versions.
Permission renewal is explicit. A same-looking volume label or path is not
sufficient evidence that a replacement device is the original one.

Trust only complete files whose content and status can be validated. Resume
missing writes, recheck incomplete verification, and finish outstanding card/GPS
work without undoing already-proven work. Recognized temporary debris may be
removed or replaced; unrelated files, verified photos, and disputed variants
are preserved. Unknown schema versions or contradictory manifests are named
refusals rather than guessed migrations.

The app persists a bounded run report and recovery metadata. Completed external
archives remain usable if the app is removed or the local journal is lost.
Reports record run identity, selected locations, phase outcomes, photo counts,
per-SSD verification evidence, corroboration/GPS status, interruption reasons,
and the assurance/disconnect contract in force for that build.

## Acceptance examples for later implementation

| Scenario | Required outcome |
| --- | --- |
| Matching cards and three valid SSDs, no GPS selected | Same planned photo bytes on three SSDs, successful verification, corroborated cards, explicit No GPS track result, and independent disconnect guidance. |
| Only two SSDs, one card, duplicate destinations, or source overlap | Preflight refuses; no reduced-copy success or source writes. |
| One card contains an extra CR3 or a different-sized CR3 | Named inventory mismatch before photo destination writes. |
| Cards have equal paths/sizes but different bytes | Detect in corroboration; re-read against canonical bytes, retain existing copies, and require attention without automatic deletion. |
| A matching-looking existing file has corrupt bytes | Do not skip it by name or size; preserve the conflict and withhold a clean result until explicitly resolved. |
| A second session resets the camera sequence | Deterministic non-overwriting paths, identical across SSDs; a later rerun reuses only validated bytes. |
| A readable CR3 lacks usable UTC capture metadata | Preserve bytes on all three SSDs outside the date tree, record the filing problem, and require attention. |
| An SSD disconnects or runs out of space mid-write | No completed partial filename or three-copy milestone; retain other completed work and support validated recovery. |
| Cancellation, screen lock, or app termination during a phase | Save only proved results, report interruption, and resume without assuming background completion. |
| Immediate read-back matches but media persistence is unproved | Report only the tested content assurance, not physical-media verification or safe removal. |
| GPX does not cover a photo or crosses a recording break | Leave its GPS unset, report the gap, and preserve the verified photo result. |
| GPS sidecars differ across SSDs or a write fails | Name the metadata inconsistency; preserve RAWs and require attention rather than an all-clear. |
| All work finishes but device release cannot be established | Report completion facts and unresolved disconnect readiness separately; do not display an eject claim. |

## Source reference and remaining gates

The upstream reference for this contract is PhotoTravelWorkflow commit
`0ffbc57d7fb6514e2e800a027d7226701c19eabd`. Its
[phase orchestration](https://github.com/TerryOtt/PhotoTravelWorkflow/blob/0ffbc57d7fb6514e2e800a027d7226701c19eabd/crates/offload/src/main.rs),
[corroboration behavior](https://github.com/TerryOtt/PhotoTravelWorkflow/blob/0ffbc57d7fb6514e2e800a027d7226701c19eabd/crates/offload/src/phase4.rs),
[naming](https://github.com/TerryOtt/PhotoTravelWorkflow/blob/0ffbc57d7fb6514e2e800a027d7226701c19eabd/crates/offload/src/naming.rs),
[manifests](https://github.com/TerryOtt/PhotoTravelWorkflow/blob/0ffbc57d7fb6514e2e800a027d7226701c19eabd/crates/offload/src/manifest.rs),
and [GPX rules](https://github.com/TerryOtt/PhotoTravelWorkflow/blob/0ffbc57d7fb6514e2e800a027d7226701c19eabd/crates/geotag/src/track.rs)
were inspected. This pins the behavioral reference; it does not complete card
#0002's portability/dependency/license audit.

The current hardware/build decisions come from Terry's MobileFlow instructions,
not assumptions about the older Windows rig. Review of card #0001 settled the
initial behavior, especially the non-deleting disagreement policy and separate
photo/whole-run/disconnect verdicts. Cards #0006-#0012 establish platform access,
durability, identity, lifecycle, and performance evidence. Card #0013 chooses the
architecture from those results. Signing and the device-install route remain
card #0003; GitHub Actions is the tentative macOS build host.

The principal accepted MobileFlow adaptations are:

| Upstream behavior | MobileFlow contract |
| --- | --- |
| Four destinations, including the laptop | Exactly three external SSD backups; local photo staging and quarantine are excluded. |
| Default confirmed-card-mismatch quarantine and archive removal | Preserve already-landed copies and stop with Needs attention, following the non-deleting branch. |
| Corroboration and geotag counts do not downgrade the photo landing milestone | Keep that milestone, but show unresolved card or requested GPS issues in a separate final attention result. |
| Windows cache flags, hardware discovery, and device eject | Define requirements now; reserve equivalent iPadOS guarantees and removal wording for hardware validation. |
