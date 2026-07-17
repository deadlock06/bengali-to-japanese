// Screens: Kana grid, Lesson viewer (bilingual), Review (FSRS-wired, in-memory
// demo). These mirror the HTML prototype's UX. Audio/native hooks attach where
// noted. Text-to-speech and mic are wired via platform services in the full app.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agents/persona.dart';
import '../app/providers.dart';
import '../domain/fsrs.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import '../app/theme.dart';
import 'agent_panel.dart';
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
          onTap: () {/* TODO: ttsService.speak(k.char) */},
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

/// The five steps every lesson item runs through (09 §Core lesson micro-loop).
enum _Phase { intro, recognition, production, context, srs }

/// Lesson micro-loop: Intro → Recognition → Production → Context → SRS, run once
/// per item. The autonomy invariant — [Skip] [Hint] [Quit] — is visible and
/// enabled in every step, ≤1 tap, never penalized (01 constitution / 09
/// §Invariant). Nothing auto-advances: each step ends on an explicit, neutral tap.
class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});
  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _started = false;
  bool _done = false;
  int _item = 0;
  int _phaseIx = 0;
  bool _hint = false;
  bool _showRom = true;

  // recognition step
  int? _pick;
  int? _optItem;
  List<({Tri meaning, bool correct})> _opts = const [];

  // production step
  bool _revealModel = false;
  bool _writeMode = false;

  // context step (word-block build)
  int? _ctxItem;
  final List<String> _built = [];
  List<String> _bank = [];

  // agent signals: when the current step appeared (hesitation) and whether
  // this step's first graded interaction was already timed.
  DateTime _stepShownAt = DateTime.now();
  bool _stepTimed = false;

  // per-lesson bookkeeping for the Feedback agent's completion record.
  int _lessonAnswers = 0, _lessonCorrect = 0, _lessonHints = 0, _lessonSkips = 0;

  _Phase get _phase => _Phase.values[_phaseIx];

  /// Milliseconds the learner looked at this step before first acting on it.
  /// Reported once per step so retries don't read as hesitation.
  double? _takeHesitation() {
    if (_stepTimed) return null;
    _stepTimed = true;
    return DateTime.now().difference(_stepShownAt).inMilliseconds.toDouble();
  }

  void _markStepShown() {
    _stepShownAt = DateTime.now();
    _stepTimed = false;
  }

  void _resetStep() {
    _hint = false;
    _pick = null;
    _optItem = null;
    _opts = const [];
    _revealModel = false;
    _writeMode = false;
    _ctxItem = null;
    _built.clear();
    _bank = [];
  }

  void _start() {
    setState(() {
      _started = true;
      _done = false;
      _item = 0;
      _phaseIx = 0;
      _lessonAnswers = 0;
      _lessonCorrect = 0;
      _lessonHints = 0;
      _lessonSkips = 0;
      _resetStep();
      _markStepShown();
    });
    // Wake the agent bus and feed it the SRS context (retention, days away,
    // due load) as soon as the encrypted store answers. Fire-and-forget: the
    // agents degrade to in-session signals if the DB is unavailable.
    final bus = ref.read(agentBusProvider.notifier);
    bus.startSession();
    ref.read(srsProvider).srsContext().then((c) {
      bus.updateSrsContext(
        retention: c.retention,
        daysSinceLastSession: c.daysSinceLastSession,
        dueLoad: c.dueLoad,
      );
    }).catchError((_) {/* device-only DB may be absent off-device */});
  }

  void _quit() => setState(() {
        _started = false;
        _done = false;
        _item = 0;
        _phaseIx = 0;
        _resetStep();
      });

  void _advance(int itemCount) => setState(() {
        _resetStep();
        _markStepShown();
        if (_phaseIx < _Phase.values.length - 1) {
          _phaseIx++;
        } else if (_item < itemCount - 1) {
          _item++;
          _phaseIx = 0;
        } else {
          _started = false;
          _done = true;
          _recordCompletion();
        }
      });

  /// One graded answer → both the agent bus (adaptation) and the per-lesson
  /// counters (Feedback agent's completion record).
  void _gradeAnswer({
    required bool correct,
    required String patternKey,
    required String itemId,
  }) {
    _lessonAnswers++;
    if (correct) _lessonCorrect++;
    final bus = ref.read(agentBusProvider.notifier);
    if (!correct) bus.recordItemMiss(itemId);
    bus.recordAnswer(
      correct: correct,
      patternKey: patternKey,
      hesitationMs: _takeHesitation(),
    );
  }

  /// Persists the finished lesson (fixed-XP mastery record). Fire-and-forget.
  Future<void> _recordCompletion() async {
    try {
      await ref.read(srsProvider).recordLessonCompletion(
            lessonId: widget.lessonId,
            items: _lessonAnswers,
            correct: _lessonCorrect,
            hints: _lessonHints,
            skips: _lessonSkips,
          );
    } catch (_) {/* DB unavailable off-device; completion UI still shows */}
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const Center(child: CircularProgressIndicator());
    final lesson = repo.lesson(widget.lessonId)!;

    if (_done) return _complete(context, lesson, lang);
    if (!_started) return _overview(context, lesson, lang);

    final item = lesson.items[_item];
    final n = lesson.items.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, lesson, lang),
          const SizedBox(height: 10),
          _controls(lang, n), // [Skip] [Hint] [Quit] — present in every step
          const SizedBox(height: 8),
          // The agents' visible face: psych strip, rationale, offers (04/09).
          AgentPanel(onAcceptHint: () => setState(() => _hint = true)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: _phaseBody(context, lesson, item, lang, n),
            ),
          ),
          if (_hint) ...[const SizedBox(height: 8), _hintPanel(context, item, lang)],
        ],
      ),
    );
  }

  // --- autonomy invariant: always visible, always enabled, ≤1 tap -------------
  Widget _controls(String lang, int itemCount) {
    // Flexible label so long text ellipsizes instead of overflowing on a
    // narrow (≈360dp) budget phone; English lives in the semantic label.
    Widget btn(IconData ic, String label, String semantic, VoidCallback onTap) =>
        Expanded(
          child: Semantics(
            button: true,
            label: semantic,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48), // ≥48dp touch target
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ic, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(children: [
      btn(Icons.lightbulb_outline, 'ইঙ্গিত', 'Show a hint', () {
        if (!_hint) {
          _lessonHints++;
          ref.read(agentBusProvider.notifier).recordHint();
        }
        setState(() => _hint = !_hint);
      }),
      const SizedBox(width: 8),
      btn(Icons.skip_next, 'বাদ', 'Skip this step', () {
        _lessonSkips++;
        ref.read(agentBusProvider.notifier).recordSkip();
        _advance(itemCount);
      }),
      const SizedBox(width: 8),
      btn(Icons.close, 'বন্ধ', 'Quit the lesson', _quit),
    ]);
  }

  Widget _header(BuildContext context, Lesson lesson, String lang) {
    const labels = {
      _Phase.intro: 'পরিচিতি · Intro',
      _Phase.recognition: 'চেনা · Recognition',
      _Phase.production: 'বলা/লেখা · Production',
      _Phase.context: 'বাক্য · Context',
      _Phase.srs: 'রিভিউ · SRS',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BilingualText(lesson.canDo,
            lang: lang, primaryStyle: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('শব্দ ${_item + 1}/${lesson.items.length}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(labels[_phase]!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var p = 0; p < _Phase.values.length; p++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: p == _Phase.values.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: p <= _phaseIx
                        ? const Color(0xFF00C853)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _phaseBody(
      BuildContext context, Lesson lesson, LessonItem item, String lang, int n) {
    switch (_phase) {
      case _Phase.intro:
        return _intro(context, item, lang, n);
      case _Phase.recognition:
        return _recognition(context, lesson, item, lang, n);
      case _Phase.production:
        return _production(context, item, lang, n);
      case _Phase.context:
        return _context(context, item, lang, n);
      case _Phase.srs:
        return _srs(context, item, lang, n);
    }
  }

  // 1. INTRO — target, meaning, sample note; all Bengali-first. ---------------
  Widget _intro(BuildContext context, LessonItem item, String lang, int n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(item.jp,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          if (_showRom)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.romaji,
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'শুনুন · Listen',
            onPressed: () {/* TODO: ttsService.speak(item.jp) */},
          ),
          const SizedBox(height: 8),
          BilingualText(item.meaning,
              lang: lang,
              align: TextAlign.center,
              primaryStyle: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF161D16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BilingualText(item.note, lang: lang),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            TextButton(
              onPressed: () => setState(() => _showRom = !_showRom),
              child: Text(_showRom ? 'Romaji off' : 'Romaji on'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _advance(n),
              child: const Text('বুঝেছি · Got it'),
            ),
          ]),
        ]),
      ),
    );
  }

  // 2. RECOGNITION — show the JP, pick its meaning (MC). No auto-advance. -----
  Widget _recognition(
      BuildContext context, Lesson lesson, LessonItem item, String lang, int n) {
    if (_optItem != _item) {
      final others = lesson.items.where((x) => x.id != item.id).toList()
        ..shuffle(Random(_item + 1));
      final opts = <({Tri meaning, bool correct})>[
        (meaning: item.meaning, correct: true),
        for (final o in others.take(3)) (meaning: o.meaning, correct: false),
      ]..shuffle(Random(_item * 7 + 3));
      _opts = opts;
      _optItem = _item;
    }
    final picked = _pick != null;
    final correct = picked && _opts[_pick!].correct;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            Text(item.jp,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.volume_up),
              tooltip: 'শুনুন · Listen',
              onPressed: () {/* TODO: ttsService.speak(item.jp) */},
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Text('এর মানে কী? · What does it mean?',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      const SizedBox(height: 8),
      for (var k = 0; k < _opts.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _optionTile(context, lang, k, item),
        ),
      const SizedBox(height: 4),
      if (picked && correct)
        Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
          const SizedBox(width: 6),
          // Instant positive feedback in the learner's chosen tutor voice.
          Expanded(
            child: Text(ref
                .read(agentBusProvider.notifier)
                .personaSay(PersonaEvent.correctAnswer)),
          ),
          FilledButton(
              onPressed: () => _advance(n), child: const Text('পরের · Next')),
        ])
      else if (picked && !correct)
        Text(
            '${ref.read(agentBusProvider.notifier).personaSay(PersonaEvent.wrongAnswer)} · try another',
            style: TextStyle(color: Colors.amber.shade300, fontSize: 13)),
    ]);
  }

  Widget _optionTile(
      BuildContext context, String lang, int k, LessonItem item) {
    final opt = _opts[k];
    final isPick = _pick == k;
    // Reveal correctness only for the tapped option; a hint highlights the answer.
    Color? bg;
    if (isPick) {
      bg = opt.correct ? const Color(0xFF10361F) : const Color(0xFF3A2A12);
    }
    final hinted = _hint && opt.correct;
    return InkWell(
      onTap: () {
        if (_pick != k) {
          // A changed pick is a fresh graded attempt (deterministic key match).
          _gradeAnswer(
              correct: opt.correct,
              patternKey: 'recognition',
              itemId: item.id);
        }
        setState(() => _pick = k);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg ?? Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hinted ? const Color(0xFF00C853) : Colors.transparent,
              width: 1.5),
        ),
        child: Align(
            alignment: Alignment.centerLeft,
            child: BilingualText(opt.meaning, lang: lang)),
      ),
    );
  }

  // 3. PRODUCTION — say it or write it; model + switch-type + skip always there.
  Widget _production(BuildContext context, LessonItem item, String lang, int n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(_writeMode ? 'এটি লেখো · Write this' : 'এটি বলো · Say this',
              style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 10),
          BilingualText(item.meaning,
              lang: lang,
              align: TextAlign.center,
              primaryStyle: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (_revealModel)
            Column(children: [
              Text(item.jp,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              Text(item.romaji, style: TextStyle(color: Colors.grey.shade400)),
            ])
          else
            Text('· · ·', style: TextStyle(color: Colors.grey.shade600, fontSize: 26)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.mic, size: 18),
              // Tier 0–1: record & self-compare; Tier 2+: aligned scoring (D-002).
              onPressed: () {/* TODO: recorder.start() → self-compare / alignment */},
              label: const Text('রেকর্ড · Record'),
            ),
            OutlinedButton.icon(
              icon: Icon(_revealModel ? Icons.visibility_off : Icons.visibility,
                  size: 18),
              onPressed: () => setState(() => _revealModel = !_revealModel),
              label: Text(_revealModel ? 'লুকাও · Hide' : 'মডেল · Model'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              onPressed: () => setState(() => _writeMode = !_writeMode),
              label: Text(_writeMode ? 'বলায় · Speak' : 'লেখায় · Write'),
            ),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
                onPressed: () => _advance(n), child: const Text('পরের · Next')),
          ),
        ]),
      ),
    );
  }

  // 4. CONTEXT — word-block build from srs_words. Wrong = gentle cue, no fail. -
  Widget _context(BuildContext context, LessonItem item, String lang, int n) {
    final tokens = item.srsWords;
    if (tokens.length < 2) {
      // Single-word item: nothing to arrange — show it in context, one tap on.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text('বাক্যে · In context',
                style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 12),
            Text(item.jp,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BilingualText(item.meaning, lang: lang, align: TextAlign.center),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                  onPressed: () => _advance(n), child: const Text('পরের · Next')),
            ),
          ]),
        ),
      );
    }
    if (_ctxItem != _item) {
      _built.clear();
      _bank = [...tokens]..shuffle(Random(_item + 5));
      _ctxItem = _item;
    }
    final complete = _built.length == tokens.length;
    final ordered = complete && _listEq(_built, tokens);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('শব্দগুলো সাজিয়ে বাক্য বানাও · Arrange the words',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      const SizedBox(height: 8),
      BilingualText(item.meaning, lang: lang),
      const SizedBox(height: 12),
      // assembled line
      Container(
        constraints: const BoxConstraints(minHeight: 56),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !complete
                ? Colors.transparent
                : ordered
                    ? const Color(0xFF00C853)
                    : Colors.amber,
            width: 1.5,
          ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var k = 0; k < _built.length; k++)
              ActionChip(
                label: Text(_built[k], style: const TextStyle(fontSize: 18)),
                onPressed: () => setState(() {
                  ref.read(agentBusProvider.notifier).recordInteraction();
                  _bank.add(_built.removeAt(k)); // tap to send back
                }),
              ),
            if (_built.isEmpty)
              Text('এখানে সাজাও · tap words below',
                  style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var k = 0; k < _bank.length; k++)
            ActionChip(
              label: Text(_bank[k], style: const TextStyle(fontSize: 18)),
              onPressed: () => setState(() {
                ref.read(agentBusProvider.notifier).recordInteraction();
                _built.add(_bank.removeAt(k));
                if (_built.length == tokens.length) {
                  // Placing the last block completes one graded attempt.
                  _gradeAnswer(
                      correct: _listEq(_built, tokens),
                      patternKey: 'context',
                      itemId: item.id);
                }
              }),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (complete && ordered)
        Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text('দারুণ! · ${item.jp}')),
          FilledButton(
              onPressed: () => _advance(n), child: const Text('পরের · Next')),
        ])
      else if (complete && !ordered)
        Row(children: [
          Expanded(
            child: Text('একটু এদিক-ওদিক · not quite — rearrange',
                style: TextStyle(color: Colors.amber.shade300, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => setState(() {
              _bank = [...tokens]..shuffle(Random(_item + 5));
              _built.clear();
            }),
            child: const Text('আবার · Reset'),
          ),
        ]),
    ]);
  }

  // 5. SRS — the item's words enter FSRS scheduling; user self-rates. ---------
  Widget _srs(BuildContext context, LessonItem item, String lang, int n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('রিভিউতে যোগ হলো · Added to your review',
              style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in item.srsWords)
                Chip(label: Text(w, style: const TextStyle(fontSize: 16))),
            ],
          ),
          const SizedBox(height: 20),
          Text('কেমন লাগল? · How was it?',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            for (final r in Rating.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FilledButton(
                    onPressed: () {
                      _seedAndReview(item, r); // persist to encrypted SRS
                      _advance(n);
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(_ratingLabel(r), textAlign: TextAlign.center),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _hintPanel(BuildContext context, LessonItem item, String lang) {
    return Card(
      color: const Color(0xFF1A2230),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Icon(Icons.lightbulb, color: Color(0xFFFFC400), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item.jp}  ·  ${item.romaji}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              BilingualText(item.meaning, lang: lang),
            ]),
          ),
        ]),
      ),
    );
  }

  // Lesson entry (calm overview) — Start is a choice, never auto-launched. ----
  Widget _overview(BuildContext context, Lesson lesson, String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BilingualText(lesson.canDo,
              lang: lang, primaryStyle: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${lesson.items.length} শব্দ · ${lesson.items.length} items · ৫ ধাপ',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('যেকোনো সময় Skip / Hint / Quit — কোনো চাপ নেই।',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: const Text('শুরু করো · Start'),
          ),
        ],
      ),
    );
  }

  Widget _complete(BuildContext context, Lesson lesson, String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 48),
          const SizedBox(height: 12),
          Text(
              ref
                  .read(agentBusProvider.notifier)
                  .personaSay(PersonaEvent.lessonComplete),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          // Fixed, predictable XP — never randomized (D-001 reward schedule).
          Text('+১০ XP · প্রতি লেসনে নির্দিষ্ট',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 8),
          Text('আরেকটা? · Another round?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: const Text('আবার · Restart'),
          ),
        ],
      ),
    );
  }

  // Seed the just-learned item as an FSRS card and log this rating. Fire-and-
  // forget: the encrypted DB is device-only, so a failure here (e.g. running
  // without the SQLCipher plugin) never blocks the lesson flow.
  Future<void> _seedAndReview(LessonItem item, Rating r) async {
    ref.read(agentBusProvider.notifier).recordLearned(item.id);
    try {
      final srs = ref.read(srsProvider);
      await srs.seedCard(
        id: item.id,
        word: item.jp,
        reading: item.kana,
        meaningBn: item.meaning.bn,
        meaningEn: item.meaning.en,
      );
      await srs.applyReview(ref.read(fsrsProvider), ScheduledCard(id: item.id), r);
    } catch (_) {/* DB unavailable off-device; lesson proceeds regardless */}
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var k = 0; k < a.length; k++) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  String _ratingLabel(Rating r) => switch (r) {
        Rating.again => 'আবার\nAgain',
        Rating.hard => 'কঠিন\nHard',
        Rating.good => 'ভালো\nGood',
        Rating.easy => 'সহজ\nEasy',
      };
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
