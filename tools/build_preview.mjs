// Builds a self-contained, clickable HTML preview of the Bhasago app from the
// REAL content (lessons, curriculum.json, book.json, kana strokes), so the
// current app state can be seen without a Flutter SDK. Mirrors the v4 "Bold
// Ink" design + the 2026-07-12 wiring: live classroom batch (T-112 port),
// mood staging (handoff local rules; the on-device app additionally runs the
// 4-agent bus), note.bn reasoning bubble, curriculum timeline, Bhasha Go book
// reader (T-121 slice), kana writing with sound context + intro card.
// THIS IS A SIMULATION for preview only — grading/data logic is ported 1:1
// where it matters (batch builder = tools/batch_reference.mjs port).
// Emits preview/index.html (standalone) + preview/sensei_body.html.
// Run: node tools/build_preview.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const read = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), 'utf8'));

// ── real data ────────────────────────────────────────────────────────────────
const hira = read('assets/content/hiragana.json').items;
const kata = read('assets/content/katakana.json').items;
const strokes = read('assets/stroke/kana_strokes.json');
const curriculum = read('assets/curriculum/curriculum.json');
const book = read('assets/book/book.json').chapters;

const lessonsById = {};
for (const f of fs.readdirSync(path.join(ROOT, 'assets/content'))
    .filter((f) => f.startsWith('lesson_'))) {
  const l = read(path.join('assets/content', f));
  lessonsById[l.id] = l;
}
const units = Array.isArray(curriculum) ? curriculum : curriculum.units;
const ordered = [];
for (const u of units) {
  for (const id of (u.lesson_id ?? '').split(',').map((s) => s.trim()).filter(Boolean)) {
    if (lessonsById[id] && !ordered.includes(lessonsById[id])) ordered.push(lessonsById[id]);
  }
}
for (const l of Object.values(lessonsById)) if (!ordered.includes(l)) ordered.push(l);

const BN = ['আ','ই','উ','এ','ও','কা','কি','কু','কে','কো','সা','শি','সু','সে','সো',
  'তা','চি','ৎসু','তে','তো','না','নি','নু','নে','নো','হা','হি','ফু','হে','হো',
  'মা','মি','মু','মে','মো','ইয়া','ইউ','ইয়ো','রা','রি','রু','রে','রো','ওয়া','ও','ন'];

const DATA = {
  hira: hira.map((k, i) => ({ char: k.char, romaji: k.romaji, bn: BN[i] ?? '' })),
  kata: kata.map((k, i) => ({ char: k.char, romaji: k.romaji, bn: BN[i] ?? '' })),
  strokes,
  units: units.map((u) => ({
    id: u.id, level: u.level ?? '', title: u.title?.bn ?? u.id,
    canDo: u.can_do?.bn ?? '', lessonIds: (u.lesson_id ?? '').split(',').map((s) => s.trim()).filter(Boolean),
  })),
  lessons: ordered.map((l) => ({
    id: l.id, canDo: l.can_do?.bn ?? l.id,
    items: l.items.map((it) => ({
      id: it.id, jp: it.jp, kana: it.kana, romaji: it.romaji,
      bn: it.meaning.bn, note: it.note.bn,
    })),
  })),
  book: book.map((c) => ({ id: c.id, num: c.num, title: c.title, part: c.part,
    blocks: (c.blocks ?? []).slice(0, 60) })),
};

// ── T-112 port (tools/batch_reference.mjs, 11/11) ────────────────────────────
const BATCH_JS = `
const seed=(s)=>[...s].reduce((a,c)=>(a+c.charCodeAt(0))&0x7fffffff,0);
function buildBatch(lessons,completed,maxItems=8){
  const next=lessons.find(l=>!completed.has(l.id)&&l.items.length>0);
  if(!next)return null;
  const poolL=[],poolG=[];
  for(const it of next.items)if(!poolL.includes(it.bn))poolL.push(it.bn);
  for(const l of lessons){if(l===next)continue;
    for(const it of l.items){if(!poolL.includes(it.bn)&&!poolG.includes(it.bn))poolG.push(it.bn);}}
  const qs=[];const items=next.items.slice(0,maxItems);
  for(let i=0;i<items.length;i++){const it=items[i];const correct=it.bn;const d=[];
    const local=poolL.filter(m=>m!==correct);
    for(let k=0;k<local.length&&d.length<3;k++)d.push(local[(k+i)%local.length]);
    for(let k=0;k<poolG.length&&d.length<3;k++)d.push(poolG[(k+i)%poolG.length]);
    if(d.length<3)continue;
    const ai=seed(it.id)%4;const opts=[...d];opts.splice(ai,0,correct);
    const head=(it.kana||it.jp)[0];
    qs.push({jp:it.jp,yomi:it.kana+' · '+it.romaji,options:opts,answer:ai,
      hint:'「'+head+'」 দিয়ে শুরু — '+it.note,note:it.note});}
  return qs.length?{lessonId:next.id,title:next.canDo,qs}:null;
}`;

