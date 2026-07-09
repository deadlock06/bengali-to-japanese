// Builds a self-contained, interactive HTML preview of the Bhasago app from the
// REAL content + stroke data, so the app can be seen/clicked without a Flutter
// SDK. Faithful to the Flutter UI (same tokens, screens, and the 5-step lesson
// micro-loop). Emits preview/index.html (standalone, for local screenshotting)
// and preview/sensei_body.html (body-only, for publishing as an Artifact).
// Run: node tools/build_preview.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const read = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), 'utf8'));

const hira = read('assets/content/hiragana.json');
const kata = read('assets/content/katakana.json');
const strokes = read('assets/stroke/kana_strokes.json');
const lesson = read('assets/content/lesson_work_intro.json');
const pitch = read('assets/content/pitch_accent.json');

const DATA = {
  hira: hira.items.map((k) => ({ char: k.char, romaji: k.romaji })),
  kata: kata.items.map((k) => ({ char: k.char, romaji: k.romaji })),
  strokes,
  lesson,
  pitch: pitch.items,
};

const STYLE = `
<style>
  :root{
    --bg:#0E1116; --surface:#161B22; --surface2:#1A2230; --line:rgba(255,255,255,.08);
    --text:#E8EAED; --muted:#8A93A2; --faint:#5A6472;
    --pink:#FF2D78; --pink-dim:#3A1526; --green:#00C853; --green-dim:#10361F;
    --amber:#FFC400; --amber-dim:#3A2A12; --blue:#2979FF;
    --font:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Noto Sans","Noto Sans Bengali","Noto Sans JP",sans-serif;
  }
  *{box-sizing:border-box}
  body{margin:0}
  .stage{
    min-height:100vh; display:flex; align-items:center; justify-content:center;
    padding:24px; font-family:var(--font);
    background:
      radial-gradient(1200px 600px at 20% -10%, #1b2740 0%, transparent 55%),
      radial-gradient(900px 500px at 110% 20%, #2a1330 0%, transparent 50%),
      #05070c;
  }
  .frame{
    width:390px; max-width:100%; height:800px; max-height:calc(100vh - 40px);
    background:var(--bg); border-radius:40px; position:relative; overflow:hidden;
    border:1px solid rgba(255,255,255,.10);
    box-shadow:0 40px 90px -20px rgba(0,0,0,.8), 0 0 0 10px #0a0c11, 0 0 0 11px rgba(255,255,255,.06);
    display:flex; flex-direction:column; color:var(--text);
  }
  .statusbar{display:flex; justify-content:space-between; align-items:center;
    padding:12px 22px 4px; font-size:12px; color:var(--muted); letter-spacing:.3px}
  .statusbar .dots{display:flex; gap:4px; align-items:center}
  .statusbar .dots span{width:5px;height:5px;border-radius:50%;background:var(--muted)}
  .appbar{display:flex; align-items:center; justify-content:space-between; padding:6px 18px 10px}
  .brand{font-weight:800; letter-spacing:1.5px; font-size:15px}
  .brand b{color:var(--pink)}
  .langs{display:flex; gap:4px}
  .langs button{background:transparent; border:0; color:var(--muted); font:inherit; font-size:12px;
    padding:5px 9px; border-radius:9px; cursor:pointer}
  .langs button.on{background:rgba(255,45,120,.14); color:var(--pink)}
  .screen{flex:1; overflow-y:auto; overflow-x:hidden; -webkit-overflow-scrolling:touch}
  .screen::-webkit-scrollbar{width:0}
  .nav{display:flex; border-top:1px solid var(--line); background:rgba(10,13,20,.85); backdrop-filter:blur(8px)}
  .nav button{flex:1; background:none; border:0; color:var(--faint); padding:9px 0 12px; cursor:pointer;
    display:flex; flex-direction:column; align-items:center; gap:3px; font:inherit; font-size:9.5px}
  .nav button.on{color:var(--pink)}
  .nav svg{width:22px;height:22px;stroke:currentColor;fill:none;stroke-width:1.7}
  /* shared */
  h2.title{margin:16px 20px 2px; font-size:13px; color:var(--muted); font-weight:600}
  .sub{margin:0 20px; color:var(--faint); font-size:12px}
  .card{background:var(--surface); border:1px solid var(--line); border-radius:18px; padding:18px}
  .pad{padding:16px}
  .btn{border:0; border-radius:13px; font:inherit; font-weight:600; padding:12px 16px; cursor:pointer;
    min-height:48px; display:inline-flex; align-items:center; justify-content:center; gap:7px}
  .btn.primary{background:var(--pink); color:#fff}
  .btn.filled{background:var(--green); color:#04120a}
  .btn.ghost{background:rgba(255,255,255,.06); color:var(--text)}
  .btn.line{background:transparent; border:1px solid var(--line); color:var(--text)}
  .btn:disabled{opacity:.35; cursor:default}
  .row{display:flex; gap:8px}
  .grow{flex:1}
  .jp{font-weight:700}
  .muted{color:var(--muted)} .faint{color:var(--faint)}
  /* kana grid */
  .krow{display:flex; gap:8px; padding:0 16px 12px}
  .seg{display:flex; background:var(--surface); border:1px solid var(--line); border-radius:12px; overflow:hidden; margin:14px 20px 6px}
  .seg button{flex:1; background:none; border:0; color:var(--muted); font:inherit; padding:9px; cursor:pointer}
  .seg button.on{background:var(--pink); color:#fff}
  .grid{display:grid; grid-template-columns:repeat(5,1fr); gap:8px; padding:8px 16px 20px}
  .cell{background:var(--surface); border:1px solid var(--line); border-radius:14px; aspect-ratio:1;
    display:flex; flex-direction:column; align-items:center; justify-content:center; cursor:pointer; transition:.12s}
  .cell:active{transform:scale(.94); background:var(--surface2)}
  .cell .c{font-size:24px; font-weight:600}
  .cell .r{font-size:10px; color:var(--faint)}
  /* write */
  .strip{display:flex; gap:8px; overflow-x:auto; padding:12px 16px}
  .strip::-webkit-scrollbar{height:0}
  .chip{min-width:46px; height:46px; border-radius:12px; background:rgba(255,255,255,.06); border:0; color:var(--text);
    font-size:22px; cursor:pointer; flex:0 0 auto}
  .chip.on{background:var(--pink); color:#fff}
  #paper{width:100%; aspect-ratio:1; border-radius:20px; background:#FBFBFD; touch-action:none; display:block}
  .tools{display:flex; gap:8px; padding:12px 16px}
  .tools .btn{flex:1; padding:10px}
  /* controls (invariant) */
  .controls{display:flex; gap:8px; padding:0 16px 6px}
  .controls .btn{flex:1; padding:9px}
  .steps{display:flex; gap:4px; padding:8px 20px 2px}
  .steps i{flex:1; height:4px; border-radius:2px; background:rgba(255,255,255,.14)}
  .steps i.on{background:var(--green)}
  .phaselab{display:flex; justify-content:space-between; padding:2px 20px 0; font-size:12px}
  .opt{width:100%; text-align:left; background:rgba(255,255,255,.06); border:1.5px solid transparent; color:var(--text);
    border-radius:12px; padding:12px 14px; margin-bottom:8px; cursor:pointer; font:inherit; min-height:48px}
  .opt.good{background:var(--green-dim)} .opt.bad{background:var(--amber-dim)} .opt.hint{border-color:var(--green)}
  .tok{background:rgba(255,255,255,.08); border:0; color:var(--text); border-radius:10px; padding:8px 12px;
    font-size:18px; cursor:pointer; font-family:var(--font)}
  .assembled{min-height:56px; border:1.5px solid transparent; border-radius:12px; background:rgba(255,255,255,.05);
    padding:10px; display:flex; flex-wrap:wrap; gap:8px; align-items:center}
  .assembled.good{border-color:var(--green)} .assembled.bad{border-color:var(--amber)}
  .bank{display:flex; flex-wrap:wrap; gap:8px}
  .pillrow{display:flex; flex-wrap:wrap; gap:8px}
  .pill{background:rgba(255,255,255,.08); border-radius:999px; padding:6px 12px; font-size:14px}
  .center{display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; gap:12px; padding:24px; text-align:center}
  .big{font-size:34px; font-weight:800}
  .rate{display:flex; gap:6px}
  .rate .btn{flex:1; flex-direction:column; gap:2px; font-size:12px; padding:10px 4px}
  .rate small{color:rgba(255,255,255,.7); font-weight:400}
  /* pitch */
  .contour{display:flex; align-items:flex-end; gap:2px; height:44px; margin-top:6px}
  .mora{display:flex; flex-direction:column; align-items:center; gap:4px}
  .mora .b{width:22px; border-radius:3px 3px 0 0; background:var(--pink)}
  .wave{height:70px; border-radius:14px; background:
    repeating-linear-gradient(90deg, rgba(255,45,120,.35) 0 2px, transparent 2px 7px); opacity:.5}
  .tag{display:inline-block; font-size:11px; padding:2px 8px; border-radius:999px; background:rgba(0,200,83,.15); color:var(--green)}
</style>`;

