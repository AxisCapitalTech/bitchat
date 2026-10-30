#!/usr/bin/env python3
"""Static fail-closed guard for reviewed MeshPriv privacy fixes.

This does not prove a binary has zero IP egress; use device network capture
and review every remaining online dependency before making that claim.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def read(relative):
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"Missing file: {relative}")
        return ""
    return path.read_text(encoding="utf-8")

def require(label, text, snippet):
    if snippet not in text:
        errors.append(f"{label}: missing {snippet!r}")

def forbid(label, text, snippet):
    if snippet in text:
        errors.append(f"{label}: forbidden {snippet!r}")

geo = read("bitchat/Nostr/GeoRelayDirectory.swift")
live = geo.split("private extension GeoRelayDirectoryDependencies", 1)
if len(live) < 2:
    errors.append("GeoRelayDirectory: live dependency factory missing")
else:
    live_factory = live[1].split("@MainActor\nfinal class GeoRelayDirectory", 1)[0]
    require("A1/live", live_factory, "autoStart: false")
    forbid("A1/live", live_factory, "autoStart: true")
require("A1/runtime init", geo, "self.networkDisabledInProduction = true")
require("A1/test init", geo, "self.networkDisabledInProduction = false")
for method, next_method in [
    ("func prefetchIfNeeded(force: Bool = false)", "private func fetchRemote()"),
    ("private func fetchRemote()", "nonisolated private static func fetchRemoteOutcome"),
]:
    section = geo.split(method, 1)
    if len(section) < 2:
        errors.append(f"A1: method not found: {method}")
        continue
    scope = section[1].split(next_method, 1)[0]
    require("A1/network gate", scope, "guard !networkDisabledInProduction else { return }")

chip = read("bitchat/Views/Components/PaymentChipView.swift")
for bad in ["redeem.cashu.me", "cashuWebRedeemURL", "UIApplication.shared.open(webURL)", "NSWorkspace.shared.open(webURL)"]:
    forbid("A3/Cashu", chip, bad)
require("A3/Cashu scheme", chip, 'walletURL.scheme?.lowercased() == "cashu"')

root = read("bitchat/Views/ContentView.swift")
head = root.split("var body: some View {", 1)
if len(head) < 2:
    errors.append("A4: ContentView body missing")
else:
    scope = head[1].split("private var chatContent:", 1)[0]
    require("A4/root", scope, "appChromeModel.panicClearAllData()")
    require("A4/root", scope, "appChromeModel.requestPanicWipe()")
    require("A4/root", scope, "MeshPrivMatrixTabBar(selection: $meshPrivSection)")
    if scope.count(".confirmationDialog(") != 1:
        errors.append("A4: panic confirmation must be hosted exactly once at root")

tabs = read("bitchat/Views/MeshPrivMatrixShell.swift")
native = read("bitchat/Views/MeshPrivNativeV7.swift")
require("A4/native header panic button", native, "Button(action: onRequestPanic)")
require("A4/native profile panic button", native, "func infoRow(")
require("A4/native header is present", root, "MeshPrivNativeHeader {")
require("A4/four tabs", tabs, "case profile")

vm = read("bitchat/ViewModels/ChatViewModel.swift")
require("A8/panic storage", vm, 'userDefaults.removeObject(forKey: "meshpriv.pay.sandbox.charges.v1")')
tests = read("bitchatTests/ChatViewModelTests.swift")
require("A8/test", tests, "func panicClearAllData_removesMeshPrivSandboxCharges()")
require("A8/test", tests, "#expect(UserDefaults.standard.object(forKey: key) == nil)")

if errors:
    for error in errors:
        print("FAIL: " + error, file=sys.stderr)
    sys.exit(1)
print("PASS: known A1/A3/A4/A8 regression guards present")
print("LIMIT: this is static scanning, not iOS build or network-capture evidence")
