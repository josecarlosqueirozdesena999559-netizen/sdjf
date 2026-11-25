const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');
const DATA_FILE = path.join(__dirname, 'data', 'db.json');

const COLLECTIONS = [
  'admins',
  'postos',
  'enfermeiros',
  'medicos',
  'tipos_exames',
  'exames',
  'setores'
];

const DEFAULT_DATA = {
  admins: [
    {
      id: 1,
      codigo: '001',
      nome: 'Administrador Principal',
      cpf: '000.000.000-00',
      email: 'admin@saudegest.local',
      usuario: 'admin',
      senhaHash: hashPassword('admin123'),
      perfil: 'Administrador Geral',
      ativo: true,
      criadoEm: new Date().toISOString()
    }
  ],
  postos: [
    {
      id: 1,
      codigo: '001',
      nome: 'UBS Centro',
      localidade: 'Centro - Rua Principal, 100',
      enfermeiroResponsavelId: 1,
      enfermeiroResponsavelNome: 'Maria Clara Silva',
      telefone: '(88) 3434-0001',
      ativo: true
    },
    {
      id: 2,
      codigo: '002',
      nome: 'PSF Vila Nova',
      localidade: 'Bairro Vila Nova, S/N',
      enfermeiroResponsavelId: null,
      enfermeiroResponsavelNome: '',
      telefone: '(88) 3434-0002',
      ativo: true
    }
  ],
  enfermeiros: [
    {
      id: 1,
      codigo: '001',
      nome: 'Maria Clara Silva',
      cpf: '111.222.333-44',
      coren: 'COREN-CE 123456',
      postoId: 1,
      setorId: 1,
      telefone: '(88) 99999-1111',
      ativo: true
    }
  ],
  medicos: [
    {
      id: 1,
      codigo: '001',
      nome: 'Dr. João Pedro Almeida',
      cpf: '222.333.444-55',
      crm: 'CRM-CE 12345',
      especialidade: 'Clínico Geral',
      postoId: 1,
      setorId: 2,
      telefone: '(88) 99999-2222',
      ativo: true
    }
  ],
  tipos_exames: [
    {
      id: 1,
      codigo: '001',
      nome: 'Laboratorial',
      descricao: 'Análises clínicas de sangue, urina e fezes',
      ativo: true
    },
    {
      id: 2,
      codigo: '002',
      nome: 'Imagem',
      descricao: 'Raio-X, Ultrassonografia e exames radiológicos',
      ativo: true
    }
  ],
  exames: [
    {
      id: 1,
      codigo: '001',
      nome: 'Hemograma Completo',
      tipoExameId: 1,
      setorId: 3,
      preparo: 'Não exige jejum obrigatório',
      ativo: true
    }
  ],
  setores: [
    {
      id: 1,
      codigo: '001',
      nome: 'Triagem / Enfermagem',
      postoId: 1,
      descricao: 'Acolhimento e classificação de risco',
      ativo: true
    },
    {
      id: 2,
      codigo: '002',
      nome: 'Consultório Médico',
      postoId: 1,
      descricao: 'Atendimento ambulatorial',
      ativo: true
    },
    {
      id: 3,
      codigo: '003',
      nome: 'Laboratório',
      postoId: 1,
      descricao: 'Coleta e processamento de amostras',
      ativo: true
    }
  ]
};

const sessions = new Map();

function hashPassword(pwd) {
  return crypto.createHash('sha256').update(String(pwd)).digest('hex');
}

function ensureDataFile() {
  const dir = path.dirname(DATA_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(DEFAULT_DATA, null, 2), 'utf8');
  }
}

function readDb() {
  ensureDataFile();
  const raw = fs.readFileSync(DATA_FILE, 'utf8');
  return JSON.parse(raw);
}

function writeDb(db) {
  ensureDataFile();
  fs.writeFileSync(DATA_FILE, JSON.stringify(db, null, 2), 'utf8');
}

function nextIdAndCode(items) {
  const maxId = items.reduce((max, item) => Math.max(max, Number(item.id) || 0), 0);
  const newId = maxId + 1;
  return {
    id: newId,
    codigo: String(newId).padStart(3, '0')
  };
}

function sendJson(res, status, payload) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store'
  });
  res.end(JSON.stringify(payload));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => {
      data += chunk;
      if (data.length > 2 * 1024 * 1024) {
        reject(new Error('Payload muito grande'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!data) return resolve({});
      try {
        resolve(JSON.parse(data));
      } catch {
        reject(new Error('JSON inválido'));
      }
    });
    req.on('error', reject);
  });
}

function sanitizeAdmin(admin) {
  const { senhaHash, ...safe } = admin;
  return safe;
}

function getSession(req) {
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : '';
  if (!token) return null;
  return sessions.get(token) || null;
}

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.ico': 'image/x-icon'
};

function serveStatic(req, res, pathname) {
  let filePath = pathname === '/' ? '/index.html' : pathname;
  filePath = path.normalize(filePath).replace(/^(\.\.[/\\])+/, '');
  const fullPath = path.join(PUBLIC_DIR, filePath);

  if (!fullPath.startsWith(PUBLIC_DIR) || !fs.existsSync(fullPath) || fs.statSync(fullPath).isDirectory()) {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Arquivo não encontrado');
    return;
  }

  const ext = path.extname(fullPath).toLowerCase();
  res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
  fs.createReadStream(fullPath).pipe(res);
}

