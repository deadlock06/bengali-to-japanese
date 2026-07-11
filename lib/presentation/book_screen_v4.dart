// BookScreenV4 — "ভাষা গো — বাংলায় জাপানি শেখো" (rev-3 §2).
// Green is this section\'s ink (#35E065; cover #2E7D5B→#1F5C42, spine #174632).
// Entry: book mini-card on Home + book icon in the lesson header.
// Chapter content/reader = future work (TODO T-121). Demo data below.

import 'package:flutter/material.dart';
import '../app/theme.dart';

const _green = Color(0xFF35E065);

enum _ChState { done, current, upcoming }

class _Chapter {
  const _Chapter(this.num, this.title, this.state);
  final String num, title;
  final _ChState state;
}

// TODO(T-121): replace with book/reader service.
const _chapters = [
  _Chapter('১', 'হিরাগানা পরিচয়', _ChState.done),
  _Chapter('২', 'প্রথম কথাবার্তা', _ChState.current),
  _Chapter('৩', 'সংখ্যা ও সময়', _ChState.upcoming),
  _Chapter('৪', 'খাবার ও রেস্টুরেন্ট', _ChState.upcoming),
  _Chapter('৫', 'কেনাকাটা', _ChState.upcoming),
  _Chapter('৬', 'যাতায়াত ও পথঘাট', _ChState.upcoming),
];

class BookScreenV4 extends StatelessWidget {
  const BookScreenV4({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BhasagoTheme.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 20, color: BhasagoTheme.muted)),
                const Text('বই', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
              const SizedBox(height: 6),
              _hero(),
              const SizedBox(height: 18),
              const Text('অধ্যায়',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              const SizedBox(height: 8),
              for (final c in _chapters) _chapterTile(c),
            ],
          ),
        ),
      );

  Widget _hero() => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D5B), Color(0xFF1F5C42)]),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 10, color: const Color(0xFF174632)), // spine
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: const [
                  Text('語', style: TextStyle(fontFamily: 'ZenKakuGothicNew',
                      fontSize: 44, height: 1, fontWeight: FontWeight.w900,
                      color: Color(0xFFF5F5F0))),
                  SizedBox(width: 10),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('BHASHA GO', style: TextStyle(fontSize: 10,
                        letterSpacing: 2.4, fontWeight: FontWeight.w800,
                        color: Color(0xCCF5F5F0))),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text('ভাষা গো — বাংলায় জাপানি শেখো',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                        color: Color(0xFFF5F5F0))),
                const SizedBox(height: 2),
                const Text('শূন্য থেকে N5 — গল্পে গল্পে, বাংলায় ব্যাখ্যা',
                    style: TextStyle(fontSize: 11.5, color: Color(0xB3F5F5F0))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const SizedBox(height: 4,
                          child: LinearProgressIndicator(value: .22,
                              backgroundColor: Color(0x33000000),
                              valueColor: AlwaysStoppedAnimation(_green))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('২২% পড়া হয়েছে', style: TextStyle(fontSize: 10.5,
                      fontWeight: FontWeight.w700, color: _green)),
                ]),
              ]),
            ),
          ),
        ]),
      );

  Widget _chapterTile(_Chapter c) {
    final isCur = c.state == _ChState.current;
    final isDone = c.state == _ChState.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCur ? _green.withValues(alpha: .10) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCur ? _green : const Color(0xFF2E2E2E),
            width: isCur ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30, alignment: Alignment.center,
          decoration: BoxDecoration(
              color: isDone ? _green : Colors.transparent,
              shape: BoxShape.circle,
              border: isDone ? null : Border.all(
                  color: isCur ? _green : const Color(0xFF2E2E2E), width: 1.5)),
          child: isDone
              ? const Icon(Icons.check, size: 15, color: Color(0xFF111111))
              : Text(c.num, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                  color: isCur ? _green : BhasagoTheme.muted)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (isCur)
              const Text('পড়া চলছে', style: TextStyle(color: _green, fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
          ]),
        ),
        Icon(isCur ? Icons.auto_stories : Icons.chevron_right,
            size: 18, color: isCur ? _green : BhasagoTheme.muted),
      ]),
    );
  }
}
