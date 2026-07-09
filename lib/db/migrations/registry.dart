// Append-only migration registry. Add each new migration to the END of the
// list; never reorder or edit an existing entry (06_DATABASE.md).

import 'migration.dart';
import 'm001_baseline.dart';

final List<Migration> kMigrations = <Migration>[
  m001Baseline,
  // m002_align_06_schema,  // future: widen srs_cards + add users/messages/... (06)
];

/// The latest schema version = highest migration number. Passed to
/// openDatabase(version:) so the engine drives onCreate/onUpgrade.
int get kSchemaVersion =>
    kMigrations.fold(0, (max, m) => m.version > max ? m.version : max);
