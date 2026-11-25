const state = {
  token: localStorage.getItem('vg_token') || '',
  user: JSON.parse(localStorage.getItem('vg_user') || 'null'),
  unit: JSON.parse(localStorage.getItem('vg_unit') || 'null'),
  pendingLogin: null,
  openTabs: ['inicio'],
  activeTab: 'inicio',
  moduleState: {},
  lookups: {
    postos: [],
    enfermeiros: [],
    setores: [],
    tipos_exames: []
  }
};

const MENU_FOLDERS = [
  {
    id: 'favoritos',
    label: 'Favoritos',
    expanded: true,
    items: [
      { id: 'postos', label: 'Postos de Saúde', icon: '★', iconColor: '#f59e0b' },
      { id: 'medicos', label: 'Médicos', icon: '★', iconColor: '#f59e0b' },
      { id: 'enfermeiros', label: 'Enfermeiros', icon: '★', iconColor: '#f59e0b' }
    ]
  },
  {
    id: 'cadastros',
    label: 'Cadastros',
    expanded: true,
    items: [
      { id: 'postos', label: 'Postos de Saúde', icon: '🏥' },
      { id: 'enfermeiros', label: 'Enfermeiros', icon: '👩‍⚕️' },
      { id: 'medicos', label: 'Médicos', icon: '🩺' },
      { id: 'setores', label: 'Setores', icon: '🗂️' },
      { id: 'tipos_exames', label: 'Tipos de Exames', icon: '🧪' },
      { id: 'exames', label: 'Exames', icon: '📋' }
    ]
  },
  {
    id: 'administracao',
    label: 'Administração',
    expanded: true,
    items: [
      { id: 'admins', label: 'Criar Admin / Usuários', icon: '🔐' }
    ]
  }
];

