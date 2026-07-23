// Serves the compiled Flutter web build (build/web) + a same-origin AI proxy.
// The proxy injects OPENAI_API_KEY (from the env — NEVER hardcoded) so the
// client never holds the key and there's no browser CORS. Run with:
//   OPENAI_API_KEY=sk-... node tools/web_server.mjs
import http from 'http';
import https from 'https';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { execFile } from 'child_process';
import { fileURLToPath } from 'url';
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, '..', 'build', 'web');

// ── .env loader (zero-dependency) ───────────────────────────────────────────
// Loads KEY=VALUE lines from the repo-root `.env` (gitignored) so AI provider
// keys live in ONE place instead of the command line. Real env vars always win
// (never overridden), so `KEY=... node ...` still works. Missing file = no-op.
(() => {
  try {
    const envPath = path.join(here, '..', '.env');
    for (const raw of fs.readFileSync(envPath, 'utf8').split('\n')) {
      const line = raw.trim();
      if (!line || line.startsWith('#')) continue;
      const eq = line.indexOf('=');
      if (eq < 1) continue;
      const key = line.slice(0, eq).trim();
      let val = line.slice(eq + 1).trim();
      const quoted = (val.startsWith('"') && val.endsWith('"')) ||
          (val.startsWith("'") && val.endsWith("'"));
      if (quoted) {
        val = val.slice(1, -1);
      } else {
        // Strip an inline comment: an API key never contains '#', so anything
        // from the first '#' on is the template's descriptive comment (this is
        // what turned `KEY=  # deepseek — https://…` into a bogus key that
        // crashed the Authorization header). Comment-only value → empty.
        const h = val.indexOf('#');
        if (h !== -1) val = val.slice(0, h).trim();
      }
      // A real key is a single printable-ASCII token — reject anything with a
      // space or non-ASCII char (em-dash, smart-quote) so a malformed paste is
      // treated as "no key" (provider skipped) instead of a fatal header.
      if (val && !/^[\x21-\x7e]+$/.test(val)) {
        console.warn(`.env: ${key} looks malformed (spaces/odd chars) — ignoring it`);
        val = '';
      }
      if (process.env[key] === undefined) process.env[key] = val;
    }
    console.log('loaded .env');
  } catch { /* no .env — fine, use process env only */ }
})();

// ── /ai/tts — neural Bengali/Japanese speech for the sensei (D-033) ─────────
// The device/browser TTS for dynamic Bengali replies is robotic ("sounds
// worst"); this synthesizes with the same neural voices the bundled clips use.
// GET /ai/tts?text=...&voice=bn|ja → audio/mpeg. Injection-safe: execFile
// passes argv directly (no shell); text capped; results cached by hash.
const EDGE_TTS = path.join(here, '..', '.venv-tts', 'bin', 'edge-tts');
const TTS_CACHE = path.join(here, '..', '.tts-cache');
const TTS_VOICES = { bn: 'bn-BD-NabanitaNeural', ja: 'ja-JP-NanamiNeural' };
function aiTts(req, res, urlObj) {
  const text = (urlObj.searchParams.get('text') || '').slice(0, 600).trim();
  const voice = TTS_VOICES[urlObj.searchParams.get('voice') || 'bn'] || TTS_VOICES.bn;
  if (!text || !fs.existsSync(EDGE_TTS)) { res.writeHead(404); return res.end(); }
  fs.mkdirSync(TTS_CACHE, { recursive: true });
  const f = path.join(TTS_CACHE,
    crypto.createHash('sha1').update(`${voice}|${text}`).digest('hex') + '.mp3');
  const serve = () => {
    res.writeHead(200, { 'Content-Type': 'audio/mpeg', 'Cache-Control': 'max-age=86400' });
    fs.createReadStream(f).pipe(res);
  };
  if (fs.existsSync(f) && fs.statSync(f).size > 0) return serve();
  execFile(EDGE_TTS, ['--voice', voice, '--rate=-8%', '--text', text,
    '--write-media', f], { timeout: 20000 }, (err) => {
    if (err || !fs.existsSync(f) || !fs.statSync(f).size) {
      try { fs.unlinkSync(f); } catch {}
      res.writeHead(502); return res.end();
    }
    console.log(`tts: ${voice} ${text.length} chars`);
    serve();
  });
}

