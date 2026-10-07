# Apurabra para iOS

Aplicativo nativo em SwiftUI, sem login ou cadastro, conectado às APIs do Apurabra em `https://kdfsd.vercel.app`.

## Requisitos

- macOS com Xcode 15 ou mais recente
- iOS 17 ou mais recente

## Abrir no Xcode

1. Abra `MercadoFacil.xcodeproj` diretamente no Xcode.
2. Selecione o alvo **Apurabra**.
3. Em **Signing & Capabilities**, selecione sua equipe Apple.
4. Escolha um simulador ou iPhone e execute.

O identificador padrão é `br.com.apurabra.app`. O arquivo `project.yml` está incluído apenas como alternativa para regenerar o projeto com XcodeGen.

## Telas

- Resultados: Presidente, Governador, Senador, Deputados, Brasil, UF e município.
- Mapa: SVG real do Brasil, siglas, Presidente/Governador, candidatos e cor do líder.
- Candidatos: candidaturas por UF e cargo, com fotos.
- Sobre: caráter independente, fonte TSE e Instagram.

## Arquitetura

- SwiftUI, `NavigationStack` e `TabView`
- `URLSession` com `async/await`
- modelos `Codable`
- cache HTTP do sistema
- mesma logo e App Icon do Apurabra
- nenhuma autenticação e nenhum dado pessoal coletado

O aplicativo apresenta os dados disponíveis da fonte TSE via API do Apurabra — incluindo seções totalizadas, horário da atualização, candidatos e fotos. Os votos e percentuais só são exibidos quando há dados de apuração.

## Assinatura preservada

O projeto mantém o bundle `com.achou.com`, versão 1.0.12 e build 113. O nome exibido no aparelho é Apurabra.