const STYLE = `<style>
:root{--bg:#0F0F0F;--card:#1A1A1A;--card2:#242424;--line:#2E2E2E;--pill:#3A3A3A;
--text:#F5F5F0;--muted:#8F8F8A;--yellow:#EFE94B;--pink:#F06EB7;--blue:#4D7DF7;
--green:#35E065;--red:#B3121B;--redsub:#F5B8BC;--struggle:#F0954B;--bore:#A78BF7;--onacc:#111;
--font:-apple-system,"Segoe UI",Roboto,"Noto Sans Bengali","Noto Sans JP","Hiragino Sans",sans-serif}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{margin:0;background:#000;font-family:var(--font);color:var(--text)}
.stage{display:flex;justify-content:center;padding:18px}
.phone{width:390px;height:844px;background:var(--bg);border-radius:34px;border:1px solid var(--line);
overflow:hidden;display:flex;flex-direction:column;position:relative}
.screen{flex:1;overflow-y:auto;padding:16px;display:none}
.screen.on{display:block}
.nav{display:flex;border-top:1px solid var(--line);background:var(--bg);padding:8px 10px;gap:6px}
.nav button{flex:1;border:0;background:transparent;color:var(--muted);font-family:var(--font);
font-size:11px;padding:8px 4px;border-radius:99px;cursor:pointer;font-weight:700}
.nav button.on{background:#fff;color:#111}
h1{font-size:26px;margin:4px 0 12px;font-weight:800}
.row{display:flex;justify-content:space-between;align-items:center}
.small{font-size:12px;color:var(--muted)}
.bar{height:8px;border-radius:99px;background:#262626;overflow:hidden;margin:6px 0 14px}
.bar i{display:block;height:100%;background:var(--yellow)}
.acc{border-radius:20px;padding:16px;margin-bottom:10px;cursor:pointer;color:var(--onacc)}
.acc h3{margin:0 0 4px;font-size:15px}.acc p{margin:0;font-size:11.5px;opacity:.8}
.card{background:var(--card);border:1px solid var(--line);border-radius:20px;padding:14px;margin-bottom:10px}
.pillbtn{border:1.5px solid var(--pill);background:transparent;color:var(--text);border-radius:99px;
min-height:44px;padding:0 16px;font-family:var(--font);font-weight:700;font-size:12.5px;cursor:pointer}
.pillbtn.acc2{border-color:transparent;color:#111}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:9px}
.opt{border:1.5px solid var(--pill);border-radius:99px;min-height:46px;background:transparent;
color:var(--text);font-family:var(--font);font-weight:700;font-size:13px;cursor:pointer}
.moodpill{border:1.5px solid;border-radius:99px;padding:3px 11px;font-size:11px;font-weight:700;
display:inline-flex;align-items:center;gap:6px}
.dot{width:6px;height:6px;border-radius:50%;display:inline-block}
.jp{font-size:54px;font-weight:900;text-align:center;margin:6px 0 0}
.yomi{text-align:center;font-size:13.5px;color:var(--muted);font-weight:700;margin-bottom:12px}
.qlabel{text-align:center;font-size:11.5px;font-weight:700;letter-spacing:.5px}
.hint{border:1.5px solid;border-radius:16px;padding:12px 14px;font-size:12.5px;margin-top:10px}
.teacher{display:flex;align-items:flex-end;gap:10px;margin-top:14px}
.bubble{background:var(--card);border:1px solid var(--line);border-radius:14px 14px 14px 3px;
padding:8px 12px;font-size:12px;max-width:250px}
.toolbar{display:flex;gap:10px;margin-top:12px}
.sheet{position:absolute;left:0;right:0;bottom:0;height:76%;background:#141414;border-top:1px solid var(--line);
border-radius:24px 24px 0 0;padding:12px 16px;display:none;flex-direction:column;z-index:9}
.sheet.on{display:flex}
.msg{max-width:280px;padding:9px 13px;border-radius:16px;font-size:12.5px;margin:4px 0;line-height:1.5}
.chips{display:flex;gap:8px;overflow-x:auto;padding:6px 0}
.chips button{white-space:nowrap;border:1px solid var(--line);background:transparent;color:var(--muted);
border-radius:99px;min-height:34px;padding:0 14px;font-size:11.5px;font-weight:700;cursor:pointer;font-family:var(--font)}
.tl{display:flex;gap:12px;margin-bottom:8px}
.tl .dotcol{width:34px;display:flex;flex-direction:column;align-items:center}
.tl .knot{width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:15px}
.tl .conn{flex:1;width:2px;background:#242424}
.ucard{flex:1;background:var(--card);border:1px solid var(--line);border-radius:16px;padding:12px;margin-bottom:4px}
.ucard.cur{background:var(--red);border-color:var(--red);color:#F5F5F0}
canvas.paper{background:#FBFBFD;border-radius:20px;width:100%;touch-action:none}
.kstrip{display:flex;overflow-x:auto;gap:8px;padding:6px 0}
.kstrip div{min-width:46px;height:42px;border-radius:12px;background:#ffffff1a;display:flex;
align-items:center;justify-content:center;font-size:22px;cursor:pointer}
.kstrip div.on{background:var(--pink)}
.chap{display:flex;align-items:center;gap:12px;background:var(--card);border:1px solid var(--line);
border-radius:16px;padding:12px;margin-bottom:8px;cursor:pointer}
.chnum{width:34px;height:34px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-weight:800}
.back{background:transparent;border:0;color:var(--muted);font-size:18px;cursor:pointer;padding:6px 10px 6px 0}
.note{font-size:10.5px;color:#5A6472;text-align:center;padding:6px}
table{border-collapse:collapse;font-size:11.5px;margin:6px 0}
td,th{border:1px solid var(--line);padding:4px 8px}
blockquote{border-left:3px solid var(--green);margin:6px 0;padding:4px 10px;color:var(--muted);font-size:12px}
.depth{position:absolute;inset:0;pointer-events:none;overflow:hidden}
.sun{position:absolute;top:46px;right:-34px;width:150px;height:150px;border-radius:50%;background:radial-gradient(circle at 42% 38%,rgba(216,64,64,.34),rgba(216,64,64,.1) 62%,transparent 78%);animation:sunPulse 7s ease-in-out infinite}
.fk{position:absolute;font-weight:900}
@keyframes sunPulse{0%,100%{transform:scale(1);opacity:.5}50%{transform:scale(1.06);opacity:.7}}
@keyframes floatA{0%,100%{transform:translate(0,0)}50%{transform:translate(6px,-14px)}}
@keyframes floatB{0%,100%{transform:translate(0,0)}50%{transform:translate(-10px,12px)}}
@keyframes starSpin{0%,100%{transform:rotate(0) scale(1)}50%{transform:rotate(12deg) scale(1.08)}}
@keyframes pulseDot{0%,100%{opacity:.25}50%{opacity:1}}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
</style>`;

