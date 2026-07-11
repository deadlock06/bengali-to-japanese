// CurriculumScreenV4 — JLPT-N5 path the AI tutor follows (rev-3 §1).
// Part of the AI Classroom red section (#B3121B — exclusive to this section).
// Entry: map icon in the lesson header. Demo data until the curriculum
// service exists (TODO T-120); the AI tutor MUST select lesson batches from
// the current curriculum unit once wired.
// D-001: no locks — upcoming units are visible and neutral, never gated.

import 'package:flutter/material.dart';
import '../app/theme.dart';

const _red = Color(0xFFB3121B);
const _redSub = Color(0xFFF5B8BC);

enum _UnitState { done, current, upcoming }

class _Unit {
  const _Unit(this.title, this.sub, this.state, [this.pct = 0]);
  final String title, sub;
  final _UnitState state;
  final double pct;
}

// TODO(T-120): replace with the curriculum service.
const _units = [
  _Unit('হিরাগানা', '৪৬ অক্ষর · লেখা + পড়া', _UnitState.done),
  _Unit('কাতাকানা', '৪৬ অক্ষর · বিদেশি শব্দ', _UnitState.done),
  _Unit('অভিবাদন ও পরিচয়', 'あいさつ · নিজের কথা বলা', _UnitState.done),
  _Unit('খাবার ও রেস্টুরেন্ট', 'তাবেমোনো · অর্ডার করা', _UnitState.current, .45),
  _Unit('কেনাকাটা ও সংখ্যা', 'かいもの · দাম জিজ্ঞেস করা', _UnitState.upcoming),
  _Unit('যাতায়াত', 'でんしゃ · পথ জিজ্ঞেস করা', _UnitState.upcoming),
  _Unit('কাজের ভাষা', 'しごと · নিরাপত্তা + অনুরোধ', _UnitState.upcoming),
];

class CurriculumScreenV4 extends StatelessWidget {
  const CurriculumScreenV4({super.key});

  @override
  Widget build(BuildContext context) {
    const overall = 3.45 / 7; // demo: 3 done + 45% of unit 4
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
              child: const SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                    value: overall,
                    backgroundColor: Color(0xFF242424),
                    valueColor: AlwaysStoppedAnimation(_red)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              itemCount: _units.length,
              itemBuilder: (context, i) =>
                  _row(context, _units[i], last: i == _units.length - 1),
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
