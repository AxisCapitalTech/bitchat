//
// MeshPrivNativeV7.swift
// Native Matrix-inspired UI using ONLY real data from the existing BLE models.
// No new networking, message codec, keys, blockchain API, or payment processing.
//

#if os(iOS)
import BitFoundation
import SwiftUI

enum MeshPrivV7Style {
    static let black = Color(red: 0.006, green: 0.03, blue: 0.023)
    static let panel = Color(red: 0.025, green: 0.094, blue: 0.067)
    static let raised = Color(red: 0.044, green: 0.15, blue: 0.107)
    static let line = Color(red: 0.10, green: 0.31, blue: 0.22)
    static let neon = Color(red: 0.015, green: 0.96, blue: 0.65)
    static let white = Color(red: 0.94, green: 1, blue: 0.96)
    static let secondary = Color(red: 0.63, green: 0.79, blue: 0.70)
}

/// Original triangular mesh symbol used across the native Matrix shell.
/// Shape-based artwork stays crisp at every screen density.
private struct MeshPrivNativeBrandMark: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: width * 0.15, y: height * 0.06))
                    path.addLine(to: CGPoint(x: width * 0.91, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.94))
                    path.closeSubpath()
                }
                .stroke(
                    MeshPrivV7Style.neon,
                    style: StrokeStyle(lineWidth: 1.9, lineJoin: .round)
                )

                Path { path in
                    path.move(to: CGPoint(x: width * 0.15, y: height * 0.06))
                    path.addLine(to: CGPoint(x: width * 0.52, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.94))
                    path.move(to: CGPoint(x: width * 0.52, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width * 0.91, y: height * 0.5))
                }
                .stroke(
                    MeshPrivV7Style.neon.opacity(0.85),
                    style: StrokeStyle(lineWidth: 1.25, lineJoin: .round)
                )
            }
        }
        .frame(width: 30, height: 32)
        .shadow(color: MeshPrivV7Style.neon.opacity(0.5), radius: 7)
        .accessibilityHidden(true)
    }
}

struct MeshPrivNativeHeader: View {
    @Environment(\.locale) private var locale

    private func meshPrivNativeLabel(_ portuguese: String, _ english: String) -> String {
        locale.language.languageCode?.identifier == "pt" ? portuguese : english
    }

    let onRequestPanic: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            MeshPrivNativeBrandMark()

            HStack(spacing: 0) {
                Text("Mesh")
                    .foregroundColor(MeshPrivV7Style.white)
                Text("Priv")
                    .foregroundColor(MeshPrivV7Style.neon)
                Text("_")
                    .foregroundColor(MeshPrivV7Style.neon)
            }
            .font(.system(size: 19, weight: .bold, design: .monospaced))
            .accessibilityLabel("MeshPriv")

            Spacer()

            Text("MATRIX")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundColor(MeshPrivV7Style.neon)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(MeshPrivV7Style.panel, in: Capsule())
                .overlay(Capsule().stroke(MeshPrivV7Style.line, lineWidth: 1))

            Button(action: onRequestPanic) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 16))
                    .foregroundColor(MeshPrivV7Style.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                meshPrivNativeLabel("Apagar dados em emergência", "Emergency wipe")
            )
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 8)
        .background(MeshPrivV7Style.black)
    }
}

private struct MeshPrivNativeConversation: Identifiable {
    let peerID: PeerID
    let name: String
    let isConnected: Bool
    let isReachable: Bool
    let isUnread: Bool
    let lastActivity: Date?
    let lastMessagePreview: String?

    var id: String { peerID.id }
}

private struct MeshPrivNativeAvatar: View {
    let name: String
    let active: Bool
    var diameter: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [MeshPrivV7Style.raised, MeshPrivV7Style.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .stroke(
                    active ? MeshPrivV7Style.neon : MeshPrivV7Style.line,
                    lineWidth: 1.5
                )
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: diameter * 0.42, weight: .semibold, design: .rounded))
                .foregroundColor(MeshPrivV7Style.white)
        }
        .frame(width: diameter, height: diameter)
        .shadow(
            color: active ? MeshPrivV7Style.neon.opacity(0.25) : .clear,
            radius: 6
        )
        .accessibilityHidden(true)
    }
}

