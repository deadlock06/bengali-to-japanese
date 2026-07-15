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
const OPENAI_KEY = process.env.OPENAI_API_KEY || '';

// POST /ai/chat → forward the OpenAI chat body with server-side auth.
function aiProxy(req, res) {
  if (!OPENAI_KEY) { res.writeHead(400); return res.end('{"error":"no key"}'); }
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    const upstream = https.request({
      host: 'api.openai.com', path: '/v1/chat/completions', method: 'POST',
      headers: { 'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_KEY}`, 'Content-Length': Buffer.byteLength(body) },
    }, (up) => {
      res.writeHead(up.statusCode || 502, { 'Content-Type': 'application/json' });
      up.pipe(res);
    });
    upstream.on('error', () => { res.writeHead(502); res.end('{"error":"upstream"}'); });
    upstream.end(body);
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
