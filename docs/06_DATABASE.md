# 06 DATABASE — Local SQLite Schema
<!-- READ WHEN: writing SQL, DAOs, migrations. DEPENDS: 00. Encryption: SQLCipher AES-256. ~1.4K tokens -->

Migrations: sequential, numbered, in /lib/db/migrations/. Never edit a shipped migration.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY, created_at INTEGER NOT NULL,
  current_level TEXT DEFAULT 'N5', current_streak INTEGER DEFAULT 0, max_streak INTEGER DEFAULT 0,
  last_study_date INTEGER, total_words_learned INTEGER DEFAULT 0, total_cards_reviewed INTEGER DEFAULT 0,
  total_conversations INTEGER DEFAULT 0, total_minutes_studied INTEGER DEFAULT 0,
  preferred_persona TEXT DEFAULT 'sensei', daily_cap_minutes INTEGER DEFAULT 120,
  break_reminder_minutes INTEGER DEFAULT 20, voice TEXT DEFAULT 'jf_alpha', voice_speed REAL DEFAULT 1.0,
  daily_new_card_limit INTEGER DEFAULT 10, daily_review_limit INTEGER DEFAULT 20,
  cloud_sync_enabled INTEGER DEFAULT 0, parental_mode_enabled INTEGER DEFAULT 0,
  account_status TEXT DEFAULT 'active',
  data_export_requested_at INTEGER, data_export_completed_at INTEGER,
  account_deletion_requested_at INTEGER, account_deletion_grace_period_end INTEGER );

CREATE TABLE srs_cards (
  id TEXT PRIMARY KEY, word TEXT NOT NULL, reading TEXT NOT NULL, meaning_bn TEXT NOT NULL,
  meaning_en TEXT, jlpt_level TEXT NOT NULL, word_type TEXT, tags TEXT,
  example_sentence_jp TEXT, example_sentence_bn TEXT, bengali_mnemonic TEXT,
  image_path TEXT, audio_path TEXT,
  due INTEGER NOT NULL, stability REAL DEFAULT 0, difficulty REAL DEFAULT 0,
  reps INTEGER DEFAULT 0, lapses INTEGER DEFAULT 0, state TEXT DEFAULT 'new',
  last_review INTEGER, elapsed_days REAL DEFAULT 0, created_at INTEGER NOT NULL,
  source TEXT DEFAULT 'lesson', card_type TEXT DEFAULT 'recognition',
  optimal_mood TEXT DEFAULT 'neutral', mood_history TEXT DEFAULT '[]' );
CREATE INDEX idx_cards_due ON srs_cards(due);
CREATE INDEX idx_cards_state ON srs_cards(state);
CREATE INDEX idx_cards_jlpt ON srs_cards(jlpt_level);

CREATE TABLE review_history ( id TEXT PRIMARY KEY, card_id TEXT NOT NULL, reviewed_at INTEGER NOT NULL,
  rating INTEGER NOT NULL, mood TEXT DEFAULT 'neutral', scheduled_interval REAL, actual_interval REAL,
  old_stability REAL, new_stability REAL, old_difficulty REAL, new_difficulty REAL,
  FOREIGN KEY (card_id) REFERENCES srs_cards(id) );
CREATE INDEX idx_history_card ON review_history(card_id);
CREATE INDEX idx_history_date ON review_history(reviewed_at);

CREATE TABLE conversations ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, scenario TEXT, role TEXT,
  started_at INTEGER NOT NULL, ended_at INTEGER, total_exchanges INTEGER DEFAULT 0,
  grammar_mistakes INTEGER DEFAULT 0, new_words INTEGER DEFAULT 0,
  emotional_state TEXT DEFAULT 'flow', session_duration INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE messages ( id TEXT PRIMARY KEY, conversation_id TEXT NOT NULL, role TEXT NOT NULL,
  content TEXT NOT NULL, language TEXT, timestamp INTEGER NOT NULL,
  parsed_jp TEXT, parsed_bn TEXT, parsed_rom TEXT, grammar_notes TEXT, srs_words TEXT,
  emotional_state TEXT DEFAULT 'neutral',
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) );
CREATE INDEX idx_messages_conv ON messages(conversation_id);

CREATE TABLE grammar_mistakes ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, mistake_type TEXT NOT NULL,
  user_input TEXT NOT NULL, correct_form TEXT NOT NULL, explanation_bn TEXT NOT NULL, explanation_en TEXT,
  first_seen INTEGER NOT NULL, last_seen INTEGER NOT NULL, occurrence_count INTEGER DEFAULT 1,
  remediation_lesson_id TEXT, FOREIGN KEY (user_id) REFERENCES users(id) );
CREATE INDEX idx_mistakes_user ON grammar_mistakes(user_id);
CREATE INDEX idx_mistakes_type ON grammar_mistakes(mistake_type);

CREATE TABLE achievements ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, achievement_id TEXT NOT NULL,
  unlocked_at INTEGER NOT NULL, milestone_id TEXT NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE daily_stats ( date TEXT PRIMARY KEY, user_id TEXT NOT NULL,
  cards_reviewed INTEGER DEFAULT 0, new_cards_learned INTEGER DEFAULT 0, minutes_studied INTEGER DEFAULT 0,
  retention_rate REAL, mistakes_made INTEGER DEFAULT 0, conversations_completed INTEGER DEFAULT 0,
  emotional_state TEXT DEFAULT 'neutral', FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE brain_map_nodes ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, concept_id TEXT NOT NULL,
  concept_name TEXT NOT NULL, mastery_level REAL DEFAULT 0, is_glowing INTEGER DEFAULT 0,
  last_updated INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE installed_packs ( id TEXT PRIMARY KEY, version INTEGER NOT NULL, tier INTEGER NOT NULL,
  size_bytes INTEGER, installed_at INTEGER NOT NULL, verified INTEGER DEFAULT 0, source TEXT DEFAULT 'cdn' );
-- source: cdn | p2p | preload  (03_DISTRIBUTION)

CREATE TABLE pack_download_state ( pack_id TEXT PRIMARY KEY, target_version INTEGER,
  chunks_total INTEGER, chunks_done INTEGER DEFAULT 0, bytes_done INTEGER DEFAULT 0,
  status TEXT DEFAULT 'queued', network_policy TEXT DEFAULT 'wifi_only',
  last_error TEXT, updated_at INTEGER );

CREATE TABLE offline_queue ( id INTEGER PRIMARY KEY AUTOINCREMENT, action_type TEXT NOT NULL,
  payload TEXT NOT NULL, created_at INTEGER NOT NULL, retry_count INTEGER DEFAULT 0,
  last_error TEXT, status TEXT DEFAULT 'pending' );

CREATE TABLE data_export_log ( id TEXT PRIMARY KEY, user_id TEXT NOT NULL, requested_at INTEGER NOT NULL,
  completed_at INTEGER, file_size_bytes INTEGER, file_path TEXT, status TEXT DEFAULT 'pending',
  error_message TEXT, FOREIGN KEY (user_id) REFERENCES users(id) );

CREATE TABLE agent_log ( id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL,
  agent TEXT NOT NULL, decision TEXT NOT NULL, rationale_bn TEXT, overridden_by_user INTEGER DEFAULT 0 );
```
Removed vs old spec: `loot_inventory` random-drop semantics (achievements table now carries milestone cosmetics via `milestone_id`); `emotional_difficulty` column (99 D-003).
