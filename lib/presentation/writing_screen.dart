// Kana writing practice: finger drawing + offline stroke-order animation.
// Stroke medians load from bundled assets/stroke/kana_strokes.json (no network).
// Autonomy: Skip is always visible; Quit = leave the tab (bottom nav). (01/09)

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';
import '../data/audio_service.dart';
import 'sensei_chat_sheet.dart';

const _hiraChars = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん';
const _kataChars = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';

// Same gojūon order as the char strings above — so the learner always sees
// WHAT sound they are tracing (romaji + Bengali equivalent), never a bare
// glyph. Bengali mapping follows classroom/BOOK.md Ch.1 (আ ই উ এ ও …).
const _romaji = [
  'a','i','u','e','o','ka','ki','ku','ke','ko','sa','shi','su','se','so',
  'ta','chi','tsu','te','to','na','ni','nu','ne','no','ha','hi','fu','he','ho',
  'ma','mi','mu','me','mo','ya','yu','yo','ra','ri','ru','re','ro','wa','wo','n',
];
const _bnSound = [
  'আ','ই','উ','এ','ও','কা','কি','কু','কে','কো','সা','শি','সু','সে','সো',
  'তা','চি','ৎসু','তে','তো','না','নি','নু','নে','নো','হা','হি','ফু','হে','হো',
  'মা','মি','মু','মে','মো','ইয়া','ইউ','ইয়ো','রা','রি','রু','রে','রো','ওয়া','ও','ন',
];

// First-open explainer — condensed from classroom/BOOK.md PART 0 (verified
// content, not generated). Interim UI until the "blackboard scene" design.
const _kanaIntroBn =
    'হিরাগানা আর কাতাকানা হলো জাপানি "বর্ণমালা" — বাংলার মতোই sound-based, '
    'যুক্তবর্ণের জঙ্গল নেই।\n\n'
    '• হিরাগানা (৪৬টা): জাপানি শব্দ ও grammar লেখা হয় — আগে এটা শেখো।\n'
    '• কাতাকানা: same ৪৬টা sound, আলাদা চেহারা — বিদেশি শব্দ আর তোমার '
    'নিজের নাম লিখতে লাগে।\n\n'
    'পুরো system ৫টা vowel এর উপর দাঁড়িয়ে: あ(আ) い(ই) う(উ) え(এ) お(ও) — '
    'বাকি সব consonant + এই ৫ vowel। সঠিক stroke order এ লেখো — জাপানিরা '
    'এক নজরেই চেনে (ফর্ম, নাম-ট্যাগ, daily report এ কাজে লাগবে)।';

class WritingScreen extends StatefulWidget {
  const WritingScreen(
      {super.key, this.startKatakana = false, this.startChar = '', this.onComplete});

  /// Open directly on katakana (for the L0.2 curriculum unit).
  final bool startKatakana;

  /// Open focused on a specific kana (e.g. 'き' from the classroom "লিখে দেখাও"
  /// button). Auto-detects script; falls back to the start if not writable.
  final String startChar;

  /// When set, this screen IS a curriculum unit (L0.1/L0.2): a "কানা শেষ ✓"
  /// action appears that records the unit complete and pops. D-001: it's an
  /// offer — Skip/Quit still work, nothing is forced.
  final VoidCallback? onComplete;

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = const {};
  late bool _kata = widget.startKatakana;
  int _idx = 0;
  bool _guide = true;
  final List<List<Offset>> _ink = [];
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _animating = false;
  bool _staticStrokes = false; // reduced-motion: full character, no animation
  bool _showIntro = false; // "what is kana?" — first open only

  String get _script => _kata ? 'katakana' : 'hiragana';
  String get _chars => _kata ? _kataChars : _hiraChars;
  String get _cur => _chars[_idx];

  /// Bundled-audio key for the current kana (Tier-0 offline pronunciation).
  String get _audioKey => 'kana_${_kata ? "kata" : "hira"}_${_romaji[_idx]}';