const BODY = `
<div class="stage"><div class="phone">
  <div class="depth" aria-hidden="true">
    <div class="sun"></div>
    <svg width="100%" height="90" viewBox="0 0 322 90" style="position:absolute;bottom:54px;left:0;opacity:.07"><g fill="none" stroke="#F5F5F0" stroke-width="1"><path d="M-20 90 a40 40 0 0 1 80 0 M60 90 a40 40 0 0 1 80 0 M140 90 a40 40 0 0 1 80 0 M220 90 a40 40 0 0 1 80 0"/><path d="M-20 90 a28 28 0 0 1 56 0 M60 90 a28 28 0 0 1 56 0 M140 90 a28 28 0 0 1 56 0 M220 90 a28 28 0 0 1 56 0" transform="translate(12,0)"/></g></svg>
    <div class="fk" style="top:120px;left:8px;font-size:64px;color:rgba(245,245,240,.045);animation:floatA 12s ease-in-out infinite">語</div>
    <div class="fk" style="top:300px;right:6px;font-size:50px;color:rgba(216,64,64,.07);animation:floatB 15s ease-in-out infinite">あ</div>
    <div class="fk" style="top:430px;left:20px;font-size:40px;color:rgba(245,245,240,.04);animation:floatA 17s ease-in-out infinite 2s">ん</div>
  </div>
  <div id="scr-home" class="screen on"></div>
  <div id="scr-learn" class="screen"></div>
  <div id="scr-speak" class="screen"></div>
  <div id="scr-progress" class="screen"></div>
  <div id="scr-lesson" class="screen"></div>
  <div id="scr-curr" class="screen"></div>
  <div id="scr-book" class="screen"></div>
  <div id="scr-write" class="screen"></div>
  <div id="sheet" class="sheet"></div>
  <div class="nav" id="nav">
    <button data-t="home" class="on">🏠 হোম</button>
    <button data-t="learn">🎓 শেখা</button>
    <button data-t="speak">🎤 বলা</button>
    <button data-t="progress">📈 অগ্রগতি</button>
  </div>
</div></div>
<p class="note">PREVIEW — HTML mirror of the real app state (real content, T-112 batch port). The Flutter app additionally runs the 4-agent bus, SRS persistence and brand fonts.</p>
<script>
const DATA=%%DATA%%;
%%BATCH%%
const MOODS={neutral:['#EFE94B','পরিচিতি','ধীরে ধীরে — সময় আছে।'],
flow:['#35E065','ফ্লো · দারুণ চলছে','এই গতিতেই থাকো!'],
struggle:['#F0954B','একসাথে দেখি','চলো একসাথে ভাবি — সমস্যা নেই।'],
burnout:['#4D7DF7','বিশ্রামের সময়','একটু বিরতি নিলে ভালো হয়।'],
boredom:['#A78BF7','খুব সহজ লাগছে?','সহজ লাগছে? আরও কঠিন আসছে।']};
const bn=n=>String(n).split('').map(d=>'০১২৩৪৫৬৭৮৯'[+d]).join('');
const $=id=>document.getElementById(id);
const completed=new Set(); // session-only (the app persists via SQLCipher)
const LANGS={bn:'বাংলা',en:'English',ja:'日本語'};let lang='bn';
function cycleLang(){const o=['bn','en','ja'];lang=o[(o.indexOf(lang)+1)%3];render();}
let greetTimer=null;
function typeGreet(){const el=document.getElementById('aitxt');if(!el)return;
  const b=buildBatch(DATA.lessons,completed);
  const full=b?('আজ "'+b.title+'" — '+bn(b.qs.length)+'টা নতুন শব্দ, প্রস্তুত?'):'সব পাঠ শেষ — ফ্রি অনুশীলন চলো!';
  clearInterval(greetTimer);let i=0;
  greetTimer=setInterval(()=>{i+=2;el.textContent=full.slice(0,i);if(i>=full.length)clearInterval(greetTimer);},30);}
let tab='home',push=null;

function show(){for(const s of document.querySelectorAll('.screen'))s.classList.remove('on');
  $('scr-'+(push??tab)).classList.add('on');
  for(const b of document.querySelectorAll('#nav button'))b.classList.toggle('on',b.dataset.t===tab&&!push);}
$('nav').onclick=e=>{const t=e.target.closest('button');if(!t)return;tab=t.dataset.t;push=null;render();};
function go(p){push=p;render();}
function pop(){push=null;render();}

// ── HOME ──
function rHome(){
  const totalL=DATA.lessons.length,doneL=DATA.lessons.filter(l=>completed.has(l.id)).length;
  const pct=totalL?Math.round(100*doneL/totalL):0;
  $('scr-home').innerHTML=\`
  <div class="row" style="margin-bottom:8px">
    <button class="pillbtn" style="min-height:34px;font-size:12px" onclick="cycleLang()">\${LANGS[lang]} ▾</button>
    <div style="display:flex;gap:10px;align-items:center">
      <span style="cursor:pointer;font-size:17px" onclick="go('write')" title="Write">✍️</span>
      <div style="width:34px;height:34px;border-radius:50%;background:var(--yellow);color:#111;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px">র</div>
    </div></div>
  <h1 style="margin:0 0 10px">হাই, রাফি</h1>
  <div class="row"><span class="small">কোর্স অগ্রগতি</span><b>\${bn(pct)}%</b></div>
  <div class="bar"><i style="width:\${pct}%"></i></div>
  <div class="acc" style="background:var(--red);color:#F5F5F0;position:relative" onclick="startLesson()">
    <svg width="34" height="34" viewBox="0 0 34 34" style="position:absolute;top:12px;right:12px;animation:starSpin 5s ease-in-out infinite"><path d="M17 0 L20 13 L33 17 L20 21 L17 34 L14 21 L1 17 L14 13 Z" fill="#F5F5F0"/></svg>
    <h3 style="color:#F5F5F0">AI ক্লাসরুম</h3><p style="color:var(--redsub)">\${(buildBatch(DATA.lessons,completed)||{title:'কনবিনিতে কেনাকাটা — Can-do'}).title}</p>
    <div style="margin-top:12px;background:#111;border-radius:999px;height:26px;display:flex;align-items:center;padding:0 4px">
      <div style="height:18px;width:\${Math.max(6,pct)}%;background:#F5F5F0;border-radius:999px;position:relative">
        <div style="position:absolute;right:-1px;top:-4px;width:26px;height:26px;border-radius:50%;background:var(--red);border:3px solid #111;box-sizing:border-box"></div>
      </div></div></div>
  <div class="grid2">
    <div class="acc" style="background:var(--pink)"><h3>আজকের রিভিউ</h3><p>\${bn(0)}টা কার্ড ডিউ</p></div>
    <div class="acc" style="background:var(--blue)"><h3>AI চেক</h3><p>মক পরীক্ষা দাও</p></div></div>
  <div class="card" style="display:flex;gap:12px;align-items:center;cursor:pointer" onclick="go('book')">
    <div style="width:34px;height:44px;border-radius:6px;background:linear-gradient(160deg,#2E7D5B,#1F5C42);
      display:flex;align-items:center;justify-content:center;font-size:15px">語</div>
    <div style="flex:1"><b style="font-size:13px">ভাষা গো</b><div class="small">অধ্যায় \${bn(1)} চলছে</div></div>
    <span style="color:var(--green)">›</span></div>
  <div class="row" style="margin:6px 0 8px"><span class="small">এই সপ্তাহের টপিক</span>
    <span class="small" style="cursor:pointer" onclick="tab='learn';push=null;render()">সব দেখো ›</span></div>
  \${DATA.lessons.slice(0,3).map(l=>\`<div class="card" style="padding:12px 14px;font-size:12.5px;cursor:pointer" onclick="tab='learn';push=null;render()">\${l.canDo}</div>\`).join('')}
  <div style="border:1.5px solid #F5F5F0;border-radius:999px;padding:11px 16px;display:flex;align-items:center;gap:9px;cursor:pointer;margin-top:4px" onclick="startLesson()">
    <span style="width:7px;height:7px;border-radius:50%;background:var(--green);animation:pulseDot 1.4s ease-in-out infinite;flex-shrink:0"></span>
    <div id="aitxt" style="flex:1;font-size:12.5px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis"></div>
    <span>→</span></div>\`;
  typeGreet();
}

// ── CLASSROOM (T-112 live batch + mood staging + reasoning bubble) ──
let L=null;
function startLesson(){
  const b=buildBatch(DATA.lessons,completed);
  L=b?{...b,idx:0,streak:0,wrongs:0,picked:-1,hints:0,done:false,mood:'neutral',note:null,free:false}
     :{lessonId:null,title:'ফ্রি অনুশীলন',qs:[],idx:0,done:true,mood:'neutral',free:true};
  go('lesson');
}
function rLesson(){
  if(!L){startLesson();return;}
  const m=MOODS[L.mood],q=L.qs[Math.min(L.idx,L.qs.length-1)];
  $('scr-lesson').innerHTML=L.done?\`
    <div style="display:flex;height:100%;align-items:center">
    <div class="card" style="flex:1;text-align:center;border-color:var(--green)">
      <div style="font-size:38px">🎉</div><h2 style="margin:6px 0">পাঠ শেষ!</h2>
      <p class="small">\${bn(L.qs.length)}টি নতুন শব্দ শেখা হলো।</p>
      <button class="pillbtn acc2" style="background:var(--green);width:100%;margin:12px 0 8px" onclick="startLesson()">পরের পাঠ</button>
      <button class="pillbtn" style="width:100%" onclick="pop()">হোমে ফিরুন</button></div></div>\`
  :\`
  <div class="row">
    <button class="back" onclick="pop()">←</button>
    <b style="flex:1;font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">\${L.title}</b>
    <span style="cursor:pointer;padding:0 8px;color:var(--muted)" onclick="go('curr')">🗺️</span>
    <span style="cursor:pointer;padding:0 8px;color:var(--muted)" onclick="go('book')">📖</span>
    <span class="moodpill" style="border-color:\${m[0]};color:\${m[0]}"><span class="dot" style="background:\${m[0]}"></span>\${m[1]}</span></div>
  <div class="bar" style="height:5px"><i style="width:\${100*L.idx/L.qs.length}%;background:\${m[0]}"></i></div>
  <div class="card">
    <div class="qlabel" style="color:\${m[0]}">এর মানে কী?</div>
    <div class="jp">\${q.jp}</div><div class="yomi">\${q.yomi}</div>
    <div class="grid2">\${q.options.map((o,i)=>{
      let st='';if(L.picked===i)st=i===q.answer?\`background:\${m[0]};border-color:\${m[0]};color:#111\`
        :'border-color:var(--struggle);background:#F0954B26';
      return\`<button class="opt" style="\${st}" onclick="pick(\${i})">\${o}</button>\`}).join('')}</div></div>
  \${L.hintOpen?\`<div class="hint" style="border-color:\${m[0]}"><b style="color:\${m[0]};font-size:12px">💡 ইঙ্গিত</b><br>\${q.hint}</div>\`:''}
  <div class="teacher">
    <div style="font-size:44px;cursor:pointer" onclick="openChat()" title="Talk to sensei">🧑‍🏫</div>
    <div class="bubble">\${L.note??m[2]}</div></div>
  <div class="toolbar">
    <button class="pillbtn" style="flex:1" onclick="L.hintOpen=!L.hintOpen;rLesson()">💡 ইঙ্গিত</button>
    <button class="pillbtn" style="flex:1" onclick="skipQ()">⏭ বাদ</button>
    <button class="pillbtn" onclick="pop()">✕ বন্ধ</button></div>\`;
}
function pick(i){const q=L.qs[L.idx];if(L.picked===i||L.done)return;
  if(i===q.answer){L.picked=i;L.mood='flow';L.note=q.note;rLesson();
    setTimeout(()=>{L.streak++;L.mood=L.streak>=3?'boredom':'flow';
      if(L.idx>=L.qs.length-1){L.done=true;if(L.lessonId)completed.add(L.lessonId);}
      else L.idx++;L.picked=-1;L.hintOpen=false;rLesson();},600);}
  else{L.wrongs++;L.streak=0;L.picked=i;L.hintOpen=true;
    L.mood=L.wrongs>=3?'burnout':'struggle';rLesson();}}
function skipQ(){L.idx=Math.min(L.idx+1,L.qs.length-1);L.picked=-1;L.hintOpen=false;L.mood='neutral';L.note=null;rLesson();}

// ── SENSEI CHAT (canned, as in the app until the tutor service) ──
const CANNED=['ভালো প্রশ্ন! এই শব্দটা ভেঙে দেখি — উচ্চারণটা ধীরে ৩ বার বলো।',
'উদাহরণ: お茶をのみます — আমি চা খাই।','মানে মনে রাখার কৌশল: প্রথম অক্ষরটা ধরো, তারপর ছবি বানাও মনে।'];
let msgs=[],ci=0;
function openChat(){msgs=[{m:0,t:'কিছু জিজ্ঞেস করতে চাও? আমি আছি — যেকোনো শব্দ বা বাক্য নিয়ে প্রশ্ন করো।'}];rChat();$('sheet').classList.add('on');}
function rChat(){const a=MOODS[L?.mood??'neutral'][0];
  $('sheet').innerHTML=\`
  <div style="width:40px;height:4px;border-radius:99px;background:var(--line);margin:0 auto 10px"></div>
  <div class="row" style="margin-bottom:6px"><div style="display:flex;gap:10px;align-items:center">
    <div style="width:38px;height:38px;border-radius:50%;border:2px solid \${a};display:flex;align-items:center;justify-content:center;font-weight:900;color:\${a}">先</div>
    <div><b style="font-size:14px">সেনসেই</b><div style="font-size:10.5px;color:\${a}">● \${MOODS[L?.mood??'neutral'][1]}</div></div></div>
    <button class="back" onclick="$('sheet').classList.remove('on')">✕</button></div>
  <div style="flex:1;overflow-y:auto;display:flex;flex-direction:column-reverse">
    \${msgs.map(x=>\`<div class="msg" style="\${x.m?\`background:\${a};color:#111;align-self:flex-end;border-radius:16px 16px 4px 16px\`:'background:var(--card);border:1px solid var(--line);align-self:flex-start;border-radius:16px 16px 16px 4px'}">\${x.t}</div>\`).join('')}</div>
  <div class="chips">\${['আবার বুঝিয়ে দাও','একটা উদাহরণ','উচ্চারণ'].map(c=>\`<button onclick="sendMsg('\${c}')">\${c}</button>\`).join('')}</div>
  <div style="display:flex;gap:8px">
    <input id="chatin" placeholder="সেনসেইকে জিজ্ঞেস করো…" style="flex:1;height:44px;border-radius:99px;border:1px solid var(--line);background:var(--card);color:var(--text);padding:0 16px;font-family:var(--font)">
    <button class="pillbtn acc2" style="background:\${a};min-width:44px" onclick="sendMsg($('chatin').value)">➤</button></div>\`;}
function sendMsg(t){if(!t.trim())return;msgs.unshift({m:1,t});rChat();
  setTimeout(()=>{msgs.unshift({m:0,t:CANNED[ci++%CANNED.length]});rChat();},700);}

// ── CURRICULUM ──
function rCurr(){
  let foundCur=false;
  $('scr-curr').innerHTML=\`<div class="row"><button class="back" onclick="pop()">←</button>
  <b style="flex:1">AI পাঠক্রম</b><span class="moodpill" style="border-color:var(--red);color:var(--red)">JLPT N5</span></div>
  <div class="bar" style="height:4px;margin:10px 0 16px"><i style="background:var(--red);width:\${Math.round(100*DATA.lessons.filter(l=>completed.has(l.id)).length/DATA.lessons.length)}%"></i></div>
  \${DATA.units.map(u=>{
    const ls=u.lessonIds.filter(id=>DATA.lessons.some(l=>l.id===id));
    const done=ls.length>0&&ls.every(id=>completed.has(id));
    const cur=!done&&!foundCur&&ls.length>0;if(cur)foundCur=true;
    const knot=done?'<div class="knot" style="background:var(--red)">✓</div>'
      :cur?'<div class="knot" style="border:2px solid var(--red);color:var(--red)">▶</div>'
      :'<div class="knot" style="border:2px solid var(--line);color:var(--muted)">🕒</div>';
    return\`<div class="tl"><div class="dotcol">\${knot}<div class="conn"></div></div>
      <div class="ucard\${cur?' cur':''}"><b style="font-size:13px">\${u.id} · \${u.title}</b>
      <div class="small" style="\${cur?'color:var(--redsub)':''};margin-top:2px">\${u.canDo}</div>
      \${cur?\`<button class="pillbtn" style="width:100%;background:#F5F5F0;color:#111;border:0;margin-top:10px" onclick="startLesson()">চালিয়ে যাও</button>\`:''}</div></div>\`}).join('')}\`;
}

// ── BOOK (T-121 slice: real book.json reader) ──
let chap=null;
function rBook(){
  const chapters=DATA.book.filter(c=>c.num>=1);
  if(chap!=null){const c=DATA.book.find(x=>x.id===chap);
    $('scr-book').innerHTML=\`<div class="row"><button class="back" onclick="chap=null;rBook()">←</button>
    <b style="flex:1;font-size:13px">\${c.title}</b></div>
    <div style="font-size:13px;line-height:1.7">\${c.blocks.map(b=>
      b.t==='h'?\`<h3 style="color:var(--green);font-size:14px">\${b.c}</h3>\`
      :b.t==='li'?\`<div style="padding-left:14px">• \${b.c}</div>\`
      :b.t==='q'?\`<blockquote>\${b.c}</blockquote>\`
      :b.t==='table'?\`<table>\${(b.rows||[]).map(r=>\`<tr>\${r.map(x=>\`<td>\${x}</td>\`).join('')}</tr>\`).join('')}</table>\`
      :\`<p>\${b.c}</p>\`).join('')}
    <p class="small">… (প্রথম অংশ — পুরোটা অ্যাপে)</p></div>\`;return;}
  $('scr-book').innerHTML=\`<div class="row"><button class="back" onclick="pop()">←</button><b style="flex:1">ভাষা গো</b></div>
  <div class="card" style="background:linear-gradient(160deg,#2E7D5B,#1F5C42);border:0;color:#F5F5F0">
    <div style="font-size:34px;font-weight:900">語</div><b>BHASHA GO — বাংলায় জাপানি শেখো</b>
    <div class="bar" style="background:#174632;margin:10px 0 0"><i style="width:5%;background:var(--green)"></i></div></div>
  \${chapters.map(c=>\`<div class="chap" onclick="chap='\${c.id}';rBook()">
    <div class="chnum" style="\${c.num===1?'background:var(--green);color:#111':'background:var(--card2);color:var(--muted)'}">\${bn(c.num)}</div>
    <div style="flex:1;font-size:12.5px;font-weight:700">\${c.title.replace(/^Chapter \\d+ — /,'')}</div><span class="small">›</span></div>\`).join('')}\`;
}

// ── WRITE (kana + sound context + intro, stroke animation from real medians) ──
let W={kata:false,idx:0,intro:true,ink:[],anim:0,animOn:false};
function kchars(){return W.kata?DATA.kata:DATA.hira;}
function rWrite(){
  const ks=kchars(),k=ks[W.idx];
  $('scr-write').innerHTML=\`<div class="row"><button class="back" onclick="pop()">←</button><b style="flex:1">লিখো · Write</b></div>
  \${W.intro?\`<div class="card" style="background:var(--card2)"><b style="font-size:13px">এটা কী শিখছ?</b>
    <p style="font-size:12px;line-height:1.55;color:var(--text)">হিরাগানা আর কাতাকানা হলো জাপানি "বর্ণমালা" — বাংলার মতোই sound-based। হিরাগানা (৪৬টা) দিয়ে জাপানি শব্দ ও grammar লেখা হয় — আগে এটা। কাতাকানা same ৪৬ sound — বিদেশি শব্দ আর তোমার নিজের নাম লিখতে। ৫টা vowel: あ(আ) い(ই) う(উ) え(এ) お(ও) — বাকি সব consonant+vowel। সঠিক stroke order এ লেখো — জাপানিরা এক নজরে চেনে।</p>
    <div style="text-align:right"><button class="pillbtn" style="min-height:34px" onclick="W.intro=false;rWrite()">বুঝেছি</button></div></div>\`:''}
  <div style="display:flex;gap:8px;margin:6px 0">
    <button class="pillbtn" style="flex:1;\${!W.kata?'background:#fff;color:#111;border:0':''}" onclick="W.kata=false;W.idx=0;W.ink=[];rWrite()">ひらがな</button>
    <button class="pillbtn" style="flex:1;\${W.kata?'background:#fff;color:#111;border:0':''}" onclick="W.kata=true;W.idx=0;W.ink=[];rWrite()">カタカナ</button></div>
  <div class="kstrip">\${ks.map((x,i)=>\`<div class="\${i===W.idx?'on':''}" onclick="W.idx=\${i};W.ink=[];W.animOn=false;rWrite()">\${x.char}</div>\`).join('')}</div>
  <div style="text-align:center;margin:2px 0 6px"><b style="font-size:18px">\${k.char}</b>
    <span class="small" style="font-size:13.5px"> \${k.romaji} · উচ্চারণ: <b style="color:var(--text)">\${k.bn}</b></span></div>
  <canvas id="paper" class="paper" width="340" height="340"></canvas>
  <div class="toolbar">
    <button class="pillbtn acc2" style="flex:1;background:var(--pink)" onclick="playStroke()">▶ দেখো</button>
    <button class="pillbtn" style="flex:1" onclick="W.ink=[];W.animOn=false;drawPaper()">মুছো</button>
    <button class="pillbtn" style="flex:2" onclick="W.idx=(W.idx+1)%kchars().length;W.ink=[];W.animOn=false;rWrite()">Skip / পরের ›</button></div>\`;
  setupPaper();drawPaper();
}
function med(){const s=W.kata?'katakana':'hiragana';return DATA.strokes[s]?.[kchars()[W.idx].char]??null;}
function drawPaper(){const c=$('paper');if(!c)return;const g=c.getContext('2d'),w=c.width;
  g.fillStyle='#FBFBFD';g.fillRect(0,0,w,w);g.strokeStyle='#E6E7EE';g.lineWidth=1.4;
  const p=w*.06;g.strokeRect(p,p,w-2*p,w-2*p);
  g.beginPath();g.moveTo(w/2,p);g.lineTo(w/2,w-p);g.moveTo(p,w/2);g.lineTo(w-p,w/2);g.stroke();
  if(!W.animOn){g.fillStyle='#E3E4EC';g.font=(w*.7)+'px sans-serif';g.textAlign='center';g.textBaseline='middle';
    g.fillText(kchars()[W.idx].char,w/2,w/2+w*.03);}
  g.lineCap='round';g.lineJoin='round';
  if(W.animOn){const m=med();if(m){g.strokeStyle='#14141F';g.lineWidth=w*.06;const sc=w/1000;
    const lens=m.map(st=>{let L=0;for(let i=1;i<st.length;i++)L+=Math.hypot(st[i][0]-st[i-1][0],st[i][1]-st[i-1][1]);return L;});
    let target=W.anim*lens.reduce((a,b)=>a+b,0);
    for(let s=0;s<m.length&&target>0;s++){const st=m[s];g.beginPath();g.moveTo(st[0][0]*sc,st[0][1]*sc);let acc=0;
      for(let i=1;i<st.length;i++){const seg=Math.hypot(st[i][0]-st[i-1][0],st[i][1]-st[i-1][1]);
        if(acc+seg<=target){g.lineTo(st[i][0]*sc,st[i][1]*sc);acc+=seg;}
        else{const f=(target-acc)/seg;g.lineTo((st[i-1][0]+(st[i][0]-st[i-1][0])*f)*sc,(st[i-1][1]+(st[i][1]-st[i-1][1])*f)*sc);break;}}
      g.stroke();target-=lens[s];}}}
  g.strokeStyle='#14141F';g.lineWidth=w*.045;
  for(const st of W.ink){if(st.length<2)continue;g.beginPath();g.moveTo(st[0][0],st[0][1]);
    for(let i=1;i<st.length;i++)g.lineTo(st[i][0],st[i][1]);g.stroke();}}
function playStroke(){if(!med())return;W.ink=[];W.animOn=true;W.anim=0;
  const step=()=>{W.anim+=.02;drawPaper();if(W.anim<1)requestAnimationFrame(step);};step();}
function setupPaper(){const c=$('paper');if(!c)return;let down=false;
  const pos=e=>{const r=c.getBoundingClientRect();
    return[(e.clientX-r.left)*c.width/r.width,(e.clientY-r.top)*c.height/r.height];};
  c.onpointerdown=e=>{down=true;W.animOn=false;W.ink.push([pos(e)]);drawPaper();};
  c.onpointermove=e=>{if(!down)return;W.ink[W.ink.length-1].push(pos(e));drawPaper();};
  c.onpointerup=()=>down=false;}

// ── LEARN / SPEAK / PROGRESS tabs ──
function rLearn(){$('scr-learn').innerHTML='<h1>শেখা</h1>'+DATA.lessons.map(l=>
  \`<div class="card" style="cursor:pointer" onclick="startLesson()">
   <b style="font-size:13px">\${completed.has(l.id)?'✅ ':''}\${l.canDo}</b>
   <div class="small">\${bn(l.items.length)} শব্দ · ৫ ধাপ</div></div>\`).join('');}
function rSpeak(){$('scr-speak').innerHTML=\`<h1>বলা</h1>
  <div class="card" style="cursor:pointer"><b style="font-size:13.5px">📊 পিচ অ্যাকসেন্ট অনুশীলন</b>
  <div class="small">Tokyo pitch — শুনে মিলিয়ে বলো ›</div></div>
  <div class="card"><b style="font-size:13.5px">🎤 শ্যাডোয়িং</b>
  <div class="small">রেকর্ড করে নিজের উচ্চারণ মিলাও (অ্যাপে মাইক লাগে)</div></div>\`;}
function rProgress(){$('scr-progress').innerHTML=\`<h1>অগ্রগতি</h1>
  <div class="card"><b style="font-size:13px;color:var(--green)">ধারণ (retention)</b>
  <div class="small" style="margin:8px 0">নতুন শিক্ষার্থী — রিভিউ শুরু হলে চার্ট আঁকা হবে</div>
  <div class="bar"><i style="width:0%;background:var(--green)"></i></div></div>
  <div class="grid2">
   <div class="acc" style="background:var(--green)"><h3>শোনা</h3><p>ডেমো — ডেটা উৎস আসছে</p></div>
   <div class="acc" style="background:var(--pink)"><h3>বলা</h3><p>ডেমো — pitch history আসছে</p></div></div>
  <div class="acc" style="background:var(--blue)"><h3>AI চেক দাও</h3><p>মক পরীক্ষা → দুর্বল জায়গা বের করো</p></div>\`;}

function render(){rHome();rLearn();rSpeak();rProgress();
  if(push==='lesson')rLesson();if(push==='curr')rCurr();if(push==='book')rBook();if(push==='write')rWrite();
  show();}
render();
</script>`;

const page = (body) => `<!doctype html><html lang="bn"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bhasago — v4 preview</title>${STYLE}</head><body>${body}</body></html>`;

const body = BODY.replace('%%DATA%%', JSON.stringify(DATA)).replace('%%BATCH%%', BATCH_JS);
fs.mkdirSync(path.join(ROOT, 'preview'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'preview/index.html'), page(body));
fs.writeFileSync(path.join(ROOT, 'preview/sensei_body.html'), STYLE + body);
console.log('preview built: preview/index.html (%d lessons, %d units, %d book entries)',
  DATA.lessons.length, DATA.units.length, DATA.book.length);
