//
// MeshPrivMatrixShell.swift
// Matrix-inspired navigation and LOCAL payment sandbox.
// No network APIs, blockchain RPC, private keys or real payments.
//

#if os(iOS)
import BitFoundation
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

private enum MeshPrivPalette {
    static let background = Color(red: 0.015, green: 0.038, blue: 0.025)
    static let surface = Color(red: 0.035, green: 0.09, blue: 0.062)
    static let accent = Color(red: 0.24, green: 0.96, blue: 0.52)
    static let border = Color(red: 0.11, green: 0.34, blue: 0.22)
    static let secondary = Color(red: 0.63, green: 0.79, blue: 0.68)
}

private func meshPrivText(_ portuguese: String, _ english: String) -> String {
    let language = Locale.current.language.languageCode?.identifier ?? "pt"
    return language == "pt" ? portuguese : english
}

enum MeshPrivSection: String, CaseIterable, Identifiable {
    case chats
    case nearby
    case pay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chats: meshPrivText("Conversas", "Chats")
        case .nearby: meshPrivText("Mesh", "Mesh")
        case .pay: meshPrivText("Carteira", "Wallet")
        }
    }

    var symbol: String {
        switch self {
        case .chats: "bubble.left.and.bubble.right"
        case .nearby: "antenna.radiowaves.left.and.right"
        case .pay: "wallet.pass"
        }
    }
}

struct MeshPrivMatrixTabBar: View {
    @Binding var selection: MeshPrivSection
    let onRequestPanic: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MeshPrivSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: section.symbol)
                            .font(.system(size: 18, weight: .medium))
                            .frame(height: 23)
                        Text(section.label)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(
                        selection == section
                            ? MeshPrivPalette.accent : MeshPrivPalette.secondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if selection == section {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(MeshPrivPalette.surface)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == section ? [.isSelected] : [])
            }
            // Emergency wipe remains reachable outside the Chats tab.
            Button(action: onRequestPanic) {
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(MeshPrivPalette.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                meshPrivText("Apagar dados em emergência", "Emergency data wipe")
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .background(MeshPrivPalette.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MeshPrivPalette.border)
                .frame(height: 1)
        }
    }
}

struct MeshPrivNearbyPanel: View {
    let peers: [MeshPeerRow]
    let connectedCount: Int
    let onOpenPeer: (PeerID) -> Void

    private var visiblePeers: [MeshPeerRow] {
        peers.filter { !$0.isMe && ($0.isConnected || $0.isReachable) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heading

                HStack(spacing: 11) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 25))
                        .foregroundColor(MeshPrivPalette.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(meshPrivText("Rede Bluetooth", "Bluetooth network"))
                            .font(.headline)
                        Text(
                            meshPrivText(
                                "Pessoas alcançáveis por rádio ou retransmissão",
                                "Peers reachable directly or through mesh relays"
                            )
                        )
                        .font(.caption)
                        .foregroundColor(MeshPrivPalette.secondary)
                    }
                    Spacer()
                }
                .padding(17)
                .background(MeshPrivPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MeshPrivPalette.border, lineWidth: 1)
                }

                Text(
                    meshPrivText(
                        "\(connectedCount) conexões diretas",
                        "\(connectedCount) direct connections"
                    )
                )
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(MeshPrivPalette.accent)

                if visiblePeers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 35))
                            .foregroundColor(MeshPrivPalette.accent)
                        Text(meshPrivText("Nenhum aparelho ao alcance", "No nearby devices"))
                            .font(.headline)
                        Text(
                            meshPrivText(
                                "Ative o Bluetooth e mantenha outros aparelhos com MeshPriv próximos.",
                                "Turn on Bluetooth and keep other MeshPriv devices nearby."
                            )
                        )
                        .font(.subheadline)
                        .foregroundColor(MeshPrivPalette.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(35)
                    .background(MeshPrivPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(visiblePeers) { peer in
                        Button {
                            onOpenPeer(peer.peerID)
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: peer.isConnected
                                        ? "antenna.radiowaves.left.and.right"
                                        : "point.3.connected.trianglepath.dotted"
                                )
                                .foregroundColor(MeshPrivPalette.accent)
                                .font(.title3)
                                .frame(width: 33)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(verbatim: peer.displayName)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(
                                        peer.isConnected
                                            ? meshPrivText("BLE direto", "Direct BLE")
                                            : meshPrivText("Via mesh", "Mesh relay")
                                    )
                                    .font(.caption)
                                    .foregroundColor(MeshPrivPalette.secondary)
                                }
                                Spacer()
                                Image(systemName: "bubble.right")
                                    .foregroundColor(MeshPrivPalette.accent)
                            }
                            .padding(15)
                            .background(
                                MeshPrivPalette.surface,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(MeshPrivPalette.background)
        .foregroundColor(.white)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MESHPRIV_")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(3)
                .foregroundColor(MeshPrivPalette.accent)
            Text(meshPrivText("Perto de mim", "Nearby"))
                .font(.system(size: 29, weight: .bold, design: .monospaced))
            Text(meshPrivText("Comunicação local, sem relays de internet.", "Local communication, no internet relays."))
                .font(.subheadline)
                .foregroundColor(MeshPrivPalette.secondary)
        }
    }
}