  @override
  void initState() {
    super.initState();
    // Open focused on a requested character (from the classroom). Detect script
    // from which set contains it; ignore if it isn't a writable base kana.
    final want = widget.startChar;
    if (want.isNotEmpty) {
      if (_hiraChars.contains(want)) {
        _kata = false;
        _idx = _hiraChars.indexOf(want);
      } else if (_kataChars.contains(want)) {
        _kata = true;
        _idx = _kataChars.indexOf(want);
      }
    }
    rootBundle.loadString('assets/stroke/kana_strokes.json').then((s) {
      setState(() => _data = json.decode(s) as Map<String, dynamic>);
    });
    SharedPreferences.getInstance().then((p) {
      if (mounted && p.getBool('kana_intro_seen') != true) {
        setState(() => _showIntro = true);
      }
    });
  }

  /// Offline: play the pre-bundled native pronunciation (Tier 0, no network).
  void _listen() => AudioService.instance.play(_audioKey);

  /// Optional online-AI help (~20% edge cases, D-013): the SAME sensei explains
  /// this character — mnemonic, stroke tip, how to say it — with an offline
  /// canned fallback. Explanatory only; it never grades your handwriting.
  void _askSensei() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SenseiChatSheet(
          accent: const Color(0xFFF06EB7),
          moodLabel: 'লেখা',
          seedText: '「$_cur」 (${_romaji[_idx]}) — এই ${_kata ? "কাতাকানা" : "হিরাগানা"} '
              'অক্ষরটা কীভাবে সহজে মনে রাখব, লিখব আর উচ্চারণ করব?',
        ),
      );

  void _dismissIntro() {
    setState(() => _showIntro = false);
    SharedPreferences.getInstance()
        .then((p) => p.setBool('kana_intro_seen', true));
  }

  /// The sensei's teaching line for the current character — introduces the
  /// sound BEFORE the learner traces (teach → show → practice). The first 5
  /// are the vowels everything else is built from.
  String _senseiLine() {
    final r = _romaji[_idx], bn = _bnSound[_idx];
    final head = 'এই যে — 「$_cur」। উচ্চারণ "$bn" (romaji: $r)। ';
    if (_idx < 5) {
      return '$head এটি জাপানির ৫টি মূল স্বরের একটি — সব অক্ষর এই স্বরগুলোর উপরে দাঁড়ানো। ভালো করে চিনে নাও।';
    }
    return '$head ▶ চেপে স্ট্রোক-অর্ডার দেখো, তারপর আঙুল দিয়ে নিজে লিখে ফেলো।';
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<List<Offset>>? _strokes() {
    final m = (_data[_script] as Map?)?[_cur];
    if (m == null) return null;
    return (m as List)
        .map<List<Offset>>((st) => (st as List)
            .map<Offset>((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList())
        .toList();
  }

  void _play() {
    if (_strokes() == null || _animating) return;
    // Accessibility gate (DESIGN_BRIEF §2): reduced-motion kills ALL
    // animation — show the finished character statically instead.
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _ink.clear();
        _staticStrokes = true;
      });
      return;
    }
    setState(() {
      _ink.clear();
      _staticStrokes = false;
      _animating = true;
    });
    _anim.forward(from: 0).whenComplete(() => setState(() => _animating = false));
  }

  void _select(int i) => setState(() {
        _idx = i;
        _ink.clear();
        _animating = false;
        _staticStrokes = false;
        _anim.reset();
      });

  @override
  Widget build(BuildContext context) {
    final strokes = _strokes();
    return Column(children: [
      // First open: what kana IS and why it's learned first (BOOK.md PART 0) —
      // the learner should never trace glyphs without knowing what they are.
      if (_showIntro)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('এটা কী শিখছ?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              const SizedBox(height: 6),
              const Text(_kanaIntroBn, style: TextStyle(fontSize: 12, height: 1.5)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _dismissIntro, child: const Text('বুঝেছি')),
              ),
            ]),
          ),
        ),
      // script toggle
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('ひらがな')),
            ButtonSegment(value: true, label: Text('カタカナ')),
          ],
          selected: {_kata},
          onSelectionChanged: (s) => setState(() {
            _kata = s.first;
            _idx = 0;
            _ink.clear();
            _anim.reset();
          }),
        ),
      ),
      // character strip
      SizedBox(
        height: 54,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _chars.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _select(i),
            child: Container(
              width: 46,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: i == _idx ? const Color(0xFFFF2D78) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(_chars[i], style: const TextStyle(fontSize: 22))),
            ),
          ),
        ),
      ),
      // Sensei teaches THIS character — avatar + speech bubble (classroom feel,
      // not a bare tool). The line introduces the sound before you practice.
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF06EB7), width: 2),
            ),
            child: const Text('先',
                style: TextStyle(fontFamily: 'ZenKakuGothicNew', fontSize: 15,
                    fontWeight: FontWeight.w900, color: Color(0xFFF06EB7))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                border: Border.all(color: const Color(0xFF2E2E2E)),
              ),
              child: Text(_senseiLine(), style: const TextStyle(fontSize: 12, height: 1.5)),
            ),
          ),
        ]),
      ),
      // Sensei's two helpers: OFFLINE pronunciation (pre-bundled audio, Tier 0)
      // and OPTIONAL online-AI explanation (unified chat, offline fallback).
      // Neither touches handwriting grading — that stays the deterministic
      // stroke model (D-001 / arch 02 Tier 0).
      Padding(
        padding: const EdgeInsets.fromLTRB(58, 8, 16, 0),
        child: Row(children: [
          OutlinedButton.icon(
            onPressed: _listen,
            icon: const Icon(Icons.volume_up, size: 16),
            label: const Text('উচ্চারণ'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              foregroundColor: BhasagoTheme.text,
              side: const BorderSide(color: Color(0xFFF06EB7), width: 1.3),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _askSensei,
            icon: const Icon(Icons.chat_bubble_outline, size: 15),
            label: const Text('সেনসেইকে জিজ্ঞেস'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              foregroundColor: BhasagoTheme.muted,
              side: const BorderSide(color: Color(0xFF2E2E2E), width: 1.3),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
      // paper — takes the leftover height, square sized by the shorter axis,
      // so short/landscape viewports (split-screen, test surface) never overflow
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Listener(
                  onPointerDown: (e) {
                    if (_animating) return;
                    setState(() {
                      _staticStrokes = false; // start drawing over the model
                      _ink.add([e.localPosition]);
                    });
                  },
                  onPointerMove: (e) {
                    if (_animating || _ink.isEmpty) return;
                    setState(() => _ink.last.add(e.localPosition));
                  },
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => CustomPaint(
                      size: Size.infinite,
                      painter: _WritingPainter(
                        ink: _ink,
                        guideChar: _guide && !_animating && !_staticStrokes ? _cur : null,
                        animStrokes: _animating || _staticStrokes ? strokes : null,
                        animT: _animating ? _anim.value : 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // tools
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _tool(Icons.play_arrow, 'watch', strokes != null ? _play : null, primary: true),
          _tool(_guide ? Icons.visibility : Icons.visibility_off, 'guide',
              () => setState(() => _guide = !_guide)),
          _tool(Icons.undo, 'undo',
              _ink.isEmpty ? null : () => setState(() => _ink.removeLast())),
          _tool(Icons.delete_outline, 'clear',
              _ink.isEmpty ? null : () => setState(_ink.clear)),
        ]),
      ),
      // autonomy row: Skip always available
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _select((_idx - 1 + _chars.length) % _chars.length),
              child: const Text('‹'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => _select((_idx + 1) % _chars.length),
              child: const Text('Skip / পরের ›'),
            ),
          ),
        ]),
      ),
      // Curriculum-unit completion (L0.1/L0.2): learner marks the set learned,
      // which advances the ladder to the next unit (numbers). D-001: an offer.
      if (widget.onComplete != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: widget.onComplete,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF35E065),
              foregroundColor: const Color(0xFF111111),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(_kata ? 'কাতাকানা শেষ ✓' : 'হিরাগানা শেষ ✓'),
          ),
        ),
    ]);
  }

  Widget _tool(IconData ic, String label, VoidCallback? onTap, {bool primary = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 52,
          child: primary
              ? FilledButton(onPressed: onTap, child: Icon(ic))
              : OutlinedButton(onPressed: onTap, child: Icon(ic)),
        ),
      ),
    );
  }
}

