import SwiftUI
import PhotosUI

/// Modal reutilizável 100% flat branco para adicionar despesa/item com Descrição + Quantidade × Valor unitário (multiplica ao vivo!)
struct AddExpenseItemSheet: View {
    var title: String = "Adicionar despesa"
    var onAdd: (ComandaItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var itemName: String = ""
    @State private var unitPriceText: String = ""
    @State private var quantity: Int = 1

    private var parsedUnitPrice: Double {
        let cleaned = unitPriceText
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned) ?? 0
    }

    private var multipliedTotal: Double {
        parsedUnitPrice * Double(max(1, quantity))
    }

    private var canConfirm: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedUnitPrice > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Topo 100% flat branco com X e ✓
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text(title)
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(
                    icon: "checkmark",
                    bgColor: canConfirm ? JuntoColors.primary : JuntoColors.surfaceSubtle,
                    fgColor: canConfirm ? .white : JuntoColors.textLight
                ) {
                    confirmItem()
                }
                .disabled(!canConfirm)
            }
            .padding(.top, 14)

            CleanOutlineInput(
                label: "Descrição",
                placeholder: "Ex: Mercado, Bebidas, Picanha, Uber",
                text: $itemName
            )

            HStack(alignment: .bottom, spacing: 14) {
                // Quantidade
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quantidade")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)

                    HStack(spacing: 12) {
                        Button {
                            if quantity > 1 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                quantity -= 1
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(quantity > 1 ? JuntoColors.textMain : JuntoColors.textLight)
                                .frame(width: 32, height: 32)
                                .background(JuntoColors.surfaceSubtle)
                                .clipShape(Circle())
                        }
                        .disabled(quantity <= 1)

                        Text("\(quantity)")
                            .font(.inter(16, weight: .semibold))
                            .foregroundColor(JuntoColors.textMain)
                            .frame(minWidth: 26)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()

                        Button {
                            if quantity < 99 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                quantity += 1
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(JuntoColors.primary)
                                .clipShape(Circle())
                        }
                    }
                    .frame(height: 48)
                }

                // Valor unitário
                CleanOutlineInput(
                    label: "Valor unitário (R$)",
                    placeholder: "0,00",
                    text: $unitPriceText,
                    keyboardType: .decimalPad,
                    leadingPrefix: "R$"
                )
            }

            Divider().opacity(0.6)

            // Multiplicação automática em tempo real
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total do item")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Text("\(quantity) × \(JuntoStore.formatBRL(parsedUnitPrice))")
                        .font(.inter(12, weight: .medium))
                        .foregroundColor(JuntoColors.textMuted)
                }
                Spacer()
                Text(JuntoStore.formatBRL(multipliedTotal))
                    .font(.inter(22, weight: .bold))
                    .foregroundColor(multipliedTotal > 0 ? JuntoColors.primary : JuntoColors.textLight)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
        .presentationBackground(Color.white)
    }

    private func confirmItem() {
        guard canConfirm else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let clean = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = quantity > 1 ? "\(quantity)x \(JuntoStore.formatBRL(parsedUnitPrice))" : ""
        onAdd(
            ComandaItem(
                name: clean,
                detail: detail,
                price: multipliedTotal,
                isSelected: true,
                quantity: quantity,
                unitPrice: parsedUnitPrice
            )
        )
        dismiss()
    }
}

