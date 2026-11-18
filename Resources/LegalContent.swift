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
            subtitle: "Condições gerais, elegibilidade e responsabilidades",
            iconName: "doc.text.fill",
            version: currentVersion,
            content: """
            TERMOS DE USO — VERSÃO \(currentVersion)

            1. Objeto e Aceitação
            Estes Termos de Uso regulam o acesso e a utilização deste aplicativo de relacionamento e comunicação em tempo real. Ao marcar a caixa de aceite e concluir o cadastro, você declara ter lido, compreendido e concordado integralmente com estas disposições, registrando-se eletronicamente a versão e a data do aceite.

            2. Elegibilidade e Maioridade (18+)
            O uso da plataforma é estritamente restrito a pessoas naturais com 18 (dezoito) anos completos ou mais, plenamente capazes nos termos da legislação civil brasileira. A validação definitiva da data de nascimento e da elegibilidade é realizada nos servidores da plataforma. Contas com indício de menoridade ou fraude etária serão imediatamente bloqueadas e encerradas.

            3. Cadastro, Veracidade e Segurança da Conta
            Para criar uma conta, você deverá fornecer nome completo, endereço de e-mail válido, nome de usuário único e senha pessoal. Suas credenciais são individuais e intransferíveis. Você é integralmente responsável pela veracidade das informações publicadas em seu perfil, incluindo fotografias, biografia e interesses, sendo vedada a criação de perfis falsos ou em nome de terceiros.

            4. Funcionalidades da Plataforma
            O aplicativo disponibiliza descoberta de perfis compatíveis por proximidade aproximada e interesses, envio de curtidas e destaques, formação de matches mútuos e troca de mensagens em tempo real entre usuários com match ativo. Não há cobrança obrigatória ou bloqueio artificial das funcionalidades essenciais de conexão.

            5. Condutas Proibidas
            É expressamente proibido utilizar o serviço para:
            a) assédio, intimidação, perseguição, ameaça ou discurso de ódio;
            b) envio de spam, golpes financeiros, solicitação de transferências ou divulgação comercial não autorizada;
            c) publicação de conteúdo ilegal, violento, pornográfico não consensual ou que viole direitos de terceiros;
            d) tentativa de engenharia reversa, automação abusiva ou contornar mecanismos de segurança e bloqueio.

            6. Moderação, Bloqueio e Encerramento
            Qualquer usuário pode bloquear outros perfis ou desfazer matches a qualquer momento, interrompendo imediatamente o envio de mensagens e a exibição mútua na descoberta. A plataforma poderá suspender ou encerrar contas que violem estes Termos ou as Regras de Convivência, bem como preservar registros pelo prazo legal em caso de ordem judicial.

            7. Foro e Legislação Aplicável
            Estes Termos são regidos pelas leis da República Federativa do Brasil, em especial pelo Marco Civil da Internet (Lei nº 12.965/2014) e pela Lei Geral de Proteção de Dados (Lei nº 13.709/2018).
            """
        ),
        LegalDocument(
            id: "privacy",
            title: "Política de Privacidade",
            subtitle: "Tratamento de dados pessoais conforme LGPD e ANPD",
            iconName: "hand.raised.fill",
            version: currentVersion,
            content: """
            POLÍTICA DE PRIVACIDADE — VERSÃO \(currentVersion)

            Esta Política de Privacidade descreve como coletamos, utilizamos, armazenamos e protegemos seus dados pessoais em conformidade com a Lei Geral de Proteção de Dados Pessoais (LGPD — Lei nº 13.709/2018), as orientações da Autoridade Nacional de Proteção de Dados (ANPD) e o Marco Civil da Internet (Lei nº 12.965/2014).

            1. Dados Pessoais Tratados
            Tratamos exclusivamente os dados necessários à prestação do serviço:
            • Dados cadastrais: nome completo, e-mail, nome de usuário, data de nascimento e senha (armazenada com hash criptográfico Argon2id, jamais em texto puro);
            • Dados de perfil: fotografias enviadas por você (máximo de 6), biografia e interesses selecionados;
            • Dados de interação: curtidas, matches, mensagens enviadas no chat, bloqueios, denúncias e notificações;
            • Dados técnicos e registros de acesso: endereço IP, agente de usuário, data e hora UTC das operações relevantes.

            2. Segurança e Criptografia das Mensagens
            Todas as comunicações entre o aplicativo e os servidores ocorrem por canais criptografados (HTTPS/TLS e WebSocket seguro). Adicionalmente, o conteúdo das mensagens de chat é armazenado em repouso no banco de dados utilizando criptografia autenticada AES-256-GCM, protegendo o sigilo das conversas contra acessos indevidos.

            3. Localização Aproximada
            Quando autorizada por você durante o uso do aplicativo, sua localização é processada no servidor apenas para calcular a distância aproximada (em quilômetros) e sugerir pessoas próximas na tela de descoberta. Coordenadas exatas de outros usuários nunca são expostas na interface ou nas respostas públicas da API.

            4. Prazos de Retenção e Requisição Judicial
            Os registros de acesso à aplicação são mantidos sob sigilo, em ambiente controlado e seguro, pelo prazo mínimo de 6 (seis) meses (180 dias), em cumprimento ao artigo 15 do Marco Civil da Internet e ao artigo 16, inciso I, da LGPD. Em caso de solicitação de exclusão de conta, seu perfil é imediatamente desativado e removido da descoberta, mantendo-se os registros mínimos sob retenção legal segura até o término do prazo aplicável ou eventual determinação judicial (legal hold).

            5. Direitos do Titular (LGPD Art. 18)
            Você pode exercer seus direitos de confirmação de tratamento, acesso, correção, portabilidade (exportação de dados) e eliminação diretamente pelos recursos do aplicativo e endpoints dedicados da plataforma.
            """
        ),
        LegalDocument(
            id: "community",
            title: "Regras de Convivência",
            subtitle: "Respeito, autenticidade e boas práticas na comunidade",
            iconName: "person.2.fill",
            version: currentVersion,
            content: """
            REGRAS DE CONVIVÊNCIA

            Nosso objetivo é oferecer um ambiente leve, transparente e respeitoso para novas conexões. O cumprimento destas regras é obrigatório para todos os participantes:

            1. Respeito Mútuo
            Comunique-se com educação e empatia. Não toleramos ofensas, assédio, perseguição, intimidação ou qualquer forma de discriminação por origem, raça, gênero, orientação sexual, religião ou condição física.

            2. Autenticidade nas Fotos e Perfil
            Utilize fotografias reais e recentes em que você apareça claramente. Perfis criados com fotos de terceiros, celebridades, imagens enganosas ou contas automatizadas serão suspensos.

            3. Consentimento e Limites
            Respeite quando alguém não corresponder ao seu interesse ou optar por encerrar uma conversa. Se receber uma recusa ou bloqueio, não tente contatar a pessoa por outros meios sem consentimento.

            4. Uso Pessoal e Não Comercial
            A plataforma destina-se exclusivamente a relacionamentos pessoais. É proibida a divulgação de produtos, serviços, links externos promocionais, perfis de vendas ou captação financeira.
            """
        ),
        LegalDocument(
            id: "safety",
            title: "Diretrizes de Segurança",
            subtitle: "Boas práticas para conversas e encontros presenciais",
            iconName: "checkmark.shield.fill",
            version: currentVersion,
            content: """
            DIRETRIZES DE SEGURANÇA

            Sua segurança é prioridade. Adote sempre estas recomendações ao interagir com novas pessoas:

            1. Proteja Seus Dados Sensíveis
            Nunca compartilhe senhas, códigos de verificação, dados bancários, chave Pix, documentos pessoais ou endereço residencial/profissional nas primeiras conversas.

            2. Desconfie de Pedidos Financeiros
            Jamais envie dinheiro, presentes de alto valor ou informações financeiras para pessoas conhecidas no aplicativo, independentemente da justificativa apresentada. Utilize a ferramenta de denúncia imediatamente caso isso ocorra.

            3. Encontros Presenciais Seguros
            • Marque os primeiros encontros em locais públicos, iluminados e movimentados;
            • Utilize transporte próprio ou por aplicativo sob seu controle na ida e na volta;
            • Informe a um familiar ou amigo próximo onde você estará e com quem se encontrará.

            4. Bloqueio e Denúncia Imediatos
            Caso identifique comportamento suspeito, desrespeitoso ou inadequado, utilize imediatamente as opções de bloquear usuário e denunciar perfil ou mensagem disponíveis no aplicativo.
            """
        )
    ]
}
