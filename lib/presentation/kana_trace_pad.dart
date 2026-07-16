// Compact kana tracing pad — Phase 3 (Production) of the 09 micro-loop,
// embeddable INSIDE the classroom so writing is a step of the lesson flow
// (not a separate tool). Offline: stroke medians from bundled
// assets/stroke/kana_strokes.json; ▶ plays the stroke-order animation;
// the learner traces with a finger over the faint guide. Deterministic
// self-compare — no AI grading of handwriting (D-001 / arch 02 Tier-0).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class KanaTracePad extends StatefulWidget {
  const KanaTracePad({super.key, required this.char, required this.katakana});
  final String char;
  final bool katakana;

  @override
  State<KanaTracePad> createState() => _KanaTracePadState();
}

class _KanaTracePadState extends State<KanaTracePad>
    with SingleTickerProviderStateMixin {
  // Stroke data is loaded once per app run and shared across pads.
  static Map<String, dynamic>? _cache;
  static Future<Map<String, dynamic>>? _loading;

  Map<String, dynamic> _data = const {};
  final List<List<Offset>> _ink = [];
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    if (_cache != null) {
      _data = _cache!;
    } else {
      _loading ??= rootBundle
          .loadString('assets/stroke/kana_strokes.json')
          .then((s) => _cache = json.decode(s) as Map<String, dynamic>);
      _loading!.then((d) {
        if (mounted) setState(() => _data = d);
      });
    }
  }

  @override
  void didUpdateWidget(KanaTracePad old) {
    super.didUpdateWidget(old);
    if (old.char != widget.char) {
      _ink.clear();
      _animating = false;
      _anim.reset();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<List<Offset>>? _strokes() {
    final m =
        (_data[widget.katakana ? 'katakana' : 'hiragana'] as Map?)?[widget.char];
    if (m == null) return null;
    return (m as List)
        .map<List<Offset>>((st) => (st as List)
            .map<Offset>((p) =>
                Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList())
        .toList();
  }

  void _play() {
    if (_strokes() == null || _animating) return;
    if (MediaQuery.of(context).disableAnimations) {
      // Reduced motion: no animation — the guide glyph already shows the form.
      setState(_ink.clear);
      return;
    }
    setState(() {
      _ink.clear();
      _animating = true;
    });
    _anim
        .forward(from: 0)
        .whenComplete(() => mounted ? setState(() => _animating = false) : null);
  }

  @override
  Widget build(BuildContext context) {
    final strokes = _strokes();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Height-capped so the non-scrolling classroom column never overflows
      // on short/landscape viewports; on phones the width constraint wins.
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 230),
        child: AspectRatio(
        aspectRatio: 1.35, // wide pad — fits the classroom card
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Listener(
            onPointerDown: (e) {
              if (_animating) return;
              setState(() => _ink.add([e.localPosition]));
            },
            onPointerMove: (e) {
              if (_animating || _ink.isEmpty) return;
              setState(() => _ink.last.add(e.localPosition));
            },
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: _TracePainter(
                  ink: _ink,
                  guideChar: _animating ? null : widget.char,
                  animStrokes: _animating ? strokes : null,
                  animT: _anim.value,
                ),
              ),
            ),
          ),
        ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: strokes == null ? null : _play,
            icon: const Icon(Icons.play_arrow, size: 17),
            label: const Text('স্ট্রোক দেখো'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _ink.isEmpty ? null : () => setState(_ink.clear),
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('আবার লিখি'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ]);
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter(
      {required this.ink, this.guideChar, this.animStrokes, this.animT = 0});
  final List<List<Offset>> ink;
  final String? guideChar;
  final List<List<Offset>>? animStrokes;
  final double animT;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFFBFBFD));
    // center cross guides
    final gl = Paint()
      ..color = const Color(0xFFE6E7EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
        Offset(size.width / 2, 8), Offset(size.width / 2, size.height - 8), gl);
    canvas.drawLine(
        Offset(8, size.height / 2), Offset(size.width - 8, size.height / 2), gl);

    if (guideChar != null) {
      final tp = TextPainter(
        text: TextSpan(
            text: guideChar,
            style: TextStyle(
                fontSize: size.height * 0.78, color: const Color(0xFFE3E4EC))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }

    final inkPaint = Paint()
      ..color = const Color(0xFF14141F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final st in ink) {
      if (st.length < 2) {
        if (st.length == 1) {
          canvas.drawCircle(st.first, inkPaint.strokeWidth / 2,
              Paint()..color = const Color(0xFF14141F));
        }
        continue;
      }
      final p = Path()..moveTo(st.first.dx, st.first.dy);
      for (var i = 1; i < st.length; i++) {
        p.lineTo(st[i].dx, st[i].dy);
      }
      canvas.drawPath(p, inkPaint);
    }

    // stroke-order animation (medians in a 1000-unit viewBox, centered)
    if (animStrokes != null) {
      final sc = size.height / 1000.0;
      final dx = (size.width - size.height) / 2; // center the square glyph box
      final ap = Paint()
        ..color = const Color(0xFF14141F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final scaled = animStrokes!
          .map((st) =>
              st.map((o) => Offset(o.dx * sc + dx, o.dy * sc)).toList())
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
  bool shouldRepaint(covariant _TracePainter old) =>
      old.ink != ink ||
      old.animT != animT ||
      old.guideChar != guideChar ||
      old.animStrokes != animStrokes;
}
