// Progress dashboard (T-108) — mastery map, weak points, due forecast, and
// neutral activity history, all computed offline from the encrypted SRS store
// by domain/progress.dart.
//
// Framing (01/D-001): numbers are neutral history. Weak points read as
// "tomorrow's focus", never failure; activity is a plain count, never a
// streak with loss-warnings.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agents/feedback.dart';
import '../app/providers.dart';
import '../domain/progress.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressReport? _report;
  MasteryStats? _mastery;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final srs = ref.read(srsProvider);
      final cards = await srs.allCards();
      final ratings = await srs.recentRatings();
      final days = await srs.activityDays();
      final lessons = await srs.lessonCompletionCount();
      final retained = await srs.retainedWordCount(
          minStability: RewardSchedule.retainedStabilityDays);
      final report = buildProgressReport(
        cards: cards,
        recentRatings: ratings,
        activityDays: days,
        now: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _mastery =
            MasteryStats(lessonsCompleted: lessons, wordsRetained: retained);
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    if (_error) {
      return const Center(
          child: Text('ডেটা পাওয়া যায়নি · progress data unavailable'));
    }
    if (report == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (report.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.insights, size: 40, color: Color(0xFF6B7280)),
            const SizedBox(height: 12),
            const Text('এখনো কিছু জমা হয়নি · nothing tracked yet',
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('একটা লেসন শেষ করলে এখানে অগ্রগতি দেখা যাবে',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
        ),
      );
    }
    final mastery = _mastery;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (mastery != null) _headerStats(mastery),
          const SizedBox(height: 12),
          _masteryCard(report),
          const SizedBox(height: 12),
          _forecastCard(report),
          if (report.weakest.isNotEmpty) ...[
            const SizedBox(height: 12),
            _weakCard(report),
          ],
          const SizedBox(height: 12),
          _activityCard(report),
        ],
      ),
    );
  }

  // XP / level / exam readiness — every number a fixed function of mastery.
  Widget _headerStats(MasteryStats m) {
    Widget stat(String label, String value) => Expanded(
          child: Column(children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Row(children: [
            stat('XP', '${m.xp}'),
            stat('লেভেল · Level', '${m.level}'),
            stat('লেসন · Lessons', '${m.lessonsCompleted}'),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'JFT-A2 প্রস্তুতি · exam readiness  ${(m.examReadiness * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: m.examReadiness,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFF00C853),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _masteryCard(ProgressReport r) {
    final buckets = [
      ('নতুন', r.newCount, const Color(0xFF6B7280)),
      ('শিখছি', r.learning, const Color(0xFFFFAB00)),
      ('কাঁচা', r.young, const Color(0xFF29B6F6)),
      ('মনে আছে', r.retained, const Color(0xFF00C853)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('স্মৃতির মানচিত্র · memory map (${r.total})',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(children: [
                for (final (_, count, color) in buckets)
                  if (count > 0)
                    Expanded(flex: count, child: Container(color: color)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (final (label, count, color) in buckets)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, color: color),
                const SizedBox(width: 4),
                Text('$label $count', style: const TextStyle(fontSize: 12)),
              ]),
          ]),
          const SizedBox(height: 8),
          Text(
              'রিটেনশন · retention ${(r.retention * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ]),
      ),
    );
  }

  Widget _forecastCard(ProgressReport r) {
    const dayLabels = ['আজ', '+১', '+২', '+৩', '+৪', '+৫', '+৬'];
    final maxCount =
        r.dueForecast.fold(1, (max, v) => v > max ? v : max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('সামনের রিভিউ · due this week',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var d = 0; d < r.dueForecast.length && d < 7; d++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (r.dueForecast[d] > 0)
                            Text('${r.dueForecast[d]}',
                                style: const TextStyle(fontSize: 10)),
                          const SizedBox(height: 2),
                          Container(
                            height: 40.0 * r.dueForecast[d] / maxCount + 2,
                            decoration: BoxDecoration(
                              color: d == 0
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF3D5AFE),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(dayLabels[d],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // "Tomorrow's focus" — weakness framed as guidance, never as failure.
  Widget _weakCard(ProgressReport r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ঝালাইয়ের তালিকা · focus next',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('এগুলো একটু বেশি দেখা দরকার — এটাই স্বাভাবিক শেখা।',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          for (final w in r.weakest)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.word,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        if (w.meaningBn.isNotEmpty)
                          Text(w.meaningBn,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                      ]),
                ),
                Text(
                    w.lapses > 0
                        ? '${w.lapses}× ভুলে গেছ'
                        : 'এখনো কাঁচা',
                    style: TextStyle(
                        fontSize: 11, color: Colors.amber.shade300)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _activityCard(ProgressReport r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.calendar_month, size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            // Neutral history — a fact, never a streak to protect (D-001).
            child: Text(
                'গত ৩০ দিনে ${r.activeDaysLast30} দিন পড়েছ · '
                '${r.activeDaysLast30} active days in 30',
                style: const TextStyle(fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}