const MODULES = {
  postos: {
    title: 'Postos de Saúde',
    endpoint: 'postos',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Nome do Posto' },
      { key: 'localidade', label: 'Localidade' },
      { key: 'enfermeiroResponsavelId', label: 'Enfermeiro Responsável', render: row => lookupName('enfermeiros', row.enfermeiroResponsavelId) || row.enfermeiroResponsavelNome || '-' },
      { key: 'telefone', label: 'Telefone', width: '130px' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Posto *', type: 'text', required: true },
      { name: 'localidade', label: 'Localidade / Endereço *', type: 'text', required: true, full: true },
      { name: 'enfermeiroResponsavelId', label: 'Enfermeiro Responsável', type: 'select', source: 'enfermeiros' },
      { name: 'telefone', label: 'Telefone', type: 'text', placeholder: '(00) 0000-0000' },
      { name: 'ativo', label: 'Posto Ativo', type: 'checkbox', default: true }
    ]
  },
  enfermeiros: {
    title: 'Enfermeiros',
    endpoint: 'enfermeiros',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Nome' },
      { key: 'cpf', label: 'CPF', width: '130px' },
      { key: 'coren', label: 'COREN', width: '140px' },
      { key: 'postoId', label: 'Posto de Saúde', render: row => lookupName('postos', row.postoId) || '-' },
      { key: 'setorId', label: 'Setor', render: row => lookupName('setores', row.setorId) || '-' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome Completo *', type: 'text', required: true },
      { name: 'cpf', label: 'CPF *', type: 'text', mask: 'cpf', required: true, placeholder: '000.000.000-00' },
      { name: 'coren', label: 'COREN *', type: 'text', required: true, placeholder: 'COREN-UF 000000' },
      { name: 'postoId', label: 'Posto de Saúde', type: 'select', source: 'postos' },
      { name: 'setorId', label: 'Setor', type: 'select', source: 'setores' },
      { name: 'telefone', label: 'Telefone', type: 'text', placeholder: '(00) 00000-0000' },
      { name: 'ativo', label: 'Cadastro Ativo', type: 'checkbox', default: true }
    ]
  },
  medicos: {
    title: 'Médicos',
    endpoint: 'medicos',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Nome' },
      { key: 'cpf', label: 'CPF', width: '130px' },
      { key: 'crm', label: 'CRM', width: '130px' },
      { key: 'especialidade', label: 'Especialidade' },
      { key: 'postoId', label: 'Posto de Saúde', render: row => lookupName('postos', row.postoId) || '-' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome Completo *', type: 'text', required: true },
      { name: 'cpf', label: 'CPF *', type: 'text', mask: 'cpf', required: true, placeholder: '000.000.000-00' },
      { name: 'crm', label: 'CRM *', type: 'text', required: true, placeholder: 'CRM-UF 00000' },
      { name: 'especialidade', label: 'Especialidade', type: 'text', placeholder: 'Ex: Clínico Geral, Pediatria' },
      { name: 'postoId', label: 'Posto de Saúde', type: 'select', source: 'postos' },
      { name: 'setorId', label: 'Setor', type: 'select', source: 'setores' },
      { name: 'telefone', label: 'Telefone', type: 'text', placeholder: '(00) 00000-0000' },
      { name: 'ativo', label: 'Cadastro Ativo', type: 'checkbox', default: true }
    ]
  },
  setores: {
    title: 'Setores',
    endpoint: 'setores',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Nome do Setor' },
      { key: 'postoId', label: 'Posto de Saúde', render: row => lookupName('postos', row.postoId) || '-' },
      { key: 'descricao', label: 'Descrição' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Setor *', type: 'text', required: true },
      { name: 'postoId', label: 'Posto de Saúde', type: 'select', source: 'postos' },
      { name: 'ativo', label: 'Setor Ativo', type: 'checkbox', default: true },
      { name: 'descricao', label: 'Descrição / Observações', type: 'textarea', full: true }
    ]
  },
  tipos_exames: {
    title: 'Tipos de Exames',
    endpoint: 'tipos_exames',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Tipo de Exame' },
      { key: 'descricao', label: 'Descrição' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Tipo *', type: 'text', required: true, placeholder: 'Ex: Laboratorial, Imagem' },
      { name: 'descricao', label: 'Descrição', type: 'textarea', full: true },
      { name: 'ativo', label: 'Tipo Ativo', type: 'checkbox', default: true }
    ]
  },
  exames: {
    title: 'Exames',
    endpoint: 'exames',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Nome do Exame' },
      { key: 'tipoExameId', label: 'Tipo de Exame', render: row => lookupName('tipos_exames', row.tipoExameId) || '-' },
      { key: 'setorId', label: 'Setor', render: row => lookupName('setores', row.setorId) || '-' },
      { key: 'preparo', label: 'Preparo' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Exame *', type: 'text', required: true },
      { name: 'tipoExameId', label: 'Tipo de Exame *', type: 'select', source: 'tipos_exames', required: true },
      { name: 'setorId', label: 'Setor Responsável', type: 'select', source: 'setores' },
      { name: 'preparo', label: 'Preparo / Orientações', type: 'textarea', full: true },
      { name: 'ativo', label: 'Exame Ativo', type: 'checkbox', default: true }
    ]
  },
  admins: {
    title: 'Administradores',
    endpoint: 'admins',
    columns: [
      { key: 'codigo', label: 'Código', width: '75px' },
      { key: 'nome', label: 'Nome' },
      { key: 'usuario', label: 'Usuário', width: '130px' },
      { key: 'cpf', label: 'CPF', width: '130px' },
      { key: 'perfil', label: 'Perfil', width: '160px' },
      { key: 'ativo', label: 'Status', width: '90px', render: row => statusBadge(row.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome Completo *', type: 'text', required: true },
      { name: 'cpf', label: 'CPF', type: 'text', mask: 'cpf', placeholder: '000.000.000-00' },
      { name: 'email', label: 'E-mail', type: 'email', placeholder: 'admin@exemplo.com' },
      { name: 'usuario', label: 'Usuário de Acesso *', type: 'text', required: true },
      { name: 'senha', label: 'Senha', type: 'password', placeholder: 'Obrigatória ao incluir; deixe vazio para manter' },
      { name: 'perfil', label: 'Perfil', type: 'selectStatic', options: ['Administrador Geral', 'Administrador de Unidade', 'Gestor de Cadastros'] },
      { name: 'ativo', label: 'Usuário Ativo', type: 'checkbox', default: true }
    ]
  }
};

// ==================== UTILITÁRIOS ====================
function showLoading(show) {
  document.getElementById('loadingOverlay').classList.toggle('hidden', !show);
}

function toast(msg, isError = false) {
  const container = document.getElementById('toastContainer');
  const el = document.createElement('div');
  el.className = `toast ${isError ? 'error' : ''}`;
  el.textContent = msg;
  container.appendChild(el);
  setTimeout(() => el.remove(), 3200);
}

function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function statusBadge(ativo) {
  return ativo !== false
    ? '<span class="badge badge-active">Ativo</span>'
    : '<span class="badge badge-inactive">Inativo</span>';
}

function lookupName(source, id) {
  if (!id) return '';
  const item = (state.lookups[source] || []).find(x => Number(x.id) === Number(id));
  return item ? item.nome : '';
}

function formatCpf(value) {
  const digits = value.replace(/\D/g, '').slice(0, 11);
  return digits
    .replace(/(\d{3})(\d)/, '$1.$2')
    .replace(/(\d{3})(\d)/, '$1.$2')
    .replace(/(\d{3})(\d{1,2})$/, '$1-$2');
}

async function api(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (state.token) {
    headers['Authorization'] = `Bearer ${state.token}`;
  }
  const res = await fetch(path, { ...options, headers });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && path !== '/api/login') {
    logout(true);
    throw new Error('Sessão expirada. Faça login novamente.');
  }
  if (!res.ok) {
    throw new Error(data.error || 'Erro ao comunicar com o servidor.');
  }
  return data;
}

// ==================== AUTENTICAÇÃO E UNIDADE ====================
document.getElementById('loginForm').addEventListener('submit', async e => {
  e.preventDefault();
  const errEl = document.getElementById('loginError');
  errEl.classList.add('hidden');

  const usuario = document.getElementById('loginUser').value.trim();
  const senha = document.getElementById('loginPass').value;

  showLoading(true);
  try {
    const res = await api('/api/login', {
      method: 'POST',
      body: JSON.stringify({ usuario, senha })
    });
    state.pendingLogin = res;
    const select = document.getElementById('selectUnit');
    select.innerHTML = '';
    if (res.postos.length === 0) {
      select.innerHTML = '<option value="0">00 - Administração Central</option>';
    } else {
      res.postos.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.id;
        opt.textContent = `${p.codigo} - ${p.nome}`;
        select.appendChild(opt);
      });
    }
    document.getElementById('unitModal').classList.remove('hidden');
  } catch (err) {
    errEl.textContent = err.message;
    errEl.classList.remove('hidden');
  } finally {
    showLoading(false);
  }
});

