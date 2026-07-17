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
// OFFLINE fallback (arch 08: llama.cpp + Qwen3 1.7B Q4_K_M): a local
// llama-server speaking the same OpenAI API. LAST in the chain — used when no
// cloud key works (or none set), so the sensei answers even fully offline.
//   tools/run_local_llm.sh   (starts it on 127.0.0.1:8089)
PROVIDERS.push({ name: 'local-qwen3', host: '127.0.0.1', port: 8089,
  insecure: true, key: 'local', model: 'qwen3' });

// POST /ai/chat → forward the chat body to the first available provider (with
// its own model), failing over to the next on any 5xx / network error.
function aiProxy(req, res) {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    let payload;
    try { payload = JSON.parse(body); } catch { res.writeHead(400); return res.end('{"error":"bad body"}'); }
    const tryProvider = (i) => {
      if (i >= PROVIDERS.length) { res.writeHead(502); return res.end('{"error":"all providers failed"}'); }
      const p = PROVIDERS[i];
      const out = Buffer.from(JSON.stringify({ ...payload, model: p.model }));
      const lib = p.insecure ? http : https; // local llama-server is plain http
      const up = lib.request({
        host: p.host, port: p.port, path: '/v1/chat/completions', method: 'POST',
        headers: { 'Content-Type': 'application/json',
          'Authorization': `Bearer ${p.key}`, 'Content-Length': out.length },
      }, (r) => {
        if ((r.statusCode || 500) >= 500) { r.resume(); return tryProvider(i + 1); }
        console.log(`ai: ${p.name} → ${r.statusCode}`);
        if (!p.insecure) {
          res.writeHead(r.statusCode || 502, { 'Content-Type': 'application/json' });
          return r.pipe(res);
        }
        // local Qwen3: strip leaked <think> reasoning tags before returning
        let buf = '';
        r.on('data', (c) => (buf += c));
        r.on('end', () => {
          try {
            const j = JSON.parse(buf);
            for (const ch of j.choices || []) {
              if (ch.message?.content) ch.message.content = ch.message.content
                .replace(/<think>[\s\S]*?<\/think>/g, '').replace(/^[\s]*<\/think>/, '').trim();
            }
            buf = JSON.stringify(j);
          } catch {/* pass through as-is */}
          res.writeHead(r.statusCode || 502, { 'Content-Type': 'application/json' });
          res.end(buf);
        });
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
  // Browsers that registered the OLD Flutter PWA worker cached the app so hard
  // that new builds never showed ("changes aren't visible"). Always serve the
  // self-destruct worker (web/) here: it wipes caches, unregisters, reloads.
  if (f === '/flutter_service_worker.js') {
    res.writeHead(200, { 'Content-Type': 'text/javascript', 'Cache-Control': 'no-cache' });
    return fs.createReadStream(path.join(root, '..', '..', 'web', 'flutter_service_worker.js')).pipe(res);
  }
  let p = path.join(root, f);
  if (!fs.existsSync(p) || fs.statSync(p).isDirectory()) p = path.join(root, 'index.html');
  const ext = path.extname(p).toLowerCase();
  res.writeHead(200, {
    'Content-Type': MIME[ext] || 'application/octet-stream',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    // Always revalidate — stale-build symptoms ("changes aren't visible")
    // came from the browser caching main.dart.js/assets with no headers.
    'Cache-Control': 'no-cache',
  });
  fs.createReadStream(p).pipe(res);
}).listen(process.env.PORT || 5601, () => console.log(`flutter web on http://localhost:${process.env.PORT || 5601}`));
