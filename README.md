# Aplicativo de Relacionamento iOS (SwiftUI • iOS 17+)

Estrutura modular em **Swift + SwiftUI nativo (MVVM)**, sem nome, logotipo ou identidade de marca definitiva nesta etapa (espaços reservados em `Resources/BrandPlaceholder.swift`).

## Estrutura de Pastas

- `App/` — Ponto de entrada (`DatingApp.swift`) e estado global (`AppState.swift`).
- `Models/` — Modelos de domínio (`UserProfile`, `Interest`, `MatchItem`, `Conversation`, `ChatMessage`).
- `Views/` — Telas separadas por módulo (`Onboarding/` e `Main/`).
- `ViewModels/` — `OnboardingViewModel`, `DiscoverViewModel`, `ChatViewModel`.
- `Components/` — Componentes reutilizáveis (`GlassModifiers`, `PrimaryButton`, `MinimalTextField`, `InterestChip`, `PhotoGalleryView`, `SwipeableProfileCard`, `TopSegmentedNav`, `FloatingTabBar`).
- `Services/` — Protocolos prontos para backend (`ServiceProtocols.swift`), implementações locais de demonstração (`MockServices.swift`) e permissões nativas (`PermissionService.swift`).
- `Resources/` — Paleta e tipografia (`Theme.swift`), espaços reservados de marca (`BrandPlaceholder.swift`), documentos legais (`LegalContent.swift`) e `Info.plist`.
- `Utilities/` — `Color+Hex.swift`, `Date+Age.swift`, `Validators.swift`.

## Como abrir no Xcode (macOS)

1. **Com XcodeGen** (recomendado):
   ```bash
   brew install xcodegen
   cd ProjetoRelacionamento_iOS
   xcodegen generate
   open ProjetoRelacionamento.xcodeproj
   ```
2. **Manualmente no Xcode**:
   - Crie um novo projeto **iOS App** (Interface: SwiftUI, Language: Swift, Minimum Deployment: iOS 17.0).
   - Substitua os arquivos padrão pelas pastas `App/`, `Models/`, `Views/`, `ViewModels/`, `Components/`, `Services/`, `Resources/` e `Utilities/`.
   - Configure `Resources/Info.plist` nas propriedades de build para incluir as descrições de `NSLocationWhenInUseUsageDescription` e `NSPhotoLibraryUsageDescription`.

- Como este projeto usa `project.yml`, o arquivo `codemagic.yaml` já está configurado na raiz para gerar o `.xcodeproj` com o XcodeGen e compilar no macOS da nuvem.

## Codemagic (CI/CD na nuvem)

O arquivo [codemagic.yaml](codemagic.yaml) possui dois workflows prontos:

1. **`ios-simulator-build`** *(sem necessidade de conta Apple Developer)*:
   - Instala o `xcodegen` (caso necessário), gera o `ProjetoRelacionamento.xcodeproj` e compila para Simulador iOS (`CODE_SIGNING_ALLOWED=NO`).
2. **`ios-release-ipa`** *(para TestFlight / App Store)*:
   - Requer configurar a integração `app_store_connect` e o `bundle_identifier` definitivo no Codemagic.

### Passos para usar no Codemagic:
1. Suba a pasta `ProjetoRelacionamento_iOS` como raiz de um repositório Git (GitHub, GitLab ou Bitbucket).
2. No painel do Codemagic, conecte o repositório e selecione **Use `codemagic.yaml`**.
3. Execute o workflow **`ios-simulator-build`** para validar a compilação do projeto iOS.

## Observações de Segurança e Backend

- As validações locais (disponibilidade de nome de usuário, idade 18+, aceite de termos) existem para experiência de interface. A validação definitiva, autenticação, persistência e upload de mídia devem ser integrados no servidor através dos protocolos em `Services/ServiceProtocols.swift`.
