import SwiftUI

struct WelcomeAuthView: View {
    @EnvironmentObject var store: JuntoStore

    enum WelcomeLegalPopup: Identifiable {
        case terms
        case privacy
        case contact

        var id: Int { hashValue }
    }

    @State private var activePopup: WelcomeLegalPopup? = nil

    var body: some View {
        ZStack {
            JuntoColors.warmBg.ignoresSafeArea()

            // Ondas presas no rodapé real da tela (cobre a safe area, sem faixa branca)
            VStack(spacing: 0) {
                Spacer()
                JuntoBottomWaves()
                    .frame(height: 150)
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    JuntoLogoMark(size: 88)

                    Text("Juntô")
                        .font(.inter(28, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("Divida rolês, viagens e contas\nsem estresse.")
                        .font(.inter(15, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 52)

                VStack(spacing: 12) {
                    JuntoPillButton(title: "Entrar", color: JuntoColors.primary) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .login
                        }
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            store.route = .registerFlow
                        }
                    } label: {
                        Text("Cadastre-se")
                            .font(.inter(16, weight: .semibold))
                            .foregroundColor(JuntoColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(JuntoColors.primary, lineWidth: 1.4)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(JuntoTapBounceStyle(scaleAmount: 0.97))
                }
                .padding(.horizontal, 32)

                // Links reais clicáveis que abrem popups com X no topo para fechar
                HStack(spacing: 10) {
                    Button {
                        activePopup = .terms
                    } label: {
                        Text("Termos").underline()
                    }

                    Text("·")

                    Button {
                        activePopup = .privacy
                    } label: {
                        Text("Privacidade").underline()
                    }

                    Text("·")

                    Button {
                        activePopup = .contact
                    } label: {
                        Text("Fale conosco").underline()
                    }
                }
                .font(.inter(12, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .padding(.top, 24)

                Spacer()
                Spacer().frame(height: 150)
            }
        }
        .sheet(item: $activePopup) { popup in
            switch popup {
            case .terms:
                TermsOfUsePopupSheet()
                    .presentationDetents([.large])
                    .presentationCornerRadius(20)
            case .privacy:
                PrivacyPolicyPopupSheet()
                    .presentationDetents([.large])
                    .presentationCornerRadius(20)
            case .contact:
                ContactUsPopupSheet()
                    .environmentObject(store)
                    .presentationDetents([.large])
                    .presentationCornerRadius(20)
            }
        }
    }
}

// MARK: - 1. Popup Termos de Uso Completos e Detalhados (Com botão X no topo para sair)
struct TermsOfUsePopupSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Barra Superior Fixa com Botão X para sair
            HStack {
                Text("Termos e Condições de Uso")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 34, height: 34)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color.white)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Termos e Condições Gerais de Uso da Plataforma Juntô")
                            .font(.inter(19, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Vigência: 23 de novembro de 2026 · Versão 1.2 Oficial")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text("Instrumento regido pela Lei Federal nº 10.406/2002 (Código Civil Brasileiro), Lei Federal nº 8.078/1990 (Código de Defesa do Consumidor – CDC), Lei Federal nº 12.965/2014 (Marco Civil da Internet) e Lei Federal nº 13.709/2018 (Lei Geral de Proteção de Dados Pessoais – LGPD).")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .lineSpacing(3)
                            .padding(.top, 2)
                    }

                    Divider()

                    legalClause(
                        title: "Cláusula 1ª — Objeto e Natureza Tecnológica da Plataforma",
                        content: """
1.1. O aplicativo Juntô (“Plataforma”) consiste em um software de gestão compartilhada de despesas, rateio de contas em grupos, organização de potes coletivos (meta única ou mensalidades para excursões), controle de caixinhas financeiras pessoais e comunicação instantânea entre usuários cadastrados.

1.2. Nos termos da Lei Federal nº 12.865/2013 e das normas do Banco Central do Brasil (BACEN), o Juntô declara expressamente que NÃO é instituição financeira, NÃO atua como instituição de pagamento ou custodiante de recursos de terceiros, e NÃO retém nem movimenta valores bancários dos usuários em contas próprias.

1.3. Todas as liquidações via arranjo de pagamento instantâneo (Pix) ocorrem diretamente entre as contas bancárias ou de pagamento de titularidade dos próprios usuários (modelo Peer-to-Peer – P2P) ou mediante integração oficial autorizada pelo titular. A Plataforma fornece exclusivamente a infraestrutura tecnológica de cálculo de cotas, geração de payload EMV® QRCPS-MPM (QR Code Pix Estático/Copia e Cola) com base na chave Pix informada pelo organizador e registro das confirmações de pagamento.
"""
                    )

                    legalClause(
                        title: "Cláusula 2ª — Elegibilidade, Cadastro e Segurança da Conta",
                        content: """
2.1. O cadastro na Plataforma é permitido a pessoas físicas maiores de 18 (dezoito) anos plenamente capazes, ou menores entre 16 (dezesseis) e 18 (dezoito) anos devidamente assistidos por seus representantes legais, na forma dos artigos 3º, 4º e 5º do Código Civil Brasileiro (Lei nº 10.406/2002).

2.2. Para a criação da conta, o usuário compromete-se a fornecer dados verdadeiros, exatos, atuais e completos (nome completo, endereço de e-mail válido, @usuário único, telefone celular brasileiro +55 e chave Pix de sua titularidade), responsabilizando-se civil e criminalmente pela veracidade das informações prestadas (art. 299 do Código Penal).

2.3. É dever exclusivo do usuário conferir rigorosamente os caracteres da sua chave Pix no momento do cadastro ou alteração. O Juntô não responde por transferências enviadas a destinatários incorretos em decorrência de erro de digitação da chave Pix pelo próprio usuário organizador.

2.4. A senha de acesso é pessoal e intransferível, sendo armazenada sob hash criptográfico irreversível Argon2id. O usuário pode monitorar e encerrar remotamente qualquer sessão ativa na função “Dispositivos conectados”.
"""
                    )

                    legalClause(
                        title: "Cláusula 3ª — Funcionamento dos Grupos, Pote Coletivo, Pote Mensal e Caixinhas",
                        content: """
3.1. O criador de um grupo assume a função de “Dono” (organizador), podendo designar outros participantes como “Administradores”. Apenas o Dono e os Administradores possuem permissão para lançar novas despesas na comanda do grupo ou remover membros, garantindo a integridade contábil do rateio.

3.2. No módulo “Pote Coletivo” (Meta Única) e “Pote Mensal (Excursão)”, o sistema divide automaticamente a meta financeira pelo número de participantes e pelo número de meses estipulados. O indicador percentual de cada mês e da meta geral somente atinge 100% (cem por cento) quando a totalidade dos participantes tiver seus pagamentos devidamente confirmados pelo organizador.

3.3. Quando um membro realiza o pagamento via Pix e aciona o botão “Marcar como pago”, o registro permanece com status “Aguardando confirmação do dono” até que o organizador confira o crédito em seu extrato bancário e acione “Confirmar pago”.

3.4. O módulo “Potes Pessoais (Caixinhas)” funciona como ferramenta de planejamento e controle orçamentário individual, permitindo ao usuário registrar valores guardados em sua própria instituição bancária para ocasiões futuras, sem transferência de numerário para o Juntô.
"""
                    )

                    legalClause(
                        title: "Cláusula 4ª — Plano Gratuito, Assinatura Juntô Pro e Direito de Arrependimento (Art. 49 do CDC)",
                        content: """
4.1. Todas as funcionalidades de comunicação do Chat (mensagens de texto, gravação de áudio, fotos, documentos, respostas, enquetes interativas e chave Pix) e todas as modalidades de Pote (Meta Única e Pote Mensal para excursões) são 100% gratuitas. No Plano Gratuito (Normal), o usuário pode criar e manter 1 (um) grupo ativo simultaneamente.

4.2. A assinatura “Juntô Pro” (modalidade Mensal por R$ 19,90/mês ou Anual por R$ 178,80/ano) desbloqueia a criação ilimitada de grupos, viagens, rolês e excursões simultâneas, além de múltiplos administradores por grupo e alertas avançados de gestão.

4.3. A renovação da assinatura ocorre de forma automática ao final de cada ciclo contratado, salvo se cancelada pelo usuário com antecedência mínima de 24 (vinte e quatro) horas do término do período vigente, diretamente na tela “Juntô Pro” ou nas configurações de assinaturas da Apple App Store.

4.4. Em estrito cumprimento ao artigo 49 da Lei nº 8.078/1990 (Código de Defesa do Consumidor), o usuário dispõe do prazo legal de 7 (sete) dias corridos, contados da primeira contratação da assinatura Juntô Pro, para exercer seu direito de arrependimento e solicitar o reembolso integral.
"""
                    )

                    legalClause(
                        title: "Cláusula 5ª — Condutas Vedadas, Comunicações no Chat e Moderação",
                        content: """
5.1. Ao utilizar os chats individuais e de grupo (mensagens de texto, áudios, fotografias e documentos), o usuário obriga-se a respeitar a legislação brasileira vigente, sendo expressamente proibido:
a) Utilizar a Plataforma para práticas ilícitas, lavagem de dinheiro (Lei nº 9.613/1998), fraudes financeiras, pirâmides ou cobranças abusivas;
b) Transmitir conteúdo difamatório, injurioso, discriminatório, ameaçador ou que viole direitos de imagem e propriedade intelectual de terceiros;
c) Tentar violar mecanismos de autenticação, realizar engenharia reversa ou sobrecarregar servidores e APIs da Plataforma.

5.2. O Juntô disponibiliza ferramentas imediatas de autoproteção, incluindo o bloqueio de usuários, silenciamento de notificações e exclusão de mensagens para todos em até 5 (cinco) segundos ou remoção definitiva. O descumprimento destes Termos poderá acarretar a suspensão ou encerramento da conta.
"""
                    )

                    legalClause(
                        title: "Cláusula 6ª — Propriedade Intelectual e Limitação de Responsabilidade",
                        content: """
6.1. Todos os direitos sobre a marca “Juntô”, logotipos, código-fonte, interfaces visuais, arquitetura de banco de dados e algoritmos de rateio pertencem exclusivamente aos titulares da Plataforma, protegidos pela Lei nº 9.609/1998 (Lei de Software), Lei nº 9.610/1998 (Direitos Autorais) e Lei nº 9.279/1996 (Propriedade Industrial).

6.2. O Juntô não garante a adimplência dos membros de um grupo, cabendo exclusivamente aos participantes entre si a cobrança e liquidação de eventuais dívidas ou cotas pendentes de rolês, viagens, excursões ou despesas domiciliares.
"""
                    )

                    legalClause(
                        title: "Cláusula 7ª — Legislação Aplicável e Foro de Eleição",
                        content: """
7.1. Estes Termos de Uso são regidos integralmente pelas leis da República Federativa do Brasil.

7.2. Para dirimir quaisquer controvérsias oriundas deste instrumento, fica assegurado ao usuário consumidor o foro de seu domicílio, nos termos do artigo 101, inciso I, do Código de Defesa do Consumidor (Lei nº 8.078/1990).
"""
                    )
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func legalClause(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.inter(15, weight: .medium))
                .foregroundColor(JuntoColors.textMain)

            Text(content)
                .font(.inter(13.5, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 2. Popup Política de Privacidade Completa (Texto corrido limpo nativo iOS — sem retângulos)
struct PrivacyPolicyPopupSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Política de Privacidade")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 34, height: 34)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color.white)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Política de Privacidade e Proteção de Dados Pessoais")
                            .font(.inter(19, weight: .medium))
                            .foregroundColor(JuntoColors.textMain)
                        Text("Aplicativo Juntô · Versão 1.2 · Atualizada em 23 de novembro de 2026")
                            .font(.inter(12, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                        Text("Elaborada em estrita conformidade com a Lei Federal nº 13.709/2018 (Lei Geral de Proteção de Dados Pessoais – LGPD), a Lei Federal nº 12.965/2014 (Marco Civil da Internet), o Decreto Federal nº 8.771/2016 e as Resoluções da Autoridade Nacional de Proteção de Dados (ANPD).")
                            .font(.inter(13, weight: .regular))
                            .foregroundColor(JuntoColors.textMuted)
                            .lineSpacing(3)
                            .padding(.top, 2)
                    }

                    Divider()

                    privacySection(
                        title: "1. Identificação do Controlador e Princípios Norteadores (Art. 6º da LGPD)",
                        content: """
Esta Política de Privacidade regulamenta o tratamento de dados pessoais realizado pelo aplicativo Juntô (“Controlador”), observando rigorosamente os princípios da finalidade, adequação, necessidade (minimização de dados), livre acesso, qualidade dos dados, transparência, segurança, prevenção, não discriminação e responsabilização e prestação de contas (art. 6º, incisos I a X, da Lei nº 13.709/2018).
"""
                    )

                    privacySection(
                        title: "2. Categorias de Dados Pessoais Coletados e Finalidades",
                        content: """
Coletamos estritamente os dados necessários para a execução dos serviços solicitados pelo Titular:

• Dados Cadastrais e de Identificação: nome completo, endereço de e-mail, identificador único de usuário (@usuário) e número de telefone móvel (+55). Finalidade: autenticação segura, localização de amigos exclusivamente pelo @usuário, prevenção a contas falsas e envio de alertas transacionais.
• Chave Pix Cadastrada pelo Usuário: CPF, telefone, e-mail ou chave EVP informada pelo titular. Finalidade: geração local e exibição do QR Code Pix / código Copia e Cola aos membros dos grupos nos quais o titular figure como organizador. A chave Pix é armazenada no banco de dados sob criptografia autenticada AES-256-GCM.
• Dados Financeiros de Rateio e Caixinhas: valores de despesas, categorias de gastos, metas de potes coletivos (únicos ou mensais de excursões), registros de caixinhas pessoais e status de quitação de cotas.
• Comunicações no Chat e Mídia: mensagens de texto, gravações de voz (áudio), imagens e documentos enviados voluntariamente pelo usuário nas conversas individuais ou de grupos, armazenados com criptografia em repouso AES-256-GCM.
• Registros de Conexão e Sessões (Art. 15 do Marco Civil da Internet): nome do dispositivo, versão do sistema iOS, hash SHA-256 do endereço IP, data e hora de acesso. Finalidade: cumprimento de obrigação legal de guarda por 6 (seis) meses e controle de sessões na tela “Dispositivos conectados”.
"""
                    )

                    privacySection(
                        title: "3. Hipóteses Legais de Tratamento (Art. 7º da LGPD)",
                        content: """
O tratamento de dados pessoais no Juntô ampara-se nas seguintes bases legais:
• Execução de Contrato (Art. 7º, V): prestação das funcionalidades de grupos, divisão de despesas, potes mensais, caixinhas e chat em tempo real.
• Consentimento do Titular (Art. 7º, I): acesso opcional à câmera, biblioteca de fotos, microfone para envio de áudios no chat e notificações push do sistema iOS.
• Cumprimento de Obrigação Legal ou Regulatória (Art. 7º, II): manutenção dos registros de acesso a aplicações de internet pelo prazo legal de 6 meses (art. 15 da Lei nº 12.965/2014) e registros fiscais relativos a assinaturas Juntô Pro.
• Legítimo Interesse e Prevenção à Fraude (Art. 7º, IX e Art. 10): proteção da segurança das contas, controle de limite de requisições (rate limiting) e auditoria contra acessos indevidos.
"""
                    )

                    privacySection(
                        title: "4. Arquitetura de Segurança e Criptografia (Art. 46 da LGPD)",
                        content: """
Em cumprimento ao art. 46 da LGPD, empregamos padrões de segurança de nível bancário:
• Criptografia Simétrica Autenticada AES-256-GCM: telefones, chaves Pix e conteúdos de mensagens de chat são cifrados antes da gravação no banco de dados PostgreSQL, utilizando vetores de inicialização (IV) únicos de 96 bits e tags de autenticação de 128 bits.
• Hash de Senhas com Argon2id: nenhuma senha é armazenada ou trafegada em texto reversível.
• Minimização de IP por SHA-256: endereços IP nos logs de sessão e auditoria são convertidos em hash criptográfico unidirecional.
• Controle de Versão de Token em Tempo Real: ao acionar “Desconectar todos os dispositivos”, o identificador de versão de token (tokenVersion) é invalidado instantaneamente no banco PostgreSQL, no cache Redis e nas conexões WebSocket (Socket.IO).
"""
                    )

                    privacySection(
                        title: "5. Compartilhamento de Dados e Transferência Internacional (Art. 33 da LGPD)",
                        content: """
O Juntô NÃO comercializa, aluga ou compartilha dados pessoais com corretores de dados ou redes de publicidade comportamental.

Os dados são visíveis apenas para os amigos aceitos e membros dos grupos dos quais o usuário participa (nome, @usuário, foto de perfil, cotas no grupo e chave Pix do organizador no momento do pagamento). Quando aplicável na assinatura Juntô Pro, dados estritamente necessários à conciliação de pagamentos ou envio de notificações podem ser processados por parceiros homologados (Apple In-App Purchase, Mercado Pago e API Oficial WhatsApp Business), todos submetidos a cláusulas contratuais de proteção de dados compatíveis com a LGPD.
"""
                    )

                    privacySection(
                        title: "6. Exclusão da Conta, Retenção Legal de 90 Dias e Anonimização (Arts. 15 e 16 da LGPD)",
                        content: """
O usuário pode excluir sua conta a qualquer momento em Conta → Segurança e privacidade → Excluir conta.

1. Bloqueio Imediato: todas as sessões são encerradas no ato e o acesso à conta é desativado imediatamente (status PENDING_DELETION).
2. Retenção Isolada por 90 Dias: nos termos do art. 16, incisos I e IV, da LGPD, metadados essenciais de auditoria e reserva do @usuário permanecem retidos em tabela criptografada isolada por 90 (noventa) dias corridos para prevenção a fraudes, apuração de eventuais disputas Pix entre membros de grupos e cumprimento de obrigações legais.
3. Expurgo e Anonimização Definitiva: após o decurso dos 90 dias, o serviço automatizado de expurgo (lgpdPurgeJob) sobrescreve e anonimiza irreversivelmente todos os dados pessoais (status ANONYMIZED), eliminando telefone, chave Pix, nome e e-mail.
"""
                    )

                    privacySection(
                        title: "7. Direitos do Titular e Canal do Encarregado / DPO (Arts. 18 e 41 da LGPD)",
                        content: """
Garantimos o exercício gratuito e facilitado de todos os direitos previstos no art. 18 da LGPD: confirmação de tratamento, acesso, correção direta no perfil, portabilidade/exportação completa em formato estruturado JSON (endpoint /v1/account/lgpd/export), anonimização, revogação de consentimento e eliminação.

• Encarregado pelo Tratamento de Dados Pessoais (DPO): Canal oficial de atendimento disponível na seção “Fale conosco” e pelo endereço eletrônico oficial de suporte e privacidade do Juntô.
• Prazo de Atendimento: requisições de titulares são respondidas em até 15 (quinze) dias corridos, conforme a Lei nº 13.709/2018.
"""
                    )
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.inter(15, weight: .medium))
                .foregroundColor(JuntoColors.textMain)

            Text(content)
                .font(.inter(13.5, weight: .regular))
                .foregroundColor(JuntoColors.textMuted)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 3. Popup Fale Conosco Limpo (Texto institucional profissional + E-mail oficial sem botão de enviar contato)
struct ContactUsPopupSheet: View {
    @EnvironmentObject var store: JuntoStore
    @Environment(\.dismiss) private var dismiss
    @State private var copiedEmail: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Fale conosco")
                    .font(.inter(17, weight: .medium))
                    .foregroundColor(JuntoColors.textMain)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)
                        .frame(width: 34, height: 34)
                        .background(JuntoColors.surfaceSubtle)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color.white)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Canal Oficial de Atendimento, Suporte e Privacidade")
                        .font(.inter(19, weight: .medium))
                        .foregroundColor(JuntoColors.textMain)

                    Text("O Juntô disponibiliza seu canal oficial de comunicação por e-mail para atendimento aos usuários, esclarecimento de dúvidas sobre grupos, viagens e rolês, suporte técnico sobre assinaturas Juntô Pro e exercício de direitos previstos na Lei Geral de Proteção de Dados Pessoais (Lei Federal nº 13.709/2018 – LGPD).")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineSpacing(4)

                    Text("Para garantir a segurança e o registro formal da sua solicitação, envie sua mensagem a partir do mesmo endereço de e-mail vinculado à sua conta ou informe seu @usuário no corpo da mensagem. Nossa equipe realiza o atendimento todos os dias, com retorno em até 24 horas úteis.")
                        .font(.inter(14, weight: .regular))
                        .foregroundColor(JuntoColors.textMuted)
                        .lineSpacing(4)

                    Divider()
                        .padding(.vertical, 4)

                    HStack(spacing: 14) {
                        Image(systemName: "envelope")
                            .font(.system(size: 19, weight: .regular))
                            .foregroundColor(JuntoColors.primary)
                            .frame(width: 26)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("E-mail oficial de contato")
                                .font(.inter(12, weight: .regular))
                                .foregroundColor(JuntoColors.textMuted)

                            Text(store.supportEmail)
                                .font(.inter(16, weight: .medium))
                                .foregroundColor(JuntoColors.textMain)
                                .textSelection(.enabled)
                        }

                        Spacer()

                        Button {
                            UIPasteboard.general.string = store.supportEmail
                            copiedEmail = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.showToast("E-mail copiado!", icon: "doc.on.doc")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedEmail = false }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: copiedEmail ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 13, weight: .medium))
                                Text(copiedEmail ? "Copiado" : "Copiar")
                                    .font(.inter(13, weight: .medium))
                            }
                            .foregroundColor(JuntoColors.primary)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

private struct JuntoBottomWaves: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Camada areia
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.30))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.22),
                        control1: CGPoint(x: w * 0.30, y: h * 0.02),
                        control2: CGPoint(x: w * 0.65, y: h * 0.48)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.sand)

                // Camada manga
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.55))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.42),
                        control1: CGPoint(x: w * 0.35, y: h * 0.30),
                        control2: CGPoint(x: w * 0.70, y: h * 0.70)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.accent)

                // Camada azul-noite
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.78))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.66),
                        control1: CGPoint(x: w * 0.40, y: h * 0.58),
                        control2: CGPoint(x: w * 0.72, y: h * 0.90)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(JuntoColors.primary)
            }
        }
    }
}