const server = http.createServer(async (req, res) => {
  const urlObj = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = urlObj.pathname;

  try {
    if (pathname === '/api/health' && req.method === 'GET') {
      return sendJson(res, 200, { ok: true, status: 'online' });
    }

    if (pathname === '/api/login' && req.method === 'POST') {
      const body = await readBody(req);
      const usuario = String(body.usuario || '').trim();
      const senha = String(body.senha || '');
      const db = readDb();
      const admin = db.admins.find(
        a => a.usuario.toLowerCase() === usuario.toLowerCase() && a.ativo !== false
      );

      if (!admin || admin.senhaHash !== hashPassword(senha)) {
        return sendJson(res, 401, { error: 'Usuário ou senha inválidos.' });
      }

      const token = crypto.randomBytes(24).toString('hex');
      const sessionData = {
        token,
        user: sanitizeAdmin(admin),
        createdAt: Date.now()
      };
      sessions.set(token, sessionData);

      return sendJson(res, 200, {
        token,
        user: sessionData.user,
        postos: db.postos.filter(p => p.ativo !== false)
      });
    }

    if (pathname === '/api/logout' && req.method === 'POST') {
      const auth = req.headers['authorization'] || '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : '';
      if (token) sessions.delete(token);
      return sendJson(res, 200, { ok: true });
    }

    if (pathname.startsWith('/api/')) {
      const session = getSession(req);
      if (!session) {
        return sendJson(res, 401, { error: 'Sessão expirada ou não autenticada.' });
      }

      if (pathname === '/api/summary' && req.method === 'GET') {
        const db = readDb();
        return sendJson(res, 200, {
          admins: db.admins.length,
          postos: db.postos.length,
          enfermeiros: db.enfermeiros.length,
          medicos: db.medicos.length,
          exames: db.exames.length,
          tipos_exames: db.tipos_exames.length,
          setores: db.setores.length
        });
      }

      const parts = pathname.replace(/^\/api\//, '').split('/');
      const collection = parts[0];
      const itemId = parts[1] ? Number(parts[1]) : null;

      if (!COLLECTIONS.includes(collection)) {
        return sendJson(res, 404, { error: 'Recurso não encontrado.' });
      }

      const db = readDb();
      const list = db[collection];

      if (req.method === 'GET' && !itemId) {
        const data = collection === 'admins' ? list.map(sanitizeAdmin) : list;
        return sendJson(res, 200, data);
      }

      if (req.method === 'POST' && !itemId) {
        const body = await readBody(req);
        const { id, codigo } = nextIdAndCode(list);

        if (collection === 'admins') {
          if (!body.nome || !body.usuario || !body.senha) {
            return sendJson(res, 400, { error: 'Nome, usuário e senha são obrigatórios.' });
          }
          const exists = list.some(a => a.usuario.toLowerCase() === String(body.usuario).trim().toLowerCase());
          if (exists) {
            return sendJson(res, 409, { error: 'Já existe um administrador com esse usuário.' });
          }
          const record = {
            id,
            codigo: body.codigo || codigo,
            nome: String(body.nome).trim(),
            cpf: String(body.cpf || '').trim(),
            email: String(body.email || '').trim(),
            usuario: String(body.usuario).trim(),
            senhaHash: hashPassword(body.senha),
            perfil: String(body.perfil || 'Administrador').trim(),
            ativo: body.ativo !== false,
            criadoEm: new Date().toISOString()
          };
          list.push(record);
          writeDb(db);
          return sendJson(res, 201, sanitizeAdmin(record));
        }

        const record = {
          ...body,
          id,
          codigo: body.codigo || codigo,
          ativo: body.ativo !== false
        };
        list.push(record);
        writeDb(db);
        return sendJson(res, 201, record);
      }

      if (req.method === 'PUT' && itemId) {
        const idx = list.findIndex(item => Number(item.id) === itemId);
        if (idx === -1) {
          return sendJson(res, 404, { error: 'Registro não encontrado.' });
        }
        const body = await readBody(req);

        if (collection === 'admins') {
          const existing = list[idx];
          const updated = {
            ...existing,
            nome: body.nome !== undefined ? String(body.nome).trim() : existing.nome,
            cpf: body.cpf !== undefined ? String(body.cpf).trim() : existing.cpf,
            email: body.email !== undefined ? String(body.email).trim() : existing.email,
            usuario: body.usuario !== undefined ? String(body.usuario).trim() : existing.usuario,
            perfil: body.perfil !== undefined ? String(body.perfil).trim() : existing.perfil,
            ativo: body.ativo !== undefined ? Boolean(body.ativo) : existing.ativo
          };
          if (body.senha && String(body.senha).trim() !== '') {
            updated.senhaHash = hashPassword(body.senha);
          }
          list[idx] = updated;
          writeDb(db);
          return sendJson(res, 200, sanitizeAdmin(updated));
        }

        const updated = {
          ...list[idx],
          ...body,
          id: itemId
        };
        list[idx] = updated;
        writeDb(db);
        return sendJson(res, 200, updated);
      }

      if (req.method === 'DELETE' && itemId) {
        const idx = list.findIndex(item => Number(item.id) === itemId);
        if (idx === -1) {
          return sendJson(res, 404, { error: 'Registro não encontrado.' });
        }
        if (collection === 'admins' && list.length === 1) {
          return sendJson(res, 400, { error: 'Não é possível excluir o único administrador.' });
        }
        list.splice(idx, 1);
        writeDb(db);
        return sendJson(res, 200, { ok: true });
      }

      return sendJson(res, 405, { error: 'Método não permitido.' });
    }

    serveStatic(req, res, pathname);
  } catch (err) {
    sendJson(res, 500, { error: err.message || 'Erro interno do servidor.' });
  }
});

ensureDataFile();
server.listen(PORT, () => {
  console.log(`SistemaSaude rodando em http://localhost:${PORT}`);
});