function closeUnitModal() {
  document.getElementById('unitModal').classList.add('hidden');
  state.pendingLogin = null;
}

document.getElementById('btnCancelUnit').addEventListener('click', closeUnitModal);
document.getElementById('btnCancelUnitX').addEventListener('click', closeUnitModal);

document.getElementById('btnConfirmUnit').addEventListener('click', async () => {
  if (!state.pendingLogin) return;
  const select = document.getElementById('selectUnit');
  const selectedId = Number(select.value);
  const selectedPosto = state.pendingLogin.postos.find(p => Number(p.id) === selectedId) || {
    id: 0,
    codigo: '000',
    nome: 'Administração Central'
  };

  state.token = state.pendingLogin.token;
  state.user = state.pendingLogin.user;
  state.unit = selectedPosto;
  state.pendingLogin = null;

  localStorage.setItem('vg_token', state.token);
  localStorage.setItem('vg_user', JSON.stringify(state.user));
  localStorage.setItem('vg_unit', JSON.stringify(state.unit));

  document.getElementById('unitModal').classList.add('hidden');
  await enterApp();
});

async function logout(silent = false) {
  if (!silent && state.token) {
    try { await api('/api/logout', { method: 'POST' }); } catch {}
  }
  state.token = '';
  state.user = null;
  state.unit = null;
  state.openTabs = ['inicio'];
  state.activeTab = 'inicio';
  state.moduleState = {};
  localStorage.removeItem('vg_token');
  localStorage.removeItem('vg_user');
  localStorage.removeItem('vg_unit');

  document.getElementById('appShell').classList.add('hidden');
  document.getElementById('loginView').classList.remove('hidden');
}

document.getElementById('btnLogout').addEventListener('click', () => logout(false));

// ==================== SHELL & NAVEGAÇÃO EM PASTAS ====================
async function enterApp() {
  showLoading(true);
  try {
    await refreshLookups();
    document.getElementById('loginView').classList.add('hidden');
    document.getElementById('appShell').classList.remove('hidden');

    document.getElementById('topbarUser').textContent = state.user?.nome || state.user?.usuario || '';
    document.getElementById('statusUser').textContent = `${state.user?.codigo || '001'} - ${state.user?.nome || ''}`;
    document.getElementById('statusUnit').textContent = `${state.unit?.codigo || '000'} - ${state.unit?.nome || 'Administração'}`;

    renderFolderTree();
    renderTabs();
  } catch (err) {
    toast(err.message, true);
    logout(true);
  } finally {
    showLoading(false);
  }
}

