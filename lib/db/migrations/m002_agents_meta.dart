// 002 — agent & autonomy support: lesson completion log (Feedback agent's
// mastery counts + progress dashboard) and an app_meta KV table (deletion
// grace timestamp, persona preference, export bookkeeping — 01 §Data autonomy).
// IMMUTABLE: never edit; append new migrations.

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'migration.dart';

final Migration m002AgentsMeta =
    Migration(2, 'agents_meta', (Database db) async {
  await db.execute('''
    CREATE TABLE lesson_completions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lesson_id TEXT NOT NULL,
      completed_at INTEGER NOT NULL,
      items INTEGER NOT NULL,
      correct INTEGER NOT NULL,
      hints INTEGER NOT NULL DEFAULT 0,
      skips INTEGER NOT NULL DEFAULT 0
    )''');
  await db.execute(
      'CREATE INDEX idx_completions_at ON lesson_completions(completed_at)');
  await db.execute('''
    CREATE TABLE app_meta(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )''');
});
