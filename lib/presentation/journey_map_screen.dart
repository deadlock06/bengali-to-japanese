// Journey-map Learn tab (C1 / D-015): the curriculum DAG as a winding road up
// Japan — Kyushu (start) to the torii gate (goal). Same verified DAG for every
// goal; the GOAL (ssw/jlpt/daily) changes EMPHASIS and recommendation copy
// only — never content, never order, never locks (D-001: done = hanko stamp,
// current = pulsing red, upcoming = neutral outline; everything tappable).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/curriculum_service.dart';
import 'lesson_screen_v4.dart';
import 'mock_exam_screen.dart';

const _red = Color(0xFFB3121B);

class JourneyMapScreen extends ConsumerWidget {
  const JourneyMapScreen({super.key});

  static const _goalMeta = {
    'ssw': (label: 'SSW ভিসার পথ', badge: 'JFT-A2', levels: {'A2'}, icon: '🏭'),
    'jlpt': (label: 'JLPT-র পথ', badge: 'N4', levels: {'N4'}, icon: '🎓'),
    'daily': (label: 'দৈনন্দিন জীবনের পথ', badge: 'A1', levels: {'A1'}, icon: '🗾'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(curriculumProvider).valueOrNull;
    final goal = ref.watch(goalProvider).valueOrNull ?? '';
    final meta = _goalMeta[goal];
    if (units == null) {
      return const Center(child: CircularProgressIndicator(color: _red));
    }
    final doneCount = units.where((u) => u.state == UnitProgress.done).length;
    return Column(children: [
      // Goal header — which road, how far, switch anytime (Settings too).
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          Text(meta?.icon ?? '🧭', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meta?.label ?? 'তোমার যাত্রাপথ',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text('$doneCount/${units.length} স্টেশন পেরিয়েছ — পথ একটাই, তাড়া নেই',
                  style: const TextStyle(color: BhasagoTheme.muted, fontSize: 11)),
            ]),
          ),
          if (meta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: _red, width: 1.4),
                  borderRadius: BorderRadius.circular(999)),
              child: Text('🎯 ${meta.badge}',
                  style: const TextStyle(
                      color: _red, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          reverse: true, // start at the bottom (Kyushu) like a real climb
          child: SizedBox(
            height: units.length * 96.0 + 140,
            child: LayoutBuilder(
              builder: (context, box) => Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                      painter: _RoadPainter(count: units.length)),
                ),
                // torii goal gate at the top
                Positioned(
                  top: 6,
                  left: 0, right: 0,
                  child: Column(children: [
                    const Text('⛩️', style: TextStyle(fontSize: 34)),
                    Text(goal == 'jlpt' ? 'JLPT N4' : goal == 'daily' ? 'জাপানের জীবন' : 'JFT-Basic → জাপান',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800, color: _red)),
                  ]),
                ),
                // Level-section banners (D-044): a visible milestone where the
                // road enters a new level — the map reads as SECTIONS of a
                // course (ভিত্তি → A1 → A2/JFT → N4 → …), not one long strip.
                for (var i = 0; i < units.length; i++)
                  if (i == 0 || units[i].level != units[i - 1].level)
                    _levelBanner(units[i].level, i, units.length),
                for (var i = 0; i < units.length; i++)
                  _node(context, ref, units[i], i, units.length, box.maxWidth,
                      emphasized: meta?.levels.contains(units[i].level) ?? false),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Level milestone banner drawn where section [i] begins (bottom-up road).
  Widget _levelBanner(String level, int i, int n) {
    const names = {
      'L0': ('ভিত্তি — কানা ও সংখ্যা', 'Foundation'),
      'A1': ('প্রথম কথাবার্তা', 'Irodori Starter'),
      'A2': ('কাজ ও জীবনের ভাষা', 'JFT-Basic'),
      'N4': ('ব্যাকরণে গভীরে', 'JLPT N4'),
      'N3': ('স্বাধীন ব্যবহারকারী', 'JLPT N3'),
      'N2': ('প্রায় native', 'JLPT N2'),
      'N1': ('পূর্ণ দক্ষতা', 'JLPT N1'),
    };
    final meta = names[level];
    final y = (n - 1 - i) * 96.0 + 90 - 34; // just above the section's first node
    return Positioned(
      top: y, left: 12, right: 12,
      child: Row(children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF2A2A2A))),
        Flexible(
          flex: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            constraints: const BoxConstraints(maxWidth: 240),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Text(
              '$level · ${meta?.$1 ?? level}${meta != null ? ' (${meta.$2})' : ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w800,
                  color: BhasagoTheme.muted),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF2A2A2A))),
      ]),
    );
  }

  /// Node i sits on the winding road, bottom (i=0) → top.
  Widget _node(BuildContext context, WidgetRef ref, CurriculumUnit u, int i,
      int n, double w, {required bool emphasized}) {
    final t = i / (n - 1);
    final y = (n - 1 - i) * 96.0 + 90; // bottom-up
    final x = w / 2 + math.sin(t * math.pi * 3) * (w * 0.26) - 27;
    final done = u.state == UnitProgress.done;
    final current = u.state == UnitProgress.current;
    final isMock = u.id.endsWith('.M');
    return Positioned(
      left: x, top: y,
      child: GestureDetector(
        onTap: () => _openUnit(context, ref, u),
        child: Column(children: [
          Container(
            width: 54, height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? _red
                  : current
                      ? const Color(0x33B3121B)
                      : const Color(0xFF1A1A1A),
              border: Border.all(
                  color: done || current
                      ? _red
                      : emphasized
                          ? const Color(0xFF6E2A2E)
                          : const Color(0xFF2E2E2E),
                  width: current ? 3 : 1.6),
            ),
            // done = hanko stamp · current = torch · mock = target · else level
            child: done
                ? const Text('印', style: TextStyle(
                    fontFamily: 'ZenKakuGothicNew', fontSize: 20,
                    fontWeight: FontWeight.w900, color: Color(0xFFF5F5F0)))
                : Text(isMock ? '🎯' : current ? '🔥' : u.level,
                    style: TextStyle(
                        fontSize: isMock || current ? 20 : 12,
                        fontWeight: FontWeight.w800,
                        color: current ? _red : BhasagoTheme.muted)),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 92,
            child: Text(u.title.of(Localizations.localeOf(context).languageCode),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: current
                        ? BhasagoTheme.text
                        : done
                            ? const Color(0xFFF5B8BC)
                            : BhasagoTheme.muted)),
          ),
        ]),
      ),
    );
  }

  /// Tap → unit card (can-do, progress) with the honest CTA: current unit →
  /// classroom, mock → mock exam; others informational (recommended path only).
  static String _afterStation(String lang) => lang == 'en'
      ? 'After this station: '
      : lang == 'ja'
          ? 'この駅のあとで: '
          : 'এই স্টেশন শেষে: ';

  void _openUnit(BuildContext context, WidgetRef ref, CurriculumUnit u) {
    final lang = Localizations.localeOf(context).languageCode;
    final current = u.state == UnitProgress.current;
    final isMock = u.id.endsWith('.M');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(u.id, style: const TextStyle(
                color: _red, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Expanded(child: Text(u.title.of(lang),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          const SizedBox(height: 6),
          Text('${_afterStation(lang)}${u.canDo.of(lang)}',
              style: const TextStyle(
                  fontSize: 12.5, height: 1.5, color: BhasagoTheme.muted)),
          if (u.pct > 0 && u.state != UnitProgress.done) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(height: 5, child: LinearProgressIndicator(
                  value: u.pct,
                  backgroundColor: const Color(0xFF242424),
                  valueColor: const AlwaysStoppedAnimation(_red))),
            ),
          ],
          const SizedBox(height: 16),
          if (isMock)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        MockExamScreen(kind: MockExamScreen.kindForUnit(u.id))));
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: _red, foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              child: const Text('🎯 মক দাও', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else if (current)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LessonScreenV4()));
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: _red, foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              child: const Text('🔥 ক্লাসরুমে চলো', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          else
            Text(
                u.state == UnitProgress.done
                    ? '✓ পেরিয়ে এসেছ — review deck-এ শব্দগুলো ফিরে ফিরে আসবে।'
                    : 'সামনের স্টেশন — সেনসেই recommended পথে এগোলে এখানে পৌঁছাবে। (কোনো তালা নেই — শুধু পরামর্শ।)',
                style: const TextStyle(
                    fontSize: 12, height: 1.5, color: BhasagoTheme.muted)),
        ]),
      ),
    );
  }
}

