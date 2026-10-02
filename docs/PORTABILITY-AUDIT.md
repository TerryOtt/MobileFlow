# PhotoTravelWorkflow portability audit

Status: ready for review, localswim card #0002, 2026-10-02. This is an audit of
existing code, not an Apple implementation or the architecture decision assigned
to card #0013. [WORKFLOW.md](WORKFLOW.md) supplies the accepted MobileFlow behavior.

## Finding and evidence boundary

Reuse the photo/metadata algorithms and archive formats where they meet the
contract. Do not compile the existing `offload` crate unchanged into an iPad app:
its library exports Windows-only modules unconditionally, and portable-looking
modules call that storage layer directly. Replacing the command-line front end
alone would leave Windows I/O, laptop-dependent logging, and different completion
semantics in place.

The audit pins upstream commit
`0ffbc57d7fb6514e2e800a027d7226701c19eabd`. `Cargo.lock` has SHA-256
`9bf595742820453c558aa0f685fe97b5d8a1d4b46212ba8ffa60faf8c867a791`.
All source references below are relative to that commit. Its
[source tree](https://github.com/TerryOtt/PhotoTravelWorkflow/tree/0ffbc57d7fb6514e2e800a027d7226701c19eabd)
and [locked dependencies](audits/upstream-dependencies.json) make the observations
reproducible. No upstream source or dependency versions were changed.

On this host, Rust 1.98.1 targets `x86_64-pc-windows-msvc`. Only that target is
installed. The following existing checks passed with locked, offline dependencies:

| Command | Result | What it establishes |
| --- | --- | --- |
| `cargo test --locked --offline -p geotag --lib` | 69 passed | Existing format, UTC-offset, GPX, and XMP unit behavior on Windows. |
| `cargo test --locked --offline -p offload --lib --test schema1 --test phase3` | 103 library + 4 schema + 4 pipeline tests passed | Existing Windows I/O and archive behavior, including synthetic four-destination copying and the frozen schema-1 reader. |
| `cargo metadata --locked --offline --format-version 1` | 136 packages: 2 workspace and 134 registry packages | Exact resolved upstream workspace inventory, including platform-specific, optional, and development packages. |

These 180 passing tests do not establish an Apple build, external-drive durability,
device identity, background execution, or real CR3 parsing on the iPad. The audit
findings below are source inspection unless a test result is expressly named.

## Module and reuse map

Upstream locations are under `crates/`. **Reuse** means retain tested logic;
**split** means separate that logic from direct filesystem, progress, or platform
calls; **replace** means implement a native responsibility without transplanting
Windows behavior.

| Module | Treatment | Boundary and required work |
| --- | --- | --- |
| `geotag/src/lib.rs` | Reuse | Already exposes format, raw, track, and XMP modules without the `offload` Windows layer. |
| `geotag/src/format.rs` | Reuse | Explicit format/tag/read-strategy table. Limit the initial product to CR3 even though upstream also recognizes NEF. |
| `geotag/src/raw.rs` | Split | Reuse offset resolution, capture parsing, and body metadata. CR3 has a seeking path and an in-memory entry point; supply authorized handles/readers or scoped paths, with native access alive for the operation. |
| `geotag/src/track.rs` | Split | Reuse sorting, deduplication, segment/gap rules, overlap detection, antimeridian handling, and lookup. GPX loading uses paths and Rayon; authorize access and measure concurrency on the iPad. |
| `geotag/src/xmp.rs` | Split | Reuse deterministic `render` and coordinate/altitude encoding. Replace `write_atomic` with the validated writer: its temp-and-persist operation is not proof of media durability and can replace an existing sidecar. |
| `offload/src/hash.rs` | Reuse | SHA-256, incremental `Hasher`, and lowercase hex are portable logic. Keep `hash-experiments` off in production; measure ARM64 hashing rather than reusing x86 SHA-NI timings. |
| `offload/src/naming.rs` | Reuse with adaptation | UTC path/time prefix and collision suffix rendering are portable. `_unfiled` currently receives only a basename; preserve source-relative identity for equal basenames in different card folders. |
| `offload/src/manifest.rs` | Split | Keep schema-1 parsing, stable photo fields, checksum canonicalization, merge semantics, and tombstone readability. `Manifest::write` directly calls `winio`; use a platform writer. Model disagreements without deleting new MobileFlow photos. |
| `offload/src/marker.rs` | Split | The schema/read/label model is reusable, with optional disk serial already supported. Marker writes call `winio`. A marker or human label is not proof of physical-device identity. |
| `offload/src/verify.rs` | Split | Preserve manifest-based independent archive verification and typed schema/damage outcomes. Replace unbuffered hashing and error-filtering directory walks. Standalone archive verification is distinct from whole-run success. |
| `offload/src/runlog.rs` | Split | Reuse verified `(file, destination)` records and torn-final-line handling. Add versioned session/lifecycle recovery, selected-volume identity, bounded reading, and the proven persistence approach. |
| `offload/src/pipeline.rs` | Split substantially | Preserve single-source-read fan-out, hash-before-verdict, per-destination passes, and backpressure. Replace direct `winio`, whole-photo buffers, per-destination naming decisions, terminal progress, and failure/cancellation orchestration. |
| `offload/src/phase4.rs` | Split substantially | Keep relative-path pairing and mismatch confirmation. Remove quarantine/deletion from the normal flow; check re-reads against the original ingest fingerprint and emit typed attention results. |
| `offload/src/phase5.rs` | Split | Reuse capture-to-GPX/XMP work and diagnostic counts. Its destination loop is already variable length, but existing sidecars are skipped without verifying cross-copy equality; add consistency checks and safe writes. |
| `offload/src/config.rs` | Replace native configuration | Labels and camera expectations can inform native settings. `%APPDATA%`, path-versus-disk-serial discovery, and a non-removable destination must not become iPad configuration requirements. |
| `offload/src/cards.rs` | Replace discovery, reuse concepts | DCIM ancestry, measured source preference, and mirrored-card roles can inform behavior. Replace Windows volumes, serial identity, and unbuffered sampling with the selected-folder model. |
| `offload/src/destinations.rs` | Replace identity/access | Preserve distinct-physical-backup and missing-device checks. Windows GUIDs, disk extents/serials, and `ejectable` roles do not carry over as implementations. |
| `offload/src/preflight.rs` | Split checks, replace environment | Preserve inventory agreement and early refusal. Replace auto-discovery/capacity access; require exactly two sources and three external destinations, strict enumeration, and intentional GPS omission. |
| `offload/src/storage.rs` | Replace | Uses Win32 volume enumeration, storage IOCTLs, Windows handles, and UTF-16 OS extensions. The iPad provider must establish its own supported identity/capacity capabilities. |
| `offload/src/winio.rs` | Replace | Uses `OpenOptionsExt`, Windows cache flags, aligned allocation, and threaded verify reads. Replace photo, manifest, and marker writes as well as read-back hashing and speed probes. |
| `offload/src/eject.rs` | Replace behavior after probe | Win32 volume locks/dismount, SetupAPI, PnP eject, retries, and power-down verdicts are device/platform specific. Native close/release operations cannot automatically earn the same verdict. |
| `offload/src/progress.rs` | Replace UI adapter | Terminal bars, console detection, indentation, and display state should become typed events consumed by SwiftUI. Do not run terminal rendering behind the app. |
| `offload/src/human.rs` | Optional reuse | Numeric formatting is portable; use native localization/accessibility where appropriate. It does not belong in storage decisions. |
| `offload/src/main.rs` | Replace orchestration/front end | Replace Clap, printing, laptop log root, flags, phase/error exits, and eject-dependent verdicts with the accepted run state machine and native UI. |
| `offload/src/lib.rs` | Replace export boundary | It unconditionally exports `storage`, `eject`, and `winio`. Extract a platform-neutral crate/API or explicitly gate adapters; moving one module without fixing this graph is insufficient. |

The recommended direction for card #0013 is a portable domain core and a native
storage/lifecycle adapter, with SwiftUI consuming typed progress and outcomes.
This is a candidate boundary, not a final FFI choice. Rust `PathBuf`, `Result`,
threads, and owned buffers are not a stable Swift interface by themselves. The
architecture card must define ownership, error transport, cancellation, callback
lifetime, and authorized URL/handle lifetime before exporting them.

## Four-copy and laptop assumptions

The production pipeline, phase-4 comparison, and phase-5 destination loop take
slices/vectors. There is no production four-slot array that needs a global
`4`-to-`3` replacement. `pipeline::DEPTH = 4` is queue depth, not destination
count; `progress::PASS = 4` is indentation. Neither should become three merely
because the backup count changed.

| Source location / behavior | Required MobileFlow change |
| --- | --- |
| `main.rs:offload`, `laptop_root` | The run refuses when no non-ejectable destination exists, and puts `_runs/<run-id>/run.jsonl` on the laptop. Store bounded recovery metadata/reporting in app storage, independently of the three photo destinations. Each SSD still needs its own archive manifest. |
| `main.rs:corroboration_phase`, `phase4.rs` | Quarantine is under the laptop `_runs` root. Remove the default automatic quarantine/removal path and use the accepted non-deleting disagreement result. Never relocate disputed photo bytes onto the iPad. |
| `main.rs:Offload`, `config.rs`, `preflight.rs` | Upstream permits single-source and `--without` reduced-destination runs. MobileFlow's initial contract requires two source folders and three external SSDs; these escapes must not weaken its success condition. |
| `pipeline.rs:run`, `Outcome::landed` | The low-level pipeline only rejects zero destinations, and the all-verified predicate is count-agnostic. Enforce exactly three selected/independent external destinations and a nonempty source inventory in the run contract before publishing a milestone. |
| `phase5.rs:run` | Already loops over arbitrary destinations. Add three-copy sidecar consistency and separate metadata completion; do not assume an existing file skipped on each drive is identical. |
| `main.rs:estimate` and `RUN_BUDGET` | Estimates and the eject deadline encode measurements/scheduling from the Windows rig. Replace them with measured iPad/hub phase times and the supported lifecycle contract. |
| `main.rs` verdict/release helpers | Upstream final language combines landing and Windows power-down state. Use separate photo, card/GPS, and disconnect results as accepted in WORKFLOW.md. |
| `tests/phase3.rs` | Four labels include `laptop`; assertions expect four destinations. Adapt to three while keeping per-pair verification, idempotence, and `_unfiled` assertions. These tests do not establish three physical devices. |
| Package description, CLI help, doc comments, examples and operating docs | Rewrite descriptions for three SSDs and folder selection. Retain historical upstream references as historical; avoid importing Windows setup/eject rituals into the iPad instructions. |

## Behavior gaps to address during the port

These are source-level differences between this snapshot and the accepted
contract. Passing existing tests does not cover all of these cases. They are
requirements for MobileFlow; this card does not modify upstream.

| Finding | Evidence and consequence | Owning MobileFlow cards |
| --- | --- | --- |
| Naming is resolved independently per destination | `pipeline.rs:place` checks each drive's existing contents and chooses its suffix there. Divergent existing archives can therefore give the same source photo different destination paths; `Outcome::landed` checks hashes/counts, not path agreement. Choose one shared plan before writing. | #0020, #0022, #0026 |
| Collision search is not a safe final-name reservation | `place` applies a suffix to the current filename on each retry and proceeds to `write_through` after the bounded loop without a final exhaustion refusal. The writer uses replacement persistence. Replace this with a shared reservation/conflict policy that cannot overwrite verified bytes; test exhaustion and races. | #0022, #0024, #0037 |
| Inventory and verifier walks suppress failures | `pipeline::cr3_files` and `verify::manifest_folders` filter failed walk entries; preflight byte totals filter failed metadata reads. A matching visible subset is not evidence of a complete card or archive. Propagate errors and name the affected path. | #0019, #0021, #0025 |
| Backpressure bounds photo count, not memory bytes | `feed` calls `fs::read` for an entire photo and shares it through depth-four queues. It does not implement fixed-size streaming buffers. Define a byte budget and seekable CR3 metadata strategy, then benchmark; do not simply retain Windows memory estimates. | #0016, #0023, #0026 |
| Resume primitives are not a complete session-resume engine | `runlog::read` exists, but production orchestration opens a new timestamped log and does not call that reader. Reruns reread the source and hash existing destination files. `_unfiled` paths include the new run ID. Implement explicit journal/inventory/identity reconciliation so recovery does not duplicate unfiled photos or trust a replaced volume. | #0018, #0022, #0034 |
| Corroboration confirmation can ignore original ingest bytes | `phase4::run` calls a mismatch transient when the two later card reads agree, without checking that their agreed hash equals `frame.sha256`. Both cards changing to the same later bytes must not corroborate an older landed copy. Preserve and compare the canonical hash. | #0027, #0037 |
| Metadata errors lose their reason in the pipeline | `capture_instant` maps every non-resolved capture result to `None`. Preserve typed missing-offset, parse-failure, and conflict reasons in reports rather than only recording an unfiled basename. | #0019, #0020, #0036 |
| Sidecar skipping is not cross-copy verification | `phase5` skips any existing sidecar; `xmp::write_atomic` itself replaces existing files and has no explicit flush/read-back step. Render bytes are reusable, but creation, consistency, persistence, and conflict handling need the native writer and a separate sidecar outcome. | #0029, #0030 |
| Atomic replacement is not the whole durability contract | Manifests and markers call `winio::write_through`; the run log calls `sync_data`; XMP uses `tempfile::persist`. Retain safe temporary/final ordering, but prove external-media flush, rename, and read-back semantics on the actual filesystems. | #0007, #0024, #0025, #0028 |
| Windows cache claims have limits even upstream | `winio::unbuffered_sha256` bypasses the OS page cache; its comments explicitly acknowledge SSD DRAM on small datasets. Preserve this distinction and do not strengthen the claim when adapting to iPadOS. | #0007, #0012, #0033 |

## Locked dependency and platform risks

Versions below come from the pinned lockfile, not a proposal to update libraries.
The [sanitized inventory](audits/upstream-dependencies.json) records every package's
declared version, Rust requirement, and license metadata without local paths.
The largest declared Rust requirement in that inventory is 1.88.0 (`time` and its
support crates). Edition 2024 is also used. This metadata bound is not proof of a
minimum-working compiler; the verified host used 1.98.1. Pin a tested compiler in
the Apple build workflow rather than assuming the runner's default is suitable.

| Dependency group | Locked versions | Port decision / risk |
| --- | --- | --- |
| CR3 parser | `nom-exif 3.6.2` | Core reuse candidate. Verify R5 fixtures on Apple and preserve seekable reading; passing metadata/offset unit tests is not a real-file parser test. Its license uses `license-file`, not SPDX metadata. |
| GPX and time | `gpx 0.10.0`, `chrono 0.4.45`, `time 0.3.55` | Retain semantic tests. Handle source access outside app storage; keep UTC conversion consistent. Confirm enabled target/timezone features and compiler requirements in the actual Apple dependency graph. |
| Hash and errors | `sha2 0.11.0`, `anyhow 1.0.104`, `thiserror 2.0.19` | Retain SHA-256/typed failure behavior; benchmark ARM64 and export stable native error codes. `thiserror 1.0.69` also appears transitively. |
| Serialization | `serde 1.0.229`, `serde_json 1.0.151` | Preserve manifest checksum canonicalization and frozen fixtures. Do not change key ordering/serialization features or stable meanings silently. |
| Concurrency | `rayon 1.12.0` plus `std::thread`/channels | Algorithms are candidates, not evidence of allowed background runtime or acceptable iPad power/memory use. Bound worker count and cancellation; avoid invoking UI callbacks under storage locks. |
| Filesystem helpers | `tempfile 3.27.0`, `walkdir 2.5.0` | Useful helpers, but direct path access must stay within a live security scope. Tempfile replacement semantics do not enforce source protection, no-overwrite, or physical durability by themselves. |
| Windows storage bindings | `windows 0.62.2` and Windows support packages | Remove or target-gate from the portable/native Apple graph. Their presence in this workspace inventory does not make them Apple dependencies. |
| Terminal/CLI | `clap 4.6.5`, `console 0.16.4`, `indicatif 0.18.6` | Exclude from the app engine where possible. Keep any developer CLI as a separate adapter. |
| Experiments and test hashing | `blake3 1.8.5`, `sha3 0.12.0`, `xxhash-rust 0.8.18` | Dev/optional scope in upstream; do not ship algorithm switching. BLAKE3's build graph includes `cc`, so the workspace is not automatically native-toolchain-free even though the default product hashes with SHA-256. |

Rust's ARM64 device and simulator targets are `aarch64-apple-ios` and
`aarch64-apple-ios-sim`. Both require the corresponding Xcode SDK; running the
tests requires a device or simulator. Standard-target availability does not
prove this dependency graph links on Apple. Card #0003 should compile the chosen
portable subset on GitHub Actions with matching Rust/Xcode deployment settings;
card #0016 handles packaging and FFI. [Rust Apple-target documentation](https://doc.rust-lang.org/rustc/platform-support/apple-ios.html)

Do not introduce a substitute parser, hash algorithm, FFI framework, or new
runtime dependency solely to make the audit look portable. Make those choices
from the storage probes and architecture decision, then validate device and
simulator builds independently.

## Fixtures and test reuse plan

| Existing evidence | Reuse / adaptation | Missing evidence |
| --- | --- | --- |
| 69 `geotag` unit tests | Carry over exact XMP packets, offset precedence, track boundaries/gaps/overlaps, and antimeridian cases. Separate render/lookup tests from authorized file I/O. | Real CR3 parsing and GPX files on Apple, including a seekable reader/handle route. |
| Naming, hashing, manifest, marker, and run-log library tests | Extract with the corresponding core modules. Preserve known hashes, suffix rules, typed errors, manifest merging, and torn-final-line behavior. | Shared three-destination naming, partial archive drift, cancellation, byte-budget bounds, and identity-based resume. |
| `tests/fixtures/manifest-schema-1.json` and 4 `schema1` tests | Keep the frozen file and its checksum; do not regenerate it from new structs. Continue understanding legacy deleted/tombstone entries while new MobileFlow mismatch handling retains copies. | New schema/assurance fields and cross-version comparisons as scoped by #0028. |
| 4 synthetic `tests/phase3.rs` integration tests | Adapt four destinations to three; retain distinct frame bytes, odd file sizes, per-pair logging, repeated-run behavior, and preserved unfiled files. | They contain no valid EXIF, so all photos take `_unfiled`; they do not test the real date-folder pipeline or physical drive identity. |
| `geotag/fixture-manifests/*.sha256` | Preserve expected fixture identities and hashes where approved. The existing format-coverage test checks manifest filenames/extensions. | Actual CR3/NEF/GPX bytes are not committed in this snapshot. A passing coverage test does not rehash or parse those real files. |
| `fixtures/dev-slice-50.json` | Reuse the selection method for a representative development slice after obtaining the privately held source corpus. Keep personal photo/GPS data out of the public repository. | The JSON names 50 frames; it does not contain them. Full-day benchmarks need an approved actual dataset. |
| Windows storage/eject tests and examples | Retain upstream historical evidence; port test intent into provider mocks and a disposable native hardware matrix. | Cache/flush behavior, hub power, independent-device identity, reconnect, background expiration, and safe release on the exact iPad rig. |

Card #0015 should create privacy-safe local fixtures for the supported CR3 path,
not broaden the product to every format in the inherited parser table. Use an
independently expected filename/hash/XMP result for a complete date-folder run.
Add three-drive disagreement, source mutation, inaccessible subtree, collision
exhaustion, unfiled basename collision, sidecar conflict, and interrupted-journal
cases. Device probes and independent remount/read-back tests remain separate
from fast CI tests.

## License and notice obligations

Upstream `LICENSE` is MIT, copyright 2026 Terry Ott. When incorporating its code
or substantial portions, preserve the copyright and permission text in source
and distributed notice material. Record the pinned origin and modified modules;
do not describe imported code as newly authored. The source license is the
authority: [upstream MIT license](https://github.com/TerryOtt/PhotoTravelWorkflow/blob/0ffbc57d7fb6514e2e800a027d7226701c19eabd/LICENSE).

`nom-exif 3.6.2` declares `license-file = LICENSE` with an empty SPDX license
field. The actual cached crate license was inspected: MIT, copyright 2024
Min Deng, SHA-256
`9cfbbedc535b1a4b73b2f7f51fd683ac6cae914f6d4bc7f271b9b230dd4e2808`.
Notice generation must read that file rather than treat missing SPDX metadata
as missing permission or silently omit the parser's notice.

Most packages offer MIT/Apache alternatives, but the workspace inventory also
contains Apache-only, BSD-2-Clause, BSL-1.0, and Unicode-3.0 metadata, plus optional
multi-license choices. That inventory includes build/dev/other-platform packages;
it is not the notice list for an iPad binary. Resolve the actual Apple release
graph/features, record the license option used, and collect its shipped license
and applicable notice files. Under Apache-2.0, preserve its required license,
attributions, change notices, and applicable upstream NOTICE content.
[Apache-2.0 terms](https://www.apache.org/licenses/LICENSE-2.0.html)

Card #0014 should establish the project's license and imported-code notice layout.
Cards #0043/#0045 should generate/review the target-specific notice inventory and
package a readable third-party notice with the signed application. Real fixture
data needs its own provenance/permission; the Rust code's MIT license does not
authorize publishing a private photography corpus. No final app license or
complete release-notice bundle is selected by this audit.

## Handoff to subsequent cards

| Card | Required input from this audit |
| --- | --- |
| #0003: build/signing access | Prove the portable subset on device and simulator targets with a tested Rust/Xcode pair; continue using GitHub Actions tentatively. |
| #0007: media verification | Cover photo, manifest, marker, run journal, and sidecar write/rename/flush semantics; distinguish OS-cache bypass from SSD-controller guarantees. |
| #0012: identity/release | Replace volume serial/GUID/extents/eject assumptions with supported native identity and release evidence. |
| #0013: architecture | Decide extraction/FFI and native provider boundaries; account for typed progress, byte budgets, cancellation, and scoped-access lifetime. |
| #0015: fixture foundation | Carry over the frozen manifest and unit semantics; obtain real private CR3/GPX bytes and add complete date-folder and recovery cases. |
| #0018/#0022/#0024/#0027/#0030 | Implement explicit recovery, shared naming, protected finalization, canonical-hash corroboration, and three-copy sidecar consistency rather than transplanting their current path calls. |

The audit meets card #0002's module/reuse map, dependency/platform risk, fixture
plan, license-obligation, and three-destination-change criteria. Apple compilation
and physical-media guarantees remain unverified and belong to the named cards.
The upstream checkout stays unchanged, and MobileFlow has not imported engine
code as part of this audit.
