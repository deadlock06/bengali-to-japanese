// Screens: Kana grid, Lesson viewer (bilingual), Review (FSRS-wired, in-memory
// demo). These mirror the HTML prototype's UX. Audio/native hooks attach where
// noted. Text-to-speech and mic are wired via platform services in the full app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../data/audio_service.dart';
import '../domain/fsrs.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import '../app/theme.dart';
import 'state_pack.dart';
import 'widgets.dart';

/// Kana grid — tap a character to hear it (TTS hook).
class KanaScreen extends ConsumerWidget {
  final bool katakana;
  const KanaScreen({super.key, this.katakana = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const Center(child: CircularProgressIndicator());
    final kana = katakana ? repo.katakana : repo.hiragana;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: kana.length,
      itemBuilder: (_, i) {
        final k = kana[i];
        return InkWell(
          // Play the bundled clip (kana_hira_a …) AND show the picture-story
          // mnemonic (D-034) — shape → sound, the YouTube kana-method hook.
          onTap: () {
            AudioService.instance
                .play('kana_${katakana ? "kata" : "hira"}_${k.romaji}');
            if (k.mnemonicBn.isNotEmpty) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text('💡 ${k.mnemonicBn}'),
                  duration: const Duration(seconds: 3),
                ));
            }
          },
          child: Card(
            child: Center(
              // scaleDown: the glyph+romaji stack is a hair taller than a
              // square 5-column cell on narrow phones — never overflow.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(k.char, style: const TextStyle(fontSize: 26)),
                  Text(k.romaji,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Review — FSRS scheduling over the encrypted SRS store (SrsLocal). Cards are
/// seeded by the lesson micro-loop's SRS step; this screen reviews what's due.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final fsrs = const Fsrs();
  bool revealed = false;
  int idx = 0;
  List<({ScheduledCard card, String word, Tri meaning})>? _deck; // null = loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final deck = await ref.read(srsProvider).dueForReview();
      if (mounted) setState(() => _deck = deck);
    } catch (_) {
      if (mounted) setState(() => _deck = const []); // DB unavailable off-device
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = ref.watch(localeProvider).languageCode;
    final deck = _deck;
    if (deck == null) {
      return const StatePack.loading(
          bn: 'রিভিউ কার্ড লোড হচ্ছে…', accent: BhasagoColors.pink);
    }
    if (deck.isEmpty) {
      return const StatePack.empty(
        emoji: '✅',
        title: 'এখন রিভিউ নেই',
        body: 'একটা পাঠ করলে নতুন শব্দ review deck-এ যোগ হবে — কালকে ফিরে আসবে।',
      );
    }
    if (idx >= deck.length) {
      return StatePack.empty(
          emoji: '🎉', title: s.reviewDone,
          body: 'আজকের সব কার্ড দেখা শেষ — দারুণ! কাল আবার দেখা হবে।');
    }
    final entry = deck[idx];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // progress dots
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('${idx + 1} / ${deck.length}',
              style: const TextStyle(
                  color: BhasagoTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                  color: BhasagoTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BhasagoColors.pink, width: 1.3)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(entry.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'ZenKakuGothicNew',
                        fontSize: 34, fontWeight: FontWeight.w900,
                        color: BhasagoTheme.text)),
                if (revealed) ...[
                  const SizedBox(height: 14),
                  const Divider(color: BhasagoTheme.outline, height: 1),
                  const SizedBox(height: 14),
                  BilingualText(entry.meaning, lang: lang, align: TextAlign.center),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!revealed)
          FilledButton(
              onPressed: () => setState(() => revealed = true),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: BhasagoColors.pink,
                  foregroundColor: const Color(0xFF111111),
                  shape: const StadiumBorder()),
              child: Text(s.showAnswer,
                  style: const TextStyle(fontWeight: FontWeight.w800)))
        else
          Row(children: [
            for (final r in Rating.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () => _rate(r),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        foregroundColor: BhasagoTheme.text,
                        side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: Text(
                        '${_label(s, r)}\n${fsrs.nextInterval(fsrs.review(entry.card, r).stability)}d',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ]),
      ]),
    );
  }

  String _label(S s, Rating r) => switch (r) {
        Rating.again => s.rAgain,
        Rating.hard => s.rHard,
        Rating.good => s.rGood,
        Rating.easy => s.rEasy,
      };

  Future<void> _rate(Rating r) async {
    final entry = _deck![idx];
    try {
      await ref.read(srsProvider).applyReview(ref.read(fsrsProvider), entry.card, r);
    } catch (_) {/* best-effort persist; UI advances regardless */}
    if (mounted) {
      setState(() {
        revealed = false;
        idx++;
      });
    }
  }
}
