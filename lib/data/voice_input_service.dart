// Voice input for "talk to the sensei" — real speech-to-text via the device's
// own recognizer (Android/iOS built-in; the browser's Web Speech API on web).
// This is CONVERSATION practice, not graded pronunciation (D-002 governs the
// latter): the learner speaks, we transcribe, the sensei replies. Japanese by
// default; Bengali when the learner is asking in Bengali.
//
// Graceful everywhere: no mic / permission denied / unsupported surface →
// isAvailable stays false and the UI keeps the text box (never blocks, D-001).
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  VoiceInputService._();
  static final VoiceInputService instance = VoiceInputService._();

  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  bool get isListening => _stt.isListening;

  /// One-time init. Returns true if speech recognition is usable on this device.
  Future<bool> ensureReady() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onError: (e) => debugPrint('stt error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('stt status: $s'),
      );
    } catch (e) {
      debugPrint('stt init failed: $e');
      _ready = false;
    }
    return _ready;
  }

  /// True if the device has any Japanese OR Bengali locale for recognition.
  Future<bool> hasUsableLocale() async {
    if (!await ensureReady()) return false;
    try {
      final locales = await _stt.locales();
      return locales.any((l) =>
          l.localeId.toLowerCase().startsWith('ja') ||
          l.localeId.toLowerCase().startsWith('bn'));
    } catch (_) {
      return false;
    }
  }

  /// Best locale id for a given intent: Japanese for speaking practice,
  /// Bengali if asking a question in Bengali. Falls back to whatever exists.
  Future<String?> _pickLocale({required bool japanese}) async {
    try {
      final locales = await _stt.locales();
      final want = japanese ? 'ja' : 'bn';
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(want)) return l.localeId;
      }
      // fall back to the OTHER language if the preferred one is absent
      final other = japanese ? 'bn' : 'ja';
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(other)) return l.localeId;
      }
    } catch (_) {}
    return null;
  }

  /// Start listening; [onResult] fires with the (partial→final) transcript.
  /// Returns false if it couldn't start (caller keeps the text box).
  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
    bool japanese = true,
  }) async {
    if (!await ensureReady()) return false;
    final localeId = await _pickLocale(japanese: japanese);
    try {
      await _stt.listen(
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          localeId: localeId,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('stt listen failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }
}