class _WritingPainter extends CustomPainter {
  final List<List<Offset>> ink;
  final String? guideChar;
  final List<List<Offset>>? animStrokes;
  final double animT;
  _WritingPainter({required this.ink, this.guideChar, this.animStrokes, this.animT = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFBFBFD));
    // grid
    final pad = w * 0.06;
    final gl = Paint()
      ..color = const Color(0xFFE6E7EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(Rect.fromLTRB(pad, pad, w - pad, size.height - pad), gl);
    canvas.drawLine(Offset(w / 2, pad), Offset(w / 2, size.height - pad), gl);
    canvas.drawLine(Offset(pad, size.height / 2), Offset(w - pad, size.height / 2), gl);

    // faint guide glyph
    if (guideChar != null) {
      final tp = TextPainter(
        text: TextSpan(
            text: guideChar,
            style: TextStyle(fontSize: size.height * 0.7, color: const Color(0xFFE3E4EC))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, (size.height - tp.height) / 2));
    }

    // user ink
    final inkPaint = Paint()
      ..color = const Color(0xFF14141F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final st in ink) {
      if (st.length < 2) {
        if (st.length == 1) {
          canvas.drawCircle(st.first, inkPaint.strokeWidth / 2, Paint()..color = const Color(0xFF14141F));
        }
        continue;
      }
      final p = Path()..moveTo(st.first.dx, st.first.dy);
      for (var i = 1; i < st.length; i++) {
        p.lineTo(st[i].dx, st[i].dy);
      }
      canvas.drawPath(p, inkPaint);
    }

    // stroke-order animation (scaled from viewBox 1000)
    if (animStrokes != null) {
      final sc = w / 1000.0;
      final ap = Paint()
        ..color = const Color(0xFF14141F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final scaled = animStrokes!
          .map((st) => st.map((o) => Offset(o.dx * sc, o.dy * sc)).toList())
          .toList();
      final lens = scaled.map(_len).toList();
      final total = lens.fold<double>(0, (a, b) => a + b);
      var target = animT * total, consumed = 0.0;
      for (var i = 0; i < scaled.length; i++) {
        if (consumed >= target) break;
        _drawUpTo(canvas, scaled[i], ap, math.min(lens[i], target - consumed));
        consumed += lens[i];
      }
    }
  }

  double _len(List<Offset> p) {
    var s = 0.0;
    for (var i = 1; i < p.length; i++) {
      s += (p[i] - p[i - 1]).distance;
    }
    return s;
  }

  void _drawUpTo(Canvas c, List<Offset> pts, Paint paint, double maxLen) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    var acc = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final seg = (pts[i] - pts[i - 1]).distance;
      if (acc + seg <= maxLen) {
        path.lineTo(pts[i].dx, pts[i].dy);
        acc += seg;
      } else {
        final f = seg <= 0 ? 0.0 : (maxLen - acc) / seg;
        final q = Offset.lerp(pts[i - 1], pts[i], f)!;
        path.lineTo(q.dx, q.dy);
        break;
      }
    }
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WritingPainter old) =>
      old.ink != ink || old.animT != animT || old.guideChar != guideChar || old.animStrokes != animStrokes;
}
