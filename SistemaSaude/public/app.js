const state = {
  token: localStorage.getItem('vg_token') || '',
  user: JSON.parse(localStorage.getItem('vg_user') || 'null'),
  unit: JSON.parse(localStorage.getItem('vg_unit') || 'null'),
  pendingLogin: null,
  openTabs: ['inicio'],
  activeTab: 'inicio',
  moduleState: {},
  lookups: { postos: [], enfermeiros: [], setores: [], tipos_exames: [] }
};

/* ===== Menu em árvore — sem emojis, ícones CSS ===== */
const MENU_FOLDERS = [
  {
    id: 'favoritos', label: 'Favoritos', expanded: true,
    items: [
      { id: 'postos', label: 'Postos de Saúde', star: true },
      { id: 'medicos', label: 'Médicos', star: true },
      { id: 'enfermeiros', label: 'Enfermeiros', star: true }
    ]
  },
  {
    id: 'cadastros', label: 'Cadastros', expanded: true,
    items: [
      { id: 'postos', label: 'Postos de Saúde' },
      { id: 'enfermeiros', label: 'Enfermeiros' },
      { id: 'medicos', label: 'Médicos' },
      { id: 'setores', label: 'Setores' },
      { id: 'tipos_exames', label: 'Tipos de Exames' },
      { id: 'exames', label: 'Exames' }
    ]
  },
  {
    id: 'administracao', label: 'Administração', expanded: true,
    items: [
      { id: 'admins', label: 'Criar Admin / Usuários' }
    ]
  }
];

