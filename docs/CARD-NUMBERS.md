# Card numbers before and after the localswim v2 import

The MobileFlow board was imported from localswim v1 into localswim v2 on
2026-11-12, and the import renumbered most cards. This repository uses the v2
numbers. Board comments and commits from before the import use the v1 numbers.

The map was built on 2026-11-26 by matching each card in the v1 board plan
(`.research/mobileflow-plan.json`, in creation order) to the v2 card whose
description carries the same scope text. Two cards whose scope was rewritten
after creation (v1 #0003 and #0043) were matched by their current titles. Board
comments confirm the method: the v2 #0004 card carries the comment
"Starting #0002", written before the import.

| v1 | v2 | Title on the v2 board |
| --- | --- | --- |
| #0001 | #0001 | Define the three-SSD workflow and completion contract |
| #0002 | #0004 (changed) | Audit PhotoTravelWorkflow code, dependencies, and license |
| #0003 | #0002 (changed) | Arrange GitHub Actions builds, signing, and iPad deployment |
| #0004 | #0003 (changed) | Prepare the iPad, Element 5 Hub, readers, and three test SSDs |
| #0005 | #0005 | Build and install a minimal native storage probe |
| #0006 | #0006 | Validate external folder permissions and reconnect behavior |
| #0007 | #0007 | Establish durable-write and physical read-back guarantees |
| #0008 | #0008 | Probe unplug, cancellation, suspension, and relaunch during copy |
| #0009 | #0009 | Measure one-source/one-SSD copy and verification throughput |
| #0010 | #0011 (changed) | Validate both readers and all three SSDs through the hub |
| #0011 | #0012 (changed) | Determine supported background and screen-lock behavior |
| #0012 | #0010 (changed) | Determine volume identity and safe disconnect capabilities |
| #0013 | #0013 | Choose the native architecture and Rust reuse boundary |
| #0014 | #0014 | Set up the app project, reproducible builds, and license notices |
| #0015 | #0015 | Create representative privacy-safe fixtures and fault hooks |
| #0016 | #0016 | Extract the reusable engine and integrate it with the native app |
| #0017 | #0017 | Implement security-scoped source and destination folder access |
| #0018 | #0018 | Implement the run state machine and durable recovery journal |
| #0019 | #0020 (changed) | Enumerate and match the two camera-card sources |
| #0020 | #0021 (changed) | Implement UTC date layout and collision-safe deterministic filenames |
| #0021 | #0022 (changed) | Implement three-destination safety and capacity checks |
| #0022 | #0023 (changed) | Build the deterministic copy plan and existing-file checks |
| #0023 | #0019 (changed) | Implement bounded streaming SHA-256 and source fingerprints |
| #0024 | #0026 (changed) | Implement interrupted-safe external writes and finalization |
| #0025 | #0027 (changed) | Implement destination read-back verification and truthful verdicts |
| #0026 | #0028 (changed) | Build the three-SSD copy/verify scheduler |
| #0027 | #0030 (changed) | Compare the secondary card by content after landing copies |
| #0028 | #0029 (changed) | Implement versioned manifests, identity, and cross-copy consistency |
| #0029 | #0024 (changed) | Port GPX matching and Lightroom-compatible XMP generation |
| #0030 | #0031 (changed) | Write and verify identical sidecars on all three SSDs |
| #0031 | #0025 (changed) | Build the iPad source, destination, and GPX selection screen |
| #0032 | #0032 | Build per-destination progress, phase status, and cancellation UI |
| #0033 | #0033 | Build completion verdicts and portable run reports |
| #0034 | #0034 | Implement cancel, disconnect, reconnect, and interrupted-run recovery |
| #0035 | #0036 (changed) | Integrate supported continued processing and expiration handling |
| #0036 | #0035 (changed) | Add useful diagnostics and export without private photo leakage |
| #0037 | #0037 | Complete behavioral engine and archive regression coverage |
| #0038 | #0038 | Validate iPad usability, VoiceOver, Dynamic Type, and UI flows |
| #0039 | #0039 | Run the complete hardware fault and recovery matrix |
| #0040 | #0041 (changed) | Benchmark the complete three-SSD workflow on a full shooting day |
| #0041 | #0042 (changed) | Tune concurrency and I/O only where measured runs require it |
| #0042 | #0043 (changed) | Validate archives after disconnect/reconnect and in Lightroom |
| #0043 | #0040 (changed) | Set up appropriate automated checks and Apple build validation |
| #0044 | #0044 | Write the nightly offload, recovery, and pre-trip operating guide |
| #0045 | #0045 | Prepare a signed installable build and update path |
| #0046 | #0046 | Rehearse the entire hotel-room workflow and obtain Terry's acceptance |
