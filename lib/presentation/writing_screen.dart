// Kana writing practice: finger drawing + offline stroke-order animation.
// Stroke medians load from bundled assets/stroke/kana_strokes.json (no network).
// Autonomy: Skip is always visible; Quit = leave the tab (bottom nav). (01/09)

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

const _hira = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん';
const _kata = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});
  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = const {};
  bool _kata = false;
  int _idx = 0;
  bool _guide = true;
  final List<List<Offset>> _ink = [];
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _animating = false;

  String get _script => _kata ? _kata_ : 'hiragana';
  final String _kata_ = 'katakana';
  String get _chars => _kata ? _kata : _hira;
  String get _cur => _chars[_idx];

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/stroke/kana_strokes.json').then((s) {
      setState(() => _data = json.decode(s) as Map<String, dynamic>);
    });
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
    setState(() {
      _ink.clear();
      _animating = true;
    });
    _anim.forward(from: 0).whenComplete(() => setState(() => _animating = false));
  }

  void _select(int i) => setState(() {
        _idx = i;
        _ink.clear();
        _animating = false;
        _anim.reset();
      });

  @override
  Widget build(BuildContext context) {
    final strokes = _strokes();
    return Column(children: [
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
      // paper
      Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                  painter: _WritingPainter(
                    ink: _ink,
                    guideChar: _guide && !_animating ? _cur : null,
                    animStrokes: _animating ? strokes : null,
                    animT: _anim.value,
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
      const Spacer(),
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
      for (var i = 1; i < st.length; i++) p.lineTo(st[i].dx, st[i].dy);
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
    for (var i = 1; i < p.length; i++) s += (p[i] - p[i - 1]).distance;
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