struct MeshPrivDemoCharge: Identifiable, Codable {
    let id: String
    let amountBRL: Double
    let asset: String
    let createdAt: Date
    var paidInSimulation: Bool

    var payload: String {
        // Private demo URI: NOT a Solana address, payment request or deep link.
        let amount = String(format: "%.2f", amountBRL)
        return "meshpriv-demo://charge/\(id)?brl=\(amount)&asset=\(asset)"
    }
}

struct MeshPrivPaySandboxView: View {
    @AppStorage("meshpriv.pay.sandbox.charges.v1") private var chargeJSON = "[]"
    @State private var amountText = "50.00"
    @State private var asset = "USDC"
    @State private var presentedCharge: MeshPrivDemoCharge?
    @State private var invalidAmount = false

    private var charges: [MeshPrivDemoCharge] {
        guard let data = chargeJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([MeshPrivDemoCharge].self, from: data)) ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("AXIS PAY / SANDBOX_")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(MeshPrivPalette.accent)

                Text(meshPrivText("Carteira", "Wallet"))
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                Text(
                    meshPrivText(
                        "Pagamentos integrados ao aplicativo. Transações reais ainda desativadas.",
                        "Payments inside the app. Real transactions are not enabled yet."
                    )
                )
                .font(.subheadline)
                .foregroundColor(MeshPrivPalette.secondary)

