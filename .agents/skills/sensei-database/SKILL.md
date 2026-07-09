---
name: sensei-database
description: >-
  SQLite/SQLCipher database skill for SENSEI. Activates when writing SQL,
  DAOs, migrations, SrsLocal, db_key, schema changes, or any data persistence
  work. Also activates on: sqlite, sqlcipher, sqflite, migration, DAO, schema,
  srs_words, review_log, grammar_rules, FTS5, db_key, flutter_secure_storage,
  Keystore, encryption, SrsLocal, applyReview, seed, upsert, onUpgrade.
---

# SENSEI Database Guide

## Stack
- **sqflite_sqlcipher** — encrypted SQLite (AES-256)
- **flutter_secure_storage** — Keystore-backed key storage
- **db_key.dart** — generates + persists the encryption key
- **migrations/** — numbered immutable migrations

## Schema overview (current — m001 baseline)
```sql
-- SRS cards: one row per vocabulary item
CREATE TABLE srs_words (
  id          TEXT PRIMARY KEY,  -- matches content JSON "id"
  due         INTEGER NOT NULL,  -- Unix ms, next review timestamp
  stability   REAL    NOT NULL DEFAULT 0,
  difficulty  REAL    NOT NULL DEFAULT 0,
  elapsed_days INTEGER NOT NULL DEFAULT 0,
  scheduled_days INTEGER NOT NULL DEFAULT 0,
  reps        INTEGER NOT NULL DEFAULT 0,
  lapses      INTEGER NOT NULL DEFAULT 0,
  state       INTEGER NOT NULL DEFAULT 0,  -- FSRS State enum
  last_review INTEGER              -- Unix ms, nullable
);

-- Review history: one row per review event
CREATE TABLE review_log (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  word_id     TEXT    NOT NULL REFERENCES srs_words(id),
  rating      INTEGER NOT NULL,   -- 1=Again, 2=Hard, 3=Good, 4=Easy
  reviewed_at INTEGER NOT NULL,   -- Unix ms
  scheduled_days INTEGER NOT NULL,
  elapsed_days INTEGER NOT NULL,
  last_elapsed_days INTEGER NOT NULL,
  review_kind INTEGER NOT NULL    -- 0=learn, 1=review, 2=relearn, 3=manual
);

-- Grammar rules (for RAG / LLM grounding)
CREATE VIRTUAL TABLE grammar_rules USING fts5(
  rule_id, title, body, level, source
);
```

## SrsLocal DAO (`lib/data/srs_local.dart`)
```dart
class SrsLocal {
  // Initialize (must call before use):
  Future<void> init();

  // Seed a new card (first time a word is introduced):
  Future<void> seedCard(String wordId);

  // Get cards due for review (ordered by due asc):
  Future<List<SrsCard>> getDue({int limit = 20});

  // Apply a review rating and reschedule:
  Future<void> applyReview(String wordId, Rating rating);

  // Get all cards (for stats / export):
  Future<List<SrsCard>> getAll();

  // Export to CSV/JSON for offline export feature:
  Future<String> exportCsv();
  Future<Map<String, dynamic>> exportJson();
}
```

## Migration system (`lib/db/migrations/`)
```dart
// registry.dart lists all migrations in order:
// [m001_baseline, m002_xxx, ...]
// Each migration is immutable — never edit a committed one.
// Add new columns with ALTER TABLE ADD COLUMN only.
// Never DROP or RENAME columns (SQLite limitation).

// Template for a new migration:
class M002AddGrammarCache extends Migration {
  @override int get version => 2;

  @override Future<void> up(Database db) async {
    await db.execute('''
      ALTER TABLE srs_words ADD COLUMN grammar_hint TEXT;
    ''');
  }
}
```

## Encryption setup (`lib/db/db_key.dart`)
```dart
// Key lifecycle:
// 1. First run: generate 256-bit random key
// 2. Store in flutter_secure_storage (Keystore-backed on Android)
// 3. On open: retrieve key, pass as `password:` to sqflite_sqlcipher
// 4. Key rotation: not yet implemented (log in 99_DECISIONS if needed)

// Opening the DB:
final db = await openDatabase(
  path,
  password: await DbKey.get(),
  version: migrations.length,
  onCreate: (db, v) => runMigrations(db, 0, v),
  onUpgrade: (db, old, new_) => runMigrations(db, old, new_),
);
```

## Wiring SrsLocal into the app (DO-NEXT item)
```dart
// In main.dart ProviderScope — add override:
// Provider<SrsLocal> srsLocalProvider = Provider((ref) => SrsLocal());

// In screens.dart _srs TODO markers:
// Replace: // TODO: SrsLocal.applyReview
// With:    await ref.read(srsLocalProvider).applyReview(wordId, rating);

// In ReviewScreen — replace in-memory demo deck:
// Use: ref.read(srsLocalProvider).getDue(limit: 20)
```

## Proven: migration selection
`node tools/migrations_reference.mjs` → 10/10 pass

## DO NOT
- Edit committed migrations (breaks existing installs)
- Use plaintext SQLite (no `sqflite` without SQLCipher)  
- Store keys in SharedPreferences
- Use `DROP TABLE` or `RENAME COLUMN` in migrations
- Sync raw decrypted data over network (07_API_SYNC handles sync layer)
