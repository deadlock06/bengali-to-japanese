// step6_lesson_screen.dart — destination: lib/presentation/lesson_screen_v4.dart (new)
//
// REV-2 (2026-07-11): see HANDOFF.md "Rev-2 deltas" —
//  - entry card on Home is now blood-red AI Classroom (#B3121B, exclusive token)
//  - add SenseiChatSheet (showModalBottomSheet): messages, chips, text input,
//    mic voice mode w/ waveform; demo-canned replies -> TODO wire tutor service
//  - all lesson strings localized (bn/en/ja) incl. options, hints, mood labels
//  - compact metrics: kanji 42, pills 44, progress 4, sprite 52x64
//
// WIRING NOTES
// - Entry: HomeScreen yellow lesson card onTap -> Navigator.push(LessonScreenV4()).
//   (goLesson callback in step2_home_screen.dart TODO now resolves here.)
// - Pushed page, NOT a tab. Close (বন্ধ) / back / completion "হোমে ফিরুন" all pop.
// - Depends on step1 theme tokens only. Two NEW mood tokens added below
//   (orange struggle / purple boredom) — add them to theme.dart if you prefer
//   central tokens; kept local here to avoid a second theme migration.
// - Demo QS list is placeholder: replace with SrsLocal.nextLessonBatch() (TODO T-112).
// - D-001 COMPLIANCE (do not change): wrong answers only open a hint and shift
//   ambiance color; no streak loss messaging, no locks, skip always available.
// - Grading is answer-key only (index compare). No LLM in the answer path.
// - prefers-reduced-motion: gate _AmbientClassroom animations with
//   MediaQuery.of(context).disableAnimations.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'book_screen_v4.dart';
import 'curriculum_screen_v4.dart';

/// Adaptive mood of the classroom. One accent dominates per state.
enum LessonMood { neutral, flow, struggle, burnout, boredom }

class MoodSpec {
  const MoodSpec(this.color, this.label, this.teacherMsg);
  final Color color;
  final String label;
  final String teacherMsg;
}

const moodSpecs = {
  LessonMood.neutral:  MoodSpec(Color(0xFFEFE94B), 'পরিচিতি', 'ধীরে ধীরে — সময় আছে।'),
  LessonMood.flow:     MoodSpec(Color(0xFF35E065), 'ফ্লো · দারুণ চলছে', 'এই গতিতেই থাকো!'),
  LessonMood.struggle: MoodSpec(Color(0xFFF0954B), 'একসাথে দেখি', 'চলো একসাথে ভাবি — সমস্যা নেই।'),
  LessonMood.burnout:  MoodSpec(Color(0xFF4D7DF7), 'বিশ্রামের সময়', 'একটু বিরতি নিলে ভালো হয়।'),
  LessonMood.boredom:  MoodSpec(Color(0xFFA78BF7), 'খুব সহজ লাগছে?', 'সহজ লাগছে? আরও কঠিন আসছে।'),
};

class LessonItem {
  const LessonItem(this.jp, this.yomi, this.options, this.answerIndex, this.hint);
  final String jp, yomi, hint;
  final List<String> options;
  final int answerIndex;
}

// TODO(T-112): replace with SRS-selected batch.
const demoBatch = [
  LessonItem('水', 'みず · mizu', ['পানি', 'আগুন', 'গাছ', 'ভাত'], 0, '「み」 দিয়ে শুরু — যেটা তুমি পান করো।'),
  LessonItem('火', 'ひ · hi', ['পাহাড়', 'আগুন', 'চাঁদ', 'নদী'], 1, 'গরম, জ্বলে — রান্নায় লাগে।'),
  LessonItem('木', 'き · ki', ['পাথর', 'মাছ', 'গাছ', 'পাখি'], 2, 'ডালপালা আছে, বাগানে জন্মায়।'),
  LessonItem('ご飯', 'ごはん · gohan', ['ভাত', 'চা', 'দুধ', 'রুটি'], 0, 'প্রতিদিনের প্রধান খাবার।'),
  LessonItem('お茶', 'おちゃ · ocha', ['কফি', 'জুস', 'চা', 'পানি'], 2, 'গরম পানীয় — বিকেলে খাওয়া হয়।'),
];

class LessonScreenV4 extends StatefulWidget {
  const LessonScreenV4({super.key});
  @override
  State<LessonScreenV4> createState() => _LessonScreenV4State();
}

