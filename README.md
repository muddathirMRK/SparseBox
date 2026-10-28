# SparseBox

SparseBox is a native SwiftUI power-user toolbox for iPhone. The project targets iOS 17+ and adopts Apple's Liquid Glass visual language on current OS releases while retaining a usable fallback on older supported releases.

## Included

- SparseRestore and BookRestore capability/status screens
- Local Files-style AFC browser surface
- Installed-app and process inventory import surfaces
- Provisioning profile import/metadata inspection
- MobileGestalt tweak catalog and JSON plan export
- AirCard workspace:
  - Wallet artwork preview/preparation
  - card-size guidance
  - passcode `.passthm` import surface
  - passcode keypad preview
  - poster / individual-key creator modes
- Liquid Glass-inspired cards, hero panels and controls
- custom SparseBox icon
- GitHub Actions workflow for an unsigned IPA artifact

## AirCard / system-write boundary

AirCard's published implementation uses a device-specific AirTraffic/Airlift bridge and writes private system caches. Apple does not expose those cache paths through the public iOS SDK. SparseBox therefore keeps the UI, artwork preparation, theme import/preview and bridge boundary separate. A compatible bridge can be added to `DeviceBridge.swift` without redesigning the UI.

Published AirCard implementations currently describe Wallet skinning and `.passthm` passcode themes, including 1536×969 / 1024×646 Wallet artwork targets and TelephonyUI cache operations. Compatibility is build-specific and Apple can patch the underlying private workflow.

Do not describe a local preview/import as a successful system flash.

## Liquid Glass

On current iOS releases, SwiftUI's standard navigation, tab bars and controls automatically receive Apple's Liquid Glass treatment when built with the current SDK. SparseBox also uses material-backed custom cards so the interface remains visually coherent on supported releases.

## Build

Open `SparseBox.xcodeproj` in the latest Xcode available for the target iOS SDK. The shared scheme is `SparseBox`.

For GitHub Actions, push the repository and run **Build unsigned IPA**. The workflow creates `SparseBox-unsigned.ipa` from the built app. The artifact is not signed and must be signed with your Apple development/distribution identity before normal installation.

## Important compatibility note

SparseRestore, BookRestore, MobileGestalt modification, AFC access, process enumeration and AirCard system-cache flashing are not public iOS APIs. The project deliberately exposes these as capability-gated tools and import/export workflows rather than claiming unsupported operations are successful.

## Power Toolkit

SparseBox now includes a compact Toolkit hub rather than adding more top-level tabs. It contains:

- Performance Lab — CPU/memory/local I/O benchmark and thermal context
- Battery Lab — battery state and repeatable drain sessions
- Thermal Monitor — session thermal history
- Storage Doctor — accessible storage capacity and local-file inspection
- Network Doctor — path, interface, HTTPS reachability and latency
- MetricKit Health — Apple MetricKit registration for app diagnostics
- Device Snapshot — portable JSON before/after reports
- IPA Inspector — safe IPA import/inspection boundary
- Signing Inspector — provisioning metadata and expiry inspection
- Crash Analyzer — common `.ips` field extraction
- Restore Assistant — preflight checklist
- External Device Bridge — explicit boundary for privileged host operations
- Automation Export — compact diagnostic hand-off data

The Toolkit is deliberately grouped under one navigation surface so the feature count does not turn SparseBox into a wall of buttons.

## Connection Health

SparseBox includes a dedicated Connection Health screen for device-facing backends. It keeps pairing, local network/tunnel path, helper reachability, and device readiness separate instead of assuming every operation needs the same transport.

- Import a pairing artifact for local inspection.
- Test an optional HTTP(S) companion-helper health endpoint.
- Check whether the iPhone has a usable local network path.
- Show READY / REQUIRED / MISSING / EXPIRED / INCOMPATIBLE / NOT REQUIRED states.
- Run an operation-specific preflight before privileged actions are attempted.

The screen is intentionally fail-closed: a file being imported or an endpoint being reachable does not by itself prove that a particular restore, AFC, Wallet, `.passthm`, or MobileGestalt backend is authorized or compatible. The external bridge remains responsible for the final device/session validation.
