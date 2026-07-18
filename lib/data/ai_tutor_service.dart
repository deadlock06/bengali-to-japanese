// Online AI tutor (OPTIONAL enhancement — offline-first is preserved).
//
// The sensei CHAT uses this to phrase explanations; GRADING never touches it
// (answer-key only, 00 §4 / D-001). The model SELECTS & GLUES verified facts
// and explains in "Smart Banglish" — it must NOT invent Japanese grammar.
//
// SECURITY: the client holds NO API key and doesn't care which provider is
// used — it POSTs to a PROXY that picks an OpenAI-compatible provider
// (DeepSeek / Kimi / OpenAI, whichever key is set, with failover) and injects
// the key server-side (no key shipped to the client, no browser CORS). The
// proxy overrides `model` per provider, so the value sent here is a placeholder.
// Local web demo: tools/web_server.mjs at same-origin '/ai/chat'; device build:
//   flutter build web                     # uses /ai/chat (run web_server.mjs
//                                          #   with OPENAI_API_KEY set)
//   flutter build apk --dart-define=AI_PROXY_URL=https://your-proxy/ai/chat
// Any failure (no proxy / offline / error) → null, and the caller falls back
// to the canned/offline reply. So the app always works.
import 'package:dio/dio.dart';

class AiTutorService {
  AiTutorService._();
  static final AiTutorService instance = AiTutorService._();