const MODULES = {
  postos: {
    title: 'Postos de Saúde', endpoint: 'postos',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Nome do Posto' },
      { key: 'localidade', label: 'Localidade' },
      { key: 'enfermeiroResponsavelId', label: 'Enfermeiro Responsável', render: r => lookupName('enfermeiros', r.enfermeiroResponsavelId) || r.enfermeiroResponsavelNome || '-' },
      { key: 'telefone', label: 'Telefone', width: '120px' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Posto', type: 'text', required: true },
      { name: 'localidade', label: 'Localidade / Endereço', type: 'text', required: true, full: true },
      { name: 'enfermeiroResponsavelId', label: 'Enfermeiro Responsável', type: 'select', source: 'enfermeiros' },
      { name: 'telefone', label: 'Telefone', type: 'text', placeholder: '(00) 0000-0000' },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true }
    ]
  },
  enfermeiros: {
    title: 'Enfermeiros', endpoint: 'enfermeiros',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Nome' },
      { key: 'cpf', label: 'CPF', width: '125px' },
      { key: 'coren', label: 'COREN', width: '130px' },
      { key: 'postoId', label: 'Posto', render: r => lookupName('postos', r.postoId) || '-' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome Completo', type: 'text', required: true },
      { name: 'cpf', label: 'CPF', type: 'text', mask: 'cpf', required: true, placeholder: '000.000.000-00' },
      { name: 'coren', label: 'COREN', type: 'text', required: true, placeholder: 'COREN-UF 000000' },
      { name: 'postoId', label: 'Posto de Saúde', type: 'select', source: 'postos' },
      { name: 'setorId', label: 'Setor', type: 'select', source: 'setores' },
      { name: 'telefone', label: 'Telefone', type: 'text', placeholder: '(00) 00000-0000' },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true }
    ]
  },
  medicos: {
    title: 'Médicos', endpoint: 'medicos',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Nome' },
      { key: 'cpf', label: 'CPF', width: '125px' },
      { key: 'crm', label: 'CRM', width: '125px' },
      { key: 'especialidade', label: 'Especialidade' },
      { key: 'postoId', label: 'Posto', render: r => lookupName('postos', r.postoId) || '-' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome Completo', type: 'text', required: true },
      { name: 'cpf', label: 'CPF', type: 'text', mask: 'cpf', required: true, placeholder: '000.000.000-00' },
      { name: 'crm', label: 'CRM', type: 'text', required: true, placeholder: 'CRM-UF 00000' },
      { name: 'especialidade', label: 'Especialidade', type: 'text' },
      { name: 'postoId', label: 'Posto de Saúde', type: 'select', source: 'postos' },
      { name: 'setorId', label: 'Setor', type: 'select', source: 'setores' },
      { name: 'telefone', label: 'Telefone', type: 'text' },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true }
    ]
  },
  setores: {
    title: 'Setores', endpoint: 'setores',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Nome do Setor' },
      { key: 'postoId', label: 'Posto', render: r => lookupName('postos', r.postoId) || '-' },
      { key: 'descricao', label: 'Descrição' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Setor', type: 'text', required: true },
      { name: 'postoId', label: 'Posto de Saúde', type: 'select', source: 'postos' },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true },
      { name: 'descricao', label: 'Descrição', type: 'textarea', full: true }
    ]
  },
  tipos_exames: {
    title: 'Tipos de Exames', endpoint: 'tipos_exames',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Tipo de Exame' },
      { key: 'descricao', label: 'Descrição' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Tipo', type: 'text', required: true },
      { name: 'descricao', label: 'Descrição', type: 'textarea', full: true },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true }
    ]
  },
  exames: {
    title: 'Exames', endpoint: 'exames',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Nome do Exame' },
      { key: 'tipoExameId', label: 'Tipo', render: r => lookupName('tipos_exames', r.tipoExameId) || '-' },
      { key: 'setorId', label: 'Setor', render: r => lookupName('setores', r.setorId) || '-' },
      { key: 'preparo', label: 'Preparo' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome do Exame', type: 'text', required: true },
      { name: 'tipoExameId', label: 'Tipo de Exame', type: 'select', source: 'tipos_exames', required: true },
      { name: 'setorId', label: 'Setor Responsável', type: 'select', source: 'setores' },
      { name: 'preparo', label: 'Preparo / Orientações', type: 'textarea', full: true },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true }
    ]
  },
  admins: {
    title: 'Administradores', endpoint: 'admins',
    columns: [
      { key: 'codigo', label: 'Código', width: '70px' },
      { key: 'nome', label: 'Nome' },
      { key: 'usuario', label: 'Usuário', width: '120px' },
      { key: 'cpf', label: 'CPF', width: '125px' },
      { key: 'perfil', label: 'Perfil', width: '150px' },
      { key: 'ativo', label: 'Status', width: '80px', render: r => statusBadge(r.ativo) }
    ],
    fields: [
      { name: 'codigo', label: 'Código', type: 'text', readonly: true, placeholder: 'Automático' },
      { name: 'nome', label: 'Nome Completo', type: 'text', required: true },
      { name: 'cpf', label: 'CPF', type: 'text', mask: 'cpf', placeholder: '000.000.000-00' },
      { name: 'email', label: 'E-mail', type: 'email' },
      { name: 'usuario', label: 'Usuário de Acesso', type: 'text', required: true },
      { name: 'senha', label: 'Senha', type: 'password', placeholder: 'Obrigatória ao incluir' },
      { name: 'perfil', label: 'Perfil', type: 'selectStatic', options: ['Administrador Geral', 'Administrador de Unidade', 'Gestor de Cadastros'] },
      { name: 'ativo', label: 'Ativo', type: 'checkbox', default: true }
    ]
  }
};

