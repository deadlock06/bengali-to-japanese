// Canonical SENSEI doc-router data.
// This is the single source of truth used by route.mjs and token_report.mjs.
// The human-readable table in ../SKILL.md mirrors this array — keep them in sync.
//
// Fields:
//   id    two-char doc id (matches filename prefix)
//   file  filename in docs/ (repo) or reference/ (installed skill)
//   tok   author's token estimate (from each doc's line-2 metadata comment)
//   when  READ WHEN summary
//   deps  ids to consider ONLY if the task actually touches them (don't preload)
//   keys  lowercase substrings that route a task description to this doc

export const DOCS = [
  { id: '00', file: '00_START_HERE.md', tok: 1500, deps: [],
    when: 'router + non-negotiables (this skill already replaces it)',
    keys: [] },

  { id: '01', file: '01_CONSTITUTION.md', tok: 1200, deps: ['00'],
    when: 'product / ethics / UX-policy decisions',
    keys: ['ethic', 'moral', 'policy', 'dark pattern', 'constitution', 'principle',
           'philosoph', 'values', 'honest', 'forc', 'guilt', 'consent', 'parental'] },

  { id: '02', file: '02_ARCHITECTURE.md', tok: 1500, deps: ['00'],
    when: 'designing components, wiring layers, adding dependencies',
    keys: ['architect', 'component', 'layer', 'depend', 'wiring', 'structure',
           'module', 'system design', 'capability ladder'] },

  { id: '03', file: '03_DISTRIBUTION.md', tok: 2000, deps: ['00', '02'],
    when: 'install size, download manager, content packs, P2P sharing, updates',
    keys: ['distribut', 'install', 'download', 'pack', 'p2p', 'sideload', 'apk',
           'size', 'manifest', 'update', 'tier', 'bundle size'] },

  { id: '04', file: '04_AGENTS.md', tok: 1600, deps: ['00', '02'],
    when: 'Director/Persona/Scaffold/Feedback agent logic, state bus, psych states',
    keys: ['agent', 'director', 'persona', 'scaffold', 'feedback', 'state bus',
           'psych', 'orchestrat', 'four-agent'] },

  { id: '05', file: '05_CONTENT_SCHEMAS.md', tok: 1800, deps: ['00'],
    when: 'authoring/validating lessons, SRS cards, mistakes, scenarios; content factory',
    keys: ['content', 'lesson', 'card', 'srs card', 'mistake', 'scenario', 'schema',
           'validat', 'json', 'factory', 'authoring', 'can-do'] },

  { id: '06', file: '06_DATABASE.md', tok: 1400, deps: ['00'],
    when: 'writing SQL, DAOs, migrations, local storage (SQLCipher AES-256)',
    keys: ['database', 'sql', 'dao', 'migrat', 'sqlite', 'sqlcipher', 'table',
           'storage', 'encrypt', 'schema v', 'at rest'] },

  { id: '07', file: '07_API_SYNC.md', tok: 1700, deps: ['00', '06'],
    when: 'endpoints, sync logic, conflict resolution, security/compliance',
    keys: ['api', 'sync', 'endpoint', 'conflict', 'backend', 'cloud', 'server',
           'compliance', 'retention', 'gdpr', 'firebase', 'supabase'] },

  { id: '08', file: '08_OFFLINE_AI.md', tok: 2200, deps: ['00', '02', '03'],
    when: 'implementing/tuning the on-device AI stack (LLM/STT/TTS/RAG/FSRS)',
    keys: ['llm', 'stt', 'tts', 'rag', 'fsrs', 'inference', 'model', 'whisper',
           'llama', 'kokoro', 'offline ai', 'ndk', 'quantiz', 'tok/s', 'prompt',
           'pitch', 'spaced repetition', 'scheduler'] },

  { id: '09', file: '09_UI_STATES.md', tok: 1500, deps: ['00', '01', '04'],
    when: 'building screens, copy, animations, accessibility, psych-state UI',
    keys: ['ui', 'screen', 'widget', 'copy', 'animation', 'accessib', 'design system',
           'color', 'layout', 'flow', 'struggle', 'burnout', 'boredom',
           'skip', 'hint', 'quit', 'micro-loop'] },

  { id: '10', file: '10_TESTING_QA.md', tok: 1200, deps: ['00'],
    when: 'writing tests, CI, benchmarks, UAT plans, ethical review',
    keys: ['test', ' ci', 'ci/', 'benchmark', 'uat', 'coverage', 'qa', 'mock',
           'ethical review', 'spike'] },

  { id: '11', file: '11_ROADMAP_TASKS.md', tok: 1600, deps: ['00'],
    when: 'deciding what to build next; single source of truth for progress',
    keys: ['roadmap', 'task', 'what next', 'build next', 'progress', 'phase',
           'board', 'backlog', 'what do i build', 'do next', 'status'] },

  { id: '12', file: '12_BUSINESS_GTM.md', tok: 1400, deps: ['00', '01'],
    when: 'monetization, marketing, launch ops, KPI/cost questions',
    keys: ['business', 'gtm', 'pricing', 'market', 'launch', 'kpi', 'metric',
           'cost', 'revenue', 'go-to-market', 'store listing'] },

  { id: '90', file: '90_EXISTING_CODEBASE.md', tok: 1000, deps: [],
    when: 'first session in this project, or CODEBASE_MAP.md missing/stale → regenerate it',
    keys: ['audit', 'existing', 'codebase map', 'first session', 'what exists',
           'reconcile', 'inventory', 'what do we already have'] },

  { id: '99', file: '99_DECISIONS.md', tok: 1000, deps: [],
    when: 'changing/questioning an existing design, or logging a new decision (APPEND-ONLY)',
    keys: ['decision', 'why was', 'rationale', 'redline', 'changed', 'log a decision',
           'reconsider', 'past mistake', 'd-0'] },
];

// Non-negotiables always apply — never routed away, never skipped.
export const NON_NEGOTIABLES = [
  'Recommend, never force (skip/pause/quit always work, no penalty; parental mode = only exception).',
  'No dark patterns (no variable rewards/loot/streak-saves/guilt/FOMO).',
  'Offline-first (every core feature works with no network, at every tier).',
  'Correctness over generation (graded = deterministic key match; grammar = retrieved, never invented).',
  'Data autonomy (one-tap offline export; instant delete w/ 7-day grace).',
  'Bengali-first (Banglish OK; EN/JA optional, never default).',
  'Free tier genuinely useful (premium = convenience only; no microtransactions).',
];

export const byId = (id) => DOCS.find((d) => d.id === id);