async function refreshLookups() {
  const [postos, enfermeiros, setores, tipos_exames] = await Promise.all([
    api('/api/postos'),
    api('/api/enfermeiros'),
    api('/api/setores'),
    api('/api/tipos_exames')
  ]);
  state.lookups = { postos, enfermeiros, setores, tipos_exames };
}

function renderFolderTree() {
  const filter = document.getElementById('menuSearch').value.trim().toLowerCase();
  const container = document.getElementById('folderTree');
  container.innerHTML = '';

  MENU_FOLDERS.forEach(folder => {
    const filteredItems = folder.items.filter(item =>
      item.label.toLowerCase().includes(filter) || folder.label.toLowerCase().includes(filter)
    );
    if (filter && filteredItems.length === 0) return;

    const folderWrap = document.createElement('div');
    const isExpanded = filter ? true : folder.expanded;

    const header = document.createElement('div');
    header.className = 'tree-folder-header';
    header.innerHTML = `
      <span class="tree-toggle">${isExpanded ? '−' : '+'}</span>
      <span class="folder-icon">${isExpanded ? '📂' : '📁'}</span>
      <span>${escapeHtml(folder.label)}</span>
    `;
    header.addEventListener('click', () => {
      folder.expanded = !folder.expanded;
      renderFolderTree();
    });

    const children = document.createElement('div');
    children.className = `tree-children ${isExpanded ? '' : 'collapsed'}`;

    filteredItems.forEach(item => {
      const el = document.createElement('div');
      el.className = `tree-item ${state.activeTab === item.id ? 'active' : ''}`;
      el.innerHTML = `
        <span class="item-icon" style="${item.iconColor ? `color:${item.iconColor}` : ''}">${item.icon}</span>
        <span>${escapeHtml(item.label)}</span>
      `;
      el.addEventListener('click', () => openModuleTab(item.id));
      children.appendChild(el);
    });

    folderWrap.appendChild(header);
    folderWrap.appendChild(children);
    container.appendChild(folderWrap);
  });
}

document.getElementById('menuSearch').addEventListener('input', renderFolderTree);
document.getElementById('btnToggleSidebar').addEventListener('click', () => {
  const sb = document.getElementById('sidebar');
  sb.classList.toggle('collapsed');
  document.getElementById('btnToggleSidebar').textContent = sb.classList.contains('collapsed') ? '▶' : '◀';
});

// ==================== ABAS ====================
async function openModuleTab(moduleId) {
  if (!state.openTabs.includes(moduleId)) {
    state.openTabs.push(moduleId);
  }
  state.activeTab = moduleId;
  if (moduleId !== 'inicio' && !state.moduleState[moduleId]) {
    state.moduleState[moduleId] = {
      subtab: 'pesquisa',
      items: [],
      selectedIndex: -1,
      mode: 'view', // view | create | edit
      search: ''
    };
  }
  renderFolderTree();
  renderTabs();
  if (moduleId !== 'inicio') {
    await loadModuleData(moduleId);
  } else {
    await renderHomeTab();
  }
}

function closeTab(tabId, event) {
  event.stopPropagation();
  if (tabId === 'inicio') return;
  state.openTabs = state.openTabs.filter(t => t !== tabId);
  if (state.activeTab === tabId) {
    state.activeTab = state.openTabs[state.openTabs.length - 1] || 'inicio';
  }
  renderFolderTree();
  renderTabs();
  if (state.activeTab === 'inicio') {
    renderHomeTab();
  }
}

function renderTabs() {
  const tabsBar = document.getElementById('tabsBar');
  const tabsContent = document.getElementById('tabsContent');
  tabsBar.innerHTML = '';

  state.openTabs.forEach(tabId => {
    const title = tabId === 'inicio' ? 'Início' : MODULES[tabId].title;
    const btn = document.createElement('div');
    btn.className = `tab-btn ${state.activeTab === tabId ? 'active' : ''}`;
    btn.innerHTML = `<span>${escapeHtml(title)}</span>` +
      (tabId !== 'inicio' ? `<span class="tab-close" title="Fechar aba">&times;</span>` : '');

    btn.addEventListener('click', () => openModuleTab(tabId));
    if (tabId !== 'inicio') {
      btn.querySelector('.tab-close').addEventListener('click', e => closeTab(tabId, e));
    }
    tabsBar.appendChild(btn);
  });

  document.getElementById('topbarContext').textContent =
    state.activeTab === 'inicio' ? 'Administração Geral' : `Cadastros • ${MODULES[state.activeTab].title}`;

  // Garantir panes no DOM
  Array.from(tabsContent.children).forEach(pane => {
    if (!state.openTabs.includes(pane.dataset.tab)) {
      pane.remove();
    }
  });

  state.openTabs.forEach(tabId => {
    let pane = tabsContent.querySelector(`.tab-pane[data-tab="${tabId}"]`);
    if (!pane) {
      pane = document.createElement('div');
      pane.className = 'tab-pane';
      pane.dataset.tab = tabId;
      tabsContent.appendChild(pane);
    }
    pane.classList.toggle('active', state.activeTab === tabId);
  });

  if (state.activeTab === 'inicio') {
    renderHomeTab();
  }
}

