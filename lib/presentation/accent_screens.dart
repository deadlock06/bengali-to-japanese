// Accent training: Shadowing (record & score your pitch) and Pitch minimal
// pairs (high/low visualization). Uses domain/pitch.dart for scoring.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../domain/pitch.dart';
import '../data/audio_service.dart';
import 'state_pack.dart';
import 'widgets.dart';

/// Draws the high/low accent line over the word's morae.
class PitchLinePainter extends CustomPainter {
  final List<int> pattern; // 0 = low, 1 = high, per mora
  PitchLinePainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern.isEmpty) return;
    final line = Paint()
      ..color = const Color(0xFFFF5A3C)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final highDot = Paint()..color = const Color(0xFF38BDF8);
    final lowDot = Paint()..color = const Color(0xFF96A0AD);

    final n = pattern.length;
    final step = size.width / (n + 0.5);
    Offset? prev;
    for (var i = 0; i < n; i++) {
      final x = step * (i + 0.5);
      final y = pattern[i] == 1 ? size.height * 0.25 : size.height * 0.75;
      final p = Offset(x, y);
      if (prev != null) canvas.drawLine(prev, p, line);
      canvas.drawCircle(p, 6, pattern[i] == 1 ? highDot : lowDot);
      prev = p;
    }
  }

  @override
  bool shouldRepaint(covariant PitchLinePainter old) => old.pattern != pattern;
}

/// Pitch minimal-pairs screen.
class PitchScreen extends ConsumerWidget {
  const PitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final repo = ref.watch(contentProvider).valueOrNull;
    if (repo == null) return const StatePack.loading(bn: 'পিচ ডেটা লোড হচ্ছে…');
    final set = repo.pitchSets.first;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('${set.dialect} · ${set.items.length} pairs',
            style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        for (final it in set.items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${it.kanji}  (${it.word})',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        // Bundled offline clip per pitch item (pa_01…). edge-tts
                        // can't render minimal-pair pitch, but the learner hears
                        // the word — no longer a dead button.
                        onPressed: () => AudioService.instance.play(it.id),
                      ),
                    ],
                  ),
                  BilingualText(it.meaning, lang: lang),
                  BilingualText(it.accentType,
                      lang: lang,
                      primaryStyle: const TextStyle(color: Color(0xFF38BDF8))),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: CustomPaint(
                        painter: PitchLinePainter(it.pattern),
                        size: const Size(double.infinity, 54)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Shadowing screen — listen, record, and get a pitch-accent score.
class ShadowingScreen extends ConsumerStatefulWidget {
  const ShadowingScreen({super.key});
  @override
  ConsumerState<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends ConsumerState<ShadowingScreen> {
  bool recording = false;
  double? score;

  // In the full app: the native reference contour ships with the audio; the
  // learner contour comes from record -> pitch.f0Contour(). Here we show the
  // wiring with representative contours so the score path is exercised.
  final List<double> _referenceContour = const [180, 200, 235, 250, 250, 240];

  void _toggleRecord() {
    setState(() {
      if (recording) {
        recording = false;
        // TODO: stop `record`, decode PCM, learner = f0Contour(pcm, 16000).
        const learner = <double>[178, 205, 232, 248, 246, 238]; // demo capture
        score = accentScore(_referenceContour, learner);
      } else {
        recording = true;
        score = null;
        // TODO: start `record` at 16 kHz mono.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('よろしくおねがいします',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('yoroshiku onegai shimasu',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              FilledButton.icon(
                // The shadowing target is よろしくおねがいします — reuse its
                // bundled clip (lesson item wi_04). Fully offline.
                onPressed: () => AudioService.instance.play('wi_04'),
                icon: const Icon(Icons.volume_up),
                label: const Text('Listen'),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _toggleRecord,
          icon: Icon(recording ? Icons.stop : Icons.mic),
          label: Text(recording ? 'Stop & score' : 'Record'),
        ),
        const SizedBox(height: 20),
        if (score != null)
          Column(children: [
            Text('${score!.round()}/100',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: score! >= 70
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFBBF24))),
            Text(score! >= 70 ? 'Great pitch match!' : 'Follow the pitch line more closely',
                style: TextStyle(color: Colors.grey.shade400)),
          ]),
      ]),
    );
  }
}
