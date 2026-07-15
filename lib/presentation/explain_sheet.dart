// The sensei explains selected/copied text — the SAME sensei who teaches in the
// AI Classroom appears, presents the text, explains it (AI dictionary), and can
// read the Bengali explanation aloud. Explanatory only — no grading (D-001).
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../app/theme.dart';
import '../data/ai_tutor_service.dart';
import 'sensei_avatar.dart';

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
      await _tts.setLanguage('bn-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(t);
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * .7;
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
        const SizedBox(height: 6),
        // The sensei presents the selected text (classroom teaching style).
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SenseiAvatar(size: 52, accent: _blue),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: BhasagoTheme.card,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                border: Border.all(color: BhasagoTheme.outline),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('এটা কী? আমি বুঝিয়ে দিচ্ছি —',
                    style: TextStyle(fontSize: 11.5, color: _blue, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('「${widget.text}」',
                    style: const TextStyle(
                        fontFamily: 'ZenKakuGothicNew', fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20, color: BhasagoTheme.muted)),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 44),
                    child: Center(
                        child: Column(children: [
                      CircularProgressIndicator(color: _blue),
                      SizedBox(height: 12),
                      Text('সেনসেই ভাবছে…',
                          style: TextStyle(color: BhasagoTheme.muted, fontSize: 12)),
                    ])))
                : _result != null
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          color: BhasagoTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _blue, width: 1.2),
                        ),
                        child: SelectableText(_result!,
                            style: const TextStyle(fontSize: 13.5, height: 1.65)),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'এখন ব্যাখ্যা দিতে পারছি না — ইন্টারনেট বা AI key দরকার। '
                          'অফলাইনে পাঠ ও Kana স্ক্রিনে শব্দগুলো শেখা যায়।',
                          style: TextStyle(
                              fontSize: 12.5, height: 1.5, color: BhasagoTheme.muted)),
                      ),
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
