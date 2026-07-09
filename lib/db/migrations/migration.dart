// Migration primitives. Migrations are sequential, numbered, and IMMUTABLE:
// never edit a shipped migration — append a new one (06_DATABASE.md).

import 'package:sqflite_sqlcipher/sqflite.dart';

/// A single forward schema step. [version] is unique and strictly ascending;
/// it maps 1:1 to the SQLite `PRAGMA user_version` the engine records.
class Migration {
  final int version;
  final String name;
  final Future<void> Function(Database db) up;
  const Migration(this.version, this.name, this.up);
}

/// Applies every migration in the half-open range (from, to] in ascending
/// order. Called for both a fresh DB (from = 0) and an upgrade (from = oldV).
Future<void> runMigrations(
  Database db,
  List<Migration> all,
  int from,
  int to,
) async {
  final pending = all.where((m) => m.version > from && m.version <= to).toList()
    ..sort((a, b) => a.version.compareTo(b.version));
  for (final m in pending) {
    await m.up(db);
  }
}
