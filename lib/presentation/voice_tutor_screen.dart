// VoiceTutorScreen — real-time AI voice conversation ("Gemini Live" mode).
//
// Loop:  idle → listening (STT) → processing (AI) → speaking (TTS) → listening…
//
// The learner speaks in Bengali or Japanese; the Sensei replies aloud using
// either the neural voice (/ai/tts proxy) or device Bengali TTS as fallback.
// Everything degrades gracefully — no mic or no internet never blocks (D-001).
//
// Access points:
//   1. Classroom toolbar → 🎙️ button (contextJp = current lesson item)
//   2. Home screen "সেনসেইয়ের সাথে কথা বলো" card (contextJp = '')

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../app/providers.dart';
import '../app/theme.dart';
import '../data/ai_tutor_service.dart';
import '../data/curriculum_service.dart';
import '../data/voice_input_service.dart';

// ── State machine ────────────────────────────────────────────────────────────

enum _VoiceState {
  idle,       // first open / between turns — tap to start
  listening,  // mic is recording / STT is live
  processing, // waiting for AI reply
  speaking,   // TTS is playing the AI reply
}

// ── Screen entry point ───────────────────────────────────────────────────────

class VoiceTutorScreen extends ConsumerStatefulWidget {
  /// The Japanese lesson item currently in the classroom (or '' for free chat).
  /// The AI uses this as context for its answers.
  final String contextJp;

  /// Classroom mood accent color — carried over so the screen feels connected.
  final Color accent;

  const VoiceTutorScreen({
    super.key,
    this.contextJp = '',
    this.accent = const Color(0xFFEFE94B),
  });

  @override
  ConsumerState<VoiceTutorScreen> createState() => _VoiceTutorScreenState();
}

// ── Message model ────────────────────────────────────────────────────────────

class _Msg {
  final bool mine;
  final String text;
  const _Msg(this.mine, this.text);
}

// ── Main state ───────────────────────────────────────────────────────────────