/* ===== Helpers ===== */
function showLoading(v) { document.getElementById('loadingOverlay').classList.toggle('hidden', !v); }
function toast(msg, err) {
  const c = document.getElementById('toastContainer'), el = document.createElement('div');
  el.className = 'toast' + (err ? ' error' : ''); el.textContent = msg; c.appendChild(el);
  setTimeout(() => el.remove(), 3200);
}
function esc(s) { return String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function statusBadge(a) { return a !== false ? '<span class="badge badge-active">Ativo</span>' : '<span class="badge badge-inactive">Inativo</span>'; }
function lookupName(src, id) { if (!id) return ''; const i = (state.lookups[src]||[]).find(x => +x.id === +id); return i ? i.nome : ''; }
function formatCpf(v) { const d = v.replace(/\D/g,'').slice(0,11); return d.replace(/(\d{3})(\d)/,'$1.$2').replace(/(\d{3})(\d)/,'$1.$2').replace(/(\d{3})(\d{1,2})$/,'$1-$2'); }

async function api(path, opts = {}) {
  const h = { 'Content-Type': 'application/json', ...(opts.headers || {}) };
  if (state.token) h['Authorization'] = 'Bearer ' + state.token;
  const r = await fetch(path, { ...opts, headers: h });
  const d = await r.json().catch(() => ({}));
  if (r.status === 401 && path !== '/api/login') { logout(true); throw new Error('Sessão expirada.'); }
  if (!r.ok) throw new Error(d.error || 'Erro no servidor.');
  return d;
}

/* ===== Login ===== */
document.getElementById('loginForm').addEventListener('submit', async e => {
  e.preventDefault();
  const err = document.getElementById('loginError'); err.classList.add('hidden');
  showLoading(true);
  try {
    const res = await api('/api/login', { method: 'POST', body: JSON.stringify({ usuario: document.getElementById('loginUser').value.trim(), senha: document.getElementById('loginPass').value }) });
    state.pendingLogin = res;
    const sel = document.getElementById('selectUnit'); sel.innerHTML = '';
    if (!res.postos.length) { sel.innerHTML = '<option value="0">00 - Administração Central</option>'; }
    else res.postos.forEach(p => { const o = document.createElement('option'); o.value = p.id; o.textContent = p.codigo + ' - ' + p.nome; sel.appendChild(o); });
    document.getElementById('unitModal').classList.remove('hidden');
  } catch (e) { err.textContent = e.message; err.classList.remove('hidden'); }
  finally { showLoading(false); }
});

function closeUnitModal() { document.getElementById('unitModal').classList.add('hidden'); state.pendingLogin = null; }
document.getElementById('btnCancelUnit').addEventListener('click', closeUnitModal);
document.getElementById('btnCancelUnitX').addEventListener('click', closeUnitModal);

document.getElementById('btnConfirmUnit').addEventListener('click', async () => {
  if (!state.pendingLogin) return;
  const sel = document.getElementById('selectUnit');
  const posto = state.pendingLogin.postos.find(p => +p.id === +sel.value) || { id: 0, codigo: '000', nome: 'Administração Central' };
  state.token = state.pendingLogin.token; state.user = state.pendingLogin.user; state.unit = posto; state.pendingLogin = null;
  localStorage.setItem('vg_token', state.token); localStorage.setItem('vg_user', JSON.stringify(state.user)); localStorage.setItem('vg_unit', JSON.stringify(state.unit));
  document.getElementById('unitModal').classList.add('hidden');
  await enterApp();
});

async function logout(silent) {
  if (!silent && state.token) try { await api('/api/logout', { method: 'POST' }); } catch {}
  state.token = ''; state.user = null; state.unit = null; state.openTabs = ['inicio']; state.activeTab = 'inicio'; state.moduleState = {};
  localStorage.removeItem('vg_token'); localStorage.removeItem('vg_user'); localStorage.removeItem('vg_unit');
  document.getElementById('appShell').classList.add('hidden'); document.getElementById('loginView').classList.remove('hidden');
}
document.getElementById('btnLogout').addEventListener('click', () => logout(false));

/* ===== Shell ===== */
async function enterApp() {
  showLoading(true);
  try {
    await refreshLookups();
    document.getElementById('loginView').classList.add('hidden'); document.getElementById('appShell').classList.remove('hidden');
    document.getElementById('topbarUser').textContent = state.user?.nome || '';
    document.getElementById('statusUser').textContent = (state.user?.codigo||'001') + ' - ' + (state.user?.nome||'');
    document.getElementById('statusUnit').textContent = (state.unit?.codigo||'000') + ' - ' + (state.unit?.nome||'Administração');
    renderFolderTree(); renderTabs();
  } catch (e) { toast(e.message, true); logout(true); }
  finally { showLoading(false); }
}
async function refreshLookups() {
  const [a,b,c,d] = await Promise.all([api('/api/postos'), api('/api/enfermeiros'), api('/api/setores'), api('/api/tipos_exames')]);
  state.lookups = { postos: a, enfermeiros: b, setores: c, tipos_exames: d };
}

/* ===== Árvore de pastas nativa ===== */
function renderFolderTree() {
  const q = document.getElementById('menuSearch').value.trim().toLowerCase();
  const container = document.getElementById('folderTree');
  container.innerHTML = '';

  MENU_FOLDERS.forEach(folder => {
    const filtered = folder.items.filter(i => i.label.toLowerCase().includes(q) || folder.label.toLowerCase().includes(q));
    if (q && !filtered.length) return;
    const expanded = q ? true : folder.expanded;

    const node = document.createElement('div');
    node.className = 'tree-node';

    // Header da pasta
    const header = document.createElement('div');
    header.className = 'tree-node-header';
    header.style.paddingLeft = '6px';
    header.innerHTML =
      `<span class="tree-toggle">${expanded ? '\u2212' : '+'}</span>` +
      `<span class="ico ${expanded ? 'ico-folder-open' : 'ico-folder'}"></span>` +
      `<span class="tree-node-label">${esc(folder.label)}</span>`;
    header.addEventListener('click', () => { folder.expanded = !folder.expanded; renderFolderTree(); });

    // Filhos
    const children = document.createElement('div');
    children.className = 'tree-children' + (expanded ? '' : ' collapsed');

    filtered.forEach(item => {
      const leaf = document.createElement('div');
      leaf.className = 'tree-leaf' + (state.activeTab === item.id ? ' active' : '');
      leaf.style.paddingLeft = '36px';
      leaf.innerHTML =
        `<span class="ico ${item.star ? 'ico-star' : 'ico-doc'}"></span>` +
        `<span class="tree-leaf-label">${esc(item.label)}</span>`;
      leaf.addEventListener('click', () => openModuleTab(item.id));
      children.appendChild(leaf);
    });

    node.appendChild(header);
    node.appendChild(children);
    container.appendChild(node);
  });
}
document.getElementById('menuSearch').addEventListener('input', renderFolderTree);
document.getElementById('btnToggleSidebar').addEventListener('click', () => {
  const sb = document.getElementById('sidebar'); sb.classList.toggle('collapsed');
  document.getElementById('btnToggleSidebar').textContent = sb.classList.contains('collapsed') ? '\u25B6' : '\u25C0';
});

/* ===== Abas ===== */
async function openModuleTab(mid) {
  if (!state.openTabs.includes(mid)) state.openTabs.push(mid);
  state.activeTab = mid;
  if (mid !== 'inicio' && !state.moduleState[mid]) state.moduleState[mid] = { subtab: 'pesquisa', items: [], selectedIndex: -1, mode: 'view', search: '' };
  renderFolderTree(); renderTabs();
  if (mid !== 'inicio') await loadModuleData(mid); else await renderHomeTab();
}
function closeTab(tid, ev) {
  ev.stopPropagation(); if (tid === 'inicio') return;
  state.openTabs = state.openTabs.filter(t => t !== tid);
  if (state.activeTab === tid) state.activeTab = state.openTabs[state.openTabs.length - 1] || 'inicio';
  renderFolderTree(); renderTabs();
  if (state.activeTab === 'inicio') renderHomeTab();
}
function renderTabs() {
  const bar = document.getElementById('tabsBar'), content = document.getElementById('tabsContent');
  bar.innerHTML = '';
  state.openTabs.forEach(tid => {
    const title = tid === 'inicio' ? 'Início' : MODULES[tid].title;
    const btn = document.createElement('div');
    btn.className = 'tab-btn' + (state.activeTab === tid ? ' active' : '');
    btn.innerHTML = '<span>' + esc(title) + '</span>' + (tid !== 'inicio' ? '<span class="tab-close" title="Fechar">&times;</span>' : '');
    btn.addEventListener('click', () => openModuleTab(tid));
    if (tid !== 'inicio') btn.querySelector('.tab-close').addEventListener('click', e => closeTab(tid, e));
    bar.appendChild(btn);
  });
  document.getElementById('topbarContext').textContent = state.activeTab === 'inicio' ? 'Geral' : MODULES[state.activeTab].title;
  Array.from(content.children).forEach(p => { if (!state.openTabs.includes(p.dataset.tab)) p.remove(); });
  state.openTabs.forEach(tid => {
    let p = content.querySelector(`.tab-pane[data-tab="${tid}"]`);
    if (!p) { p = document.createElement('div'); p.className = 'tab-pane'; p.dataset.tab = tid; content.appendChild(p); }
    p.classList.toggle('active', state.activeTab === tid);
  });
  if (state.activeTab === 'inicio') renderHomeTab();
}

async function renderHomeTab() {
  const pane = document.querySelector('.tab-pane[data-tab="inicio"]'); if (!pane) return;
  let s = { admins:0, postos:0, enfermeiros:0, medicos:0, exames:0, tipos_exames:0, setores:0 };
  try { s = await api('/api/summary'); } catch {}
  pane.innerHTML = `<div class="home-pane">
    <div class="home-banner"><h2>Bem-vindo ao Agenda Saúde</h2><p>Unidade: <strong>${esc(state.unit?.nome||'Administração Central')}</strong> — Utilize o menu lateral para acessar os cadastros.</p></div>
    <div class="cards-grid">
      <div class="stat-card" data-open="postos"><div class="stat-title">Postos de Saúde</div><div class="stat-value">${s.postos}</div><div class="stat-link">Abrir cadastro</div></div>
      <div class="stat-card" data-open="enfermeiros"><div class="stat-title">Enfermeiros</div><div class="stat-value">${s.enfermeiros}</div><div class="stat-link">Abrir cadastro</div></div>
      <div class="stat-card" data-open="medicos"><div class="stat-title">Médicos</div><div class="stat-value">${s.medicos}</div><div class="stat-link">Abrir cadastro</div></div>
      <div class="stat-card" data-open="setores"><div class="stat-title">Setores</div><div class="stat-value">${s.setores}</div><div class="stat-link">Abrir cadastro</div></div>
      <div class="stat-card" data-open="tipos_exames"><div class="stat-title">Tipos de Exames</div><div class="stat-value">${s.tipos_exames}</div><div class="stat-link">Abrir cadastro</div></div>
      <div class="stat-card" data-open="exames"><div class="stat-title">Exames</div><div class="stat-value">${s.exames}</div><div class="stat-link">Abrir cadastro</div></div>
      <div class="stat-card" data-open="admins"><div class="stat-title">Administradores</div><div class="stat-value">${s.admins}</div><div class="stat-link">Gerenciar acessos</div></div>
    </div>
    <div class="home-info-list">
      <div class="home-info-row"><span><strong>Módulo Admin</strong> — Cadastros Estruturais</span><span>Postos, Profissionais, Setores e Exames</span></div>
      <div class="home-info-row"><span><strong>Navegação em Pastas</strong> — Menu lateral esquerdo</span><span>Clique nas pastas ou pesquise pelo nome</span></div>
    </div>
  </div>`;
  pane.querySelectorAll('.stat-card[data-open]').forEach(c => c.addEventListener('click', () => openModuleTab(c.dataset.open)));
}

/* ===== CRUD ===== */
async function loadModuleData(mid) {
  const mod = MODULES[mid], st = state.moduleState[mid]; showLoading(true);
  try {
    await refreshLookups(); st.items = await api('/api/' + mod.endpoint);
    if (st.items.length && st.selectedIndex < 0) st.selectedIndex = 0;
    else if (st.selectedIndex >= st.items.length) st.selectedIndex = st.items.length - 1;
    renderModulePane(mid);
  } catch (e) { toast(e.message, true); } finally { showLoading(false); }
}

function renderModulePane(mid) {
  const pane = document.querySelector(`.tab-pane[data-tab="${mid}"]`); if (!pane) return;
  const mod = MODULES[mid], st = state.moduleState[mid];
  const rec = st.mode === 'create' ? {} : (st.items[st.selectedIndex] || null);
  const editing = st.mode === 'create' || st.mode === 'edit';

  pane.innerHTML = `
    <div class="module-subtabs">
      <button class="subtab-btn ${st.subtab==='pesquisa'?'active':''}" data-subtab="pesquisa">Pesquisa</button>
      <button class="subtab-btn ${st.subtab==='manutencao'?'active':''}" data-subtab="manutencao">Manutenção</button>
    </div>
    <div class="module-body">${st.subtab==='pesquisa' ? renderSearch(mod,st) : renderForm(mod,st,rec)}</div>
    <div class="module-actionbar">
      <div class="action-group">
        <button class="btn-action" data-act="incluir" ${editing?'disabled':''}>+ Incluir</button>
        <button class="btn-action" data-act="editar" ${editing||!rec?'disabled':''}>Editar</button>
        <button class="btn-action btn-save" data-act="gravar" ${!editing?'disabled':''}>Gravar</button>
        <button class="btn-action" data-act="cancelar" ${!editing?'disabled':''}>Cancelar</button>
        <button class="btn-action btn-danger" data-act="excluir" ${editing||!rec?'disabled':''}>Excluir</button>
      </div>
      <div class="action-group">
        <button class="pager-btn" data-page="first" ${!st.items.length||st.selectedIndex<=0||editing?'disabled':''}>&laquo;</button>
        <button class="pager-btn" data-page="prev" ${!st.items.length||st.selectedIndex<=0||editing?'disabled':''}>&lsaquo;</button>
        <span style="font-size:11.5px;color:#475569;padding:0 3px">${st.items.length&&st.selectedIndex>=0?(st.selectedIndex+1)+' / '+st.items.length:'0 / 0'}</span>
        <button class="pager-btn" data-page="next" ${!st.items.length||st.selectedIndex>=st.items.length-1||editing?'disabled':''}>&rsaquo;</button>
        <button class="pager-btn" data-page="last" ${!st.items.length||st.selectedIndex>=st.items.length-1||editing?'disabled':''}>&raquo;</button>
        <button class="btn-action btn-exit" data-act="sair" style="margin-left:6px">Sair</button>
      </div>
    </div>`;

  pane.querySelectorAll('.subtab-btn').forEach(b => b.addEventListener('click', () => { st.subtab = b.dataset.subtab; renderModulePane(mid); }));
  const si = pane.querySelector('.js-search'); if (si) { si.value = st.search; si.addEventListener('input', e => { st.search = e.target.value; pane.querySelector('tbody').innerHTML = tableRows(mod,st); bindRows(pane,mid); }); }
  bindRows(pane, mid);
  pane.querySelectorAll('input[data-mask="cpf"]').forEach(i => i.addEventListener('input', e => { e.target.value = formatCpf(e.target.value); }));
  pane.querySelector('[data-act="incluir"]').addEventListener('click', () => { st.mode='create'; st.subtab='manutencao'; renderModulePane(mid); });
  pane.querySelector('[data-act="editar"]').addEventListener('click', () => { if (!rec) return; st.mode='edit'; st.subtab='manutencao'; renderModulePane(mid); });
  pane.querySelector('[data-act="cancelar"]').addEventListener('click', () => { st.mode='view'; renderModulePane(mid); });
  pane.querySelector('[data-act="gravar"]').addEventListener('click', () => saveRecord(mid));
  pane.querySelector('[data-act="excluir"]').addEventListener('click', () => deleteRecord(mid));
  pane.querySelector('[data-act="sair"]').addEventListener('click', e => closeTab(mid, e));
  pane.querySelectorAll('.pager-btn').forEach(b => b.addEventListener('click', () => {
    const p = b.dataset.page;
    if (p==='first') st.selectedIndex=0; if (p==='prev'&&st.selectedIndex>0) st.selectedIndex--;
    if (p==='next'&&st.selectedIndex<st.items.length-1) st.selectedIndex++; if (p==='last') st.selectedIndex=st.items.length-1;
    renderModulePane(mid);
  }));
}

function renderSearch(mod, st) {
  return `<div class="search-toolbar"><input type="text" class="js-search" placeholder="Filtrar registros..." /><span style="font-size:11.5px;color:#64748b">Duplo clique para abrir em Manutenção</span></div>
  <div class="data-table-wrap"><table class="data-table"><thead><tr>${mod.columns.map(c=>'<th'+(c.width?' style="width:'+c.width+'"':'')+'>'+esc(c.label)+'</th>').join('')}</tr></thead><tbody>${tableRows(mod,st)}</tbody></table></div>`;
}
function tableRows(mod, st) {
  const q = st.search.trim().toLowerCase();
  const f = st.items.map((r,i)=>({r,i})).filter(({r})=>!q||JSON.stringify(r).toLowerCase().includes(q));
  if (!f.length) return '<tr><td colspan="'+mod.columns.length+'" style="text-align:center;padding:16px;color:#64748b">Nenhum registro encontrado.</td></tr>';
  return f.map(({r,i})=>'<tr data-idx="'+i+'"'+(i===st.selectedIndex?' class="selected"':'')+'>'+mod.columns.map(c=>'<td>'+(c.render?c.render(r):esc(r[c.key]??''))+'</td>').join('')+'</tr>').join('');
}
function bindRows(pane, mid) {
  const st = state.moduleState[mid];
  pane.querySelectorAll('tbody tr[data-idx]').forEach(tr => {
    tr.addEventListener('click', () => { st.selectedIndex=+tr.dataset.idx; renderModulePane(mid); });
    tr.addEventListener('dblclick', () => { st.selectedIndex=+tr.dataset.idx; st.subtab='manutencao'; st.mode='view'; renderModulePane(mid); });
  });
}

function renderForm(mod, st, rec) {
  const editing = st.mode==='create'||st.mode==='edit', data = rec || {};
  if (!rec && st.mode==='view') return '<p style="color:#64748b;padding:10px">Nenhum registro selecionado. Clique em <strong>+ Incluir</strong> para criar.</p>';
  return '<form class="form-grid js-form" onsubmit="return false">' + mod.fields.map(f => {
    const v = st.mode==='create' ? (f.default!==undefined?f.default:'') : (data[f.name]!==undefined?data[f.name]:'');
    const dis = (!editing||f.readonly)?'disabled':'';
    if (f.type==='checkbox') return '<div class="form-field checkbox-field"><input type="checkbox" id="f_'+mod.endpoint+'_'+f.name+'" name="'+f.name+'" '+(v!==false?'checked':'')+' '+(!editing?'disabled':'')+'><label for="f_'+mod.endpoint+'_'+f.name+'">'+esc(f.label)+'</label></div>';
    if (f.type==='select') { const opts = state.lookups[f.source]||[]; return '<div class="form-field'+(f.full?' full-span':'')+'"><label>'+esc(f.label)+'</label><select name="'+f.name+'" '+dis+'><option value="">-- Selecione --</option>'+opts.map(o=>'<option value="'+o.id+'"'+(+v===+o.id?' selected':'')+'>'+esc(o.codigo?o.codigo+' - '+o.nome:o.nome)+'</option>').join('')+'</select></div>'; }
    if (f.type==='selectStatic') return '<div class="form-field'+(f.full?' full-span':'')+'"><label>'+esc(f.label)+'</label><select name="'+f.name+'" '+dis+'>'+f.options.map(o=>'<option value="'+esc(o)+'"'+(v===o?' selected':'')+'>'+esc(o)+'</option>').join('')+'</select></div>';
    if (f.type==='textarea') return '<div class="form-field'+(f.full?' full-span':'')+'"><label>'+esc(f.label)+'</label><textarea name="'+f.name+'" rows="3" '+dis+' placeholder="'+esc(f.placeholder||'')+'">'+esc(v)+'</textarea></div>';
    return '<div class="form-field'+(f.full?' full-span':'')+'"><label>'+esc(f.label)+'</label><input type="'+(f.type||'text')+'" name="'+f.name+'" value="'+esc(v)+'" '+(f.readonly?'readonly':'')+' '+(!editing?'disabled':'')+' '+(f.mask?'data-mask="'+f.mask+'"':'')+' placeholder="'+esc(f.placeholder||'')+'" /></div>';
  }).join('') + '</form>';
}

async function saveRecord(mid) {
  const pane = document.querySelector(`.tab-pane[data-tab="${mid}"]`), form = pane.querySelector('.js-form');
  const mod = MODULES[mid], st = state.moduleState[mid], payload = {};
  for (const f of mod.fields) {
    if (f.readonly) continue; const el = form.querySelector('[name="'+f.name+'"]'); if (!el) continue;
    if (f.type==='checkbox') { payload[f.name]=el.checked; continue; }
    if (f.type==='select') { payload[f.name]=el.value?+el.value:null; if (f.required&&!payload[f.name]) { toast('Preencha: '+f.label,true); el.focus(); return; } continue; }
    const v = el.value.trim(); if (f.required&&!v) { toast('Preencha: '+f.label,true); el.focus(); return; }
    if (mid==='admins'&&f.name==='senha'&&st.mode==='create'&&!v) { toast('Informe uma senha.',true); el.focus(); return; }
    payload[f.name]=v;
  }
  if (mid==='postos'&&payload.enfermeiroResponsavelId) payload.enfermeiroResponsavelNome=lookupName('enfermeiros',payload.enfermeiroResponsavelId);
  showLoading(true);
  try {
    if (st.mode==='create') {
      const c = await api('/api/'+mod.endpoint, { method:'POST', body:JSON.stringify(payload) });
      await refreshLookups(); st.items = await api('/api/'+mod.endpoint);
      st.selectedIndex = st.items.findIndex(x=>+x.id===+c.id); toast(mod.title+': incluído com sucesso!');
    } else {
      await api('/api/'+mod.endpoint+'/'+st.items[st.selectedIndex].id, { method:'PUT', body:JSON.stringify(payload) });
      await refreshLookups(); st.items = await api('/api/'+mod.endpoint); toast(mod.title+': atualizado!');
    }
    st.mode='view'; renderModulePane(mid);
  } catch (e) { toast(e.message,true); } finally { showLoading(false); }
}
async function deleteRecord(mid) {
  const mod = MODULES[mid], st = state.moduleState[mid], cur = st.items[st.selectedIndex];
  if (!cur||!confirm('Excluir "' + (cur.nome||cur.codigo) + '"?')) return;
  showLoading(true);
  try {
    await api('/api/'+mod.endpoint+'/'+cur.id, { method:'DELETE' });
    await refreshLookups(); st.items = await api('/api/'+mod.endpoint);
    st.selectedIndex = st.items.length ? Math.min(st.selectedIndex, st.items.length-1) : -1;
    st.mode='view'; toast('Registro excluído.'); renderModulePane(mid);
  } catch (e) { toast(e.message,true); } finally { showLoading(false); }
}

/* ===== Relógio e init ===== */
function tick() { const n=new Date(); const el=document.getElementById('statusDateTime'); if(el) el.textContent=n.toLocaleDateString('pt-BR')+' '+n.toLocaleTimeString('pt-BR'); }
setInterval(tick, 1000); tick();
if (state.token && state.user) enterApp();
