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
import 'package:just_audio/just_audio.dart' as ja;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/ai_tutor_service.dart';
import '../data/curriculum_service.dart';
import '../data/voice_input_service.dart';
import '../data/chat_history_store.dart';

/// "Talk with Sensei" (D-042): opens the ONE sensei chat box in free
/// conversation mode — a live, online-AI-led spoken-practice session that
/// guides the learner to build Japanese sentences from words they know,
/// sequenced by the teaching contract. Anyone can open it; no lesson required.
/// Offline it falls back to a gentle canned invite (never blocks, D-001).
Future<void> showTalkSheet(BuildContext context, {String curriculumHint = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SenseiChatSheet(
      accent: const Color(0xFF35E065),
      moodLabel: 'কথা বলি · Talk',
      curriculumHint: curriculumHint,
      openConversation: true,
      // Persist the free-talk thread so a conversation resumes where it left off.
      chatKey: 'talk:sensei',
    ),
  );
}

class SenseiChatSheet extends ConsumerStatefulWidget {
  const SenseiChatSheet({
    super.key,
    required this.accent,
    required this.moodLabel,
    this.contextJp = '',
    this.seedText = '',
    this.curriculumHint = '',
    this.chatKey,
    this.openConversation = false,
  });
  final Color accent;
  final String moodLabel;
  final String contextJp; // the classroom item under discussion (AI context)
  final String seedText; // copy-anywhere: text to explain on open
  final String curriculumHint; // "শিক্ষার্থী এখন <unit> শিখছে" — ties to lessons

  /// Free spoken-practice mode (D-042, "Talk with Sensei"): on first open (no
  /// saved history), the sensei kicks off a REAL online-AI turn that invites
  /// the learner to build a sentence from what they already know — not a
  /// canned line. Sequenced by the existing teaching contract (teach one →
  /// check understanding → connect to prior). Falls back to the offline
  /// canned invite if no AI proxy is reachable (never blocks, D-001).
  final bool openConversation;

  /// Stable per-surface key (e.g. 'lesson:<id>', 'kana:か', 'explain:<text>').
  /// When set, this surface's conversation is saved and restored — a chat done
  /// on a specific page stays on that page. null = ephemeral (no history).
  final String? chatKey;

  @override
  ConsumerState<SenseiChatSheet> createState() => _SenseiChatSheetState();
}

class _ChatMsg {
  const _ChatMsg(this.mine, this.text);
  final bool mine;
  final String text;
}

