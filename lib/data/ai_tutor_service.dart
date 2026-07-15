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

  static const _system = '''
তুমি "সেনসেই" — বাংলাভাষীদের জন্য জাপানি শেখানোর একজন বন্ধুসুলভ শিক্ষক।
নিয়ম (কঠোরভাবে মানবে):
1. উত্তর দাও "Smart Banglish" এ — বাংলা বাক্য-গঠন রেখে key শব্দ English এ (verb blending: "check করা", "practice করো")। কর্পোরেট/তরুণ register। সহজ, উষ্ণ, সংক্ষিপ্ত (২-৪ বাক্য)।
2. জাপানি ব্যাকরণ/অর্থ কখনো বানিয়ে বলবে না — শুধু verified, standard JLPT N5-N4 / JFT-Basic স্তরের তথ্য ব্যাখ্যা করবে। নিশ্চিত না হলে বলো "এটা এখন আমাদের level এর বাইরে।"
3. তুমি শুধু ব্যাখ্যা করো — grade করো না, নম্বর দিও না।
4. কোনো চাপ/লজ্জা/guilt নয়। শিক্ষার্থীকে উৎসাহ দাও।
5. জাপানি লিখলে সাথে romaji + বাংলা উচ্চারণ দাও।''';

  /// Returns the sensei's reply, or null on no-proxy/offline/error (→ caller
  /// uses its canned fallback). [contextJp] is the item under discussion.
  Future<String?> reply(String userText, {String contextJp = ''}) async {
    try {
      final ctx = contextJp.isEmpty
          ? ''
          : 'শিক্ষার্থী এখন 「$contextJp」 নিয়ে শিখছে। ';
      final res = await _dio.post(
        _proxyUrl,
        options: Options(
            headers: {'Content-Type': 'application/json'},
            // A 4xx from the proxy (e.g. no key configured) → fallback, no throw
            validateStatus: (s) => s != null && s < 500),
        data: {
          'model': 'gpt-4o-mini',
          'temperature': 0.6,
          'max_tokens': 300,
          'messages': [
            {'role': 'system', 'content': _system},
            {'role': 'user', 'content': '$ctx$userText'},
          ],
        },
      );
      final txt = (res.data?['choices']?[0]?['message']?['content'] as String?)
          ?.trim();
      return (txt == null || txt.isEmpty) ? null : txt;
    } catch (_) {
      return null; // offline / no proxy / error → canned fallback
    }
  }
}
