# MobileFlow

A native iPad app for end-of-day photo offload to three external SSDs, based on
[PhotoTravelWorkflow](https://github.com/TerryOtt/PhotoTravelWorkflow).

Status: planning. No app implementation exists yet.

## Target setup

- 11-inch iPad Pro M5 running the app.
- Element 5 Hub connecting two camera card readers and three external SSDs.
- Two 10 Gbps USB SSDs and one Thunderbolt SSD.
- The iPad and laptop are not photo backup destinations.

### Why the 11-inch iPad Pro M5

Terry confirmed the choice on 2026-11-26. Two constraints decide it:

- **Port speed.** The Pro's Thunderbolt / USB 4 port runs at up to 40 Gbps, so
  the Thunderbolt SSD can run at full speed. The alternative, an 11-inch iPad
  Air, has a 10 Gbps USB-C port; the Thunderbolt SSD would fall back to USB
  speed and share that 10 Gbps with everything else on the hub. As of
  2026-11-26 the M5, released in October 2025, is the newest iPad Pro.
- **It has to fit Terry's Peak Design Everyday Sling 6L.** The sling's tablet
  sleeve takes tablets up to 11 inches; its retailer-listed maximum is
  250 × 180 × 6 mm. A 13-inch iPad does not fit.

| | Length | Width | Thickness |
| --- | --- | --- | --- |
| Sling 6L sleeve, maximum tablet | 250 mm | 180 mm | 6 mm |
| 11-inch iPad Pro (M5) | 249.7 mm | 177.5 mm | 5.3 mm |
| 11-inch iPad Air (M2), Terry's current iPad | 247.6 mm | 178.5 mm | 6.1 mm |

A bare Pro is within the listed maximum on every dimension, but with almost no
room to spare in length. A case pushes it past the listed size. The evidence
that it still fits is Terry's own: his current M2 Air, in its case, fits the
sling. The Pro is thinner and narrower than the Air and about 2 mm longer, so
length is the only dimension that grows. He chose Apple's Smart Folio, a
low-profile cover and stand, as the Pro's case. Whether the Pro in its Folio
fits is still to be confirmed when the hardware arrives. The iPad dimensions
were recalled from Apple's published figures on 2026-11-26 and have not yet been
checked against Apple's specification pages.

## Intended workflow

Select two source folders and three destination folders, optionally select a GPX
track, then tap **Go**.

The app will copy photographs to all three SSDs, read back and verify each copy,
compare the second camera card, and produce geotagged XMP sidecars. Progress and
errors will be visible for each destination. Success requires all three copies
to pass verification; corroboration and geotagging results will be reported
explicitly.

The accepted [workflow and completion contract](docs/WORKFLOW.md) defines phase order,
source protection, date organization, deterministic naming, three-copy verification,
corroboration, GPS behavior, recovery, and the exact meaning of each result. Source
cards must never be modified. Platform guarantees still require hardware evidence.

## Initial technical direction

Use SwiftUI for the native interface and evaluate reuse of PhotoTravelWorkflow's
Rust engine. Replace Windows-specific storage access with an iPadOS layer that
uses user-selected folders.

The [upstream portability audit](docs/PORTABILITY-AUDIT.md) maps reusable modules,
Windows replacements, locked dependencies, fixture gaps, and license obligations.
It records passing Windows tests; Apple compilation and hardware guarantees are
still to be established.

The first milestone is a hardware proof of concept: one source folder to one
external SSD. Validate folder access, durable writes, read-back verification,
throughput, interruption, and recovery before expanding to the full workflow.

The completion guarantee remains a design question until the iPadOS storage
layer is validated. A hash read served from cache must not be represented as
proof that bytes were read back from physical media. Background operation and
drive-release behavior also require validation on the actual setup.

## Development and project board

Portable engine work can be developed and tested on Windows. Building and signing
the native iPad app requires an Apple toolchain on a supported macOS host. The
tentative build host is a standard GitHub Actions macOS runner. Local Mac access
or EC2 Mac hosting remains a fallback if development needs it. Runner/Xcode
compatibility, signing, and device installation are early project milestones.

Work is tracked on the machine-local `MobileFlow` board of Terry's shared
localswim v2 service (base URL in its service receipt, `http://127.0.0.1:8811` as
of 2026-11-26). The board's data is outside this public repository. Agents reach
it through `scripts/localswim.ps1`; [AGENTS.md](AGENTS.md) gives the board ID, the
lane rules, and how Claude and Codex sessions hear board changes. Card numbers
changed when the board moved from localswim v1;
[docs/CARD-NUMBERS.md](docs/CARD-NUMBERS.md) maps them.

Agent working instructions live in [AGENTS.md](AGENTS.md); `CLAUDE.md` is a
symbolic link to it.

## License

MobileFlow is released under the [MIT License](LICENSE). Third-party and
upstream notices for shipped builds are tracked by the portability audit.