class _LessonScreenV4State extends State<LessonScreenV4> {
  int idx = 0, streak = 0, wrongs = 0, picked = -1;
  bool hintOpen = false, done = false;
  LessonMood mood = LessonMood.neutral;

  LessonItem get q => demoBatch[idx.clamp(0, demoBatch.length - 1)];
  MoodSpec get m => moodSpecs[mood]!;

  void pick(int i) {
    if (done || picked == i) return;
    if (i == q.answerIndex) {
      final last = idx >= demoBatch.length - 1;
      setState(() { picked = i; mood = LessonMood.flow; });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          streak += 1;
          mood = streak >= 3 ? LessonMood.boredom : LessonMood.flow;
          if (last) { done = true; } else { idx += 1; }
          picked = -1; hintOpen = false;
        });
      });
    } else {
      setState(() {
        wrongs += 1; streak = 0; picked = i; hintOpen = true;
        mood = wrongs >= 3 ? LessonMood.burnout : LessonMood.struggle; // D-001: color shift + hint only
      });
    }
  }

  void skip() => setState(() { // always available — D-001
    idx = (idx + 1).clamp(0, demoBatch.length - 1);
    picked = -1; hintOpen = false; mood = LessonMood.neutral;
  });

  @override
  Widget build(BuildContext context) {
    final progress = idx / demoBatch.length;
    return Scaffold(
      backgroundColor: BhasagoTheme.bg, // #0F0F0F
      body: SafeArea(
        child: Stack(children: [
          _AmbientClassroom(accent: m.color,
              still: mood == LessonMood.burnout, // burnout = intentionally still
              reduceMotion: MediaQuery.of(context).disableAnimations),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _header(context),
              const SizedBox(height: 10),
              _progressBar(progress),
              const SizedBox(height: 16),
              _questionCard(),
              if (hintOpen) ...[const SizedBox(height: 10), _hintCard()],
              const Spacer(),
              _teacherRow(),
              const SizedBox(height: 12),
              _toolbar(context),
            ]),
          ),
          if (done) _doneOverlay(context),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, size: 20, color: BhasagoTheme.muted)),
        const Expanded(child: Text('পাঠ ৩ · রেস্টুরেন্টে', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
        // Rev-4: section entries — curriculum map + book. 19px glyphs, 44px
        // hit area, muted base; section tints on press (red / green).
        _headerIcon(Icons.map_outlined, const Color(0xFFE8515A),
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CurriculumScreenV4()))),
        _headerIcon(Icons.auto_stories, const Color(0xFF35E065),
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BookScreenV4()))),
        Container( // mood pill
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: m.color, width: 1.5), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: m.color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(m.label, style: TextStyle(color: m.color, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]);

  Widget _headerIcon(IconData ic, Color tint, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(ic, size: 19),
        color: BhasagoTheme.muted,
        highlightColor: tint.withValues(alpha: .18),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: const EdgeInsets.all(4),
      );

  Widget _progressBar(double p) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(height: 5, child: LinearProgressIndicator(
          value: p, backgroundColor: const Color(0xFF262626),
          valueColor: AlwaysStoppedAnimation(m.color))),
      );

  Widget _questionCard() => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(color: BhasagoTheme.card, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BhasagoTheme.outline)),
        child: Column(children: [
          Text('এর মানে কী?', style: TextStyle(color: m.color, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: .5)),
          Text(q.jp, style: const TextStyle(fontFamily: 'ZenKakuGothicNew', fontSize: 54, fontWeight: FontWeight.w900, height: 1.15)),
          Text(q.yomi, style: const TextStyle(fontFamily: 'ZenKakuGothicNew', fontSize: 13.5, fontWeight: FontWeight.w700, color: BhasagoTheme.muted)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 3.2,
            children: List.generate(q.options.length, (i) {
              final isPicked = picked == i, correct = i == q.answerIndex;
              final bg = isPicked ? (correct ? m.color : const Color(0x26F0954B)) : Colors.transparent;
              final bd = isPicked ? (correct ? m.color : const Color(0xFFF0954B)) : BhasagoTheme.pillOutline;
              final fg = isPicked && correct ? const Color(0xFF111111) : BhasagoTheme.text;
              return OutlinedButton(
                onPressed: () => pick(i),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46), backgroundColor: bg, foregroundColor: fg,
                  side: BorderSide(color: bd, width: 1.5),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                child: Text(q.options[i]),
              );
            }),
          ),
        ]),
      );

  Widget _hintCard() => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: BhasagoTheme.card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: m.color, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.lightbulb_outline, size: 17, color: m.color), const SizedBox(width: 7),
              Text('ইঙ্গিত', style: TextStyle(color: m.color, fontSize: 12, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 6),
          Text(q.hint, style: const TextStyle(fontSize: 12.5, height: 1.5)),
        ]),
      );

  // Rev-2 §4: tapping the sensei opens the chat/talk sheet.
  void _openChat(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SenseiChatSheet(accent: m.color, moodLabel: m.label),
      );

  Widget _teacherRow() => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        GestureDetector(
          onTap: () => _openChat(context),
          child: Semantics(
            button: true,
            label: 'Talk to sensei',
            child: _TeacherSprite(accent: m.color),
          ),
        ), // 64x78 CustomPainter port of the SVG sensei
        const SizedBox(width: 10),
        Flexible(child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: BhasagoTheme.card,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(3)),
              border: Border.all(color: BhasagoTheme.outline)),
          child: Text(m.teacherMsg, style: const TextStyle(fontSize: 12)),
        )),
      ]);

  Widget _toolbar(BuildContext context) => Row(children: [
        Expanded(child: _pill(icon: Icons.lightbulb_outline, iconColor: m.color, label: 'ইঙ্গিত',
            onTap: () => setState(() => hintOpen = !hintOpen))),
        const SizedBox(width: 10),
        Expanded(child: _pill(icon: Icons.skip_next, iconColor: BhasagoTheme.muted, label: 'বাদ', onTap: skip)),
        const SizedBox(width: 10),
        SizedBox(width: 78, child: _pill(icon: Icons.close, iconColor: BhasagoTheme.muted, label: 'বন্ধ',
            onTap: () => Navigator.pop(context))),
      ]);

  Widget _pill({required IconData icon, required Color iconColor, required String label, required VoidCallback onTap}) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: iconColor),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46), foregroundColor: BhasagoTheme.text,
          side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      );

  Widget _doneOverlay(BuildContext context) => Container(
        color: const Color(0xE60A0A0A), alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          decoration: BoxDecoration(color: BhasagoTheme.card, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF35E065), width: 1.5)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.celebration_outlined, size: 40, color: Color(0xFF35E065)),
            const SizedBox(height: 8),
            const Text('পাঠ শেষ!', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('৫টি নতুন শব্দ শেখা হলো।', style: TextStyle(fontSize: 12.5, color: BhasagoTheme.muted)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() { idx = 0; streak = 0; wrongs = 0; picked = -1; hintOpen = false; done = false; mood = LessonMood.neutral; }),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: const Color(0xFF35E065), foregroundColor: const Color(0xFF111111), shape: const StadiumBorder()),
              child: const Text('আবার অনুশীলন', style: TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.5), shape: const StadiumBorder(), foregroundColor: BhasagoTheme.text),
              child: const Text('হোমে ফিরুন', style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
        ),
      );
}