async function renderHomeTab() {
  const pane = document.querySelector('.tab-pane[data-tab="inicio"]');
  if (!pane) return;

  let summary = { admins: 0, postos: 0, enfermeiros: 0, medicos: 0, exames: 0, tipos_exames: 0, setores: 0 };
  try {
    summary = await api('/api/summary');
  } catch {}

  pane.innerHTML = `
    <div class="home-pane">
      <div class="home-banner">
        <div>
          <h2>Bem-vindo ao VidaGest Saúde</h2>
          <p>Unidade selecionada: <strong>${escapeHtml(state.unit?.nome || 'Administração Central')}</strong> — Utilize as pastas à esquerda para gerenciar os cadastros.</p>
        </div>
        <span>Módulo Admin • Função 01</span>
      </div>

      <div class="cards-grid">
        <div class="stat-card" data-open="postos">
          <div class="stat-title">Postos de Saúde</div>
          <div class="stat-value">${summary.postos}</div>
          <div class="stat-link">Abrir cadastro →</div>
        </div>
        <div class="stat-card" data-open="enfermeiros">
          <div class="stat-title">Enfermeiros</div>
          <div class="stat-value">${summary.enfermeiros}</div>
          <div class="stat-link">Abrir cadastro →</div>
        </div>
        <div class="stat-card" data-open="medicos">
          <div class="stat-title">Médicos</div>
          <div class="stat-value">${summary.medicos}</div>
          <div class="stat-link">Abrir cadastro →</div>
        </div>
        <div class="stat-card" data-open="setores">
          <div class="stat-title">Setores</div>
          <div class="stat-value">${summary.setores}</div>
          <div class="stat-link">Abrir cadastro →</div>
        </div>
        <div class="stat-card" data-open="tipos_exames">
          <div class="stat-title">Tipos de Exames</div>
          <div class="stat-value">${summary.tipos_exames}</div>
          <div class="stat-link">Abrir cadastro →</div>
        </div>
        <div class="stat-card" data-open="exames">
          <div class="stat-title">Exames</div>
          <div class="stat-value">${summary.exames}</div>
          <div class="stat-link">Abrir cadastro →</div>
        </div>
        <div class="stat-card" data-open="admins">
          <div class="stat-title">Administradores</div>
          <div class="stat-value">${summary.admins}</div>
          <div class="stat-link">Gerenciar acessos →</div>
        </div>
      </div>

      <div class="home-info-list">
        <div class="home-info-row">
          <span><strong>Função 01:</strong> Cadastros Estruturais e Administrativos</span>
          <span>Postos, Enfermeiros, Médicos, Setores, Tipos de Exames e Exames</span>
        </div>
        <div class="home-info-row">
          <span><strong>Organização em Pastas:</strong> Menu lateral esquerdo</span>
          <span>Clique nas pastas ou pesquise pelo nome do programa</span>
        </div>
      </div>
    </div>
  `;

  pane.querySelectorAll('.stat-card[data-open]').forEach(card => {
    card.addEventListener('click', () => openModuleTab(card.dataset.open));
  });
}

// ==================== MÓDULOS CRUD ====================
async function loadModuleData(moduleId) {
  const mod = MODULES[moduleId];
  const st = state.moduleState[moduleId];
  showLoading(true);
  try {
    await refreshLookups();
    st.items = await api(`/api/${mod.endpoint}`);
    if (st.items.length > 0 && st.selectedIndex < 0) {
      st.selectedIndex = 0;
    } else if (st.selectedIndex >= st.items.length) {
      st.selectedIndex = st.items.length - 1;
    }
    renderModulePane(moduleId);
  } catch (err) {
    toast(err.message, true);
  } finally {
    showLoading(false);
  }
}

