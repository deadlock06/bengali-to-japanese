// "Select text anywhere → sensei explains it" popup. Opened from the global
// selection toolbar (see selection_explain.dart). The same sensei who teaches
// in the AI Classroom explains the selected text (AI dictionary), and the
// learner can HEAR the Bengali explanation read aloud (on-device TTS).
// Explanatory only — no grading (D-001 / 00 §4).
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../app/theme.dart';
import '../data/ai_tutor_service.dart';

Future<void> showExplainSheet(BuildContext context, String text) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExplainSheet(text: text),
  );
}

class _ExplainSheet extends StatefulWidget {
  const _ExplainSheet({required this.text});
  final String text;
  @override
  State<_ExplainSheet> createState() => _ExplainSheetState();
}

class _ExplainSheetState extends State<_ExplainSheet> {
  static const _blue = Color(0xFF4D7DF7);
  final FlutterTts _tts = FlutterTts();
  bool _loading = true, _speaking = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _explain();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _explain() async {
    final r = await AiTutorService.instance.explain(widget.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = r;
    });
  }

  Future<void> _speak() async {
    final t = _result;
    if (t == null) return;
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      // Bengali voice; India/Bangladesh depending on what the device has.
      await _tts.setLanguage('bn-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(t);
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * .62;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: BhasagoTheme.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: BhasagoTheme.outline,
                borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 12),
        // header: sensei + the selected text
        Row(children: [
          Container(
            width: 38, height: 38, alignment: Alignment.center,
            decoration: BoxDecoration(
                color: BhasagoTheme.card, shape: BoxShape.circle,
                border: Border.all(color: _blue, width: 2)),
            child: const Text('先',
                style: TextStyle(fontFamily: 'ZenKakuGothicNew',
                    fontSize: 16, fontWeight: FontWeight.w900, color: _blue)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('সেনসেই — অভিধান',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('「${widget.text}」',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'ZenKakuGothicNew', fontSize: 12,
                      color: BhasagoTheme.muted)),
            ]),
          ),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20, color: BhasagoTheme.muted)),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: _blue)))
                : _result != null
                    ? SelectableText(_result!,
                        style: const TextStyle(fontSize: 13.5, height: 1.65))
                    : const Text(
                        'এখন ব্যাখ্যা দিতে পারছি না — ইন্টারনেট বা AI key দরকার। '
                        'অফলাইনে পাঠ ও Kana স্ক্রিনে শব্দগুলো শেখা যায়।',
                        style: TextStyle(
                            fontSize: 12.5, height: 1.5, color: BhasagoTheme.muted)),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _speak,
              icon: Icon(_speaking ? Icons.stop : Icons.volume_up, size: 18),
              label: Text(_speaking ? 'থামাও' : 'বাংলায় শুনি 🔊'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: _blue,
                foregroundColor: const Color(0xFF111111),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