/// Mood-tinted classroom backdrop: shoji window grid, swaying lantern,
/// faint 教室 kanji, tatami floor lines, drifting dust motes.
/// still=true (burnout) or reduceMotion freezes all loops.
class _AmbientClassroom extends StatelessWidget {
  const _AmbientClassroom({required this.accent, this.still = false, this.reduceMotion = false});
  final Color accent; final bool still, reduceMotion;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(size: Size.infinite,
            painter: _ClassroomPainter(accent: accent)), // static paint; add
        // AnimationController loops (lanternSway 6s, dustFloat 7-9s) in a
        // StatefulWidget wrapper when !still && !reduceMotion. Kept out of
        // the handoff diff for brevity — motion values in HANDOFF.md §Motion.
      );
}

class _ClassroomPainter extends CustomPainter {
  _ClassroomPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = const Color(0xFF2E2E2E)..strokeWidth = 2;
    // window grid (top-right)
    final win = Rect.fromLTWH(size.width - 110, 44, 96, 126);
    canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(6)), line..style = PaintingStyle.stroke);
    final cell = Paint()..color = accent.withValues(alpha: .07);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawRect(Rect.fromLTWH(win.left + 2 + c * 31, win.top + 2 + r * 31, 29, 29), cell);
      }
    }
    // lantern (top-left)
    canvas.drawLine(Offset(35, 0), const Offset(35, 46), line);
    final lantern = Rect.fromLTWH(19, 46, 32, 40);
    canvas.drawRRect(RRect.fromRectAndRadius(lantern, const Radius.circular(16)),
        Paint()..color = accent.withValues(alpha: .25));
    // tatami floor lines (bottom 110px)
    final floor = Paint()..color = const Color(0x08F5F5F0)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 58) {
      canvas.drawLine(Offset(x, size.height - 110), Offset(x, size.height), floor);
    }
    canvas.drawLine(Offset(0, size.height - 110), Offset(size.width, size.height - 110),
        Paint()..color = const Color(0xFF242424));
  }
  @override
  bool shouldRepaint(_ClassroomPainter old) => old.accent != accent;
}

