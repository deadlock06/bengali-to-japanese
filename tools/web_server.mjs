// Serves the compiled Flutter web build (build/web) + a same-origin AI proxy.
// The proxy injects OPENAI_API_KEY (from the env — NEVER hardcoded) so the
// client never holds the key and there's no browser CORS. Run with:
//   OPENAI_API_KEY=sk-... node tools/web_server.mjs
import http from 'http';
import https from 'https';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'build', 'web');

// OpenAI-compatible providers. Each is used only if its key env var is set.
// Tried in order (DeepSeek → Kimi → OpenAI) with automatic failover, so free
// tiers that rate-limit degrade gracefully. Set one or more:
//   DEEPSEEK_API_KEY=...  MOONSHOT_API_KEY=...  OPENAI_API_KEY=...
// Hosts overridable (e.g. MOONSHOT_HOST=api.moonshot.cn for the CN endpoint).
const PROVIDERS = [
  { name: 'deepseek', host: process.env.DEEPSEEK_HOST || 'api.deepseek.com',
    key: process.env.DEEPSEEK_API_KEY, model: 'deepseek-chat' },
  { name: 'kimi', host: process.env.MOONSHOT_HOST || 'api.moonshot.ai',
    key: process.env.MOONSHOT_API_KEY || process.env.KIMI_API_KEY, model: 'kimi-latest' },
  { name: 'openai', host: 'api.openai.com',
    key: process.env.OPENAI_API_KEY, model: 'gpt-4o-mini' },
].filter((p) => p.key);

// POST /ai/chat → forward the chat body to the first available provider (with
// its own model), failing over to the next on any 5xx / network error.
function aiProxy(req, res) {
  if (PROVIDERS.length === 0) { res.writeHead(400); return res.end('{"error":"no provider key set"}'); }
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    let payload;
    try { payload = JSON.parse(body); } catch { res.writeHead(400); return res.end('{"error":"bad body"}'); }
    const tryProvider = (i) => {
      if (i >= PROVIDERS.length) { res.writeHead(502); return res.end('{"error":"all providers failed"}'); }
      const p = PROVIDERS[i];
      const out = Buffer.from(JSON.stringify({ ...payload, model: p.model }));
      const up = https.request({
        host: p.host, path: '/v1/chat/completions', method: 'POST',
        headers: { 'Content-Type': 'application/json',
          'Authorization': `Bearer ${p.key}`, 'Content-Length': out.length },
      }, (r) => {
        if ((r.statusCode || 500) >= 500) { r.resume(); return tryProvider(i + 1); }
        console.log(`ai: ${p.name} → ${r.statusCode}`);
        res.writeHead(r.statusCode || 502, { 'Content-Type': 'application/json' });
        r.pipe(res);
      });
      up.on('error', () => tryProvider(i + 1));
      up.end(out);
    };
    tryProvider(0);
  });
}
const MIME = { '.html':'text/html', '.js':'text/javascript', '.mjs':'text/javascript',
  '.json':'application/json', '.wasm':'application/wasm', '.css':'text/css',
  '.png':'image/png', '.jpg':'image/jpeg', '.svg':'image/svg+xml', '.ttf':'font/ttf',
  '.otf':'font/otf', '.woff':'font/woff', '.woff2':'font/woff2', '.ico':'image/x-icon',
  '.bin':'application/octet-stream', '.map':'application/json' };
http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/ai/chat') return aiProxy(req, res);
  let f = decodeURIComponent(req.url.split('?')[0]);
  if (f === '/') f = '/index.html';
  let p = path.join(root, f);
  if (!fs.existsSync(p) || fs.statSync(p).isDirectory()) p = path.join(root, 'index.html');
  const ext = path.extname(p).toLowerCase();
  res.writeHead(200, {
    'Content-Type': MIME[ext] || 'application/octet-stream',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
  });
  fs.createReadStream(p).pipe(res);
}).listen(5601, () => console.log('flutter web on http://localhost:5601'));
