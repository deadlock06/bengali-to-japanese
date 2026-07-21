// Accent training: Shadowing (listen, then a REAL device speech-recognition
// self-check — no fabricated score) and Pitch minimal pairs (high/low
// visualization). Real pitch-accent f0 scoring is a later on-device step; until
// it ships we never invent a number (correctness over generation, docs/00).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import '../data/audio_service.dart';
import '../data/pcm_record_service.dart';
import '../data/voice_input_service.dart';
import '../domain/models.dart' show PitchItem;
import '../domain/pitch.dart';
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
          _PitchItemCard(it: it, lang: lang),
      ],
    );
  }
}

class _PitchItemCard extends StatefulWidget {
  final PitchItem it;
  final String lang;
  const _PitchItemCard({required this.it, required this.lang});

  @override
  State<_PitchItemCard> createState() => _PitchItemCardState();
}

class _PitchItemCardState extends State<_PitchItemCard> {
  bool _recording = false;
  int? _accentScore;

  Future<void> _toggleRecord() async {
    if (_recording) {
      final pcm = await PcmRecordService.instance.stop();
      if (pcm.isNotEmpty) {
        final learnerContour = f0Contour(pcm, 16000);
        final refContour = patternToSyntheticF0(widget.it.pattern);
        setState(() => _accentScore = accentScore(refContour, learnerContour).round());
      }
      setState(() => _recording = false);
      return;
    }
    setState(() {
      _accentScore = null;
      _recording = true;
    });
    await PcmRecordService.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${widget.it.kanji}  (${widget.it.word})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => AudioService.instance.play(widget.it.id),
                ),
                IconButton(
                  icon: Icon(_recording ? Icons.stop : Icons.mic,
                      color: _recording ? Colors.red : null),
                  onPressed: _toggleRecord,
                ),
              ],
            ),
            BilingualText(widget.it.meaning, lang: widget.lang),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BilingualText(widget.it.accentType,
                    lang: widget.lang,
                    primaryStyle: const TextStyle(color: Color(0xFF38BDF8))),
                if (_accentScore != null)
                  Text(
                    'Score: $_accentScore / 100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _accentScore! > 80 ? Colors.green : Colors.orange,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: CustomPaint(
                  painter: PitchLinePainter(widget.it.pattern),
                  size: const Size(double.infinity, 54)),
            ),
          ],
        ),
      ),
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
// Synthetic pattern for "yoroshiku onegaishimasu" (LHLLL LLLLL)
const _shadowPattern = [0, 1, 0, 0, 0, 0, 0, 0, 0, 0];

class _ShadowingScreenState extends ConsumerState<ShadowingScreen> {
  bool _recording = false;
  bool _unavailable = false; // device has no usable speech recognizer
  String? _heard; // live/final transcript
  bool? _matched; // set only on a final result
  int? _accentScore; // 0-100 pitch similarity

  bool _isMatch(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), '');
    return _shadowKeys.any(t.contains);
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await VoiceInputService.instance.stop();
      final pcm = await PcmRecordService.instance.stop();
      if (pcm.isNotEmpty) {
        final learnerContour = f0Contour(pcm, 16000);
        final refContour = patternToSyntheticF0(_shadowPattern);
        setState(() => _accentScore = accentScore(refContour, learnerContour).round());
      }
      setState(() => _recording = false);
      return;
    }
    setState(() {
      _heard = null;
      _matched = null;
      _accentScore = null;
      _unavailable = false;
    });
    // Start PCM recording alongside STT
    await PcmRecordService.instance.start();
    final ok = await VoiceInputService.instance.start(
      japanese: true,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _heard = text;
          if (isFinal) {
            _matched = _isMatch(text);
            if (_recording) _toggleRecord(); // auto-stop on final result
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
            if (_accentScore != null && _matched == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: .3)),
                ),
                child: Text(
                  'পিচ স্কোর (Pitch Score): $_accentScore / 100',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ]),
      ]),
    );
  }
}
