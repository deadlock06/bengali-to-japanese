// CurriculumScreenV4 — JLPT-N5 path the AI tutor follows (rev-3 §1).
// Part of the AI Classroom red section (#B3121B — exclusive to this section).
// Entry: map icon in the lesson header. Demo data until the curriculum
// service exists (TODO T-120); the AI tutor MUST select lesson batches from
// the current curriculum unit once wired.
// D-001: no locks — upcoming units are visible and neutral, never gated.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../data/curriculum_service.dart';
import 'mock_exam_screen.dart';

const _red = Color(0xFFB3121B);
const _redSub = Color(0xFFF5B8BC);

enum _UnitState { done, current, upcoming }

class _Unit {
  const _Unit(this.title, this.sub, this.state, [this.pct = 0, this.id = '']);
  final String title, sub;
  final _UnitState state;
  final double pct;
  final String id;
  bool get isMock => id.endsWith('.M');
}

// Demo fallback — shown only while the ontology loads (or on error), so the
// screen keeps design parity. Live data: curriculumProvider (T-120, wired).
const _demoUnits = [
  _Unit('হিরাগানা', '৪৬ অক্ষর · লেখা + পড়া', _UnitState.done),
  _Unit('কাতাকানা', '৪৬ অক্ষর · বিদেশি শব্দ', _UnitState.done),
  _Unit('অভিবাদন ও পরিচয়', 'あいさつ · নিজের কথা বলা', _UnitState.done),
  _Unit('খাবার ও রেস্টুরেন্ট', 'তাবেমোনো · অর্ডার করা', _UnitState.current, .45),
  _Unit('কেনাকাটা ও সংখ্যা', 'かいもの · দাম জিজ্ঞেস করা', _UnitState.upcoming),
  _Unit('যাতায়াত', 'でんしゃ · পথ জিজ্ঞেস করা', _UnitState.upcoming),
  _Unit('কাজের ভাষা', 'しごと · নিরাপত্তা + অনুরোধ', _UnitState.upcoming),
];

class CurriculumScreenV4 extends ConsumerWidget {
  const CurriculumScreenV4({super.key});

  static _UnitState _viewState(UnitProgress p) => switch (p) {
        UnitProgress.done => _UnitState.done,
        UnitProgress.current => _UnitState.current,
        UnitProgress.upcoming => _UnitState.upcoming,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final async = ref.watch(curriculumProvider);
    final units = async.maybeWhen(
      data: (list) => [
        for (final u in list)
          _Unit(u.title.of(lang), u.canDo.of(lang), _viewState(u.state), u.pct,
              u.id),
      ],
      orElse: () => _demoUnits,
    );
    final overall = units.isEmpty
        ? 0.0
        : units.fold<double>(
              0, (s, u) => s + (u.state == _UnitState.done ? 1 : u.pct)) /
            units.length;
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 20, color: BhasagoTheme.muted)),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('কারিকুলাম', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('AI টিউটর এই পথ ধরেই পড়ায়',
                      style: TextStyle(color: BhasagoTheme.muted, fontSize: 11)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    border: Border.all(color: _red, width: 1.5),
                    borderRadius: BorderRadius.circular(999)),
                child: const Text('JLPT N5',
                    style: TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                    value: overall,
                    backgroundColor: const Color(0xFF242424),
                    valueColor: const AlwaysStoppedAnimation(_red)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              itemCount: units.length,
              itemBuilder: (context, i) =>
                  _row(context, units[i], last: i == units.length - 1),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, _Unit u, {required bool last}) =>
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 34,
            child: Column(children: [
              _dot(u.state),
              if (!last)
                Expanded(child: Container(width: 2, color: const Color(0xFF242424))),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Padding(
              padding: const EdgeInsets.only(bottom: 14), child: _card(context, u))),
        ]),
      );

  Widget _dot(_UnitState st) {
    switch (st) {
      case _UnitState.done:
        return Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 15, color: Color(0xFFF5F5F0)));
      case _UnitState.current:
        return Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: _red, width: 2)),
            child: const Icon(Icons.play_arrow, size: 15, color: _red));
      case _UnitState.upcoming:
        return Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E2E2E), width: 2)),
            child: const Icon(Icons.schedule, size: 14, color: BhasagoTheme.muted));
    }
  }

  Widget _card(BuildContext context, _Unit u) {
    // Mock units (A2.M / N4.M) launch the mock exam — an OFFER, tappable in any
    // state (recommended after the units, never gated — D-001).
    if (u.isMock) {
      return Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  MockExamScreen(kind: MockExamScreen.kindForUnit(u.id)))),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _red, width: 1.3)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(u.sub, style: const TextStyle(color: BhasagoTheme.muted, fontSize: 11.5)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                    color: _red, borderRadius: BorderRadius.circular(999)),
                child: const Text('🎯 মক দাও',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ),
        ),
      );
    }
    if (u.state != _UnitState.current) {
      // Done + upcoming look identical in weight — neutral, no lock icons.
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E2E2E))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 2),
          Text(u.sub, style: const TextStyle(color: BhasagoTheme.muted, fontSize: 11.5)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(u.title,
            style: const TextStyle(
                color: Color(0xFFF5F5F0), fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text('${u.sub} · ${(u.pct * 100).round()}%',
            style: const TextStyle(color: _redSub, fontSize: 11.5)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
                value: u.pct,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF5F5F0))),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          // Back to the lesson — the tutor continues this unit.
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: const Color(0xFFF5F5F0),
              foregroundColor: _red,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          child: const Text('চালিয়ে যাও'),
        ),
      ]),
    );
  }
}
