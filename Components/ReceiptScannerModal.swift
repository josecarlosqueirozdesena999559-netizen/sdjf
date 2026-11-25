import SwiftUI
import PhotosUI

/// Modal Nativo iOS de Escaneamento de Recibos/Comandas com OCR Vision e Checklist Interativo
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

    // Novo item manual
    @State private var newName: String = ""
    @State private var newPriceText: String = ""
    @State private var newQuantity: Int = 1

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
                        bgColor: checkedCount > 0 ? JuntoColors.primary : JuntoColors.border,
                        fgColor: .white
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
            addItemSheet
                .presentationDetents([.height(340)])
                .presentationCornerRadius(24)
                .presentationBackground(Color.white)
        }
    }

    // MARK: - Estado 1: Opções de Captura Inicial
    private var initialCaptureView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(JuntoColors.surfaceSubtle)
                        .frame(width: 90, height: 90)

                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 42, weight: .light))
                        .foregroundColor(JuntoColors.primary)
                }

                Text("Escanear recibo ou comanda")
                    .font(.inter(20, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)

                Text("Tire uma foto ou escolha da galeria. O OCR nativo do iOS detecta automaticamente os itens, quantidades e valores para dividir no grupo.")
                    .font(.inter(14, weight: .regular))
                    .foregroundColor(JuntoColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                // Botão Câmera
                Button {
                    showCameraPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Tirar foto da comanda")
                            .font(.inter(15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(JuntoColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Botão Galeria
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
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(JuntoColors.primary, lineWidth: 1.2)
                    )
                }

                // Atalho para testar amostra de recibo (ideal para testes no simulador)
                Button {
                    items = ReceiptOCRService.shared.fallbackSampleItems()
                    hasScanned = true
                } label: {
                    Text("Usar recibo de exemplo para testar")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Estado 2: Processamento OCR
    private var processingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
                .tint(JuntoColors.primary)

            Text("Lendo recibo com OCR Vision...")
                .font(.inter(16, weight: .medium))
                .foregroundColor(JuntoColors.textMain)

            Text("Identificando nomes dos itens, quantidades e valores")
                .font(.inter(13, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Estado 3: Checklist Interativo de Itens
    private var scannedItemsChecklistView: some View {
        VStack(spacing: 0) {
            // Resumo do Checklist no topo
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total selecionado (\(checkedCount)/\(items.count) itens)")
                        .font(.inter(12, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)

                    Text(JuntoStore.formatBRL(checkedTotal))
                        .font(.inter(22, weight: .medium))
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

            Divider()

            // Lista de itens do checklist
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { idx in
                        itemChecklistRow(at: idx)
                        Divider().padding(.leading, 56)
                    }
                }
                .padding(.bottom, 24)
            }

            Divider()

            // Rodapé com botão de confirmação
            VStack(spacing: 8) {
                JuntoPillButton(
                    title: "Usar \(checkedCount) itens (\(JuntoStore.formatBRL(checkedTotal)))",
                    color: JuntoColors.primary
                ) {
                    let selectedItems = items.filter { $0.isSelected }
                    onConfirmItems(selectedItems, checkedTotal)
                    dismiss()
                }
                .disabled(checkedCount == 0)

                Button {
                    pickedImage = nil
                    hasScanned = false
                    items = []
                } label: {
                    Text("Escanear outro recibo")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    private func itemChecklistRow(at index: Int) -> some View {
        let item = items[index]

        return HStack(alignment: .center, spacing: 12) {
            // Checkbox
            Button {
                items[index].isSelected.toggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(item.isSelected ? JuntoColors.primary : JuntoColors.textLight)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Nome editável
                TextField("Nome do item", text: $items[index].name)
                    .font(.inter(15, weight: .medium))
                    .foregroundColor(item.isSelected ? JuntoColors.textMain : JuntoColors.textMuted)

                // Quantidade stepper e preço unitário
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

                    if items[index].quantity > 1 {
                        Text("(\(JuntoStore.formatBRL(items[index].unitPrice)) cada)")
                            .font(.inter(11, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                    }
                }
            }

            Spacer(minLength: 8)

            // Preço total do item
            VStack(alignment: .trailing, spacing: 4) {
                Text(JuntoStore.formatBRL(item.price))
                    .font(.inter(15, weight: .medium))
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

    // Modal limpo flat (sem glass) para adicionar item manualmente com X e ✓
    private var addItemSheet: some View {
        let parsedPrice = Double(newPriceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let canAdd = !newName.trimmingCharacters(in: .whitespaces).isEmpty && parsedPrice > 0

        return VStack(spacing: 16) {
            HStack {
                PopupCloseButton { showAddItemSheet = false }
                Spacer()
                Text("Adicionar item")
                    .font(.inter(17, weight: .semibold))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                CircleNavButton(
                    icon: "checkmark",
                    bgColor: canAdd ? JuntoColors.primary : JuntoColors.border,
                    fgColor: .white
                ) {
                    guard canAdd else { return }
                    let u = parsedPrice / Double(max(1, newQuantity))
                    let detail = newQuantity > 1 ? "\(newQuantity)x \(JuntoStore.formatBRL(u))" : ""
                    items.append(
                        ComandaItem(
                            name: newName.trimmingCharacters(in: .whitespaces).capitalized,
                            detail: detail,
                            price: parsedPrice,
                            isSelected: true,
                            quantity: newQuantity,
                            unitPrice: u
                        )
                    )
                    newName = ""
                    newPriceText = ""
                    newQuantity = 1
                    showAddItemSheet = false
                }
                .disabled(!canAdd)
            }
            .padding(.top, 14)

            CleanOutlineInput(label: "Nome do item", placeholder: "Ex: Cerveja, Picanha, Refrigerante", text: $newName)

            HStack(spacing: 12) {
                CleanOutlineInput(label: "Valor total (R$)", placeholder: "0,00", text: $newPriceText, keyboardType: .decimalPad, leadingPrefix: "R$")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Quantidade")
                        .font(.inter(13, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                    Stepper(value: $newQuantity, in: 1...99) {
                        Text("\(newQuantity) un")
                            .font(.inter(14, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                    }
                    .frame(height: 50)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.white.ignoresSafeArea())
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
