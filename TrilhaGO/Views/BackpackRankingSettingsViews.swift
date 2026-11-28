import SwiftUI
import CoreImage.CIFilterBuiltins

struct BackpackView: View {
    @ObservedObject var store: TrilhaGameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.coupons) { coupon in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(coupon.storeName)
                                .font(TrilhaFont.title(15))
                                .foregroundStyle(TrilhaColors.darkText)
                            Spacer()
                            Text(coupon.rarity.title.uppercased())
                                .font(TrilhaFont.title(10))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(coupon.rarity == .premium ? TrilhaColors.goldPremium : TrilhaColors.emeraldSoft)
                                .foregroundStyle(TrilhaColors.darkText)
                                .clipShape(Capsule())
                        }
                        Text(coupon.rewardTitle)
                            .font(TrilhaFont.body(14))
                            .foregroundStyle(TrilhaColors.mutedText)

                        HStack(spacing: 14) {
                            if let qrImg = generateQRCode(from: coupon.qrToken) {
                                Image(uiImage: qrImg)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 84, height: 84)
                                    .padding(6)
                                    .background(TrilhaColors.pureWhite)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(TrilhaColors.border))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOKEN ÚNICO")
                                    .font(TrilhaFont.body(10, weight: .semibold))
                                    .foregroundStyle(TrilhaColors.mutedText)
                                Text(coupon.qrToken)
                                    .font(TrilhaFont.metric(13))
                                    .foregroundStyle(TrilhaColors.darkText)
                                Text(coupon.redeemedAt == nil ? "Disponível para resgate na loja" : "Já resgatado")
                                    .font(TrilhaFont.body(11))
                                    .foregroundStyle(coupon.redeemedAt == nil ? TrilhaColors.emeraldDark : Color.red)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Mochila")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        guard let output = filter.outputImage,
              let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

struct RankingView: View {
    @ObservedObject var store: TrilhaGameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(store.ranking) { item in
                HStack(spacing: 12) {
                    Text("#\(item.position)")
                        .font(TrilhaFont.metric(18))
                        .foregroundStyle(item.position == 1 ? TrilhaColors.goldPremium : TrilhaColors.emerald)
                        .frame(width: 36)
                    Circle().fill(item.team.color).frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.playerName).font(TrilhaFont.title(15)).foregroundStyle(TrilhaColors.darkText)
                        Text("Equipe \(item.team.displayName)").font(TrilhaFont.body(12)).foregroundStyle(TrilhaColors.mutedText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(item.territoriesCount) hex").font(TrilhaFont.metric(14)).foregroundStyle(TrilhaColors.darkText)
                        Text(String(format: "%.1f km", item.distanceKm)).font(TrilhaFont.metric(12)).foregroundStyle(TrilhaColors.mutedText)
                    }
                }
            }
            .navigationTitle("Ranking")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: TrilhaGameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Perfil e Equipe") {
                    TextField("Nome do Jogador", text: $store.playerName)
                    Picker("Equipe", selection: $store.selectedTeam) {
                        ForEach(TrilhaTeam.allCases) { team in
                            Text(team.displayName).tag(team)
                        }
                    }
                    Button("Trocar Avatar") {
                        dismiss()
                        store.stage = .avatarSetup
                    }
                }
                Section("Regras Anti-Cheat") {
                    Label("Modo Normal: limite 25 km/h", systemImage: "shield.checkered")
                    Label("Caminhada/Corrida: limite 20 km/h", systemImage: "figure.run")
                    Label("Ciclismo: limite 35 km/h", systemImage: "bicycle")
                    Label("Bloqueio automático de Mock Location", systemImage: "location.slash")
                }
                Section("Backend & Mapa") {
                    HStack {
                        Text("Supabase PostGIS")
                        Spacer()
                        Text(SupabaseService.shared.isConfigured ? "Conectado" : "Modo Demo Local")
                            .foregroundStyle(TrilhaColors.mutedText)
                    }
                }
            }
            .navigationTitle("Configurações")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } }
            }
        }
    }
}

struct MerchantPanelView: View {
    @ObservedObject var store: TrilhaGameStore
    @Environment(\.dismiss) private var dismiss
    @State private var tokenInput: String = ""
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Image("icon_qrcode").resizable().scaledToFit().frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Painel do Lojista")
                            .font(TrilhaFont.title(18)).foregroundStyle(TrilhaColors.darkText)
                        Text("Valide cupons QR Code e controle o Baú Premium 1/dia.")
                            .font(TrilhaFont.body(12)).foregroundStyle(TrilhaColors.mutedText)
                    }
                    Spacer()
                }

                TextField("Digite o token do QR Code", text: $tokenInput)
                    .textInputAutocapitalization(.characters)
                    .padding(14)
                    .background(TrilhaColors.pureWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(TrilhaColors.border))

                EmeraldPillButton(title: "VALIDAR QR CODE") {
                    let clean = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    if let idx = store.coupons.firstIndex(where: { $0.qrToken.uppercased() == clean && $0.redeemedAt == nil }) {
                        store.coupons[idx].redeemedAt = Date()
                        statusMessage = "Cupom \(clean) validado: \(store.coupons[idx].rewardTitle)"
                    } else {
                        statusMessage = "QR Code inválido ou já resgatado."
                    }
                }

                if let msg = statusMessage {
                    Text(msg)
                        .font(TrilhaFont.body(13, weight: .semibold))
                        .foregroundStyle(TrilhaColors.darkText)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(TrilhaColors.pureWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Spacer()
            }
            .padding(20)
            .background(TrilhaColors.surfaceGray.ignoresSafeArea())
            .navigationTitle("Painel do Lojista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } }
            }
        }
    }
}