function renderModulePane(moduleId) {
  const pane = document.querySelector(`.tab-pane[data-tab="${moduleId}"]`);
  if (!pane) return;

  const mod = MODULES[moduleId];
  const st = state.moduleState[moduleId];
  const currentRecord = st.mode === 'create' ? {} : (st.items[st.selectedIndex] || null);
  const isEditing = st.mode === 'create' || st.mode === 'edit';

  pane.innerHTML = `
    <div class="module-subtabs">
      <button class="subtab-btn ${st.subtab === 'pesquisa' ? 'active' : ''}" data-subtab="pesquisa">Pesquisa</button>
      <button class="subtab-btn ${st.subtab === 'manutencao' ? 'active' : ''}" data-subtab="manutencao">Manutenção</button>
    </div>

    <div class="module-body">
      ${st.subtab === 'pesquisa' ? renderPesquisaHtml(mod, st) : renderManutencaoHtml(mod, st, currentRecord)}
    </div>

    <div class="module-actionbar">
      <div class="action-group">
        <button class="btn-action" data-act="incluir" ${isEditing ? 'disabled' : ''}>+ Incluir</button>
        <button class="btn-action" data-act="editar" ${isEditing || !currentRecord ? 'disabled' : ''}>✎ Editar</button>
        <button class="btn-action btn-save" data-act="gravar" ${!isEditing ? 'disabled' : ''}>💾 Gravar</button>
        <button class="btn-action" data-act="cancelar" ${!isEditing ? 'disabled' : ''}>✖ Cancelar</button>
        <button class="btn-action btn-danger" data-act="excluir" ${isEditing || !currentRecord ? 'disabled' : ''}>🗑 Excluir</button>
      </div>
      <div class="action-group">
        <button class="pager-btn" data-page="first" ${st.items.length === 0 || st.selectedIndex <= 0 || isEditing ? 'disabled' : ''}>«</button>
        <button class="pager-btn" data-page="prev" ${st.items.length === 0 || st.selectedIndex <= 0 || isEditing ? 'disabled' : ''}>‹</button>
        <span style="font-size:12px; color:#475569; padding:0 4px;">
          ${st.items.length > 0 && st.selectedIndex >= 0 ? `${st.selectedIndex + 1} / ${st.items.length}` : '0 / 0'}
        </span>
        <button class="pager-btn" data-page="next" ${st.items.length === 0 || st.selectedIndex >= st.items.length - 1 || isEditing ? 'disabled' : ''}>›</button>
        <button class="pager-btn" data-page="last" ${st.items.length === 0 || st.selectedIndex >= st.items.length - 1 || isEditing ? 'disabled' : ''}>»</button>
        <button class="btn-action btn-exit" data-act="sair" style="margin-left:8px;">Sair</button>
      </div>
    </div>
  `;

  // Eventos sub-abas
  pane.querySelectorAll('.subtab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      st.subtab = btn.dataset.subtab;
      renderModulePane(moduleId);
    });
  });

  // Eventos pesquisa
  const searchInput = pane.querySelector('.js-module-search');
  if (searchInput) {
    searchInput.value = st.search;
    searchInput.addEventListener('input', e => {
      st.search = e.target.value;
      const tbody = pane.querySelector('tbody');
      tbody.innerHTML = renderTableRows(mod, st);
      bindRowEvents(pane, moduleId);
    });
  }
  bindRowEvents(pane, moduleId);

  // Máscara CPF
  pane.querySelectorAll('input[data-mask="cpf"]').forEach(inp => {
    inp.addEventListener('input', e => {
      e.target.value = formatCpf(e.target.value);
    });
  });

  // Eventos barra de ações
  pane.querySelector('[data-act="incluir"]').addEventListener('click', () => {
    st.mode = 'create';
    st.subtab = 'manutencao';
    renderModulePane(moduleId);
  });

  pane.querySelector('[data-act="editar"]').addEventListener('click', () => {
    if (!currentRecord) return;
    st.mode = 'edit';
    st.subtab = 'manutencao';
    renderModulePane(moduleId);
  });

  pane.querySelector('[data-act="cancelar"]').addEventListener('click', () => {
    st.mode = 'view';
    renderModulePane(moduleId);
  });

  pane.querySelector('[data-act="gravar"]').addEventListener('click', () => saveRecord(moduleId));
  pane.querySelector('[data-act="excluir"]').addEventListener('click', () => deleteRecord(moduleId));
  pane.querySelector('[data-act="sair"]').addEventListener('click', e => closeTab(moduleId, e));

  // Paginação
  pane.querySelectorAll('.pager-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const p = btn.dataset.page;
      if (p === 'first') st.selectedIndex = 0;
      if (p === 'prev' && st.selectedIndex > 0) st.selectedIndex--;
      if (p === 'next' && st.selectedIndex < st.items.length - 1) st.selectedIndex++;
      if (p === 'last') st.selectedIndex = st.items.length - 1;
      renderModulePane(moduleId);
    });
  });
}

