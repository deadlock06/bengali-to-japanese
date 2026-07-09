import http from 'http';
import fs from 'fs';
import path from 'path';
const dir = path.join(process.cwd(), 'preview');
http.createServer((req, res) => {
  let f = req.url === '/' ? '/index.html' : req.url.split('?')[0];
  const p = path.join(dir, f);
  if (!fs.existsSync(p)) { res.writeHead(404); return res.end('nope'); }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  fs.createReadStream(p).pipe(res);
}).listen(5599, () => console.log('preview on http://localhost:5599'));