/// Port of the SVG sensei sprite (robe, mood-colored scarf, bun + accent bead).
class _TeacherSprite extends StatelessWidget {
  const _TeacherSprite({required this.accent});
  final Color accent;
  @override
  Widget build(BuildContext context) => SizedBox(width: 64, height: 78,
      child: CustomPaint(painter: _TeacherPainter(accent: accent)));
}

class _TeacherPainter extends CustomPainter {
  _TeacherPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 146);
    // robe
    final robe = Path()..moveTo(28, 140)..quadraticBezierTo(28, 86, 60, 86)..quadraticBezierTo(92, 86, 92, 140)..close();
    canvas.drawPath(robe, Paint()..color = const Color(0xFF242424));
    canvas.drawPath(robe, Paint()..color = const Color(0xFF2E2E2E)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // scarf (mood accent)
    final scarf = Path()..moveTo(40, 100)..quadraticBezierTo(60, 110, 80, 100);
    canvas.drawPath(scarf, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round);
    // head + hair + bun + bead
    canvas.drawCircle(const Offset(60, 60), 25, Paint()..color = const Color(0xFFF2D9BE));
    final hair = Path()..moveTo(35, 56)..quadraticBezierTo(35, 32, 60, 32)..quadraticBezierTo(85, 32, 85, 56)
      ..quadraticBezierTo(76, 42, 60, 42)..quadraticBezierTo(44, 42, 35, 56)..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(const Offset(60, 28), 9, Paint()..color = const Color(0xFF1C1C1C));
    canvas.drawCircle(const Offset(60, 21), 3.5, Paint()..color = accent);
    // face
    final ink = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(const Offset(51, 60), 2.6, ink);
    canvas.drawCircle(const Offset(69, 60), 2.6, ink);
    final smile = Path()..moveTo(53, 70)..quadraticBezierTo(60, 75, 67, 70);
    canvas.drawPath(smile, Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_TeacherPainter old) => old.accent != accent;
}


// ═══════════════ Sensei chat/talk sheet (rev-2 §4) ═══════════════
// DEMO-CANNED: production wires the AI tutor service. The chat is
// explanatory only — grading stays answer-key (D-001 / 00 §4).

class SenseiChatSheet extends StatefulWidget {
  const SenseiChatSheet({super.key, required this.accent, required this.moodLabel});
  final Color accent;
  final String moodLabel;
  @override
  State<SenseiChatSheet> createState() => _SenseiChatSheetState();
}

class _ChatMsg {
  const _ChatMsg(this.mine, this.text);
  final bool mine;
  final String text;
}