/// No fabricated chats or locations: display only peers/recent DMs emitted
/// by PeerListModel and reuse startConversation(with:) from the upstream app.
struct MeshPrivNativeChatsHome: View {
    @Environment(\.locale) private var locale

    private func meshPrivNativeLabel(_ portuguese: String, _ english: String) -> String {
        locale.language.languageCode?.identifier == "pt" ? portuguese : english
    }

    let peers: [MeshPeerRow]
    let recentChats: [RecentChatRow]
    let onOpenPeer: (PeerID) -> Void
    let onOpenPublicChat: () -> Void

    @State private var search = ""
    @State private var filter = 0

    private var conversations: [MeshPrivNativeConversation] {
        var result: [MeshPrivNativeConversation] = []
        var seen = Set<String>()

        for recent in recentChats.sorted(by: { $0.lastActivity > $1.lastActivity }) {
            // Historical geohash/bridge/group threads may survive in the
            // conversation store, but are not transportable over BLE mesh.
            // Never advertise them as reachable native BLE conversations.
            guard !recent.peerID.isGeoDM,
                  !recent.peerID.isGeoChat,
                  !recent.peerID.isBridge,
                  !recent.peerID.isGroup else { continue }
            let peer = peers.first { $0.peerID == recent.peerID }
            guard seen.insert(recent.id).inserted else { continue }
            result.append(
                MeshPrivNativeConversation(
                    peerID: recent.peerID,
                    name: recent.displayName,
                    isConnected: peer?.isConnected ?? false,
                    isReachable: peer?.isReachable ?? false,
                    isUnread: recent.hasUnread || (peer?.hasUnread ?? false),
                    lastActivity: recent.lastActivity,
                    lastMessagePreview: recent.lastMessagePreview
                )
            )
        }

        for peer in peers where !peer.isMe && !peer.isBlocked {
            guard seen.insert(peer.id).inserted else { continue }
            // Do not show disconnected strangers as active conversations.
            guard peer.isConnected || peer.isReachable || peer.hasUnread else { continue }
            result.append(
                MeshPrivNativeConversation(
                    peerID: peer.peerID,
                    name: peer.displayName,
                    isConnected: peer.isConnected,
                    isReachable: peer.isReachable,
                    isUnread: peer.hasUnread,
                    lastActivity: nil,
                    lastMessagePreview: nil
                )
            )
        }
        return result
    }