                walletStatus
                createCharge
                chargeHistory
            }
            .padding(20)
        }
        .background(MeshPrivPalette.background)
        .foregroundColor(.white)
        .alert(
            meshPrivText("Valor inválido", "Invalid amount"),
            isPresented: $invalidAmount
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                meshPrivText(
                    "Informe um valor entre R$ 0,01 e R$ 100.000.",
                    "Enter an amount between BRL 0.01 and BRL 100,000."
                )
            )
        }
        .sheet(item: $presentedCharge) { charge in
            MeshPrivDemoChargeSheet(
                charge: charge,
                onSimulate: { markPaid(charge.id) }
            )
        }
    }

    private var walletStatus: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(
                meshPrivText("Nenhuma carteira conectada", "No wallet connected"),
                systemImage: "wallet.pass"
            )
            .font(.headline)
            Text(
                meshPrivText(
                    "Sem chaves privadas, saldo fictício ou custódia de fundos.",
                    "No private keys, fake balance or custody of funds."
                )
            )
            .font(.caption)
            .foregroundColor(MeshPrivPalette.secondary)
            Text("● SANDBOX · NO REAL TRANSACTIONS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(MeshPrivPalette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(MeshPrivPalette.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(MeshPrivPalette.border, lineWidth: 1)
        }
    }

    private var createCharge: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(meshPrivText("Nova cobrança de teste", "New demo charge"))
                .font(.headline)

            TextField("R$ 50,00", text: $amountText)
                .keyboardType(.decimalPad)
                .padding(13)
                .background(MeshPrivPalette.background, in: RoundedRectangle(cornerRadius: 9))
                .foregroundColor(.white)
                .accessibilityLabel(meshPrivText("Valor em reais", "Amount in BRL"))

            Picker(meshPrivText("Stablecoin", "Stablecoin"), selection: $asset) {
                Text("USDC").tag("USDC")
                Text("USDT").tag("USDT")
            }
            .pickerStyle(.segmented)

            Button(action: makeCharge) {
                Label(
                    meshPrivText("Gerar QR demonstrativo", "Create demo QR"),
                    systemImage: "qrcode"
                )
                .font(.system(.headline, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(13)
            }
            .buttonStyle(.plain)
            .background(MeshPrivPalette.accent, in: RoundedRectangle(cornerRadius: 10))
            .foregroundColor(MeshPrivPalette.background)

            Text(
                meshPrivText(
                    "Valores apenas em BRL: não há cotação ao vivo, conversão nem transferência.",
                    "BRL only: no live quote, conversion or transfer."
                )
            )
            .font(.caption)
            .foregroundColor(MeshPrivPalette.secondary)
        }
        .padding(17)
        .background(MeshPrivPalette.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var chargeHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meshPrivText("Histórico local", "Local history"))
                .font(.headline)
            if charges.isEmpty {
                Text(meshPrivText("Nenhuma cobrança de teste.", "No demo charges yet."))
                    .font(.subheadline)
                    .foregroundColor(MeshPrivPalette.secondary)
            } else {
                ForEach(charges) { charge in
                    Button {
                        presentedCharge = charge
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("R$ " + String(format: "%.2f", charge.amountBRL))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(charge.asset + " · " + String(charge.id.prefix(8)))
                                    .font(.caption2.monospaced())
                                    .foregroundColor(MeshPrivPalette.secondary)
                            }
                            Spacer()
                            Text(
                                charge.paidInSimulation
                                    ? meshPrivText("Simulado ✓", "Simulated ✓")
                                    : meshPrivText("Aguardando teste", "Demo pending")
                            )
                            .font(.caption)
                            .foregroundColor(MeshPrivPalette.accent)
                        }
                        .padding(13)
                        .background(
                            MeshPrivPalette.surface,
                            in: RoundedRectangle(cornerRadius: 11)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func makeCharge() {
        let normalized = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(normalized),
              amount >= 0.01, amount <= 100_000,
              amount.isFinite
        else {
            invalidAmount = true
            return
        }

        let charge = MeshPrivDemoCharge(
            id: UUID().uuidString,
            amountBRL: (amount * 100).rounded() / 100,
            asset: asset,
            createdAt: Date(),
            paidInSimulation: false
        )
        saveCharges([charge] + charges)
        presentedCharge = charge
    }

    private func markPaid(_ id: String) {
        let changed = charges.map { charge -> MeshPrivDemoCharge in
            var updated = charge
            if charge.id == id { updated.paidInSimulation = true }
            return updated
        }
        saveCharges(changed)
        presentedCharge = changed.first { $0.id == id }
    }

    private func saveCharges(_ updated: [MeshPrivDemoCharge]) {
        guard let data = try? JSONEncoder().encode(updated),
              let json = String(data: data, encoding: .utf8)
        else { return }
        chargeJSON = json
    }
}

private struct MeshPrivDemoChargeSheet: View {
    let charge: MeshPrivDemoCharge
    let onSimulate: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("AXIS PAY · DEMO ONLY")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(MeshPrivPalette.accent)
                Text("R$ " + String(format: "%.2f", charge.amountBRL))
                    .font(.system(size: 29, weight: .bold, design: .monospaced))
                MeshPrivDemoQRCode(payload: charge.payload)
                    .frame(width: 210, height: 210)
                Text(
                    meshPrivText(
                        "QR não pagável. Não envie criptomoedas.",
                        "Non-payable QR. Do not send cryptocurrency."
                    )
                )
                .font(.callout)
                .multilineTextAlignment(.center)

                if charge.paidInSimulation {
                    Label(
                        meshPrivText("Pagamento simulado", "Simulated payment"),
                        systemImage: "checkmark.circle"
                    )
                    .foregroundColor(MeshPrivPalette.accent)
                } else {
                    Button {
                        onSimulate()
                    } label: {
                        Text(
                            meshPrivText(
                                "Simular pagamento (sem dinheiro)",
                                "Simulate payment (no funds)"
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(13)
                    }
                    .buttonStyle(.plain)
                    .background(MeshPrivPalette.accent, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(MeshPrivPalette.background)
                }
                Button(meshPrivText("Fechar", "Close")) { dismiss() }
                    .foregroundColor(MeshPrivPalette.secondary)
            }
            .padding(26)
        }
        .background(MeshPrivPalette.background)
        .foregroundColor(.white)
        .presentationDetents([.medium, .large])
    }
}

private struct MeshPrivDemoQRCode: View {
    let payload: String

    var body: some View {
        Group {
            if let image = generate() {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 95))
                    .foregroundColor(.black)
            }
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
    }

    private func generate() -> UIImage? {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(payload.utf8)
        generator.correctionLevel = "M"

        let context = CIContext()
        guard let output = generator.outputImage,
              let image = context.createCGImage(output, from: output.extent)
        else { return nil }
        return UIImage(cgImage: image)
    }
}
#endif
