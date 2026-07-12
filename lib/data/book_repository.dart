// Bhasha Go book loader (T-121 first slice).
// Source: assets/book/book.json — compiled from classroom/BOOK.md by
// tools/build_book_json.mjs (re-run it after every BOOK.md edit).
// verified:false until native BN-JP review (05 rule #10) — meta carries it.
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class BookBlock {
  const BookBlock({required this.t, this.c = '', this.rows = const []});
  final String t; // h | p | li | q | table
  final String c;
  final List<List<String>> rows;

  factory BookBlock.fromJson(Map<String, dynamic> j) => BookBlock(
        t: j['t'] as String,
        c: j['c'] as String? ?? '',
        rows: (j['rows'] as List?)
                ?.map((r) => List<String>.from(r as List))
                .toList() ??
            const [],
      );
}

class BookChapter {
  const BookChapter({
    required this.id,
    required this.num, // 1..20 content · 0 intro · -1 essays · -2 appendices
    required this.title,
    required this.part,
    this.unit,
    this.level,
    required this.blocks,
  });
  final String id, title, part;
  final int num;
  final String? unit, level;
  final List<BookBlock> blocks;

  factory BookChapter.fromJson(Map<String, dynamic> j) => BookChapter(
        id: j['id'] as String,
        num: j['num'] as int,
        title: j['title'] as String,
        part: j['part'] as String? ?? '',
        unit: j['unit'] as String?,
        level: j['level'] as String?,
        blocks: (j['blocks'] as List)
            .map((b) => BookBlock.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}

class BookRepository {
  BookRepository._(this.title, this.subtitle, this.verified, this.chapters);
  final String title, subtitle;
  final bool verified;
  final List<BookChapter> chapters;

  List<BookChapter> get numbered =>
      chapters.where((c) => c.num > 0).toList()..sort((a, b) => a.num - b.num);
  BookChapter? get intro =>
      chapters.where((c) => c.id == 'intro').firstOrNull;
  List<BookChapter> get appendices =>
      chapters.where((c) => c.num == -2).toList();

  static Future<BookRepository> load() async {
    final j = json.decode(await rootBundle.loadString('assets/book/book.json'))
        as Map<String, dynamic>;
    final meta = j['meta'] as Map<String, dynamic>;
    return BookRepository._(
      meta['title'] as String,
      meta['subtitle'] as String? ?? '',
      meta['verified'] as bool? ?? false,
      (j['chapters'] as List)
          .map((c) => BookChapter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
