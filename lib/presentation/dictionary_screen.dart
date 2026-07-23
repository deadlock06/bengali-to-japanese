// AI Dictionary — paste or type any Japanese (or mixed) text and the sensei
// explains it in Smart Banglish: meaning, reading, breakdown, example, usage.
// Online enhancement (AiTutorService via the proxy); offline → gentle message.
// Explanatory only — no grading (D-001 / 00 §4).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/ai_tutor_service.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key, this.initialText = ''});

  /// Pre-fill (e.g. a word tapped elsewhere in the app).
  final String initialText;

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  late final TextEditingController _input =
      TextEditingController(text: widget.initialText);
  bool _loading = false;
  String? _result;
  bool _offline = false;

  static const _blue = Color(0xFF4D7DF7);

  @override
  void initState() {
    super.initState();
    if (widget.initialText.trim().isNotEmpty) _explain();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text?.trim();
    if (t != null && t.isNotEmpty) {
      setState(() => _input.text = t);
    }
  }

  Future<void> _explain() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _result = null;
      _offline = false;
    });
    final r = await AiTutorService.instance
        .explain(text, uiLang: ref.read(langProvider));
    if (!mounted) return;

    final offlineMatch = ref.read(contentProvider).valueOrNull?.explainOffline(text, lang: ref.read(langProvider));

    setState(() {
      _loading = false;
      _result = r ?? offlineMatch;
      _offline = r == null && offlineMatch == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      appBar: AppBar(
        title: const Text('AI অভিধান'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text('জাপানি → বাংলা',
                  style: TextStyle(fontSize: 11, color: BhasagoTheme.muted)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // input card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BhasagoTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BhasagoTheme.outline),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _input,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                    fontFamily: 'ZenKakuGothicNew', fontSize: 20, height: 1.4),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'জাপানি টেক্সট পেস্ট করো বা লেখো…\n(যেমন: おはようございます)',
                  hintStyle: TextStyle(color: BhasagoTheme.muted, fontSize: 14),
                ),
              ),
              const Divider(color: BhasagoTheme.outline, height: 16),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste, size: 17),
                  label: const Text('পেস্ট'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BhasagoTheme.text,
                    side: const BorderSide(color: BhasagoTheme.pillOutline),
                    shape: const StadiumBorder(),
                  ),
                ),
                if (_input.text.isNotEmpty)
                  IconButton(
                    onPressed: () => setState(_input.clear),
                    icon: const Icon(Icons.close, size: 18, color: BhasagoTheme.muted),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _loading ? null : _explain,
                  icon: _loading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF111111)))
                      : const Icon(Icons.auto_awesome, size: 17),
                  label: Text(_loading ? 'দেখছি…' : 'ব্যাখ্যা করো'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: const Color(0xFF111111),
                    shape: const StadiumBorder(),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          if (_result != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: BhasagoTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue, width: 1.3),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.school, size: 16, color: _blue),
                  SizedBox(width: 6),
                  Text('সেনসেই বলছে',
                      style: TextStyle(
                          color: _blue, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 8),
                SelectableText(_result!,
                    style: const TextStyle(fontSize: 13.5, height: 1.6)),
              ]),
            ),
          if (_offline)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BhasagoTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BhasagoTheme.outline),
              ),
              child: const Text(
                'AI অভিধান এখন উত্তর দিতে পারছে না — ইন্টারনেট বা AI key দরকার। '
                'অফলাইনে পাঠের শব্দগুলো ✍️ Kana ও পাঠেই শেখা যায়।',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: BhasagoTheme.muted),
              ),
            ),
        ],
      ),
    );
  }
}
