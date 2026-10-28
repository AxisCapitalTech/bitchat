#!/usr/bin/env python3
"""MeshPriv Fase 2: static guard for online transport startup regressions.

This is a source-level safeguard, NOT a network isolation proof or a build test.
The online modules still exist and must be removed in later isolated commits.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

SOURCES = {
    "runtime": "bitchat/App/AppRuntime.swift",
    "bootstrap": "bitchat/ViewModels/ChatViewModelBootstrapper.swift",
    "viewmodel": "bitchat/ViewModels/ChatViewModel.swift",
}
REQUIRED = {
    "runtime": [
        "buildMyQRString(nickname: nickname, npub: nil)",
        "chatViewModel.meshService.startServices()",
    ],
    "bootstrap": [
        "transports: [meshService]",
        "self.deduplicationService = MessageDeduplicationService()",
        "viewModel.meshService.startServices()",
    ],
    "viewmodel": [
        "static var live: PanicNetworkLifecycle { .noop }",
    ],
}
FORBIDDEN = {
    "runtime": [
        "NetworkActivationService.shared.start()",
        "GeoRelayDirectory.shared.prefetchIfNeeded()",
        "GeohashPresenceService.shared.start()",
        "NostrRelayManager.shared",
        "TorManager.shared",
    ],
    "bootstrap": [
        "let nostrTransport = NostrTransport(",
        "nostrEventStore: NostrProcessedEventStore()",
        "viewModel.nostrRelayManager = NostrRelayManager.shared",
    ],
    "viewmodel": [
        "nostrRelayManager = NostrRelayManager.shared",
        "NostrRelayManager.shared.resetForPanicWipe()",
    ],
}

def main() -> int:
    errors = []
    for name, relative in SOURCES.items():
        source_file = ROOT / relative
        if not source_file.is_file():
            errors.append(f"missing: {relative}")
            continue
        source = source_file.read_text(encoding="utf-8")
        for marker in REQUIRED[name]:
            if marker not in source:
                errors.append(f"{relative}: missing expected: {marker}")
        for marker in FORBIDDEN[name]:
            if marker in source:
                errors.append(f"{relative}: forbidden online activation: {marker}")
        if name == "bootstrap":
            begin = "    func configure() {"
            if begin not in source:
                errors.append(f"{relative}: configure() not found")
            else:
                active_config = source.split(begin, 1)[1].split("\n    }", 1)[0]
                for call in (
                    "configureGeoChannels()",
                    "configureGateway()",
                    "configureBridge()",
                    "configureBridgeCourier()",
                    "bindTeleportState()",
                ):
                    if call in active_config:
                        errors.append(f"{relative}: online bootstrap call: {call}")

    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print("PASS: MeshPriv offline-only bootstrap source guard")
    print("NOTE: this does not verify builds, binaries, background services or network traffic.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