// ── TIERED PROVIDER ROUTING (D-031: minimize API cost, maximize teaching) ──
// The client tags each request with `tier`:
//   'quick' → CHEAP chain — free/cheap models for dictionary lookups & small
//             answers (DeepSeek → Kimi → Gemini Flash → GPT-4o-mini).
//   'teach' → TEACH chain — the strongest available model for real teaching
//             (Claude → Gemini Pro → GPT-4o), falling back to the cheap chain.
// Each provider is used only if its key env var is set:
//   ANTHROPIC_API_KEY  GEMINI_API_KEY  DEEPSEEK_API_KEY  MOONSHOT_API_KEY
//   OPENAI_API_KEY
// kind 'openai'    = OpenAI-compatible /chat/completions (Bearer auth)
// kind 'anthropic' = native Anthropic Messages API (raw HTTPS, x-api-key) —
//                    request/response adapted so the Flutter client is unchanged.
const K = process.env;
const CHEAP = [
  { name: 'deepseek', kind: 'openai', host: K.DEEPSEEK_HOST || 'api.deepseek.com',
    path: '/v1/chat/completions', key: K.DEEPSEEK_API_KEY, model: 'deepseek-chat' },
  { name: 'kimi', kind: 'openai', host: K.MOONSHOT_HOST || 'api.moonshot.ai',
    path: '/v1/chat/completions', key: K.MOONSHOT_API_KEY || K.KIMI_API_KEY, model: 'kimi-latest' },
  { name: 'gemini-flash', kind: 'openai', host: 'generativelanguage.googleapis.com',
    path: '/v1beta/openai/chat/completions', key: K.GEMINI_API_KEY, model: 'gemini-2.5-flash' },
  { name: 'openai-mini', kind: 'openai', host: 'api.openai.com',
    path: '/v1/chat/completions', key: K.OPENAI_API_KEY, model: 'gpt-4o-mini' },
].filter((p) => p.key);
const TEACH = [
  { name: 'claude', kind: 'anthropic', host: 'api.anthropic.com',
    key: K.ANTHROPIC_API_KEY, model: 'claude-opus-4-8' },
  { name: 'gemini-pro', kind: 'openai', host: 'generativelanguage.googleapis.com',
    path: '/v1beta/openai/chat/completions', key: K.GEMINI_API_KEY, model: 'gemini-2.5-pro' },
  { name: 'openai', kind: 'openai', host: 'api.openai.com',
    path: '/v1/chat/completions', key: K.OPENAI_API_KEY, model: 'gpt-4o' },
].filter((p) => p.key);
// Local Qwen3-1.7B fallback — DISABLED by default (D-025 / correctness). A raw
// 1.7B model's Bengali↔Japanese is weak and can INVENT grammar, which violates
// "correctness over generation" (docs/00). So it is NOT in the learner-facing
// chain: when every cloud provider fails, the proxy returns nothing and the app
// falls back to VERIFIED content (ContentRepository.explainOffline /
// handleOfflineChat) — never fabricated grammar. Enable only for local dev
// experiments with ENABLE_LOCAL_LLM=1 (its output is UNVERIFIED — never ship it
// as the default). Real offline AI = the constrained on-device path (GBNF +
// whitelist + RAG), which is step D4, not this raw server.
if (K.ENABLE_LOCAL_LLM === '1') {
  CHEAP.push({ name: 'local-qwen3', kind: 'openai', host: '127.0.0.1', port: 8089,
    path: '/v1/chat/completions', insecure: true, key: 'local', model: 'qwen3' });
}

// Native Anthropic Messages API call (raw HTTPS — this server has zero npm
// deps by design). Adapts the client's OpenAI-style body → /v1/messages and
// the response back to the OpenAI choices[] shape the app already parses.
function callAnthropic(p, payload, ok, fail) {
  const msgs = payload.messages || [];
  const system = msgs.filter((m) => m.role === 'system').map((m) => m.content).join('\n\n');
  const turns = msgs.filter((m) => m.role !== 'system')
    .map((m) => ({ role: m.role === 'assistant' ? 'assistant' : 'user', content: String(m.content) }));
  if (!turns.length) return fail();
  const out = Buffer.from(JSON.stringify({
    model: p.model,
    max_tokens: payload.max_tokens || 1024,
    ...(system ? { system } : {}),
    messages: turns,
  }));
  const up = https.request({
    host: p.host, path: '/v1/messages', method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-api-key': p.key,
      'anthropic-version': '2023-06-01', 'Content-Length': out.length },
  }, (r) => {
    let buf = '';
    r.on('data', (c) => (buf += c));
    r.on('end', () => {
      if ((r.statusCode || 500) >= 400) return fail(); // incl. 429 → next provider
      try {
        const j = JSON.parse(buf);
        if (j.stop_reason === 'refusal') return fail(); // safety decline → fall through
        const text = (j.content || []).filter((b) => b.type === 'text').map((b) => b.text).join('');
        if (!text) return fail();
        ok({ choices: [{ message: { role: 'assistant', content: text } }] });
      } catch { fail(); }
    });
  });
  up.on('error', fail);
  up.end(out);
}

// POST /ai/chat → route by tier, failing over down the chain on any error.
function aiProxy(req, res) {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    let payload;
    try { payload = JSON.parse(body); } catch { res.writeHead(400); return res.end('{"error":"bad body"}'); }
    const tier = payload.tier === 'teach' ? 'teach' : 'quick';
    delete payload.tier; // internal routing field — never forwarded upstream
    // teach: strongest first, then the cheap chain as availability fallback
    const chain = tier === 'teach'
      ? [...TEACH, ...CHEAP.filter((c) => !TEACH.some((t) => t.name === c.name))]
      : CHEAP;
    const tryProvider = (i) => {
      if (i >= chain.length) { res.writeHead(502); return res.end('{"error":"all providers failed"}'); }
      const p = chain[i];
      if (p.kind === 'anthropic') {
        return callAnthropic(p, payload,
          (j) => {
            console.log(`ai[${tier}]: ${p.name} → 200`);
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(j));
          },
          () => tryProvider(i + 1));
      }
      const out = Buffer.from(JSON.stringify({ ...payload, model: p.model }));
      const lib = p.insecure ? http : https; // local llama-server is plain http
      // A malformed key (stray space / em-dash from a bad paste) makes
      // lib.request() THROW synchronously on the Authorization header; that
      // used to crash the whole proxy. Catch it and fail over to the next
      // provider instead — one bad key never takes the server down.
      let up;
      try {
        up = lib.request({
          host: p.host, port: p.port, path: p.path, method: 'POST',
          headers: { 'Content-Type': 'application/json',
            'Authorization': `Bearer ${p.key}`, 'Content-Length': out.length },
        }, (r) => {
        if ((r.statusCode || 500) >= 500) { r.resume(); return tryProvider(i + 1); }
        console.log(`ai[${tier}]: ${p.name} → ${r.statusCode}`);
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
      } catch (e) {
        console.warn(`ai[${tier}]: ${p.name} skipped (${e.code || 'bad request'})`);
        return tryProvider(i + 1);
      }
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
  if (req.url.startsWith('/ai/tts')) {
    return aiTts(req, res, new URL(req.url, 'http://x'));
  }
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