    private var matching: [MeshPrivNativeConversation] {
        conversations.filter { entry in
            (search.isEmpty || entry.name.localizedCaseInsensitiveContains(search))
                && (filter == 0 || (filter == 1 && (entry.isConnected || entry.isReachable))
                    || (filter == 2 && entry.isUnread))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(meshPrivNativeLabel("Conversas", "Chats"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(MeshPrivV7Style.white)
                    Spacer()
                    Button(action: onOpenPublicChat) {
                        Image(systemName: "plus.message")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MeshPrivV7Style.neon)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        meshPrivNativeLabel("Abrir canal local", "Open local channel")
                    )
                }

                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MeshPrivV7Style.secondary)
                    TextField(
                        meshPrivNativeLabel("Buscar conversas...", "Search chats..."),
                        text: $search
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(MeshPrivV7Style.white)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(MeshPrivV7Style.panel, in: Capsule())
                .overlay(Capsule().stroke(MeshPrivV7Style.line))

                HStack(spacing: 8) {
                    filterButton(0, meshPrivNativeLabel("Todas", "All"))
                    filterButton(1, meshPrivNativeLabel("Perto", "Nearby"))
                    filterButton(2, meshPrivNativeLabel("Não lidas", "Unread"))
                    Spacer(minLength: 0)
                }

                if matching.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(MeshPrivV7Style.neon)
                        Text(
                            search.isEmpty
                                ? meshPrivNativeLabel(
                                    "Nenhuma conversa encontrada",
                                    "No conversations found"
                                )
                                : meshPrivNativeLabel(
                                    "Nenhum resultado para esta busca",
                                    "No matching conversations"
                                )
                        )
                        .font(.headline)
                        .foregroundColor(MeshPrivV7Style.white)
                        Text(
                            meshPrivNativeLabel(
                                "Para conversar, aproxime outro aparelho com MeshPriv e Bluetooth ativo.",
                                "To chat, bring another MeshPriv device within Bluetooth range."
                            )
                        )
                        .font(.subheadline)
                        .foregroundColor(MeshPrivV7Style.secondary)
                        .multilineTextAlignment(.center)
                        Button(action: onOpenPublicChat) {
                            Label(
                                meshPrivNativeLabel("Abrir canal local", "Open local channel"),
                                systemImage: "bubble.left"
                            )
                            .foregroundColor(MeshPrivV7Style.neon)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 33)
                    .padding(.horizontal, 15)
                    .background(MeshPrivV7Style.panel, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(matching) { chat in
                            Button {
                                onOpenPeer(chat.peerID)
                            } label: {
                                HStack(spacing: 12) {
                                    MeshPrivNativeAvatar(
                                        name: chat.name,
                                        active: chat.isConnected
                                    )
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(verbatim: chat.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .lineLimit(1)
                                            Spacer(minLength: 5)
                                            if let lastActivity = chat.lastActivity {
                                                Text(lastActivity, style: .relative)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(MeshPrivV7Style.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        HStack(spacing: 5) {
                                            if let preview = chat.lastMessagePreview {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(MeshPrivV7Style.neon)
                                                Text(verbatim: preview)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(MeshPrivV7Style.secondary)
                                                    .lineLimit(1)
                                            } else {
                                                Circle()
                                                    .fill(
                                                        chat.isConnected
                                                            ? MeshPrivV7Style.neon
                                                            : MeshPrivV7Style.secondary
                                                    )
                                                    .frame(width: 6, height: 6)
                                                Text(
                                                    chat.isConnected
                                                        ? meshPrivNativeLabel(
                                                            "Bluetooth direto", "Direct Bluetooth"
                                                        )
                                                        : chat.isReachable
                                                            ? meshPrivNativeLabel(
                                                                "Alcançável via mesh", "Mesh reachable"
                                                            )
                                                            : meshPrivNativeLabel(
                                                                "Conversa anterior", "Previous chat"
                                                            )
                                                )
                                                .font(.system(size: 11))
                                                .foregroundColor(MeshPrivV7Style.secondary)
                                                .lineLimit(1)
                                            }
                                        }
                                    }
                                    if chat.isUnread {
                                        Circle()
                                            .fill(MeshPrivV7Style.neon)
                                            .frame(width: 9, height: 9)
                                            .accessibilityLabel(
                                                meshPrivNativeLabel("Não lida", "Unread")
                                            )
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(MeshPrivV7Style.secondary)
                                }
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(MeshPrivV7Style.white)

                            Rectangle()
                                .fill(MeshPrivV7Style.line)
                                .frame(height: 0.5)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(MeshPrivV7Style.neon)
                    Text(
                        meshPrivNativeLabel(
                            "Mensagens privadas protegidas por Noise. Canais públicos não são E2EE.",
                            "Private messages use Noise. Public channels are not E2EE."
                        )
                    )
                    .font(.system(size: 11))
                    .foregroundColor(MeshPrivV7Style.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MeshPrivV7Style.panel, in: RoundedRectangle(cornerRadius: 11))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
        }
        .background(MeshPrivV7Style.black)
    }

    private func filterButton(_ value: Int, _ label: String) -> some View {
        Button {
            filter = value
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(
                    filter == value ? MeshPrivV7Style.black : MeshPrivV7Style.secondary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    filter == value ? MeshPrivV7Style.neon : MeshPrivV7Style.panel,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(filter == value ? [.isSelected] : [])
    }
}

/// Radar geometry is SCHEMATIC, never a measured peer location or distance.
/// Connections and statuses are real BLE model data. The selected peer opens
/// its actual upstream conversation.
struct MeshPrivNativeRadar: View {
    @Environment(\.locale) private var locale

    private func meshPrivNativeLabel(_ portuguese: String, _ english: String) -> String {
        locale.language.languageCode?.identifier == "pt" ? portuguese : english
    }

    let peers: [MeshPeerRow]
    let onOpenPeer: (PeerID) -> Void

    private var visible: [MeshPeerRow] {
        peers.filter { !$0.isMe && !$0.isBlocked && ($0.isConnected || $0.isReachable) }
    }

    private var directCount: Int { visible.filter(\.isConnected).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(meshPrivNativeLabel("Perto de mim", "Nearby"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(MeshPrivV7Style.white)

                HStack(spacing: 7) {
                    statusCard("\(visible.count)", meshPrivNativeLabel("Alcançáveis", "Reachable"))
                    statusCard("\(directCount)", meshPrivNativeLabel("BLE direto", "Direct BLE"))
                    statusCard(
                        "\(visible.count - directCount)",
                        meshPrivNativeLabel("Via mesh", "Mesh relay")
                    )
                }

                GeometryReader { geo in
                    let diameter = min(geo.size.width, geo.size.height)
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [MeshPrivV7Style.raised, MeshPrivV7Style.black],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: diameter / 2
                                )
                            )
                        Circle()
                            .stroke(MeshPrivV7Style.line, lineWidth: 1)
                        Circle()
                            .stroke(
                                MeshPrivV7Style.line.opacity(0.8),
                                style: StrokeStyle(lineWidth: 1, dash: [3, 5])
                            )
                            .frame(width: diameter * 0.73, height: diameter * 0.73)
                        Circle()
                            .stroke(MeshPrivV7Style.line, lineWidth: 1)
                            .frame(width: diameter * 0.43, height: diameter * 0.43)

                        ForEach(visible.prefix(6).indices, id: \.self) { index in
                            let peer = visible[index]
                            let angle = Double(index) * 2 * .pi
                                / Double(max(1, min(visible.count, 6))) - .pi / 2
                            let x = diameter / 2 + CGFloat(cos(angle)) * diameter * 0.33
                            let y = diameter / 2 + CGFloat(sin(angle)) * diameter * 0.33

                            Path { path in
                                path.move(to: CGPoint(x: diameter / 2, y: diameter / 2))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            .stroke(
                                MeshPrivV7Style.neon.opacity(0.45),
                                style: StrokeStyle(lineWidth: 1, dash: [3, 4])
                            )

                            Button {
                                onOpenPeer(peer.peerID)
                            } label: {
                                VStack(spacing: 3) {
                                    MeshPrivNativeAvatar(
                                        name: peer.displayName,
                                        active: peer.isConnected,
                                        diameter: 37
                                    )
                                    Text(verbatim: peer.displayName)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(MeshPrivV7Style.white)
                                        .lineLimit(1)
                                        .frame(width: 76)
                                }
                            }
                            .buttonStyle(.plain)
                            .position(x: x, y: y)
                        }

                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(MeshPrivV7Style.white)
                            .frame(width: 48, height: 48)
                            .background(MeshPrivV7Style.raised, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(MeshPrivV7Style.neon, lineWidth: 2)
                            )
                            .shadow(color: MeshPrivV7Style.neon.opacity(0.6), radius: 11)
                    }
                    .frame(width: diameter, height: diameter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 340)

                Text(
                    meshPrivNativeLabel(
                        "Mapa ilustrativo de conexões. Não representa posição ou distância.",
                        "Illustrative network diagram. Does not show location or distance."
                    )
                )
                .font(.system(size: 11))
                .foregroundColor(MeshPrivV7Style.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 10) {
                    Text(meshPrivNativeLabel("Dispositivos alcançáveis", "Reachable devices"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MeshPrivV7Style.white)

                    if visible.isEmpty {
                        Text(
                            meshPrivNativeLabel(
                                "Nenhum aparelho detectado. Ative o Bluetooth nos dispositivos.",
                                "No devices detected. Enable Bluetooth on nearby devices."
                            )
                        )
                        .font(.subheadline)
                        .foregroundColor(MeshPrivV7Style.secondary)
                    }

                    ForEach(visible) { peer in
                        Button {
                            onOpenPeer(peer.peerID)
                        } label: {
                            HStack(spacing: 12) {
                                MeshPrivNativeAvatar(
                                    name: peer.displayName,
                                    active: peer.isConnected,
                                    diameter: 38
                                )
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(verbatim: peer.displayName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(MeshPrivV7Style.white)
                                    Text(
                                        peer.isConnected
                                            ? meshPrivNativeLabel(
                                                "Conexão direta", "Direct connection"
                                            )
                                            : meshPrivNativeLabel(
                                                "Alcançável via mesh", "Mesh reachable"
                                            )
                                    )
                                    .font(.system(size: 11))
                                    .foregroundColor(MeshPrivV7Style.secondary)
                                }
                                Spacer()
                                Image(systemName: "bubble.right")
                                    .foregroundColor(MeshPrivV7Style.neon)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 5)
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MeshPrivV7Style.panel, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(18)
        }
        .background(MeshPrivV7Style.black)
    }

    private func statusCard(_ value: String, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 23, weight: .bold, design: .monospaced))
                .foregroundColor(MeshPrivV7Style.neon)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(MeshPrivV7Style.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(MeshPrivV7Style.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MeshPrivV7Style.line, lineWidth: 1)
        )
    }
}

struct MeshPrivNativeProfile: View {
    @Environment(\.locale) private var locale

    private func meshPrivNativeLabel(_ portuguese: String, _ english: String) -> String {
        locale.language.languageCode?.identifier == "pt" ? portuguese : english
    }

    let reachableCount: Int
    let onRequestPanic: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text(meshPrivNativeLabel("Perfil", "Profile"))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(MeshPrivV7Style.white)

                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 65, weight: .ultraLight))
                        .foregroundColor(MeshPrivV7Style.neon)
                    Text("MeshPriv_")
                        .font(.system(size: 21, weight: .bold, design: .monospaced))
                        .foregroundColor(MeshPrivV7Style.white)
                    Text(meshPrivNativeLabel(
                        "Identidade local · sem conta de telefone",
                        "Local identity · no phone account"
                    ))
                    .font(.system(size: 12))
                    .foregroundColor(MeshPrivV7Style.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(23)
                .background(MeshPrivV7Style.panel, in: RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 12) {
                    infoRow(
                        "antenna.radiowaves.left.and.right",
                        meshPrivNativeLabel("Pessoas alcançáveis", "Reachable peers"),
                        "\(reachableCount)"
                    )
                    infoRow("lock.shield", "Noise", meshPrivNativeLabel(
                        "Conversa privada", "Private chat"
                    ))
                    infoRow("wallet.pass", "Axis Pay", "SANDBOX")
                }
                .padding(16)
                .background(MeshPrivV7Style.panel, in: RoundedRectangle(cornerRadius: 15))

                Button(action: onRequestPanic) {
                    Label(
                        meshPrivNativeLabel(
                            "Apagar dados em emergência", "Emergency wipe"
                        ),
                        systemImage: "exclamationmark.shield"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red.opacity(0.85))
                .background(
                    MeshPrivV7Style.panel,
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                )

                Text(meshPrivNativeLabel(
                    "A exclusão exige confirmação e interrompe as conversas locais.",
                    "Deletion requires confirmation and stops local conversations."
                ))
                .font(.system(size: 11))
                .foregroundColor(MeshPrivV7Style.secondary)
            }
            .padding(18)
        }
        .background(MeshPrivV7Style.black)
    }

    private func infoRow(_ symbol: String, _ label: String, _ value: String) -> some View {
        HStack {
            Image(systemName: symbol)
                .frame(width: 25)
                .foregroundColor(MeshPrivV7Style.neon)
            Text(label)
                .foregroundColor(MeshPrivV7Style.white)
            Spacer()
            Text(value)
                .foregroundColor(MeshPrivV7Style.secondary)
        }
        .font(.system(size: 13))
    }
}
#endif
