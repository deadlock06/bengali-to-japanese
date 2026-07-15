// T-121 — Bhasha Go chapter reader (green section ink, Bold Ink tokens).
// Renders a BookChapter's blocks (h/p/li/q/table) from assets/book/book.json.
// "পড়া শেষ" persists app_meta 'book_read_ch' (bookReadChapterProvider reads it)
// so the cover %, Home mini-card and chapter tiles advance. No locks — any
// chapter is readable in any order (D-001); marking read is optional.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../data/book_repository.dart';
import 'selection_explain.dart';

const _green = Color(0xFF35E065);

class BookReaderScreen extends ConsumerWidget {
  const BookReaderScreen({super.key, required this.chapter});
  final BookChapter chapter;

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    try {
      final read = await ref.read(srsProvider).getMeta('book_read_ch');
      final cur = int.tryParse(read ?? '') ?? 0;
      if (chapter.num > cur) {
        await ref.read(srsProvider).setMeta('book_read_ch', '${chapter.num}');
        ref.invalidate(bookReadChapterProvider);
      }
    } catch (_) {/* off-device DB — reading still works, position isn't kept */}
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back,
                    size: 20, color: BhasagoTheme.muted),
              ),
              Expanded(
                child: Text(chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              if (chapter.num > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      border: Border.all(color: _green, width: 1.5),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text('অধ্যায় ${_bn(chapter.num)}',
                      style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
          ),
          Expanded(
            // Select any word/sentence here → "ব্যাখ্যা" → sensei explains it.
            child: SelectionExplain(
              child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final b in chapter.blocks) _block(b),
                const SizedBox(height: 16),
                if (chapter.num > 0)
                  FilledButton(
                    onPressed: () => _markRead(context, ref),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: _green,
                      foregroundColor: const Color(0xFF111111),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('পড়া শেষ ✓',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _block(BookBlock b) {
    switch (b.t) {
      case 'h':
        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(b.c,
              style: const TextStyle(
                  color: _green, fontSize: 15, fontWeight: FontWeight.w800)),
        );
      case 'li':
        return Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•  ',
                style: TextStyle(color: _green, fontSize: 13, height: 1.6)),
            Expanded(
                child: Text(b.c,
                    style: const TextStyle(fontSize: 13, height: 1.6))),
          ]),
        );
      case 'q':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _green, width: 3))),
          child: Text(b.c,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.6, color: BhasagoTheme.muted)),
        );
      case 'table':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Table(
            border: TableBorder.all(color: BhasagoTheme.outline),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              for (final row in b.rows)
                TableRow(children: [
                  for (final cell in row)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      child: Text(cell,
                          style:
                              const TextStyle(fontSize: 11.5, height: 1.5)),
                    ),
                ]),
            ],
          ),
        );
      default: // 'p'
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child:
              Text(b.c, style: const TextStyle(fontSize: 13, height: 1.7)),
        );
    }
  }
}

String _bn(int n) =>
    n.toString().split('').map((d) => '০১২৩৪৫৬৭৮৯'[int.parse(d)]).join();
