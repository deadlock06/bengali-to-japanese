// BookScreenV4 — "ভাষা গো" (rev-3 §2, T-121 first slice — DATA-WIRED).
// Green is this section's ink (#35E065; cover #2E7D5B→#1F5C42, spine #174632).
// Entry: book mini-card on Home + book icon in the lesson header.
// Data: bookProvider (assets/book/book.json ← tools/build_book_json.mjs ←
// classroom/BOOK.md). Read-position: app_meta 'book_read_ch' (device DB;
// off-device defaults to 0 → chapter 1 is current). Tap a chapter → reader.
// verified:false until native BN-JP review (05 rule #10) — shown in reader.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../data/book_repository.dart';
import 'book_reader_screen.dart';

const _green = Color(0xFF35E065);

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
String bnNum(int n) =>
    n.toString().split('').map((d) => _bnDigits[int.parse(d)]).join();

class BookScreenV4 extends ConsumerWidget {
  const BookScreenV4({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookProvider).valueOrNull;
    final readCh = ref.watch(bookReadChapterProvider).valueOrNull ?? 0;
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      body: SafeArea(
        child: book == null
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _body(context, book, readCh),
      ),
    );
  }

  Widget _body(BuildContext context, BookRepository book, int readCh) {
    final chapters = book.numbered;
    final progress =
        chapters.isEmpty ? 0.0 : (readCh.clamp(0, chapters.length)) / chapters.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Row(children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back,
                  size: 20, color: BhasagoTheme.muted)),
          const Text('বই',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        const SizedBox(height: 6),
        _hero(context, book, progress),
        const SizedBox(height: 18),
        if (book.intro != null) ...[
          _specialTile(context, book.intro!, Icons.menu_book_outlined),
          const SizedBox(height: 14),
        ],
        const Text('অধ্যায়',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        const SizedBox(height: 8),
        for (final c in chapters) _chapterTile(context, c, readCh),
        if (book.appendices.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('রেফারেন্স (Appendix)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          const SizedBox(height: 8),
          for (final a in book.appendices)
            _specialTile(context, a, Icons.table_chart_outlined),
        ],
      ],
    );
  }

  void _open(BuildContext context, BookChapter c) =>
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookReaderScreen(chapter: c)));

  Widget _hero(BuildContext context, BookRepository book, double progress) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D5B), Color(0xFF1F5C42)]),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 10, color: const Color(0xFF174632)), // spine
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('語',
                      style: TextStyle(
                          fontFamily: 'ZenKakuGothicNew',
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF5F5F0))),
                  SizedBox(width: 10),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('BHASHA GO',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.4,
                            fontWeight: FontWeight.w800,
                            color: Color(0xCCF5F5F0))),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(book.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFFF5F5F0))),
                const SizedBox(height: 2),
                Text(book.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xB3F5F5F0))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0x33000000),
                              valueColor:
                                  const AlwaysStoppedAnimation(_green))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${(progress * 100).round()}% পড়া হয়েছে',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _green)),
                ]),
              ]),
            ),
          ),
        ]),
      );

  Widget _chapterTile(BuildContext context, BookChapter c, int readCh) {
    final isDone = c.num <= readCh;
    final isCur = c.num == readCh + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCur ? _green.withValues(alpha: .10) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isCur ? _green : const Color(0xFF2E2E2E),
            width: isCur ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: () => _open(context, c),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: isDone ? _green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isDone
                      ? null
                      : Border.all(
                          color: isCur ? _green : const Color(0xFF2E2E2E),
                          width: 1.5)),
              child: isDone
                  ? const Icon(Icons.check, size: 15, color: Color(0xFF111111))
                  : Text(bnNum(c.num),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isCur ? _green : BhasagoTheme.muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                if (isCur)
                  const Text('পড়া চলছে',
                      style: TextStyle(
                          color: _green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
              ]),
            ),
            Icon(isCur ? Icons.auto_stories : Icons.chevron_right,
                size: 18, color: isCur ? _green : BhasagoTheme.muted),
          ]),
        ),
      ),
    );
  }

  Widget _specialTile(BuildContext context, BookChapter c, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: InkWell(
          onTap: () => _open(context, c),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(icon, size: 18, color: BhasagoTheme.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: BhasagoTheme.muted),
            ]),
          ),
        ),
      );
}