class _SenseiChatSheetState extends ConsumerState<SenseiChatSheet>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  // Neural sensei speech (D-033): plays /ai/tts (bn-BD-Nabanita) when the
  // proxy is reachable; device TTS remains the offline fallback.
  final ja.AudioPlayer _neural = ja.AudioPlayer();
  final List<_ChatMsg> _msgs = [];
  bool _typing = false, _listening = false;
  int _speakingIdx = -1;
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();

  // Context the AI reasons with: the seeded text (copy-anywhere) or the
  // classroom item.
  String get _ctx => widget.seedText.isNotEmpty ? widget.seedText : widget.contextJp;

  /// Curriculum level (L0/A1/A2/N4…N1) → the sensei's BN↔JP language balance
  /// (13_MASTER_VISION). Empty while the ladder is still loading.
  String get _level => ref.read(learnerLevelProvider).valueOrNull ?? '';

  /// The learner's chosen UI language ('bn'|'en'|'ja') — the teaching medium
  /// the sensei explains in (D-041).
  String get _uiLang => ref.read(langProvider);

  /// Taught-scope hint (docs/14 teaching philosophy, D-030): tells the tutor
  /// what the learner has ALREADY completed and what unit is current, so it
  /// never assumes untaught knowledge and can connect new material to old.
  /// Built here (not per-caller) so every chat entry point gets it for free.
  String get _hint {
    final lang = _uiLang;
    final parts = <String>[];
    final units = ref.read(curriculumProvider).valueOrNull;
    if (units != null) {
      final done = [
        for (final u in units)
          if (u.state == UnitProgress.done && u.title.of(lang).trim().isNotEmpty)
            u.title.of(lang).trim()
      ];
      CurriculumUnit? cur;
      for (final u in units) {
        if (u.state == UnitProgress.current) { cur = u; break; }
      }
      if (done.isNotEmpty) {
        parts.add(lang == 'en'
            ? 'Already learned: ${done.join(', ')}.'
            : lang == 'ja'
                ? '学習済み: ${done.join('、')}。'
                : 'শেখা শেষ: ${done.join(', ')}।');
      } else {
        parts.add(lang == 'en'
            ? 'The learner is brand new — has learned nothing yet.'
            : lang == 'ja'
                ? '学習者は初めて — まだ何も学んでいない。'
                : 'শিক্ষার্থী একদম নতুন — এখনো কিছু শেখেনি।');
      }
      final curTitle = cur?.title.of(lang).trim() ?? '';
      if (cur != null && curTitle.isNotEmpty) {
        parts.add(lang == 'en'
            ? 'Now studying: "$curTitle" (${cur.level}).'
            : lang == 'ja'
                ? '学習中: 「$curTitle」(${cur.level})。'
                : 'এখন শিখছে: "$curTitle" (${cur.level})।');
      }
      parts.add(lang == 'en'
          ? "Don't use grammar/words beyond this scope in questions/examples; "
              'if something new is needed, teach it first.'
          : lang == 'ja'
              ? 'この範囲外の文法・語を問題や例に使わない。新しいものが必要なら先に教える。'
              : 'এই স্কোপের বাইরের grammar/শব্দ দিয়ে প্রশ্ন-উদাহরণ দেবে না; '
                  'নতুন কিছু লাগলে আগে শিখিয়ে নেবে।');
    }
    if (widget.curriculumHint.isNotEmpty) parts.add(widget.curriculumHint);
    return parts.join(' ');
  }

  // Offline honesty (D-025 / correctness): when there's no cloud AI AND no
  // verified match, we do NOT fabricate an answer — a wrong reply is worse than
  // none. We say so and point to what DOES work offline (select any verified
  // word → real explanation).
  String get _offlineHonest => switch (_uiLang) {
        'en' =>
          "Offline right now — I won't make up an answer to this (that could be "
              'wrong). I\'ll explain in full once you\'re back online. For now: '
              'select any Japanese word or sentence in the app — I can give a '
              'verified explanation instantly.',
        'ja' =>
          'いまオフライン — 作り話はしたくないので、この質問には答えないでおくね。'
              'ネットがつながれば くわしく説明するよ。今できること: アプリの日本語を'
              '選んでみて — 確かな説明ならすぐ出せる。',
        _ =>
          'এখন অফলাইন — এই প্রশ্নের উত্তর বানিয়ে বললে ভুল হতে পারে, তাই বলছি না। '
              'নেট এলে বিস্তারিত বুঝিয়ে দেব। এখন যা পারি: অ্যাপের যেকোনো জাপানি শব্দ বা '
              'বাক্য select করো — verified ব্যাখ্যা সাথে সাথেই দিতে পারব।',
      };

  /// The "can't reach the AI now" line, in the learner's UI language.
  static String _offlineMsg(String lang) => switch (lang) {
        'en' =>
          "I can't fetch an online explanation right now — needs internet or an "
              'AI key. But ask away and I\'ll help as much as I can.',
        'ja' =>
          'いまオンライン説明が出せない — ネットか AI key が必要。でも聞いてくれ'
              'たら できるだけ手伝うよ。',
        _ =>
          'এখন অনলাইন ব্যাখ্যা দিতে পারছি না — ইন্টারনেট বা AI key দরকার। '
              'তবে জিজ্ঞেস করলে যতটা পারি সাহায্য করব।',
      };

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingIdx = -1);
    });
    if (widget.chatKey != null) {
      _restoreHistory(); // page-specific: reload this surface's conversation
    } else {
      _openingMessage();
    }
  }

  /// First-open content when there's no saved history.
  void _openingMessage() {
    if (widget.seedText.isNotEmpty) {
      _bootstrapExplain(); // open by explaining the selected text
    } else if (widget.openConversation) {
      _bootstrapConversation(); // live AI-led sentence-practice kickoff
    } else {
      setState(() => _msgs.add(_ChatMsg(false, _askMeAnything(_uiLang))));
    }
  }

  static String _askMeAnything(String lang) => switch (lang) {
        'en' => "Want to ask something? I'm here — ask about any word or sentence.",
        'ja' => '何か聞きたい？ここにいるよ — どんな単語や文でも聞いて。',
        _ => 'কিছু জিজ্ঞেস করতে চাও? আমি আছি — যেকোনো শব্দ বা বাক্য নিয়ে প্রশ্ন করো।',
      };

  /// "Talk with Sensei" kickoff (D-042): a REAL online-AI turn (not canned)
  /// that opens guided, level-aware sentence-building practice. The hidden
  /// instruction never appears as a user bubble — mirrors _bootstrapExplain.
  Future<void> _bootstrapConversation() async {
    setState(() => _typing = true);
    final kickoff = switch (_uiLang) {
      'en' =>
        'Start a short spoken-practice turn: greet me warmly and invite me to '
            'build ONE simple Japanese sentence using words I already know at my '
            'level. Give me a tiny example to riff on, then wait for my try.',
      'ja' =>
        '短い会話練習を始めて: あたたかく挨拶して、私が知っている単語で簡単な文を'
            '1つ作るよう誘って。小さな例を1つ見せて、それから私の答えを待って。',
      _ =>
        'একটা ছোট্ট কথা-বলার অনুশীলন শুরু করো: উষ্ণভাবে সালাম দাও, আর আমাকে '
            'বলো আমি যা যা শিখেছি সেই শব্দ দিয়ে একটা সহজ জাপানি বাক্য বানাতে। '
            'ছোট্ট একটা উদাহরণ দাও, তারপর আমার চেষ্টার অপেক্ষা করো।',
    };
    final ai = await AiTutorService.instance.reply(kickoff,
        curriculumHint: _hint, level: _level, uiLang: _uiLang);
    if (!mounted) return;
    setState(() {
      _msgs.insert(0, _ChatMsg(false, ai ?? _talkOfflineFallback(_uiLang)));
      _typing = false;
    });
    _persist();
  }

  static String _talkOfflineFallback(String lang) => switch (lang) {
        'en' =>
          "I'm offline right now, so I can't lead live practice — but type any "
              'Japanese word or sentence and I\'ll explain what I can from '
              'verified content.',
        'ja' =>
          'いまオフラインだから、生の会話練習はできない — でも日本語の単語や文を'
              '入力してくれれば、確かな内容でできるだけ説明するよ。',
        _ =>
          'এখন অফলাইন, তাই লাইভ practice করাতে পারছি না — তবে যেকোনো জাপানি শব্দ '
              'বা বাক্য লিখলে verified কনটেন্ট থেকে যতটা পারি বুঝিয়ে দেব।',
      };

  Future<void> _restoreHistory() async {
    final hist = await ChatHistoryStore.instance.load(widget.chatKey!);
    if (!mounted) return;
    if (hist.isNotEmpty) {
      setState(() {
        _msgs
          ..clear()
          ..addAll(hist.reversed.map((t) => _ChatMsg(t.mine, t.text)));
      });
    } else {
      _openingMessage();
    }
  }

  /// Save the conversation for this surface (chronological order).
  void _persist() {
    final key = widget.chatKey;
    if (key == null) return;
    ChatHistoryStore.instance.save(
        key, _msgs.reversed.map((m) => ChatTurn(m.mine, m.text)).toList());
  }

  Future<void> _clearHistory() async {
    final key = widget.chatKey;
    setState(() {
      _msgs.clear();
      _speakingIdx = -1;
    });
    if (key != null) await ChatHistoryStore.instance.clear(key);
    if (!mounted) return;
    _openingMessage();
  }

  // Copy-anywhere open: the sensei presents & explains the selected text first.
  Future<void> _bootstrapExplain() async {
    setState(() => _typing = true);
    final ai = await AiTutorService.instance.explain(widget.seedText,
        curriculumHint: _hint, level: _level, uiLang: _uiLang);
    if (!mounted) return;
    
    final offlineMatch = ref.read(contentProvider).valueOrNull?.explainOffline(widget.seedText, lang: _uiLang);

    setState(() {
      _msgs.insert(
          0,
          _ChatMsg(
              false,
              ai ?? offlineMatch ?? _offlineMsg(_uiLang)));
      _typing = false;
    });
    _persist();
  }

  @override
  void dispose() {
    _neural.dispose();
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
    final ai = await AiTutorService.instance.reply(t,
        contextJp: _ctx, curriculumHint: _hint, level: _level, uiLang: _uiLang);
    if (!mounted) return;
    if (ai != null) {
      setState(() {
        _msgs.insert(0, _ChatMsg(false, ai));
        _typing = false;
      });
      _persist();
      return;
    }

    // Offline: ONLY a verified-content answer (handleOfflineChat searches the
    // store), else the honest "can't fabricate" line — never invented grammar.
    final offlineResponse =
        ref.read(contentProvider).valueOrNull?.handleOfflineChat(t, _ctx);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _msgs.insert(0, _ChatMsg(false, offlineResponse ?? _offlineHonest));
        _typing = false;
      });
      _persist();
    });
  }

  /// The device's Bengali TTS voice tag (bn-IN / bn-BD / bn…), or null if the
  /// platform has no Bengali voice. Bengali script can only be read by a
  /// Bengali voice, so we can't fall back to another language.
  Future<String?> _bengaliVoice() async {
    try {
      final langs = await _tts.getLanguages;
      if (langs is! List || langs.isEmpty) return null;
      final tags = langs.map((e) => e.toString()).toList();
      for (final want in ['bn-IN', 'bn-BD', 'bn']) {
        for (final t in tags) {
          if (t.toLowerCase() == want.toLowerCase()) return t;
        }
      }
      for (final t in tags) {
        if (t.toLowerCase().startsWith('bn')) return t;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _speakNeural(int msgIdx, String text) async {
    try {
      await _neural
          .setUrl(AiTutorService.ttsUrl(text))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return true;
      setState(() => _speakingIdx = msgIdx);
      _neural.play();
      _neural.playerStateStream
          .firstWhere((st) => st.processingState == ja.ProcessingState.completed)
          .then((_) {
        if (mounted && _speakingIdx == msgIdx) {
          setState(() => _speakingIdx = -1);
        }
      });
      return true;
    } catch (_) {
      return false; // proxy unreachable → device-TTS fallback
    }
  }

  Future<void> _speak(int msgIdx, String text) async {
    if (_speakingIdx == msgIdx) {
      await _tts.stop();
      await _neural.stop();
      if (mounted) setState(() => _speakingIdx = -1);
      return;
    }
    await _tts.stop();
    await _neural.stop();
    // 1) Neural voice via the proxy (D-033) — same Nabanita/Nanami quality as
    // the bundled clips. Unreachable (offline/APK without proxy) → device TTS.
    if (await _speakNeural(msgIdx, text)) return;
    final voice = await _bengaliVoice();
    if (!mounted) return;
    if (voice == null) {
      // No Bengali voice on this device (common on desktop/headless browsers) —
      // tell the learner instead of failing silently.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'এই ডিভাইসে বাংলা voice নেই — মোবাইলে (Android/iOS) পড়ে শোনানো যাবে। '
            'জাপানি উচ্চারণ 🔊 বাটনে অফলাইনেই শোনা যায়।'),
        duration: Duration(seconds: 4),
      ));
      return;
    }
    setState(() => _speakingIdx = msgIdx);
    try {
      await _tts.setLanguage(voice);
      await _tts.setSpeechRate(0.45);
      final r = await _tts.speak(text);
      if (r == 0 && mounted) setState(() => _speakingIdx = -1);
    } catch (_) {
      if (mounted) setState(() => _speakingIdx = -1);
    }
  }

  // REAL voice input (talk to the sensei) — device/browser STT. Speaking
  // practice, so Japanese first (falls back to Bengali). Live transcript fills
  // the box; stopping sends it. No STT on this device → snackbar + text box
  // stays (never blocks, D-001).
  Future<void> _toggleMic() async {
    if (_listening) {
      await VoiceInputService.instance.stop();
      if (!mounted) return;
      final said = _input.text.trim();
      setState(() => _listening = false);
      if (said.isNotEmpty) _send(said);
      return;
    }
    final ok = await VoiceInputService.instance.start(
      japanese: true,
      onResult: (text, isFinal) {
        if (!mounted) return;
        _input.text = text; // live transcript into the input box
        if (isFinal) {
          setState(() => _listening = false);
          final said = text.trim();
          if (said.isNotEmpty) _send(said);
        }
      },
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _listening = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('এই ডিভাইসে ভয়েস চেনা নেই/অনুমতি নেই — লিখে জিজ্ঞেস করো। '
            '(মোবাইলে জাপানি/বাংলা ভয়েস থাকলে বলে কথা বলা যায়।)'),
        duration: Duration(seconds: 4),
      ));
    }
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
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('সেনসেই',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Row(children: [
                  Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: a, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(seeded ? 'ব্যাখ্যা' : widget.moodLabel,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: a, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                  if (widget.chatKey != null)
                    const Text('  ·  সংরক্ষিত',
                        maxLines: 1,
                        style: TextStyle(
                            color: BhasagoTheme.muted,
                            fontSize: 10.5, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            // Page-specific history: clear THIS surface's saved conversation.
            if (widget.chatKey != null)
              IconButton(
                tooltip: 'এই পেজের চ্যাট মুছুন',
                onPressed: _msgs.isEmpty
                    ? null
                    : () {
                        _clearHistory();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('এই পেজের চ্যাট মুছে ফেলা হলো।'),
                          duration: Duration(seconds: 2),
                        ));
                      },
                icon: const Icon(Icons.delete_outline, size: 19,
                    color: BhasagoTheme.muted),
              ),
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
