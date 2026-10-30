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
        // Test-only examples: all visible contact names and previews are
        // synthetic. Use relative times that look like active local chats.
        let now = Date()
        let demoRecent: [RecentChatRow] = [
            .init(
                peerID: PeerID(str: "0011223344556677"),
                displayName: "Contato A · DEMO",
                hasUnread: true,
                lastActivity: now.addingTimeInterval(-120),
                lastMessagePreview: "Tudo certo para o encontro de hoje?"
            ),
            .init(
                peerID: PeerID(str: "0011223344556688"),
                displayName: "Contato B · DEMO",
                hasUnread: false,
                lastActivity: now.addingTimeInterval(-1_800),
                lastMessagePreview: "Mensagem recebida pelo canal privado."
            ),
            .init(
                peerID: PeerID(str: "0011223344556699"),
                displayName: "Contato C · DEMO",
                hasUnread: false,
                lastActivity: now.addingTimeInterval(-4_000),
                lastMessagePreview: "Combinado! Até mais."
            ),
            .init(
                peerID: PeerID(str: "00112233445566AA"),
                displayName: "Contato D · DEMO",
                hasUnread: false,
                lastActivity: now.addingTimeInterval(-9_000),
                lastMessagePreview: "Podemos conversar quando estiver perto."
            ),
            .init(
                peerID: PeerID(str: "00112233445566BB"),
                displayName: "Contato E · DEMO",
                hasUnread: true,
                lastActivity: now.addingTimeInterval(-21_000),
                lastMessagePreview: "Recebido com segurança."
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

        // ImageRenderer can return a valid image before a ScrollView has
        // performed its hosted layout. The old PNGs contained just the
        // header and tab bar, with all four screen bodies blank.
        // Render through a real UIKit hierarchy instead.
        let host = UIHostingController(rootView: screen)
        host.view.frame = CGRect(
            x: 0, y: 0, width: canvasWidth, height: canvasHeight
        )
        let window = UIWindow(frame: host.view.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        // Allow SwiftUI's first update pass to realize lazy/scroll content.
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(
            size: host.view.bounds.size,
            format: {
                let format = UIGraphicsImageRendererFormat()
                format.scale = 2
                format.opaque = true
                return format
            }()
        )
        let image = renderer.image { _ in
            host.view.drawHierarchy(
                in: host.view.bounds,
                afterScreenUpdates: true
            )
        }

        // Never declare a screenshot test green for an empty body again.
        try assertCentralContentIsVisible(image, name: name)
        let attachment = XCTAttachment(image: image)
        attachment.name = "MESHPRIV-V8-\(name)-393x780"
        attachment.lifetime = .keepAlways
        add(attachment)

    }

    private func assertCentralContentIsVisible(
        _ image: UIImage,
        name: String
    ) throws {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let rowBytes = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * rowBytes)
        let context = try XCTUnwrap(CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Exclude the header and footer: both rendered correctly in the
        // previous bug and gave a false impression of successful snapshots.
        var contrastPixels = 0
        for y in stride(from: height / 6, to: height * 5 / 6, by: 8) {
            for x in stride(from: width / 12, to: width * 11 / 12, by: 8) {
                let index = y * rowBytes + x * bytesPerPixel
                if max(pixels[index], pixels[index + 1], pixels[index + 2]) > 75 {
                    contrastPixels += 1
                }
            }
        }
        XCTAssertGreaterThan(
            contrastPixels, 40,
            "Matrix screenshot \(name) has an empty central body"
        )
    }
}
#endif