/// The winding road + region bands — a stylized south→north Japan climb.
class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.count});
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    // region bands (bottom→top): foundations → survival → work-life → summit
    final bands = [
      (name: 'ভিত্তি · 九州', frac: 0.16, color: const Color(0x14EFE94B)),
      (name: 'টিকে থাকা · 四国', frac: 0.20, color: const Color(0x1435E065)),
      (name: 'কাজ-জীবন · 本州', frac: 0.38, color: const Color(0x14B3121B)),
      (name: 'চূড়া · 北海道', frac: 0.26, color: const Color(0x144D7DF7)),
    ];
    var top = size.height;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final b in bands) {
      final h = size.height * b.frac;
      top -= h;
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, h), Paint()..color = b.color);
      tp.text = TextSpan(text: b.name, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: Color(0x66F5F5F0)));
      tp.layout();
      tp.paint(canvas, Offset(10, top + 8));
    }
    // the road: same sine the nodes sit on
    final road = Paint()
      ..color = const Color(0xFF2E2E2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < count; i++) {
      final t = i / (count - 1);
      final y = (count - 1 - i) * 96.0 + 90 + 27;
      final x = size.width / 2 + math.sin(t * math.pi * 3) * (size.width * 0.26);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, road);
    // dashed center line for the board-game feel
    canvas.drawPath(path, Paint()
      ..color = const Color(0x33F5F5F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => old.count != count;
}
