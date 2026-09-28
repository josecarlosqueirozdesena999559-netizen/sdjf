const fs = require('fs');
let content = fs.readFileSync('Views/Product/EditProductView.swift', 'utf8');

content = content.replace(/Fotos e V.*?deos/g, 'Fotos e Vídeos');
content = content.replace(/Pre.*?o do Produto/g, 'Preço do Produto');
content = content.replace(/T.*?tulo/g, 'Título');
content = content.replace(/Ex: iPhone 13 128GB impec.*?vel/g, 'Ex: iPhone 13 128GB impecável');
content = content.replace(/Descri.*?o/g, 'Descrição');
content = content.replace(/Estado de conserva.*?o/g, 'Estado de conservação');
content = content.replace(/Localiza.*?o/g, 'Localização');
content = content.replace(/Ex: S.*?o Paulo - SP/g, 'Ex: São Paulo - SP');
content = content.replace(/Aceita negocia.*?o\?/g, 'Aceita negociação?');
content = content.replace(/Publicar An.*?ncio/g, 'Publicar Anúncio');
content = content.replace(/Altera.*?es salvas!/g, 'Alterações salvas!');
content = content.replace(/Editar An.*?ncio/g, 'Editar Anúncio');

const regex = /    var body: some View \{[\s\S]*?    @ViewBuilder private var mediaSection: some View/;
const newBody =     @AppStorage("hideFloatingButton") private var hideFloatingButton = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                mediaSection
                priceSection
                mainInfoSection
                Spacer(minLength: 40)
            }
        }
        .background(Color.white)
        .navigationTitle("Editar Anúncio")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomButton }
        .onChange(of: selectedItems) { _, newItems in
            loadMedia(from: newItems)
        }
        .overlay(loadingOverlay)
        .onChange(of: viewModel.publishSuccess) { _, success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                    onPublishSuccess?()
                }
            }
        }
        .alert("Erro", isPresented: Binding<Bool>(
            get: { viewModel.publishError != nil },
            set: { if !0 { viewModel.publishError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.publishError ?? "Erro desconhecido")
        }
        .onAppear { hideFloatingButton = true }
        .onDisappear { hideFloatingButton = false }
    }
    
    @ViewBuilder private var mediaSection: some View;

content = content.replace(regex, newBody);

fs.writeFileSync('Views/Product/EditProductView.swift', content, 'utf8');