const BODY = `
<div class="stage">
  <div class="frame">
    <div class="statusbar"><span>9:41</span><div class="dots"><span></span><span></span><span></span> ▮</div></div>
    <div class="appbar">
      <div class="brand">SEN<b>SEI</b></div>
      <div class="langs" id="langs">
        <button data-l="en">EN</button>
        <button data-l="bn" class="on">বাংলা</button>
        <button data-l="ja">日本語</button>
      </div>
    </div>
    <div class="screen" id="screen"></div>
    <div class="nav" id="nav"></div>
  </div>
</div>
<script>
const DATA = __DATA__;
let LANG = 'bn';
let tab = 2; // open on Learn (the micro-loop) first

const T = (tri) => (tri ? (tri[LANG] || tri.en) : '');
const gloss = (tri) => (LANG === 'bn' && tri && tri.en ? tri.en : '');

const NAV = [
  ['Kana','M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v6H4zM14 15h6v6h-6z'],
  ['Write','M4 20h16M6 16l9-9a2 2 0 0 1 3 3l-9 9-4 1z'],
  ['Learn','M3 7l9-4 9 4-9 4zM7 10v5c0 1 5 3 5 3s5-2 5-3v-5'],
  ['Speak','M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM5 11a7 7 0 0 0 14 0M12 18v3'],
  ['Pitch','M3 17l5-6 4 3 5-8'],
  ['Review','M4 9a8 8 0 0 1 14-4M20 5v4h-4M20 15a8 8 0 0 1-14 4M4 19v-4h4'],
];

function renderNav(){
  document.getElementById('nav').innerHTML = NAV.map((n,i)=>
    '<button class="'+(i===tab?'on':'')+'" onclick="go('+i+')"><svg viewBox="0 0 24 24"><path d="'+n[1]+'"/></svg>'+n[0]+'</button>'
  ).join('');
}
function go(i){ tab=i; render(); }
window.go = go;

function render(){
  renderNav();
  const s = document.getElementById('screen');
  s.innerHTML = [screenKana, screenWrite, screenLearn, screenSpeak, screenPitch, screenReview][tab]();
  if (tab===1) initWrite();
  s.scrollTop = 0;
}

/* ---------- 0: KANA ---------- */
let kataMode=false;
function screenKana(){
  const set = kataMode?DATA.kata:DATA.hira;
  return '<h2 class="title">'+(LANG==='bn'?'কানা শেখো':'Kana')+'</h2>'+
    '<div class="seg"><button class="'+(!kataMode?'on':'')+'" onclick="setKata(0)">ひらがな</button>'+
    '<button class="'+(kataMode?'on':'')+'" onclick="setKata(1)">カタカナ</button></div>'+
    '<div class="grid">'+set.map(k=>
      '<div class="cell" onclick="ping(this)"><div class="c">'+k.char+'</div><div class="r">'+k.romaji+'</div></div>'
    ).join('')+'</div>';
}
window.setKata=(v)=>{kataMode=!!v; render();};
window.ping=(el)=>{el.style.borderColor='var(--pink)'; setTimeout(()=>el.style.borderColor='',260);};

/* ---------- 1: WRITE (real KanjiVG stroke animation) ---------- */
let wKata=false, wIdx=0;
function screenWrite(){
  const chars = (wKata?DATA.kata:DATA.hira).map(k=>k.char);
  return '<h2 class="title">'+(LANG==='bn'?'লেখা অনুশীলন':'Write')+'</h2>'+
    '<div class="seg"><button class="'+(!wKata?'on':'')+'" onclick="setW(0)">ひらがな</button>'+
    '<button class="'+(wKata?'on':'')+'" onclick="setW(1)">カタカナ</button></div>'+
    '<div class="strip">'+chars.map((c,i)=>'<button class="chip '+(i===wIdx?'on':'')+'" onclick="pickW('+i+')">'+c+'</button>').join('')+'</div>'+
    '<div class="pad"><canvas id="paper"></canvas></div>'+
    '<div class="tools">'+
      '<button class="btn primary" onclick="playStroke()">▶ '+(LANG==='bn'?'দেখাও':'watch')+'</button>'+
      '<button class="btn line" onclick="toggleGuide()" id="guideBtn">👁 guide</button>'+
      '<button class="btn line" onclick="clearInk()">⌫ clear</button>'+
    '</div>'+
    '<div class="row" style="padding:0 16px 18px"><button class="btn filled grow" onclick="pickW('+((wIdx+1))+')">Skip / পরের ›</button></div>';
}
window.setW=(v)=>{wKata=!!v; wIdx=0; render();};
window.pickW=(i)=>{const n=(wKata?DATA.kata:DATA.hira).length; wIdx=((i%n)+n)%n; render();};
let guide=true, ink=[], anim=null;
window.toggleGuide=()=>{guide=!guide; drawPaper(0,null);};
window.clearInk=()=>{ink=[]; drawPaper(0,null);};
function curStrokes(){const c=(wKata?DATA.kata:DATA.hira)[wIdx].char; const set=wKata?DATA.strokes.katakana:DATA.strokes.hiragana; return set[c]||[];}
function initWrite(){
  const cv=document.getElementById('paper'); if(!cv) return;
  const fit=()=>{const r=cv.getBoundingClientRect(); const dpr=Math.min(devicePixelRatio||1,2);
    cv.width=r.width*dpr; cv.height=r.width*dpr; cv._s=r.width*dpr; drawPaper(0,null);};
  fit();
  let drawing=false;
  const pt=(e)=>{const r=cv.getBoundingClientRect(); const s=cv._s/r.width; return [(e.clientX-r.left)*s,(e.clientY-r.top)*s];};
  cv.onpointerdown=(e)=>{if(anim)return; drawing=true; ink.push([pt(e)]); cv.setPointerCapture(e.pointerId);};
  cv.onpointermove=(e)=>{if(!drawing||anim)return; ink[ink.length-1].push(pt(e)); drawPaper(animT,animStrokesLocal);};
  cv.onpointerup=()=>{drawing=false;};
}
let animT=0, animStrokesLocal=null;
function drawPaper(t, strokesShown){
  const cv=document.getElementById('paper'); if(!cv)return; const g=cv.getContext('2d'); const S=cv._s||cv.width;
  g.clearRect(0,0,S,S); g.fillStyle='#FBFBFD'; g.fillRect(0,0,S,S);
  const pad=S*0.06; g.strokeStyle='#E6E7EE'; g.lineWidth=1.4;
  g.strokeRect(pad,pad,S-2*pad,S-2*pad);
  g.beginPath(); g.moveTo(S/2,pad); g.lineTo(S/2,S-pad); g.moveTo(pad,S/2); g.lineTo(S-pad,S/2); g.stroke();
  if(guide && !strokesShown){ g.fillStyle='#E3E4EC'; g.font='700 '+(S*0.7)+'px var(--font)'; g.textAlign='center'; g.textBaseline='middle';
    g.fillText((wKata?DATA.kata:DATA.hira)[wIdx].char, S/2, S/2+S*0.04); }
  // user ink
  g.strokeStyle='#14141F'; g.lineWidth=S*0.045; g.lineCap='round'; g.lineJoin='round';
  for(const st of ink){ if(st.length<2){continue;} g.beginPath(); g.moveTo(st[0][0],st[0][1]); for(let i=1;i<st.length;i++)g.lineTo(st[i][0],st[i][1]); g.stroke(); }
  // stroke-order animation (scaled from viewBox 1000)
  if(strokesShown){
    const sc=S/1000; g.lineWidth=S*0.06;
    const scaled=strokesShown.map(s=>s.map(p=>[p[0]*sc,p[1]*sc]));
    const lens=scaled.map(len); const total=lens.reduce((a,b)=>a+b,0); let target=t*total, consumed=0;
    for(let i=0;i<scaled.length;i++){ if(consumed>=target)break; drawUpTo(g,scaled[i],Math.min(lens[i],target-consumed)); consumed+=lens[i]; }
  }
}
function len(p){let s=0;for(let i=1;i<p.length;i++)s+=Math.hypot(p[i][0]-p[i-1][0],p[i][1]-p[i-1][1]);return s;}
function drawUpTo(g,pts,maxLen){ if(pts.length<2)return; g.beginPath(); g.moveTo(pts[0][0],pts[0][1]); let acc=0;
  for(let i=1;i<pts.length;i++){const seg=Math.hypot(pts[i][0]-pts[i-1][0],pts[i][1]-pts[i-1][1]);
    if(acc+seg<=maxLen){g.lineTo(pts[i][0],pts[i][1]); acc+=seg;}
    else{const f=seg<=0?0:(maxLen-acc)/seg; g.lineTo(pts[i-1][0]+(pts[i][0]-pts[i-1][0])*f, pts[i-1][1]+(pts[i][1]-pts[i-1][1])*f); break;}}
  g.stroke(); }
window.playStroke=()=>{
  const strokes=curStrokes(); if(!strokes.length)return; ink=[]; if(anim)cancelAnimationFrame(anim);
  animStrokesLocal=strokes; const dur=600*strokes.length; const t0=performance.now();
  const step=(now)=>{animT=Math.min(1,(now-t0)/dur); drawPaper(animT,strokes);
    if(animT<1){anim=requestAnimationFrame(step);} else {anim=null; animStrokesLocal=null;}};
  anim=requestAnimationFrame(step);
};

/* ---------- 2: LEARN (5-step micro-loop) ---------- */
const PHASES=['intro','recognition','production','context','srs'];
const PLAB={intro:['পরিচিতি','Intro'],recognition:['চেনা','Recognition'],production:['বলা/লেখা','Production'],context:['বাক্য','Context'],srs:['রিভিউ','SRS']};
let L={started:false,done:false,item:0,phase:0,hint:false,pick:null,revealed:false,write:false,built:[],bank:null,bankItem:-1,showRom:true};
function lz(){return DATA.lesson.items;}
function resetStep(){L.hint=false;L.pick=null;L.revealed=false;L.write=false;L.built=[];L.bank=null;L.bankItem=-1;}
window.lStart=()=>{L.started=true;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lQuit=()=>{L.started=false;L.done=false;L.item=0;L.phase=0;resetStep();render();};
window.lHint=()=>{L.hint=!L.hint;render();};
window.lAdvance=()=>{const n=lz().length;resetStep();
  if(L.phase<4)L.phase++; else if(L.item<n-1){L.item++;L.phase=0;} else {L.started=false;L.done=true;} render();};
window.lToggleRom=()=>{L.showRom=!L.showRom;render();};
window.lReveal=()=>{L.revealed=!L.revealed;render();};
window.lWrite=()=>{L.write=!L.write;render();};

function seededShuffle(arr,seed){const a=arr.slice();let s=seed;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};
  for(let i=a.length-1;i>0;i--){const j=Math.floor(rnd()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}

function screenLearn(){
  const les=DATA.lesson;
  if(L.done) return '<div class="center"><div style="font-size:42px">✅</div><div class="big" style="font-size:20px">'+(LANG==='bn'?'লেসন শেষ':'Lesson complete')+'</div><div class="muted">'+(LANG==='bn'?'আরেকটা?':'Another round?')+'</div><button class="btn filled" style="margin-top:12px" onclick="lStart()">'+(LANG==='bn'?'আবার':'Restart')+'</button></div>';
  if(!L.started) return '<div class="center"><div class="big" style="font-size:19px;text-wrap:balance">'+T(les.can_do)+'</div>'+(gloss(les.can_do)?'<div class="faint">'+gloss(les.can_do)+'</div>':'')+'<div class="muted">'+les.items.length+' '+(LANG==='bn'?'শব্দ':'items')+' · ৫ '+(LANG==='bn'?'ধাপ':'steps')+'</div><div class="faint" style="font-size:12px">'+(LANG==='bn'?'যেকোনো সময় Skip / Hint / Quit — কোনো চাপ নেই।':'Skip / Hint / Quit anytime — no pressure.')+'</div><button class="btn primary" style="margin-top:14px;min-width:160px" onclick="lStart()">'+(LANG==='bn'?'শুরু করো':'Start')+'</button></div>';

  const it=lz()[L.item]; const ph=PHASES[L.phase];
  let head='<div class="phaselab"><span class="muted">'+(LANG==='bn'?'শব্দ':'word')+' '+(L.item+1)+'/'+lz().length+'</span><span style="font-weight:600">'+(LANG==='bn'?PLAB[ph][0]:PLAB[ph][1])+'</span></div>'+
    '<div class="steps">'+PHASES.map((_,i)=>'<i class="'+(i<=L.phase?'on':'')+'"></i>').join('')+'</div>'+
    '<div class="controls"><button class="btn line" onclick="lHint()">💡 '+(LANG==='bn'?'ইঙ্গিত':'Hint')+'</button>'+
      '<button class="btn line" onclick="lAdvance()">⏭ '+(LANG==='bn'?'বাদ':'Skip')+'</button>'+
      '<button class="btn line" onclick="lQuit()">✕ '+(LANG==='bn'?'বন্ধ':'Quit')+'</button></div>';

  let body='';
  if(ph==='intro') body=phIntro(it);
  else if(ph==='recognition') body=phRecog(it);
  else if(ph==='production') body=phProd(it);
  else if(ph==='context') body=phContext(it);
  else body=phSrs(it);

  const hint = L.hint? '<div class="pad"><div class="card" style="background:var(--surface2);display:flex;gap:10px;align-items:flex-start"><span>💡</span><div><b>'+it.jp+'</b> · <span class="faint">'+it.romaji+'</span><div>'+T(it.meaning)+'</div></div></div></div>':'';
  return head+'<div class="pad">'+body+'</div>'+hint;
}
function phIntro(it){return '<div class="card" style="text-align:center">'+
  '<div class="big">'+it.jp+'</div>'+(L.showRom?'<div class="faint">'+it.romaji+'</div>':'')+
  '<div style="font-size:22px;margin:6px">🔊</div>'+
  '<div style="font-size:18px;font-weight:600">'+T(it.meaning)+'</div>'+(gloss(it.meaning)?'<div class="faint">'+gloss(it.meaning)+'</div>':'')+
  '<div class="card" style="background:#12190f;margin-top:12px;text-align:left">'+T(it.note)+(gloss(it.note)?'<div class="faint" style="font-size:12px">'+gloss(it.note)+'</div>':'')+'</div>'+
  '<div class="row" style="margin-top:14px"><button class="btn ghost" onclick="lToggleRom()">Romaji '+(L.showRom?'off':'on')+'</button><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'বুঝেছি':'Got it')+' ✓</button></div></div>';}
function phRecog(it){
  const others=lz().filter(x=>x.id!==it.id); const pick=seededShuffle(others,L.item+1).slice(0,3);
  const opts=seededShuffle([{m:it.meaning,ok:true}].concat(pick.map(o=>({m:o.meaning,ok:false}))), L.item*7+3);
  L._opts=opts;
  const chosen=L.pick!=null; const good=chosen&&opts[L.pick].ok;
  let h='<div class="card" style="text-align:center;margin-bottom:12px"><div class="big" style="font-size:28px">'+it.jp+'</div><div style="font-size:20px">🔊</div></div>';
  h+='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'এর মানে কী?':'What does it mean?')+'</div>';
  h+=opts.map((o,k)=>{let cls='opt'; if(L.pick===k)cls+=o.ok?' good':' bad'; if(L.hint&&o.ok)cls+=' hint';
    return '<button class="'+cls+'" onclick="lPick('+k+')">'+T(o.m)+'</button>';}).join('');
  if(good) h+='<div class="row" style="align-items:center;margin-top:4px"><span class="tag">✓ '+(LANG==='bn'?'ঠিক!':'Correct')+'</span><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(chosen) h+='<div style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'আবার দেখো':'Not quite — try another')+'</div>';
  return h;
}
window.lPick=(k)=>{L.pick=k;render();};
function phProd(it){return '<div class="card" style="text-align:center">'+
  '<div class="muted">'+(L.write?(LANG==='bn'?'এটি লেখো':'Write this'):(LANG==='bn'?'এটি বলো':'Say this'))+'</div>'+
  '<div style="font-size:18px;font-weight:600;margin:8px">'+T(it.meaning)+'</div>'+
  (L.revealed?'<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div>':'<div class="faint" style="font-size:26px">· · ·</div>')+
  '<div class="pillrow" style="justify-content:center;margin:14px 0">'+
    '<button class="btn line">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button>'+
    '<button class="btn line" onclick="lReveal()">'+(L.revealed?'🙈 Hide':'👁 Model')+'</button>'+
    '<button class="btn line" onclick="lWrite()">🔁 '+(L.write?'Speak':'Write')+'</button></div>'+
  '<div class="row"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';}
function phContext(it){
  const tokens=it.srs_words;
  if(tokens.length<2) return '<div class="card" style="text-align:center"><div class="muted">'+(LANG==='bn'?'বাক্যে':'In context')+'</div><div class="big" style="font-size:26px;margin:8px">'+it.jp+'</div><div>'+T(it.meaning)+'</div><div class="row" style="margin-top:14px"><span class="grow"></span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div></div>';
  if(L.bankItem!==L.item){L.built=[]; L.bank=seededShuffle(tokens,L.item+5); L.bankItem=L.item;}
  const complete=L.built.length===tokens.length; const ordered=complete&&L.built.join('|')===tokens.join('|');
  let h='<div class="faint" style="margin-bottom:8px">'+(LANG==='bn'?'শব্দগুলো সাজিয়ে বাক্য বানাও':'Arrange the words')+'</div>';
  h+='<div style="margin-bottom:10px">'+T(it.meaning)+'</div>';
  h+='<div class="assembled '+(complete?(ordered?'good':'bad'):'')+'">'+(L.built.length?L.built.map((w,k)=>'<button class="tok" onclick="lUnbuild('+k+')">'+w+'</button>').join(''):'<span class="faint">'+(LANG==='bn'?'নিচের শব্দে ট্যাপ করো':'tap words below')+'</span>')+'</div>';
  h+='<div class="bank" style="margin-top:12px">'+L.bank.map((w,k)=>'<button class="tok" onclick="lBuild('+k+')">'+w+'</button>').join('')+'</div>';
  if(complete&&ordered) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="tag">✓</span><span class="grow" style="font-size:14px">'+it.jp+'</span><button class="btn filled" onclick="lAdvance()">'+(LANG==='bn'?'পরের':'Next')+' ›</button></div>';
  else if(complete) h+='<div class="row" style="align-items:center;margin-top:12px"><span class="grow" style="color:var(--amber);font-size:13px">'+(LANG==='bn'?'একটু এদিক-ওদিক':'not quite — rearrange')+'</span><button class="btn ghost" onclick="lResetCtx()">'+(LANG==='bn'?'আবার':'Reset')+'</button></div>';
  return h;
}
window.lBuild=(k)=>{L.built.push(L.bank.splice(k,1)[0]);render();};
window.lUnbuild=(k)=>{L.bank.push(L.built.splice(k,1)[0]);render();};
window.lResetCtx=()=>{const t=lz()[L.item].srs_words;L.bank=seededShuffle(t,L.item+5);L.built=[];render();};
function phSrs(it){return '<div class="card"><div class="muted">'+(LANG==='bn'?'রিভিউতে যোগ হলো':'Added to your review')+'</div>'+
  '<div class="pillrow" style="margin:12px 0">'+it.srs_words.map(w=>'<span class="pill">'+w+'</span>').join('')+'</div>'+
  '<div class="faint" style="font-size:13px;margin-bottom:8px">'+(LANG==='bn'?'কেমন লাগল?':'How was it?')+'</div>'+
  '<div class="rate">'+[['আবার','Again'],['কঠিন','Hard'],['ভালো','Good'],['সহজ','Easy']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="lAdvance()">'+(LANG==='bn'?r[0]:r[1])+'</button>').join('')+'</div></div>';}

/* ---------- 3: SPEAK (shadowing stub) ---------- */
function screenSpeak(){const it=lz()[0];
  return '<h2 class="title">'+(LANG==='bn'?'শ্যাডোয়িং':'Speak')+'</h2><div class="pad"><div class="card" style="text-align:center">'+
    '<div class="big" style="font-size:26px">'+it.jp+'</div><div class="faint">'+it.romaji+'</div><div>'+T(it.meaning)+'</div>'+
    '<div class="wave" style="margin:16px 0"></div>'+
    '<div class="pillrow" style="justify-content:center"><button class="btn line">🔊 '+(LANG==='bn'?'শোনো':'Listen')+'</button><button class="btn primary">🎤 '+(LANG==='bn'?'রেকর্ড':'Record')+'</button></div>'+
    '<div class="faint" style="font-size:12px;margin-top:10px">'+(LANG==='bn'?'রেকর্ড করে নিজের সাথে মিলাও (Tier 0–1)':'Record & self-compare (Tier 0–1)')+'</div></div></div>';}

/* ---------- 4: PITCH ---------- */
function screenPitch(){
  return '<h2 class="title">'+(LANG==='bn'?'উচ্চারণ · পিচ':'Pitch accent')+'</h2><div class="pad">'+
    DATA.pitch.map(p=>{const max=Math.max.apply(null,p.pattern);
      const contour='<div class="contour">'+p.pattern.map((v,i)=>'<div class="mora"><div class="b" style="height:'+(v?38:16)+'px;background:'+(v?'var(--pink)':'var(--faint)')+'"></div><small class="faint" style="font-size:10px">'+([...p.word][i]||'')+'</small></div>').join('')+'</div>';
      return '<div class="card" style="margin-bottom:10px"><div class="row" style="justify-content:space-between;align-items:baseline"><div><span class="big" style="font-size:22px">'+p.word+'</span> <span class="faint">'+p.romaji+'</span></div><span class="tag">'+T(p.accent_type)+'</span></div>'+contour+'<div class="muted" style="font-size:13px;margin-top:6px">'+T(p.meaning)+'</div></div>';
    }).join('')+'</div>';
}

/* ---------- 5: REVIEW (FSRS flashcard) ---------- */
let rIdx=0, rRevealed=false;
const RDECK=[{w:'ありがとうございます',m:{en:'Thank you',bn:'ধন্যবাদ',ja:'ありがとう'}},{w:'すみません',m:{en:'Excuse me',bn:'মাফ করবেন',ja:'すみません'}}];
function screenReview(){
  if(rIdx>=RDECK.length) return '<div class="center"><div style="font-size:40px">🎉</div><div class="big" style="font-size:18px">'+(LANG==='bn'?'রিভিউ শেষ':'Review done')+'</div><button class="btn ghost" onclick="rReset()">↺</button></div>';
  const c=RDECK[rIdx];
  let h='<h2 class="title">'+(LANG==='bn'?'রিভিউ · FSRS':'Review')+'</h2><div class="pad"><div class="card" style="text-align:center;padding:28px"><div class="big" style="font-size:26px">'+c.w+'</div>'+(rRevealed?'<div style="margin-top:10px">'+T(c.m)+'</div>':'')+'</div>';
  if(!rRevealed) h+='<button class="btn primary" style="width:100%;margin-top:14px" onclick="rShow()">'+(LANG==='bn'?'উত্তর দেখাও':'Show answer')+'</button>';
  else h+='<div class="rate" style="margin-top:14px">'+[['আবার','Again','1d'],['কঠিন','Hard','3d'],['ভালো','Good','7d'],['সহজ','Easy','15d']].map(r=>'<button class="btn '+(r[1]==='Good'||r[1]==='Easy'?'filled':'ghost')+'" onclick="rRate()">'+(LANG==='bn'?r[0]:r[1])+'<small>'+r[2]+'</small></button>').join('')+'</div>';
  return h+'</div>';
}
window.rShow=()=>{rRevealed=true;render();};
window.rRate=()=>{rRevealed=false;rIdx++;render();};
window.rReset=()=>{rIdx=0;rRevealed=false;render();};

/* ---------- lang + boot ---------- */
document.getElementById('langs').addEventListener('click',(e)=>{const b=e.target.closest('button'); if(!b)return;
  LANG=b.dataset.l; [...document.querySelectorAll('#langs button')].forEach(x=>x.classList.toggle('on',x===b)); render();});
render();
</script>`;

const body = BODY.replace('__DATA__', JSON.stringify(DATA));
fs.mkdirSync(path.join(ROOT, 'preview'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'preview', 'sensei_body.html'), STYLE + body);
fs.writeFileSync(
  path.join(ROOT, 'preview', 'index.html'),
  '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Bhasago preview</title></head><body>' +
    STYLE + body + '</body></html>',
);
console.log('wrote preview/index.html and preview/sensei_body.html');
console.log('  kana:', DATA.hira.length + DATA.kata.length, '| stroke sets:',
  Object.keys(strokes.hiragana).length + Object.keys(strokes.katakana).length,
  '| lesson items:', DATA.lesson.items.length, '| pitch:', DATA.pitch.length);
