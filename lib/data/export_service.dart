// One-tap offline data export (01 §Data autonomy): everything the learner
// owns, zipped as JSON (full fidelity) + CSVs (spreadsheet-friendly) + a
// human-readable summary. No network, no support ticket, no account.
//
// PDF report generation is deferred (needs the `pdf` package ≈ +1MB APK);
// summary.txt carries the same content in plain text meanwhile.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'srs_local.dart';

class ExportService {
  ExportService(this._srs);
  final SrsLocal _srs;

  /// Builds the ZIP and returns the written file. Everything happens
  /// on-device; the caller shows the path (and later a share sheet).
  Future<File> exportZip({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final data = await _srs.exportAll();

    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('bhasago_data.json', const JsonEncoder.withIndent('  ').convert(data));
    add('srs_cards.csv',
        _csv(data['srs_cards'] as List<Map<String, Object?>>));
    add('review_history.csv',
        _csv(data['review_history'] as List<Map<String, Object?>>));
    add('lesson_completions.csv',
        _csv(data['lesson_completions'] as List<Map<String, Object?>>));
    add('summary.txt', _summary(data, at));

    final bytes = ZipEncoder().encode(archive)!;
    final dir = await getApplicationDocumentsDirectory();
    final stamp =
        '${at.year}${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}';
    final file = File(p.join(dir.path, 'bhasago_export_$stamp.zip'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// RFC-4180-style CSV: header from the first row's keys, fields quoted
  /// when they contain commas/quotes/newlines.
  String _csv(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return '';
    final cols = rows.first.keys.toList();
    String cell(Object? v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp(r'[",\n]'))
          ? '"${s.replaceAll('"', '""')}"'
          : s;
    }

    final b = StringBuffer()..writeln(cols.join(','));
    for (final r in rows) {
      b.writeln(cols.map((c) => cell(r[c])).join(','));
    }
    return b.toString();
  }

  String _summary(Map<String, Object?> data, DateTime at) {
    final cards = (data['srs_cards'] as List).length;
    final reviews = (data['review_history'] as List).length;
    final lessons = (data['lesson_completions'] as List).length;
    return '''
Bhasago — তোমার শেখার ডেটা · your learning data
Exported: ${at.toIso8601String()}

কার্ড · cards: $cards
রিভিউ · reviews: $reviews
লেসন শেষ · lessons completed: $lessons

এই ফাইলগুলো তোমার — যেকোনো অ্যাপে খুলতে পারো, যেখানে খুশি রাখতে পারো।
These files are yours: open them anywhere, keep them anywhere.
JSON = full fidelity · CSV = spreadsheets · this file = quick overview.
''';
  }
}