  // Same-origin proxy by default (works in the web build). Override for device.
  static const _proxyUrl =
      String.fromEnvironment('AI_PROXY_URL', defaultValue: '/ai/chat');

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 25),
  ));

  // The #1 quality complaint was "AI-এর বাংলা translated মনে হয়" — cloud models
  // default to stiff textbook Bengali (আপনি/এটি/"নিশ্চিত করুন" register) unless
  // the register is pinned with explicit bans + examples. This contract is
  // appended to EVERY system prompt. Style only — content rules stay separate.
  static const _styleContract = '''

ভাষার স্টাইল (সবচেয়ে জরুরি নিয়ম — ভাঙলে উত্তরটাই ভুল):
তুমি ঢাকার একজন বড় ভাই/আপুর মতো কথা বলো — মুখের ভাষায়, লেখার ভাষায় না। English থেকে অনুবাদ করা বাংলা একদম নিষেধ।
✗ কখনো লিখবে না: "আপনি", "এটি", "উহা", "করুন/বলুন/দেখুন", "অত্যন্ত গুরুত্বপূর্ণ", "নিশ্চিত করুন", "সহায়তা প্রদান", "অনুগ্রহ করে", "এটি লক্ষ্য করা যায়"
✓ সবসময়: "তুমি", "এটা/ওটা", "করো/বলো/দেখো", ছোট ছোট মুখের বাক্য, আর "তো / না? / আচ্ছা / দেখো / আরে" জাতীয় কথ্য টান।
Banglish মেশাও যেভাবে মানুষ সত্যিই বলে — word, practice, level, grammar, tension এসব English-ই থাকবে: "টেনশন নিও না", "এই word টা", "একটু practice করলেই হয়ে যাবে"। জোর করে বাংলা পরিভাষা বানাবে না ("ব্যাকরণগত কাঠামো" ✗)।
উদাহরণ —
✗ খারাপ (translated): "এটি একটি গুরুত্বপূর্ণ কণা। আপনি এটি বিষয় চিহ্নিত করতে ব্যবহার করতে পারেন।"
✓ ভালো (আসল Banglish): "は হলো topic marker — মানে 'কার কথা বলছি' সেটা দেখায়। যেমন わたしは মানে 'আমি হলাম গিয়ে...' টাইপ ভাব। সোজা, না?"''';

  static const _system = '''
তুমি "সেনসেই" — বাংলাভাষীদের জন্য জাপানি শেখানোর একজন বন্ধুসুলভ শিক্ষক।
নিয়ম (কঠোরভাবে মানবে):
1. উত্তর দাও "Smart Banglish" এ — বাংলা বাক্য-গঠন রেখে key শব্দ English এ (verb blending: "check করা", "practice করো")। সহজ, উষ্ণ, সংক্ষিপ্ত (২-৪ বাক্য)।
2. জাপানি ব্যাকরণ/অর্থ কখনো বানিয়ে বলবে না — শুধু verified, standard JLPT N5-N4 / JFT-Basic স্তরের তথ্য ব্যাখ্যা করবে। নিশ্চিত না হলে বলো "এটা এখন আমাদের level এর বাইরে।"
3. তুমি শুধু ব্যাখ্যা করো — grade করো না, নম্বর দিও না।
4. কোনো চাপ/লজ্জা/guilt নয়। শিক্ষার্থীকে উৎসাহ দাও।
5. জাপানি লিখলে সাথে romaji + বাংলা উচ্চারণ দাও।$_styleContract''';

  /// Dynamic BN↔JP language balance (13_MASTER_VISION): the sensei's mix of
  /// Bengali and Japanese follows the learner's curriculum level — beginner
  /// mostly Bengali, advanced mostly Japanese. D-017/D-028 mapping:
  /// L0/A1 → beginner · A2 → intermediate · N4 → advanced ·
  /// N3 → advanced+ · N2 → near-native · N1 → native-like.
  static String _balanceLine(String level) => switch (level) {
        'N1' =>
          '\nভাষার ভারসাম্য: শিক্ষার্থী NATIVE-LIKE (N1) স্তরে। প্রায় পুরোটাই স্বাভাবিক '
              'native register জাপানিতে দাও — বাংলা শুধু ব্যবহারকারী স্পষ্ট চাইলে।',
        'N2' =>
          '\nভাষার ভারসাম্য: শিক্ষার্থী NEAR-NATIVE (N2) স্তরে। ~৯০-৯৫% জাপানিতে দাও '
              '(kana/kanji সহ) — বাংলা শুধু সত্যিই কঠিন nuance-এ, খুব সংক্ষেপে।',
        'N3' =>
          '\nভাষার ভারসাম্য: শিক্ষার্থী ADVANCED+ (N3) স্তরে। ~৯০% জাপানিতে দাও — '
              'বাংলা শুধু নতুন grammar/শব্দের ছোট ব্যাখ্যায়।',
        'N4' =>
          '\nভাষার ভারসাম্য: শিক্ষার্থী ADVANCED (N4) স্তরে। উত্তরের ৮০-৯০% জাপানিতে দাও '
              '(স্বাভাবিক বাক্যে, kana/kanji সহ) — বাংলা শুধু কঠিন জায়গার ছোট ব্যাখ্যায়।',
        'A2' =>
          '\nভাষার ভারসাম্য: শিক্ষার্থী INTERMEDIATE (A2) স্তরে। বাংলা ও জাপানি প্রায় ৫০/৫০ '
              'মেশাও — জাপানি বাক্য আগে, তারপর বাংলা ব্যাখ্যা।',
        _ =>
          '\nভাষার ভারসাম্য: শিক্ষার্থী BEGINNER (L0/A1) স্তরে। ৮০-৯০% বাংলায় বলো; জাপানি '
              'অল্প-অল্প করে, আর জাপানি লিখলেই সাথে romaji + বাংলা উচ্চারণ দেবে।',
      };

  /// Returns the sensei's reply, or null on no-proxy/offline/error (→ caller
  /// uses its canned fallback). [contextJp] is the item under discussion.
  /// [level] = curriculum level (L0/A1/A2/N4) for the BN↔JP balance.
  Future<String?> reply(String userText,
      {String contextJp = '', String curriculumHint = '', String level = ''}) {
    final ctx = StringBuffer();
    if (curriculumHint.isNotEmpty) ctx.write('$curriculumHint ');
    // Context is BACKGROUND only — the learner's actual question wins. (Bug:
    // "hiragana ki?" got answered about the current item あ instead.)
    if (contextJp.isNotEmpty) {
      ctx.write('[প্রসঙ্গ, শুধু দরকার হলে: ক্লাসরুমে এখন 「$contextJp」 চলছে। '
          'শিক্ষার্থীর প্রশ্ন অন্য/বড় বিষয়ে হলে প্রশ্নটারই উত্তর দাও — '
          'জোর করে 「$contextJp」-তে টেনো না।] ');
    }
    ctx.write('শিক্ষার্থীর প্রশ্ন: ');
    final system = level.isEmpty ? _system : '$_system${_balanceLine(level)}';
    return _complete(system, '$ctx$userText', maxTokens: 300);
  }

  static const _dictSystem = '''
তুমি "সেনসেই" — বাংলাভাষীদের বন্ধুসুলভ শিক্ষক ও AI অভিধান। ব্যবহারকারী অ্যাপের যেকোনো জায়গা থেকে টেক্সট select করে তোমাকে দেখাবে — সেটা যাই হোক, তুমি সবসময় সাহায্য করবে। কখনো "level এর বাইরে" বলে ফিরিয়ে দেবে না।

টেক্সট বুঝে ঠিক ফরম্যাট বেছে নাও:

▸ যদি একক জাপানি বর্ণ (হিরাগানা/কাতাকানা, যেমন: あ, ア) হয় → এই ফরম্যাটে (Smart Banglish):
• অর্থ: (জাপানি বর্ণ/Alphabet)
• উচ্চারণ: (romaji + বাংলা উচ্চারণ)
• মনে রাখার ট্রিক (Mnemonic): (সহজে মনে রাখার জন্য কোনো ছবি বা ট্রিক, যেমন: あ দেখতে মাছের মতো)
• লেখার স্ট্রোক: (স্ট্রোক সংখ্যা ও লেখার নিয়ম)
• শব্দে ব্যবহার: (এই বর্ণ দিয়ে শুরু ১টি সহজ শব্দ + মানে)

▸ যদি জাপানি শব্দ/বাক্য হয় → এই ফরম্যাটে (Smart Banglish, বাংলা + English key words):
• অর্থ: (বাংলায় মানে)
• পড়া: (kana + romaji + বাংলা উচ্চারণ)
• ভাঙা: (শব্দ/particle ধরে ধরে ছোট breakdown — থাকলে)
• উদাহরণ: (একটা ছোট natural বাক্য + মানে)
• টিপ: (কখন/কোথায় ব্যবহার হয়)

▸ যদি জাপানি না হয় (বাংলা শব্দ, নাম, English, বা অ্যাপের কোনো লেখা) → ফরম্যাট বাদ, শুধু ২-৩ বাক্যে সহজভাবে বুঝিয়ে দাও এটা কী/কী মানে। নাম হলে বলো এটা একটা নাম। চাইলে জাপানিতে কীভাবে বলা/লেখা হয় সেটা যোগ করতে পারো।

নিয়ম: জাপানি ব্যাকরণ/অর্থ কখনো বানিয়ে বলবে না (verified, standard তথ্য)। বাকি সব ক্ষেত্রে স্বাভাবিকভাবে সাহায্য করো। উষ্ণ, সংক্ষিপ্ত, উৎসাহী।$_styleContract''';

  /// AI dictionary — explains arbitrary (usually Japanese) text. null on
  /// offline / no-key / error (caller shows a gentle offline message).
  /// [curriculumHint] ties the answer to the learner's unit; [level] drives
  /// the BN↔JP balance (13_MASTER_VISION).
  Future<String?> explain(String text,
      {String curriculumHint = '', String level = ''}) {
    final t = text.trim();
    final user = curriculumHint.isEmpty ? t : '$curriculumHint\n\nটেক্সট: $t';
    final system =
        level.isEmpty ? _dictSystem : '$_dictSystem${_balanceLine(level)}';
    return _complete(system, user, maxTokens: 400);
  }

  Future<String?> _complete(String system, String user, {int maxTokens = 300}) async {
    if (user.isEmpty) return null;
    try {
      final res = await _dio.post(
        _proxyUrl,
        options: Options(
            headers: {'Content-Type': 'application/json'},
            // A 4xx from the proxy (e.g. no key configured) → fallback, no throw
            validateStatus: (s) => s != null && s < 500),
        data: {
          'model': 'gpt-4o-mini',
          'temperature': 0.5,
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
        },
      );
      final txt = (res.data?['choices']?[0]?['message']?['content'] as String?)
          ?.trim();
      return (txt == null || txt.isEmpty) ? null : txt;
    } catch (_) {
      return null; // offline / no proxy / error → fallback
    }
  }
}
