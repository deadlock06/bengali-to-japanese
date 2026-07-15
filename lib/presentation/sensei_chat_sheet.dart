// The ONE sensei chat box — used both inside the AI Classroom (tap the sensei)
// and from copy-anywhere "ব্যাখ্যা" (select text → same sensei explains, then
// you keep chatting). Explanatory only — grading stays answer-key (D-001/00§4).
//
// Seeded mode: pass `seedText` (the selected/copied text) → the sensei opens by
// explaining it, then the conversation continues normally with that text as
// context. `curriculumHint` lets him tie the answer to what you're learning.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../app/theme.dart';
import '../data/ai_tutor_service.dart';

class SenseiChatSheet extends StatefulWidget {
  const SenseiChatSheet({
    super.key,
    required this.accent,
    required this.moodLabel,
    this.contextJp = '',
    this.seedText = '',
    this.curriculumHint = '',
  });
  final Color accent;
  final String moodLabel;
  final String contextJp; // the classroom item under discussion (AI context)
  final String seedText; // copy-anywhere: text to explain on open
  final String curriculumHint; // "শিক্ষার্থী এখন <unit> শিখছে" — ties to lessons
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
  final FlutterTts _tts = FlutterTts();
  final List<_ChatMsg> _msgs = [];
  bool _typing = false, _listening = false;
  int _speakingIdx = -1;
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  int _cannedIdx = 0;

  // Context the AI reasons with: the seeded text (copy-anywhere) or the
  // classroom item.
  String get _ctx => widget.seedText.isNotEmpty ? widget.seedText : widget.contextJp;

