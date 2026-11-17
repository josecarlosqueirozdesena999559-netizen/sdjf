import Foundation

struct LegalDocument: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let version: String
    let content: String
}

enum LegalContent {
    static let currentVersion = "1.0.0"

    static let documents: [LegalDocument] = [
        LegalDocument(
            id: "terms",
            title: "Termos de Uso",
            subtitle: "Condições gerais de utilização do serviço",
            iconName: "doc.text.fill",
            version: currentVersion,
            content: """
            TERMOS DE USO — VERSÃO \(currentVersion)

            1. Elegibilidade
            Este serviço é destinado exclusivamente a pessoas com 18 anos completos ou mais. A validação definitiva de elegibilidade e identidade é realizada no servidor no momento da integração com os serviços de backend.

            2. Conta e Responsabilidades
            Você é responsável por manter a confidencialidade das suas credenciais e pela veracidade das informações publicadas em seu perfil, incluindo fotos e descrição pessoal.

            3. Uso Adequado
            Não é permitido utilizar a plataforma para assédio, fraude, spam, divulgação comercial não autorizada ou compartilhamento de conteúdo ilegal.

            4. Encerramento
            Você pode encerrar sua conta a qualquer momento. Podemos suspender contas que violem estes Termos ou as Regras de Convivência.
            """
        ),
        LegalDocument(
            id: "privacy",
            title: "Política de Privacidade",
            subtitle: "Como tratamos seus dados pessoais e permissões",
            iconName: "hand.raised.fill",
            version: currentVersion,
            content: """
            POLÍTICA DE PRIVACIDADE — VERSÃO \(currentVersion)

            1. Dados Coletados
            Coletamos apenas os dados necessários para o funcionamento do perfil e das conexões: nome, e-mail, nome de usuário, data de nascimento, fotos, interesses e descrição.

            2. Localização
            A permissão de localização (quando autorizada durante o uso do aplicativo) é utilizada exclusivamente para calcular distância aproximada e sugerir pessoas próximas.

            3. Notificações
            As notificações informam sobre novos matches, mensagens e interações relevantes. Você pode gerenciar essa permissão nos Ajustes do iOS a qualquer momento.

            4. Seus Direitos
            Você pode revisar, atualizar ou solicitar a exclusão dos seus dados pessoais conforme a legislação aplicável (LGPD).
            """
        ),
        LegalDocument(
            id: "community",
            title: "Regras de Convivência",
            subtitle: "Respeito, autenticidade e boas práticas",
            iconName: "person.2.fill",
            version: currentVersion,
            content: """
            REGRAS DE CONVIVÊNCIA

            1. Respeito em Primeiro Lugar
            Trate todas as pessoas com cordialidade. Discurso de ódio, discriminação ou ofensas não são tolerados.

            2. Autenticidade
            Use fotos reais e recentes suas. Perfis falsos ou que se passem por terceiros serão removidos.

            3. Consentimento
            Respeite os limites e decisões das outras pessoas em todas as interações e conversas.
            """
        ),
        LegalDocument(
            id: "safety",
            title: "Diretrizes de Segurança",
            subtitle: "Recomendações para interações e encontros",
            iconName: "checkmark.shield.fill",
            version: currentVersion,
            content: """
            DIRETRIZES DE SEGURANÇA

            1. Proteja Informações Sensíveis
            Evite compartilhar dados financeiros, documentos, senhas ou endereço residencial nas primeiras conversas.

            2. Encontros Presenciais
            Caso decida conhecer alguém pessoalmente, prefira locais públicos e movimentados e avise uma pessoa de confiança.

            3. Denúncias e Bloqueios
            Utilize as ferramentas de bloqueio ou denúncia sempre que notar qualquer comportamento suspeito ou inadequado.
            """
        )
    ]
}