function renderPesquisaHtml(mod, st) {
  return `
    <div class="search-toolbar">
      <input type="text" class="js-module-search" placeholder="Filtrar registros em ${escapeHtml(mod.title)}..." />
      <span style="font-size:12px; color:#64748b;">Dica: clique duplo para abrir em Manutenção</span>
    </div>
    <div class="data-table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            ${mod.columns.map(c => `<th style="${c.width ? `width:${c.width}` : ''}">${escapeHtml(c.label)}</th>`).join('')}
          </tr>
        </thead>
        <tbody>
          ${renderTableRows(mod, st)}
        </tbody>
      </table>
    </div>
  `;
}

function renderTableRows(mod, st) {
  const q = st.search.trim().toLowerCase();
  const filtered = st.items
    .map((row, idx) => ({ row, idx }))
    .filter(({ row }) => {
      if (!q) return true;
      return JSON.stringify(row).toLowerCase().includes(q);
    });

  if (filtered.length === 0) {
    return `<tr><td colspan="${mod.columns.length}" style="text-align:center; padding:18px; color:#64748b;">Nenhum registro encontrado.</td></tr>`;
  }

  return filtered.map(({ row, idx }) => `
    <tr data-idx="${idx}" class="${idx === st.selectedIndex ? 'selected' : ''}">
      ${mod.columns.map(c => {
        const val = c.render ? c.render(row) : escapeHtml(row[c.key] ?? '');
        return `<td>${val}</td>`;
      }).join('')}
    </tr>
  `).join('');
}

function bindRowEvents(pane, moduleId) {
  const st = state.moduleState[moduleId];
  pane.querySelectorAll('tbody tr[data-idx]').forEach(tr => {
    tr.addEventListener('click', () => {
      st.selectedIndex = Number(tr.dataset.idx);
      pane.querySelectorAll('tbody tr').forEach(r => r.classList.remove('selected'));
      tr.classList.add('selected');
      renderModulePane(moduleId);
    });
    tr.addEventListener('dblclick', () => {
      st.selectedIndex = Number(tr.dataset.idx);
      st.subtab = 'manutencao';
      st.mode = 'view';
      renderModulePane(moduleId);
    });
  });
}

function renderManutencaoHtml(mod, st, record) {
  const isEditing = st.mode === 'create' || st.mode === 'edit';
  const data = record || {};

  if (!record && st.mode === 'view') {
    return `<p style="color:#64748b; padding:12px;">Nenhum registro selecionado. Clique em <strong>+ Incluir</strong> para criar um novo.</p>`;
  }

  return `
    <form class="form-grid js-module-form" onsubmit="return false;">
      ${mod.fields.map(f => {
        const val = st.mode === 'create'
          ? (f.default !== undefined ? f.default : '')
          : (data[f.name] !== undefined ? data[f.name] : '');
        const disabledAttr = (!isEditing || f.readonly) ? 'disabled' : '';

        if (f.type === 'checkbox') {
          return `
            <div class="form-field checkbox-field">
              <input type="checkbox" id="fld_${mod.endpoint}_${f.name}" name="${f.name}" ${val !== false ? 'checked' : ''} ${!isEditing ? 'disabled' : ''} />
              <label for="fld_${mod.endpoint}_${f.name}">${escapeHtml(f.label)}</label>
            </div>
          `;
        }

        if (f.type === 'select') {
          const opts = state.lookups[f.source] || [];
          return `
            <div class="form-field ${f.full ? 'full-span' : ''}">
              <label>${escapeHtml(f.label)}</label>
              <select name="${f.name}" ${disabledAttr}>
                <option value="">-- Selecione --</option>
                ${opts.map(o => `<option value="${o.id}" ${Number(val) === Number(o.id) ? 'selected' : ''}>${escapeHtml(o.codigo ? `${o.codigo} - ${o.nome}` : o.nome)}</option>`).join('')}
              </select>
            </div>
          `;
        }

        if (f.type === 'selectStatic') {
          return `
            <div class="form-field ${f.full ? 'full-span' : ''}">
              <label>${escapeHtml(f.label)}</label>
              <select name="${f.name}" ${disabledAttr}>
                ${f.options.map(opt => `<option value="${escapeHtml(opt)}" ${val === opt ? 'selected' : ''}>${escapeHtml(opt)}</option>`).join('')}
              </select>
            </div>
          `;
        }

        if (f.type === 'textarea') {
          return `
            <div class="form-field ${f.full ? 'full-span' : ''}">
              <label>${escapeHtml(f.label)}</label>
              <textarea name="${f.name}" rows="3" ${disabledAttr} placeholder="${escapeHtml(f.placeholder || '')}">${escapeHtml(val)}</textarea>
            </div>
          `;
        }

        return `
          <div class="form-field ${f.full ? 'full-span' : ''}">
            <label>${escapeHtml(f.label)}</label>
            <input
              type="${f.type || 'text'}"
              name="${f.name}"
              value="${escapeHtml(val)}"
              ${f.readonly ? 'readonly' : ''}
              ${!isEditing ? 'disabled' : ''}
              ${f.mask ? `data-mask="${f.mask}"` : ''}
              placeholder="${escapeHtml(f.placeholder || '')}"
            />
          </div>
        `;
      }).join('')}
    </form>
  `;
}