  static const _canned = [
    '「水 · みず」মানে পানি। মনে রাখো: み(mi) দিয়ে শুরু — যেটা তুমি পান করো। উদাহরণ: 水をください — একটু পানি দিন।',
    'ভালো প্রশ্ন! উচ্চারণটা ভেঙে বলি: go-HAN — দ্বিতীয় অংশে একটু জোর। আস্তে আস্তে ৩ বার বলো।',
    'উদাহরণ বাক্য: お茶をのみます — আমি চা খাই। のみます মানে পান করা।',
  ];

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingIdx = -1);
    });
    if (widget.seedText.isNotEmpty) {
      _bootstrapExplain(); // open by explaining the selected text
    } else {
      _msgs.add(const _ChatMsg(false,
          'কিছু জিজ্ঞেস করতে চাও? আমি আছি — যেকোনো শব্দ বা বাক্য নিয়ে প্রশ্ন করো।'));
    }
  }

  // Copy-anywhere open: the sensei presents & explains the selected text first.
  Future<void> _bootstrapExplain() async {
    setState(() => _typing = true);
    final ai = await AiTutorService.instance
        .explain(widget.seedText, curriculumHint: widget.curriculumHint);
    if (!mounted) return;
    setState(() {
      _msgs.insert(
          0,
          _ChatMsg(
              false,
              ai ??
                  'এখন অনলাইন ব্যাখ্যা দিতে পারছি না — ইন্টারনেট বা AI key দরকার। '
                      'তবে জিজ্ঞেস করলে যতটা পারি সাহায্য করব।'));
      _typing = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _anim.dispose();
    _input.dispose();
    super.dispose();
  }

  void _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _typing) return;
    _input.clear();
    setState(() {
      _msgs.insert(0, _ChatMsg(true, t));
      _typing = true;
    });
    // Online AI (Smart Banglish) if a key is configured; else canned/offline.
    final ai = await AiTutorService.instance
        .reply(t, contextJp: _ctx, curriculumHint: widget.curriculumHint);
    if (!mounted) return;
    if (ai != null) {
      setState(() {
        _msgs.insert(0, _ChatMsg(false, ai));
        _typing = false;
      });
      return;
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _msgs.insert(0, _ChatMsg(false, _canned[_cannedIdx % _canned.length]));
        _cannedIdx++;
        _typing = false;
      });
    });
  }

  Future<void> _speak(int msgIdx, String text) async {
    if (_speakingIdx == msgIdx) {
      await _tts.stop();
      if (mounted) setState(() => _speakingIdx = -1);
      return;
    }
    await _tts.stop();
    setState(() => _speakingIdx = msgIdx);
    try {
      await _tts.setLanguage('bn-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _speakingIdx = -1);
    }
  }

  void _toggleMic() {
    if (_listening) {
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted || !_listening) return;
      setState(() => _listening = false);
      _send('「ご飯」মানে কী আবার বুঝিয়ে দাও');
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * .78;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final a = widget.accent;
    final seeded = widget.seedText.isNotEmpty;
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
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              width: 38, height: 38, alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A), shape: BoxShape.circle,
                  border: Border.all(color: a, width: 2)),
              child: Text('先',
                  style: TextStyle(
                      fontFamily: 'ZenKakuGothicNew',
                      fontSize: 16, fontWeight: FontWeight.w900, color: a)),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('সেনসেই',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Row(children: [
                Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: a, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(seeded ? 'ব্যাখ্যা' : widget.moodLabel,
                    style: TextStyle(
                        color: a, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ]),
            ]),
            const Spacer(),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20, color: BhasagoTheme.muted)),
          ]),
          // Copy-anywhere: show WHAT is being explained.
          if (seeded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: a.withValues(alpha: .5))),
              child: Text('「${widget.seedText}」',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'ZenKakuGothicNew',
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _msgs.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (_typing && i == 0) return _typingBubble();
                final mi = _typing ? i - 1 : i;
                return _bubble(_msgs[mi], mi);
              },
            ),
          ),
          if (_listening) _waveform(a) else _chips(seeded),
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
                      hintStyle:
                          TextStyle(color: BhasagoTheme.muted, fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _roundBtn(Icons.mic_none, _listening ? a : const Color(0xFF1A1A1A),
                _listening ? const Color(0xFF111111) : BhasagoTheme.muted,
                _toggleMic),
            const SizedBox(width: 8),
            _roundBtn(Icons.send, a, const Color(0xFF111111),
                () => _send(_input.text)),
          ]),
        ]),
      ),
    );
  }

  Widget _roundBtn(IconData ic, Color bg, Color fg, VoidCallback onTap) =>
      SizedBox(
        width: 44, height: 44,
        child: Material(
          color: bg,
          shape: const CircleBorder(side: BorderSide(color: Color(0xFF2E2E2E))),
          child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Icon(ic, size: 19, color: fg)),
        ),
      );

  Widget _bubble(_ChatMsg msg, int msgIdx) {
    final a = widget.accent;
    final mine = msg.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
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
            child: SelectableText(msg.text,
                style: TextStyle(
                    fontSize: 12.5, height: 1.5,
                    color: mine ? const Color(0xFF111111) : BhasagoTheme.text)),
          ),
          // Bengali read-aloud on the sensei's messages.
          if (!mine)
            TextButton.icon(
              onPressed: () => _speak(msgIdx, msg.text),
              icon: Icon(
                  _speakingIdx == msgIdx ? Icons.stop_circle : Icons.volume_up,
                  size: 15, color: a),
              label: Text(_speakingIdx == msgIdx ? 'থামাও' : 'শুনি',
                  style: TextStyle(
                      fontSize: 11, color: a, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
        ],
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
            builder: (context, child) => Row(
                mainAxisSize: MainAxisSize.min,
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

  Widget _chips(bool seeded) {
    final labels = seeded
        ? const ['আরেকটা উদাহরণ', 'উচ্চারণ ভেঙে দাও', 'কোথায় ব্যবহার হয়', 'সহজ করে বলো']
        : const ['আবার বুঝিয়ে দাও', 'একটা উদাহরণ', 'উচ্চারণ'];
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
                  textStyle:
                      const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
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
                    decoration: BoxDecoration(
                        color: a, borderRadius: BorderRadius.circular(99)),
                  );
                })),
          ),
          const SizedBox(width: 10),
          Text('শুনছি…',
              style:
                  TextStyle(color: a, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}