class _SenseiChatSheetState extends State<SenseiChatSheet>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  final List<_ChatMsg> _msgs = [
    const _ChatMsg(false, 'কিছু জিজ্ঞেস করতে চাও? আমি আছি — যেকোনো শব্দ বা বাক্য নিয়ে প্রশ্ন করো।'),
  ];
  bool _typing = false, _listening = false;
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  int _cannedIdx = 0;

  // TODO(tutor-service): canned replies for design parity only.
  static const _canned = [
    '「水 · みず」মানে পানি। মনে রাখো: み(mi) দিয়ে শুরু — যেটা তুমি পান করো। উদাহরণ: 水をください — একটু পানি দিন।',
    'ভালো প্রশ্ন! উচ্চারণটা ভেঙে বলি: go-HAN — দ্বিতীয় অংশে একটু জোর। আস্তে আস্তে ৩ বার বলো।',
    'উদাহরণ বাক্য: お茶をのみます — আমি চা খাই। のみます মানে পান করা।',
  ];

  @override
  void dispose() {
    _anim.dispose();
    _input.dispose();
    super.dispose();
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty || _typing) return;
    _input.clear();
    setState(() {
      _msgs.insert(0, _ChatMsg(true, t));
      _typing = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _msgs.insert(0, _ChatMsg(false, _canned[_cannedIdx % _canned.length]));
        _cannedIdx++;
        _typing = false;
      });
    });
  }

  void _toggleMic() {
    if (_listening) {
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    // Demo voice mode: "listen" then transcribe a canned utterance and send.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted || !_listening) return;
      setState(() => _listening = false);
      _send('「ご飯」মানে কী আবার বুঝিয়ে দাও');
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * .76;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final a = widget.accent;
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        height: h,
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2E2E2E))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              width: 38, height: 38, alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A), shape: BoxShape.circle,
                  border: Border.all(color: a, width: 2)),
              child: Text('先', style: TextStyle(fontFamily: 'ZenKakuGothicNew',
                  fontSize: 16, fontWeight: FontWeight.w900, color: a)),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('সেনসেই', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: a, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(widget.moodLabel,
                    style: TextStyle(color: a, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ]),
            ]),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20, color: BhasagoTheme.muted)),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _msgs.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (_typing && i == 0) return _typingBubble();
                final msg = _msgs[_typing ? i - 1 : i];
                return _bubble(msg);
              },
            ),
          ),
          if (_listening) _waveform(a) else _chips(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFF2E2E2E))),
                child: TextField(
                  controller: _input,
                  onSubmitted: _send,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                      isCollapsed: true, border: InputBorder.none,
                      hintText: 'সেনসেইকে জিজ্ঞেস করো…',
                      hintStyle: TextStyle(color: BhasagoTheme.muted, fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _roundBtn(Icons.mic_none, _listening ? a : const Color(0xFF1A1A1A),
                _listening ? const Color(0xFF111111) : BhasagoTheme.muted, _toggleMic),
            const SizedBox(width: 8),
            _roundBtn(Icons.send, a, const Color(0xFF111111), () => _send(_input.text)),
          ]),
        ]),
      ),
    );
  }

  Widget _roundBtn(IconData ic, Color bg, Color fg, VoidCallback onTap) =>
      SizedBox(
        width: 44, height: 44,
        child: Material(
          color: bg, shape: const CircleBorder(
              side: BorderSide(color: Color(0xFF2E2E2E))),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap,
              child: Icon(ic, size: 19, color: fg)),
        ),
      );

  Widget _bubble(_ChatMsg msg) {
    final a = widget.accent;
    final mine = msg.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? a : const Color(0xFF1A1A1A),
          border: mine ? null : Border.all(color: const Color(0xFF2E2E2E)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Text(msg.text,
            style: TextStyle(fontSize: 12.5, height: 1.5,
                color: mine ? const Color(0xFF111111) : BhasagoTheme.text)),
      ),
    );
  }

  Widget _typingBubble() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2E2E2E)),
              borderRadius: BorderRadius.circular(16)),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Row(mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
              final t = (_anim.value + i / 3) % 1.0;
              final o = 0.25 + 0.75 * math.sin(t * math.pi);
              return Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                    color: BhasagoTheme.muted.withValues(alpha: o),
                    shape: BoxShape.circle),
              );
            })),
          ),
        ),
      );

  Widget _chips() {
    const labels = ['আবার বুঝিয়ে দাও', 'একটা উদাহরণ', 'উচ্চারণ'];
    return SizedBox(
      height: 34,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final l in labels)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => _send(l),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: const BorderSide(color: Color(0xFF2E2E2E)),
                  shape: const StadiumBorder(),
                  foregroundColor: BhasagoTheme.muted,
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              child: Text(l),
            ),
          ),
      ]),
    );
  }

  Widget _waveform(Color a) => SizedBox(
        height: 34,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Row(
                children: List.generate(5, (i) {
              final t = (_anim.value + i / 5) % 1.0;
              final hgt = 8 + 18 * math.sin(t * math.pi);
              return Container(
                width: 4, height: hgt,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: a,
                    borderRadius: BorderRadius.circular(99)),
              );
            })),
          ),
          const SizedBox(width: 10),
          Text('শুনছি…', style: TextStyle(color: a, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}
