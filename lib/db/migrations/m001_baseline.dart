// 001 — baseline SRS schema (cards + review history). Matches the shipped v1
// tables the FSRS DAO reads/writes. IMMUTABLE: never edit; append new migrations.

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'migration.dart';

final Migration m001Baseline = Migration(1, 'baseline_srs', (Database db) async {
  await db.execute('''
    CREATE TABLE srs_cards(
      id TEXT PRIMARY KEY,
      word TEXT NOT NULL,
      reading TEXT NOT NULL,
      meaning_bn TEXT NOT NULL,
      meaning_en TEXT NOT NULL,
      jlpt_level TEXT NOT NULL,
      due INTEGER NOT NULL,
      stability REAL DEFAULT 0,
      difficulty REAL DEFAULT 0,
      reps INTEGER DEFAULT 0,
      lapses INTEGER DEFAULT 0,
      state TEXT DEFAULT 'new',
      last_review INTEGER,
      elapsed_days REAL DEFAULT 0
    )''');
  await db.execute('CREATE INDEX idx_cards_due ON srs_cards(due)');
  await db.execute('''
    CREATE TABLE review_history(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      card_id TEXT NOT NULL,
      reviewed_at INTEGER NOT NULL,
      rating INTEGER NOT NULL,
      old_stability REAL, new_stability REAL,
      old_difficulty REAL, new_difficulty REAL
    )''');
});