class _VoiceTutorScreenState extends ConsumerState<VoiceTutorScreen>
    with TickerProviderStateMixin {
  _VoiceState _vstate = _VoiceState.idle;
  final List<_Msg> _msgs = [];

  // Audio: neural TTS (proxy) → device TTS fallback
  final ja.AudioPlayer _neural = ja.AudioPlayer();
  final FlutterTts _deviceTts = FlutterTts();
  bool _micUnavailable = false;

  // Animations
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  late final AnimationController _dotCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  String get _level => ref.read(learnerLevelProvider).valueOrNull ?? '';
  String get _uiLang => ref.read(langProvider);
  String get _hint {
    final parts = <String>[];
    final units = ref.read(curriculumProvider).valueOrNull;
    if (units != null) {
      CurriculumUnit? cur;
      for (final u in units) {
        if (u.state == UnitProgress.current) { cur = u; break; }
      }
      final title = cur?.title.of(_uiLang).trim() ?? '';
      if (cur != null && title.isNotEmpty) {
        parts.add(_t(
          'শিক্ষার্থী এখন "$title" (${cur.level}) শিখছে।',
          'The learner is currently studying "$title" (${cur.level}).',
          '学習者は今「$title」(${cur.level}) を学んでいます。',
        ));
      }
    }
    return parts.join(' ');
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _deviceTts.setCompletionHandler(_onTtsDone);
    // Warm greeting on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _dotCtrl.dispose();
    _neural.dispose();
    _deviceTts.stop();
    VoiceInputService.instance.stop();
    super.dispose();
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  Future<void> _greet() async {
    setState(() => _vstate = _VoiceState.processing);
    // Lead with a real, level-aware teaching kickoff (D-042): the sensei opens
    // the FIRST guided sentence-building step, not a passive "ask me anything".
    // Online → live AI turn; offline → a warm canned invite (never blocks).
    final kickoff = _uiLang == 'en'
        ? 'Start a spoken-practice session: greet me warmly in one line, then '
            'begin the first tiny step — give me one simple word or pattern at my '
            'level, say a short example sentence, and ask me to try one.'
        : _uiLang == 'ja'
            ? '話す練習を始めて: 一言あたたかく挨拶し、最初の小さな一歩を — '
                '私のレベルの簡単な単語かパターンを一つ出し、短い例文を言って、'
                '私に一つ言わせて。'
            : 'কথা বলার practice শুরু করো: এক লাইনে উষ্ণ সালাম দাও, তারপর প্রথম '
                'ছোট্ট ধাপ — আমার level-এর একটা সহজ শব্দ বা pattern দাও, একটা ছোট '
                'উদাহরণ-বাক্য বলো, আর আমাকে একটা বলতে বলো।';
    final ai = await AiTutorService.instance.voiceReply(kickoff,
        contextJp: widget.contextJp,
        curriculumHint: _hint,
        level: _level,
        uiLang: _uiLang);
    if (!mounted) return;
    final greeting = ai ??
        (_uiLang == 'en'
            ? "Hi! I'm Sensei. Let's practice speaking — say any Japanese word "
                'you know and we\'ll build a sentence together!'
            : _uiLang == 'ja'
                ? 'こんにちは！話す練習をしよう。知っている日本語を一つ言ってみて、'
                    '一緒に文を作ろう！'
                : 'হাই! আমি সেনসেই। চলো কথা বলা practice করি — তুমি জানো এমন '
                    'একটা জাপানি শব্দ বলো, একসাথে বাক্য বানাই!');
    _addMsg(false, greeting);
    await _speakOut(greeting);
  }

  // ── STT ────────────────────────────────────────────────────────────────────

  Future<void> _startListening() async {
    setState(() => _vstate = _VoiceState.listening);
    final ok = await VoiceInputService.instance.start(
      japanese: false, // accept both languages
      onResult: (text, isFinal) {
        if (!mounted) return;
        if (isFinal && text.trim().isNotEmpty) {
          _onSpeechFinal(text.trim());
        }
      },
    );
    if (!ok && mounted) {
      // No STT → text box will be the fallback
      setState(() {
        _micUnavailable = true;
        _vstate = _VoiceState.idle;
      });
    }
  }

  Future<void> _stopListening() async {
    await VoiceInputService.instance.stop();
    if (mounted && _vstate == _VoiceState.listening) {
      setState(() => _vstate = _VoiceState.idle);
    }
  }

  void _onSpeechFinal(String text) {
    if (!mounted) return;
    _addMsg(true, text);
    _askAi(text);
  }

  // ── AI ─────────────────────────────────────────────────────────────────────

  Future<void> _askAi(String userText) async {
    setState(() => _vstate = _VoiceState.processing);
    final reply = await AiTutorService.instance.voiceReply(
      userText,
      contextJp: widget.contextJp,
      curriculumHint: _hint,
      level: _level,
      uiLang: _uiLang,
    );
    if (!mounted) return;
    final text = reply ??
        (_uiLang == 'en'
            ? 'Sorry, I\'m offline right now. Try again when you\'re connected!'
            : _uiLang == 'ja'
                ? 'ごめん、今オフラインです。後でまた試してね！'
                : 'এখন অফলাইন — নেট এলে আবার জিজ্ঞেস করো!');
    _addMsg(false, text);
    await _speakOut(text);
  }

  // ── TTS ────────────────────────────────────────────────────────────────────

  /// True when [text] is mostly Japanese script — such replies should be
  /// spoken by the Japanese neural voice, not the Bengali/English one (D-044:
  /// "the voice is not good" — a bn/en voice mangling Japanese was the cause).
  static bool _mostlyJapanese(String text) {
    var jp = 0, other = 0;
    for (final r in text.runes) {
      if ((r >= 0x3040 && r <= 0x30FF) || (r >= 0x4E00 && r <= 0x9FFF)) {
        jp++;
      } else if (r > 0x20) {
        other++;
      }
    }
    return jp > 0 && jp >= other;
  }

  Future<void> _speakOut(String text) async {
    setState(() => _vstate = _VoiceState.speaking);
    // 1. Neural voice (proxy /ai/tts — Nabanita quality)
    try {
      final voice =
          (_uiLang == 'ja' || _mostlyJapanese(text)) ? 'ja' : 'bn';
      await _neural
          .setUrl(AiTutorService.ttsUrl(text, voice: voice))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _neural.play();
      await _neural.playerStateStream
          .firstWhere((s) => s.processingState == ja.ProcessingState.completed)
          .timeout(const Duration(seconds: 30));
      _onTtsDone();
      return;
    } catch (_) {/* proxy unreachable → device TTS */}

    // 2. Device Bengali TTS
    try {
      final langs = await _deviceTts.getLanguages as List?;
      String? voice;
      if (langs != null) {
        for (final want in ['bn-IN', 'bn-BD', 'bn']) {
          for (final t in langs) {
            if (t.toString().toLowerCase() == want.toLowerCase()) {
              voice = t.toString(); break;
            }
          }
          if (voice != null) break;
        }
        if (voice == null) {
          for (final t in langs) {
            if (t.toString().toLowerCase().startsWith('bn')) {
              voice = t.toString(); break;
            }
          }
        }
      }
      if (voice != null && mounted) {
        await _deviceTts.setLanguage(voice);
        await _deviceTts.setSpeechRate(0.45);
        await _deviceTts.speak(text);
        // completion is handled by setCompletionHandler → _onTtsDone
        return;
      }
    } catch (_) {}

    // 3. No voice available — just show the text
    _onTtsDone();
  }

  void _onTtsDone() {
    if (!mounted) return;
    // Auto-restart listening after a brief natural pause
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _vstate == _VoiceState.speaking) {
        _startListening();
      }
    });
    setState(() => _vstate = _VoiceState.idle);
  }

  Future<void> _interrupt() async {
    await _neural.stop();
    await _deviceTts.stop();
    if (mounted && _vstate == _VoiceState.speaking) {
      _startListening();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _addMsg(bool mine, String text) {
    if (!mounted) return;
    setState(() => _msgs.insert(0, _Msg(mine, text)));
  }

  // ── Text fallback send ─────────────────────────────────────────────────────

  final _textCtrl = TextEditingController();

  void _sendText(String t) {
    t = t.trim();
    if (t.isEmpty || _vstate == _VoiceState.processing) return;
    _textCtrl.clear();
    _addMsg(true, t);
    _askAi(t);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(context, a),
          // ── Context chip (if in classroom) ──────────────────────────────
          if (widget.contextJp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: a.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: a.withValues(alpha: .35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.class_outlined, size: 13, color: a),
                  const SizedBox(width: 6),
                  Text('${_t('ক্লাসে', 'In class', 'クラス')}: 「${widget.contextJp}」',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: a)),
                ]),
              ),
            ),
          // ── Chat transcript ─────────────────────────────────────────────
          Expanded(
            child: _msgs.isEmpty
                ? _buildEmptyHint(a)
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) => _buildBubble(_msgs[i], a),
                  ),
          ),
          // ── Avatar + state indicator ────────────────────────────────────
          _buildAvatar(a),
          const SizedBox(height: 16),
          // ── Bottom controls ─────────────────────────────────────────────
          _buildBottomControls(context, a),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, Color a) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 28, color: BhasagoTheme.muted),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t('সেনসেই', 'Sensei', '先生'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BhasagoTheme.text)),
              Text(_t('Voice Mode · AI কথোপকথন', 'Voice Mode · AI conversation',
                      'ボイスモード · AI会話'),
                  style: TextStyle(
                      fontSize: 11, color: a, fontWeight: FontWeight.w600)),
            ]),
          ),
          // LIVE indicator
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Opacity(
              opacity: 0.3 + 0.7 * math.sin(_pulseCtrl.value * math.pi).abs(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: a, width: 1.3),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 6, height: 6,
                      decoration:
                          BoxDecoration(color: a, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('LIVE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: a,
                          letterSpacing: 1)),
                ]),
              ),
            ),
          ),
        ]),
      );

  // ── Empty hint ─────────────────────────────────────────────────────────────

  Widget _buildEmptyHint(Color a) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mic_none_rounded, size: 32, color: a.withValues(alpha: .4)),
          const SizedBox(height: 8),
          Text(_t('নিচের বাটন ট্যাপ করে বলো…', 'Tap the button below to speak…',
                  '下のボタンをタップして話して…'),
              style: TextStyle(
                  fontSize: 13,
                  color: BhasagoTheme.muted.withValues(alpha: .6),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _startChips(a),
        ]),
      );

  /// Interactive learn-menu (D-044): tap → a real spoken-practice request.
  Widget _startChips(Color a) {
    final labels = _uiLang == 'en'
        ? const ['Start from hiragana', 'Teach me a word', 'Build a word with me', 'Quiz me']
        : _uiLang == 'ja'
            ? const ['ひらがなから', '単語を教えて', '一緒に単語を作ろう', 'テストして']
            : const ['হিরাগানা থেকে শুরু', 'একটা শব্দ শেখাও', 'অক্ষর জুড়ে শব্দ বানাই', 'আমাকে টেস্ট করো'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8, runSpacing: 8,
        children: [
          for (final l in labels)
            OutlinedButton(
              onPressed: () => _sendText(l),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: BorderSide(color: a.withValues(alpha: .4)),
                  shape: const StadiumBorder(),
                  foregroundColor: a,
                  textStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
              child: Text(l),
            ),
        ],
      ),
    );
  }

  // ── Chat bubble ────────────────────────────────────────────────────────────

  Widget _buildBubble(_Msg msg, Color a) {
    final mine = msg.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? a : const Color(0xFF1C1C1C),
          border: mine ? null : Border.all(color: const Color(0xFF2E2E2E)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Text(msg.text,
            style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color:
                    mine ? const Color(0xFF111111) : BhasagoTheme.text)),
      ),
    );
  }

  // ── Central animated avatar ────────────────────────────────────────────────

  Widget _buildAvatar(Color a) {
    return SizedBox(
      height: 160,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _waveCtrl]),
          builder: (_, __) {
            final t = _pulseCtrl.value;

            // Outer ring glow scale
            final outerScale = _vstate == _VoiceState.listening
                ? 1.0 + 0.15 * math.sin(t * 2 * math.pi).abs()
                : _vstate == _VoiceState.speaking
                    ? 1.0 + 0.08 * math.sin(t * 4 * math.pi).abs()
                    : 1.0;

            final ringColor = switch (_vstate) {
              _VoiceState.listening => a,
              _VoiceState.speaking => const Color(0xFF35E065),
              _VoiceState.processing => const Color(0xFF4D7DF7),
              _VoiceState.idle => BhasagoTheme.muted,
            };
            final ringOpacity = switch (_vstate) {
              _VoiceState.listening => 0.4 + 0.6 * math.sin(t * 2 * math.pi).abs(),
              _VoiceState.speaking => 0.3 + 0.5 * math.sin(t * 3 * math.pi).abs(),
              _ => 0.2,
            };

            return Stack(alignment: Alignment.center, children: [
              // Outer glow rings
              for (final ring in [1.6, 1.35, 1.15])
                Transform.scale(
                  scale: outerScale * (ring == 1.6 ? outerScale : 1),
                  child: Container(
                    width: 90 * ring,
                    height: 90 * ring,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ringColor.withValues(
                            alpha: ringOpacity / (ring == 1.6 ? 4 : ring == 1.35 ? 2.5 : 1.5)),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              // Core avatar circle
              Transform.scale(
                scale: _vstate == _VoiceState.speaking
                    ? 1.0 + 0.05 * math.sin(t * 5 * math.pi).abs()
                    : 1.0,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF141414),
                    border: Border.all(color: ringColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: ringColor.withValues(alpha: ringOpacity * 0.6),
                        blurRadius: 20, spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _vstate == _VoiceState.processing
                        ? _buildDots(a)
                        : Text('先',
                            style: TextStyle(
                              fontFamily: 'ZenKakuGothicNew',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: ringColor,
                            )),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  // Thinking dots inside avatar
  Widget _buildDots(Color a) => AnimatedBuilder(
        animation: _dotCtrl,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_dotCtrl.value + i / 3) % 1.0;
            final o = 0.25 + 0.75 * math.sin(t * math.pi);
            return Container(
              width: 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                  color: a.withValues(alpha: o),
                  shape: BoxShape.circle),
            );
          }),
        ),
      );

  // ── State label ────────────────────────────────────────────────────────────

  /// Tiny 3-language picker for this screen's spoken-UI chrome (D-041).
  String _t(String bn, String en, String ja) =>
      _uiLang == 'en' ? en : _uiLang == 'ja' ? ja : bn;

  String get _stateLabel => switch (_vstate) {
        _VoiceState.idle => _t('ট্যাপ করে শুরু করো', 'Tap to start', 'タップして開始'),
        _VoiceState.listening => _t('শুনছি…', 'Listening…', '聞いています…'),
        _VoiceState.processing => _t('ভাবছি…', 'Thinking…', '考えています…'),
        _VoiceState.speaking =>
          _t('ট্যাপ করলে থামবে', 'Tap to stop', 'タップで停止'),
      };

  // ── Bottom controls ────────────────────────────────────────────────────────

  Widget _buildBottomControls(BuildContext context, Color a) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(20, 0, 20, kb > 0 ? 0 : 0),
      child: Column(children: [
        // State label
        Text(_stateLabel,
            style: const TextStyle(
                fontSize: 12,
                color: BhasagoTheme.muted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        // Waveform (listening) or main mic button
        if (_vstate == _VoiceState.listening)
          _buildWaveform(a)
        else
          _buildMicButton(a),
        const SizedBox(height: 14),
        // Text fallback row
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
                controller: _textCtrl,
                onSubmitted: _sendText,
                style: const TextStyle(fontSize: 13, color: BhasagoTheme.text),
                decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: _micUnavailable
                        ? _t('মাইক নেই — এখানে লিখো…', 'No mic — type here…',
                            'マイクなし — ここに入力…')
                        : _t('লিখেও জিজ্ঞেস করতে পারো…', 'You can also type…',
                            '入力してもいいよ…'),
                    hintStyle: const TextStyle(
                        color: BhasagoTheme.muted, fontSize: 12.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44, height: 44,
            child: Material(
              color: a,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _sendText(_textCtrl.text),
                child: const Icon(Icons.send_rounded,
                    size: 18, color: Color(0xFF111111)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // Animated waveform while listening
  Widget _buildWaveform(Color a) => SizedBox(
        height: 72,
        child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(7, (i) {
                final t = (_waveCtrl.value + i / 7) % 1.0;
                final h = 12.0 + 36.0 * math.sin(t * math.pi).abs();
                return GestureDetector(
                  onTap: _stopListening,
                  child: Container(
                    width: 5, height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: a,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: _stopListening,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    shape: BoxShape.circle,
                    border: Border.all(color: a.withValues(alpha: .5)),
                  ),
                  child: Icon(Icons.stop_rounded, size: 20, color: a),
                ),
              ),
            ],
          ),
        ),
      );

  // Main large mic / interrupt button
  Widget _buildMicButton(Color a) {
    final isSpeaking = _vstate == _VoiceState.speaking;
    final isProcessing = _vstate == _VoiceState.processing;
    final btnColor = isSpeaking
        ? const Color(0xFF35E065)
        : isProcessing
            ? const Color(0xFF2A2A2A)
            : a;
    final iconColor = isProcessing ? BhasagoTheme.muted : const Color(0xFF111111);

    return GestureDetector(
      onTap: isProcessing
          ? null
          : isSpeaking
              ? _interrupt
              : _startListening,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) {
          final scale = (_vstate == _VoiceState.idle)
              ? 1.0 + 0.04 * math.sin(_pulseCtrl.value * 2 * math.pi).abs()
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: btnColor,
                shape: BoxShape.circle,
                boxShadow: isProcessing
                    ? []
                    : [
                        BoxShadow(
                          color: btnColor.withValues(alpha: .45),
                          blurRadius: 18, spreadRadius: 2,
                        ),
                      ],
              ),
              child: Icon(
                isSpeaking ? Icons.stop_rounded : Icons.mic_rounded,
                size: 30, color: iconColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
