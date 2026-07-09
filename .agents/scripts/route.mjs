#!/usr/bin/env node
/**
 * SENSEI skill router helper
 * Usage: node .agents/scripts/route.mjs "what you're doing"
 * Prints: recommended spec file(s) + estimated token cost
 */

const ROUTER = [
  { keywords: ['constitution','ethics','policy','ux policy','dark pattern','parental','guardian'], file: 'docs/01_CONSTITUTION.md', tokens: '0.7K' },
  { keywords: ['architecture','system design','component','dependency','add library','add package'], file: 'docs/02_ARCHITECTURE.md', tokens: '0.9K' },
  { keywords: ['distribution','install size','download','content pack','p2p','update','tier'], file: 'docs/03_DISTRIBUTION.md', tokens: '1.1K' },
  { keywords: ['agent','director','persona','scaffold','feedback','state bus','ai agent'], file: 'docs/04_AGENTS.md', tokens: '0.9K' },
  { keywords: ['content','lesson','schema','srs card','mistake','scenario','kana','vocabulary','json','validate'], file: 'docs/05_CONTENT_SCHEMAS.md', tokens: '1.0K' },
  { keywords: ['sql','dao','migration','sqlite','database','srs_local','srslocal','sqlcipher','schema'], file: 'docs/06_DATABASE.md', tokens: '1.5K' },
  { keywords: ['api','sync','endpoint','conflict','security','compliance','supabase sync'], file: 'docs/07_API_SYNC.md', tokens: '0.9K' },
  { keywords: ['llm','inference','llama','whisper','kokoro','tts','stt','fsrs','rag','on-device','offline ai','pitch','f0'], file: 'docs/08_OFFLINE_AI.md', tokens: '1.4K' },
  { keywords: ['screen','ui','ux','widget','animation','accessibility','copy','state','onboard','psych'], file: 'docs/09_UI_STATES.md', tokens: '0.9K' },
  { keywords: ['test','ci','benchmark','uat','ethical review','proof','validate'], file: 'docs/10_TESTING_QA.md', tokens: '0.8K' },
  { keywords: ['roadmap','task','next','backlog','progress','sprint','what to build'], file: 'docs/11_ROADMAP_TASKS.md', tokens: '1.3K' },
  { keywords: ['pricing','gtm','marketing','launch','kpi','cost','revenue','business'], file: 'docs/12_BUSINESS_GTM.md', tokens: '1.0K' },
  { keywords: ['existing','codebase','audit','what exists','repo','map','explore','first session'], file: 'docs/90_EXISTING_CODEBASE.md', tokens: '0.7K' },
  { keywords: ['decision','why was','why did','trade-off','99_decisions','log decision','d-0','design choice'], file: 'docs/99_DECISIONS.md', tokens: '0.9K' },
];

const query = process.argv.slice(2).join(' ').toLowerCase();
if (!query) {
  console.log('Usage: node .agents/scripts/route.mjs "your task description"');
  process.exit(0);
}

const matches = ROUTER.filter(r => r.keywords.some(k => query.includes(k)));

if (matches.length === 0) {
  console.log('No specific match — start with: NEXT_SESSION.md + CODEBASE_MAP.md');
  console.log('Then pick the closest row from docs/00_START_HERE.md');
} else {
  console.log(`\n✓ Router match for: "${query}"\n`);
  matches.forEach(m => {
    console.log(`  📄 ${m.file}  (~${m.tokens})`);
  });
  const totalK = matches.reduce((sum, m) => sum + parseFloat(m.tokens), 0);
  console.log(`\n  Total: ~${totalK.toFixed(1)}K tokens (vs 15K full spec)\n`);
}
