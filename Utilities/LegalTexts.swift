import Foundation

struct LegalTexts {
    static let termosDeUso = """
TERMOS E CONDIÇÕES DE USO DO APLICATIVO ACHOU

Última atualização: 21 de Setembro de 2026.

1. ACEITAÇÃO DOS TERMOS
Ao acessar e utilizar o aplicativo "Achou" (doravante "Plataforma"), você concorda em cumprir e estar vinculado aos presentes Termos de Uso. Caso não concorde com qualquer disposição, solicitamos que não utilize os nossos serviços.

2. SOBRE A PLATAFORMA
O Achou é um aplicativo de classificados e marketplace local que atua como mero intermediador e facilitador de anúncios, permitindo que usuários ("Vendedores") publiquem produtos para venda e usuários ("Compradores") encontrem e negociem esses produtos. Não somos proprietários dos produtos oferecidos, não guardamos posse, não intervimos na fixação dos preços e não nos responsabilizamos pela entrega dos produtos.

3. CADASTRO DO USUÁRIO
Para utilizar as funcionalidades da Plataforma, é exigido um cadastro contendo dados precisos, incluindo Nome, CPF (para garantir a segurança das transações), E-mail, e Localização. O usuário é o único responsável pela veracidade dos dados fornecidos e por manter o sigilo das suas credenciais de acesso. O compartilhamento de senhas é proibido.

4. POLÍTICA DE PUBLICAÇÃO DE ANÚNCIOS
O usuário compromete-se a não publicar produtos ilícitos, roubados, falsificados, ou que infrinjam direitos autorais. O Achou reserva-se o direito de remover, sem aviso prévio, anúncios que violem nossos termos ou as leis vigentes, além de banir as contas infratoras.

5. RESPONSABILIDADES
O Achou não garante a qualidade, segurança ou legalidade dos itens anunciados, tampouco a veracidade ou exatidão das descrições. As negociações são feitas diretamente entre os usuários através do chat integrado. Recomendamos cautela em encontros presenciais, priorizando locais públicos e seguros.

6. COMUNICAÇÃO E MENSAGENS
O chat do Achou destina-se exclusivamente à negociação de produtos. É proibido o uso do chat para envio de spam, ofensas, assédio ou qualquer conduta ilícita.

7. ALTERAÇÕES NOS TERMOS
Podemos atualizar estes Termos ocasionalmente. O uso continuado da Plataforma após as alterações configura aceitação das novas condições.
"""
    
    static let privacidade = """
POLÍTICA DE PRIVACIDADE E PROTEÇÃO DE DADOS

O aplicativo Achou compromete-se com a sua privacidade. Esta política, elaborada em conformidade com a Lei Geral de Proteção de Dados Pessoais (LGPD - Lei nº 13.709/2018), descreve como coletamos, usamos e protegemos seus dados.

1. DADOS QUE COLETAMOS
Coletamos os dados necessários para o funcionamento da plataforma e para a sua segurança:
- Dados Cadastrais: Nome completo, E-mail, CPF, Data de Nascimento e Foto de perfil. O CPF é coletado com o fim de mitigar fraudes e proporcionar um ambiente mais seguro.
- Dados de Localização: Coletamos dados de localização aproximada (Cidade, Estado, Bairro) para exibir anúncios relevantes próximos a você. A localização precisa (GPS) só é coletada mediante autorização explícita.
- Dados de Navegação e Chat: As mensagens enviadas no chat são armazenadas para garantir o histórico das negociações, podendo ser acessadas para apuração de fraudes ou denúncias.
- Identificadores de Dispositivo: Coletamos tokens de dispositivo (Push Notifications) para enviar avisos importantes sobre os seus anúncios ou mensagens.

2. USO DOS DADOS
Utilizamos seus dados para:
- Viabilizar a criação da conta e a publicação de anúncios;
- Facilitar o contato entre compradores e vendedores;
- Enviar notificações operacionais e alertas do sistema;
- Identificar, investigar e coibir atividades fraudulentas.

3. COMPARTILHAMENTO DE DADOS
O Achou não vende, não aluga e não cede seus dados pessoais para terceiros para fins publicitários não solicitados. Os dados podem ser compartilhados apenas com:
- Nossos provedores de infraestrutura e hospedagem (ex: Supabase, Apple);
- Autoridades legais, quando exigido por ordem judicial ou para proteger nossos direitos jurídicos.

4. SEUS DIREITOS (LGPD)
Você possui o direito de confirmar a existência de tratamento, acessar seus dados, corrigir dados incompletos ou solicitar a exclusão da sua conta e dos seus dados a qualquer momento diretamente nas configurações do aplicativo.

5. COOKIES E TECNOLOGIAS SEMELHANTES
O aplicativo utiliza armazenamentos locais criptografados no dispositivo para manter a sua sessão ativa e salvar preferências.
"""
    
    static let seguranca = """
DIRETRIZES DE SEGURANÇA DE DADOS

Sua segurança é nossa prioridade. No aplicativo Achou, aplicamos rigorosos padrões internacionais de segurança para proteger as informações e as interações dos nossos usuários.

1. INFRAESTRUTURA EM NUVEM E CRIPTOGRAFIA
- Criptografia em Trânsito (TLS/SSL): Toda comunicação entre o seu celular e nossos servidores é criptografada. É impossível que um terceiro intercepte os dados no meio do caminho.
- Criptografia em Repouso: Utilizamos o banco de dados Supabase, hospedado em servidores de última geração. Todos os dados armazenados em nossos discos são criptografados através de tecnologia AES-256 (Padrão de Criptografia Avançada).

2. AUTENTICAÇÃO E ACESSOS
- O acesso ao seu perfil é protegido por tokens de autenticação temporários (JWT - JSON Web Tokens) gerenciados nativamente pela infraestrutura.
- Senhas não são salvas em texto puro. Elas passam por um processo de hash irreversível (usando algoritmos modernos) antes de serem guardadas. Ninguém da nossa equipe tem acesso à sua senha.

3. BACKUPS E RESILIÊNCIA
- Mantemos backups automatizados de rotina e réplicas de segurança (Point-in-Time Recovery) para garantir que nenhuma negociação ou dado importante seja perdido em caso de falha de hardware.

4. MONITORAMENTO E PREVENÇÃO DE ATAQUES
- Empregamos firewalls de aplicação e monitoramento constante de tráfego para bloquear tentativas de invasão, injeção de SQL ou abusos de sistema.
- A segurança do tráfego das mensagens instantâneas (chat) e das imagens do sistema funciona através de conexões WebSocket restritas e validáveis a cada emissão de pacote.

5. RESPONSABILIDADE COMPARTILHADA
Apesar dos nossos esforços, a segurança depende de boas práticas mútuas. Aconselhamos:
- Nunca use senhas fáceis como "123456".
- Não compartilhe seu aparelho destravado ou passe seus dados de login a estranhos.
- Reporte qualquer link suspeito recebido no chat.
"""
}
