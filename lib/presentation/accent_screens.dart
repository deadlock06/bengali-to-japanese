// Accent training: Shadowing (listen, then a REAL device speech-recognition
// self-check — no fabricated score) and Pitch minimal pairs (high/low
// visualization). Real pitch-accent f0 scoring is a later on-device step; until
// it ships we never invent a number (correctness over generation, docs/00).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../data/audio_service.dart';
import '../data/voice_input_service.dart';
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

/// Shadowing screen — listen to the target phrase, then a REAL self-check:
/// the device speech recognizer transcribes what you said and we show whether
/// it heard the target phrase. No fabricated pitch score is ever shown; when
/// the device has no recognizer we say so honestly and keep Listen working.
class ShadowingScreen extends ConsumerStatefulWidget {
  const ShadowingScreen({super.key});
  @override
  ConsumerState<ShadowingScreen> createState() => _ShadowingScreenState();
}

// The shadowing target (lesson item wi_04). Matching is lenient: the recognizer
// may drop the trailing ます or mis-segment, so hearing either key chunk counts.
const _shadowTarget = 'よろしくおねがいします';
const _shadowKeys = ['よろしく', 'おねがい'];

class _ShadowingScreenState extends ConsumerState<ShadowingScreen> {
  bool _recording = false;
  bool _unavailable = false; // device has no usable speech recognizer
  String? _heard; // live/final transcript
  bool? _matched; // set only on a final result

  bool _isMatch(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), '');
    return _shadowKeys.any(t.contains);
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await VoiceInputService.instance.stop();
      setState(() => _recording = false);
      return;
    }
    setState(() {
      _heard = null;
      _matched = null;
      _unavailable = false;
    });
    final ok = await VoiceInputService.instance.start(
      japanese: true,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _heard = text;
          if (isFinal) {
            _matched = _isMatch(text);
            _recording = false;
          }
        });
      },
    );
    if (!mounted) return;
    setState(() {
      if (ok) {
        _recording = true;
      } else {
        _unavailable = true; // keep Listen; never block (D-001)
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
              const Text(_shadowTarget,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('yoroshiku onegai shimasu',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              FilledButton.icon(
                // Reuse the bundled clip for wi_04 — fully offline.
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
          icon: Icon(_recording ? Icons.stop : Icons.mic),
          label: Text(_recording
              ? 'শুনছি… থামাও'
              : 'বলে দেখাও · Record'),
        ),
        const SizedBox(height: 20),
        if (_unavailable)
          Text(
            'এই ডিভাইসে ভয়েস রেকগনিশন নেই — উপরের Listen চেপে শুনে শুনে '
            'অনুশীলন করো।',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          )
        else if (_heard != null)
          Column(children: [
            Text('শোনা গেছে: ${_heard!.isEmpty ? '…' : _heard!}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (_matched != null)
              Text(
                _matched!
                    ? '✓ ঠিক আছে! আবার বলে আরও পরিষ্কার করো।'
                    : 'আবার চেষ্টা করো — Listen চেপে সুরটা মিলিয়ে নাও।',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _matched!
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFBBF24)),
              ),
          ]),
      ]),
    );
  }
}
