//
// MeshPrivV8VisualSnapshots.swift
//
// iOS snapshot attachments for SIDE-BY-SIDE review against the approved
// Matrix concept. All sample contacts are explicitly synthetic test fixtures.
// Never used by production transports, contacts, payments or UI state.
//

#if os(iOS)
import XCTest
import SwiftUI
import BitFoundation
@testable import bitchat

@MainActor
final class MeshPrivV8VisualSnapshots: XCTestCase {
    private let canvasWidth: CGFloat = 393
    private let canvasHeight: CGFloat = 780

    func testMatrixScreensAttachReviewImages() throws {
        let peers: [MeshPeerRow] = []
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let demoRecent: [RecentChatRow] = [
            .init(
                peerID: PeerID(str: "0011223344556677"),
                displayName: "Contato A · DEMO",
                hasUnread: true,
                lastActivity: now
            ),
            .init(
                peerID: PeerID(str: "0011223344556688"),
                displayName: "Contato B · DEMO",
                hasUnread: false,
                lastActivity: now.addingTimeInterval(-3_600)
            ),
            .init(
                peerID: PeerID(str: "0011223344556699"),
                displayName: "Contato C · DEMO",
                hasUnread: false,
                lastActivity: now.addingTimeInterval(-86_400)
            )
        ]

        try attach(
            "01-Conversas",
            MeshPrivNativeChatsHome(
                peers: peers,
                recentChats: demoRecent,
                onOpenPeer: { _ in },
                onOpenPublicChat: {}
            ),
            tab: .chats
        )
        try attach(
            "02-Radar-sem-peers",
            MeshPrivNativeRadar(peers: peers, onOpenPeer: { _ in }),
            tab: .nearby
        )
        try attach(
            "03-AXIS-Pay-sandbox",
            MeshPrivPaySandboxView(),
            tab: .pay
        )
        try attach(
            "04-Perfil",
            MeshPrivNativeProfile(reachableCount: 0, onRequestPanic: {}),
            tab: .profile
        )
    }

    private func attach<Screen: View>(
        _ name: String,
        _ content: Screen,
        tab: MeshPrivSection
    ) throws {
        let screen = VStack(spacing: 0) {
            MeshPrivNativeHeader(onRequestPanic: {})
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            MeshPrivMatrixTabBar(selection: .constant(tab))
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .background(MeshPrivV7Style.black)
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .overlay(alignment: .topTrailing) {
            // Prevent screenshots from being mistaken for real connections.
            Text("UI TEST · DEMO")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(MeshPrivV7Style.neon)
                .padding(5)
                .background(MeshPrivV7Style.black)
        }

        let renderer = ImageRenderer(content: screen)
        renderer.proposedSize = ProposedViewSize(
            width: canvasWidth,
            height: canvasHeight
        )
        renderer.scale = 2

        let image = try XCTUnwrap(
            renderer.uiImage,
            "SwiftUI snapshot could not render for \(name)"
        )
        let attachment = XCTAttachment(image: image)
        attachment.name = "MESHPRIV-V8-\(name)-393x780"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