async function saveRecord(moduleId) {
  const pane = document.querySelector(`.tab-pane[data-tab="${moduleId}"]`);
  const form = pane.querySelector('.js-module-form');
  const mod = MODULES[moduleId];
  const st = state.moduleState[moduleId];

  const payload = {};
  for (const f of mod.fields) {
    if (f.readonly) continue;
    const el = form.querySelector(`[name="${f.name}"]`);
    if (!el) continue;

    if (f.type === 'checkbox') {
      payload[f.name] = el.checked;
    } else if (f.type === 'select') {
      payload[f.name] = el.value ? Number(el.value) : null;
      if (f.required && !payload[f.name]) {
        toast(`Preencha o campo obrigatório: ${f.label.replace(' *', '')}`, true);
        el.focus();
        return;
      }
    } else {
      const v = el.value.trim();
      if (f.required && !v) {
        toast(`Preencha o campo obrigatório: ${f.label.replace(' *', '')}`, true);
        el.focus();
        return;
      }
      if (moduleId === 'admins' && f.name === 'senha' && st.mode === 'create' && !v) {
        toast('Informe uma senha para o novo administrador.', true);
        el.focus();
        return;
      }
      payload[f.name] = v;
    }
  }

  if (moduleId === 'postos' && payload.enfermeiroResponsavelId) {
    payload.enfermeiroResponsavelNome = lookupName('enfermeiros', payload.enfermeiroResponsavelId);
  }

  showLoading(true);
  try {
    if (st.mode === 'create') {
      const created = await api(`/api/${mod.endpoint}`, {
        method: 'POST',
        body: JSON.stringify(payload)
      });
      await refreshLookups();
      st.items = await api(`/api/${mod.endpoint}`);
      st.selectedIndex = st.items.findIndex(x => Number(x.id) === Number(created.id));
      toast(`${mod.title}: registro incluído com sucesso!`);
    } else {
      const current = st.items[st.selectedIndex];
      await api(`/api/${mod.endpoint}/${current.id}`, {
        method: 'PUT',
        body: JSON.stringify(payload)
      });
      await refreshLookups();
      st.items = await api(`/api/${mod.endpoint}`);
      toast(`${mod.title}: registro atualizado!`);
    }
    st.mode = 'view';
    renderModulePane(moduleId);
  } catch (err) {
    toast(err.message, true);
  } finally {
    showLoading(false);
  }
}

async function deleteRecord(moduleId) {
  const mod = MODULES[moduleId];
  const st = state.moduleState[moduleId];
  const current = st.items[st.selectedIndex];
  if (!current) return;

  if (!confirm(`Deseja realmente excluir "${current.nome || current.codigo}"?`)) {
    return;
  }

  showLoading(true);
  try {
    await api(`/api/${mod.endpoint}/${current.id}`, { method: 'DELETE' });
    await refreshLookups();
    st.items = await api(`/api/${mod.endpoint}`);
    st.selectedIndex = st.items.length > 0 ? Math.min(st.selectedIndex, st.items.length - 1) : -1;
    st.mode = 'view';
    toast('Registro excluído.');
    renderModulePane(moduleId);
  } catch (err) {
    toast(err.message, true);
  } finally {
    showLoading(false);
  }
}

// ==================== RELÓGIO E INICIALIZAÇÃO ====================
function updateClock() {
  const now = new Date();
  const formatted = now.toLocaleDateString('pt-BR') + ' ' + now.toLocaleTimeString('pt-BR');
  const el = document.getElementById('statusDateTime');
  if (el) el.textContent = formatted;
}
setInterval(updateClock, 1000);
updateClock();

if (state.token && state.user) {
  enterApp();
}