/// Modal Nativo iOS de Escaneamento de Recibos/Comandas com OCR Vision Real e Checklist Interativo (100% Flat Branco)
struct ReceiptScannerModal: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback chamado quando o usuário confirma os itens do recibo
    var onConfirmItems: ([ComandaItem], Double) -> Void

    @State private var pickedImage: UIImage? = nil
    @State private var showCameraPicker: Bool = false
    @State private var showGalleryPicker: Bool = false
    @State private var isProcessingOCR: Bool = false
    @State private var items: [ComandaItem] = []
    @State private var hasScanned: Bool = false
    @State private var showAddItemSheet: Bool = false

    private var checkedTotal: Double {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.price }
    }

    private var checkedCount: Int {
        items.filter { $0.isSelected }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Topo limpo flat (sem NavigationStack glass): X | Título | ✓
            HStack {
                PopupCloseButton { dismiss() }
                Spacer()
                Text(hasScanned ? "Itens do Recibo" : "Escanear Recibo")
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                if hasScanned {
                    CircleNavButton(
                        icon: "checkmark",
                        bgColor: checkedCount > 0 ? JuntoColors.primary : JuntoColors.surfaceSubtle,
                        fgColor: checkedCount > 0 ? .white : JuntoColors.textLight
                    ) {
                        let selectedItems = items.filter { $0.isSelected }
                        onConfirmItems(selectedItems, checkedTotal)
                        dismiss()
                    }
                    .disabled(checkedCount == 0)
                } else {
                    Color.clear.frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color.white)

            Divider().opacity(0.6)

            if isProcessingOCR {
                processingView
            } else if !hasScanned {
                initialCaptureView
            } else {
                scannedItemsChecklistView
            }
        }
        .background(Color.white.ignoresSafeArea())
        .presentationBackground(Color.white)
        .sheet(isPresented: $showCameraPicker) {
            CameraReceiptPicker(selectedImage: $pickedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showGalleryPicker) {
            CameraReceiptPicker(selectedImage: $pickedImage, sourceType: .photoLibrary)
                .ignoresSafeArea()
        }
        .onChange(of: pickedImage) { _, newImg in
            if let img = newImg {
                processImage(img)
            }
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddExpenseItemSheet(title: "Adicionar item") { newItem in
                items.append(newItem)
            }
            .presentationDetents([.height(340)])
            .presentationCornerRadius(24)
            .presentationBackground(Color.white)
        }
    }

    // MARK: - Estado 1: Opções de Captura Inicial (Ilustração flat oficial + sem botão manual)
    private var initialCaptureView: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 10) {
                Image("ReceiptScanHero")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 215)

                Text("Escanear recibo ou comanda")
                    .font(.inter(20, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)

                Text("Tire uma foto nítida ou escolha da galeria para ler automaticamente a descrição, quantidade e valores reais.")
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    showCameraPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Tirar foto do recibo")
                            .font(.inter(15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(JuntoColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    showGalleryPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16))
                        Text("Escolher foto da galeria")
                            .font(.inter(15, weight: .medium))
                    }
                    .foregroundColor(JuntoColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(JuntoColors.primary, lineWidth: 1.2)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Estado 2: Processamento OCR Real
    private var processingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
                .tint(JuntoColors.primary)

            Text("Lendo texto real do recibo...")
                .font(.inter(16, weight: .medium))
                .foregroundColor(JuntoColors.textMain)

            Text("Identificando descrições, quantidades e valores")
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Estado 3: Checklist Interativo de Itens
    private var scannedItemsChecklistView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total selecionado (\(checkedCount)/\(items.count) itens)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Text(JuntoStore.formatBRL(checkedTotal))
                        .font(.inter(22, weight: .semibold))
                        .foregroundColor(JuntoColors.pixGreen)
                }

                Spacer()

                Button {
                    showAddItemSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(JuntoColors.primary)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)

            Divider().opacity(0.6)

            if items.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image("ReceiptScanHero")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 165)
                    Text("Nenhum valor legível encontrado")
                        .font(.inter(16, weight: .semibold))
                        .foregroundColor(JuntoColors.textMain)
                    Text("Tente uma foto mais próxima e bem iluminada do recibo.")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(items.indices, id: \.self) { idx in
                            itemChecklistRow(at: idx)
                            Divider().padding(.leading, 56)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }

            Divider().opacity(0.6)

            VStack(spacing: 8) {
                Button {
                    pickedImage = nil
                    hasScanned = false
                    items = []
                } label: {
                    Text("Escanear outra foto")
                        .font(.inter(14, weight: .medium))
                        .foregroundColor(JuntoColors.primary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private func itemChecklistRow(at index: Int) -> some View {
        let item = items[index]

        return HStack(alignment: .center, spacing: 12) {
            Button {
                items[index].isSelected.toggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(item.isSelected ? JuntoColors.primary : JuntoColors.textLight)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Descrição do item", text: $items[index].name)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(item.isSelected ? JuntoColors.textMain : JuntoColors.textMuted)

                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Button {
                            if items[index].quantity > 1 {
                                items[index].quantity -= 1
                                items[index].price = items[index].unitPrice * Double(items[index].quantity)
                                items[index].detail = items[index].quantity > 1 ? "\(items[index].quantity)x \(JuntoStore.formatBRL(items[index].unitPrice))" : ""
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 14))
                                .foregroundColor(JuntoColors.textMuted)
                        }

                        Text("\(items[index].quantity)x")
                            .font(.inter(13, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)

                        Button {
                            items[index].quantity += 1
                            items[index].price = items[index].unitPrice * Double(items[index].quantity)
                            items[index].detail = "\(items[index].quantity)x \(JuntoStore.formatBRL(items[index].unitPrice))"
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14))
                                .foregroundColor(JuntoColors.textMuted)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(JuntoColors.surfaceSubtle)
                    .clipShape(Capsule())

                    Text("(\(JuntoStore.formatBRL(items[index].unitPrice)) un)")
                        .font(.inter(11, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(JuntoStore.formatBRL(item.price))
                    .font(.inter(15, weight: .semibold))
                    .foregroundColor(item.isSelected ? JuntoColors.textMain : JuntoColors.textLight)

                Button {
                    items.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(JuntoColors.textLight)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(item.isSelected ? Color.clear : JuntoColors.surfaceSubtle.opacity(0.3))
    }

    private func processImage(_ image: UIImage) {
        isProcessingOCR = true
        Task {
            let recognized = await ReceiptOCRService.shared.recognizeReceipt(from: image)
            await MainActor.run {
                self.items = recognized
                self.isProcessingOCR = false
                self.hasScanned = true
            }
        }
    }
}
