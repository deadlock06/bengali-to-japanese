// Service for capturing raw 16-bit PCM audio from the microphone for pitch analysis.
// Used by the Accent/Pitch screens to extract F0 contours via the fftea/pitch engine.

import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class PcmRecordService {
  PcmRecordService._();
  static final PcmRecordService instance = PcmRecordService._();

  final AudioRecorder _record = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final List<double> _buffer = [];
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Start recording raw PCM at 16kHz.
  Future<bool> start() async {
    if (_isRecording) return false;
    try {
      if (!await _record.hasPermission()) return false;
      _buffer.clear();
      final stream = await _record.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      _sub = stream.listen((data) {
        // Convert Uint8List of 16-bit PCM to double -1.0..1.0
        final int16 = Int16List.view(data.buffer, data.offsetInBytes, data.lengthInBytes ~/ 2);
        for (final sample in int16) {
          _buffer.add(sample / 32768.0);
        }
      });
      _isRecording = true;
      return true;
    } catch (_) {
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the accumulated PCM float buffer.
  Future<List<double>> stop() async {
    if (!_isRecording) return [];
    try {
      await _record.stop();
      await _sub?.cancel();
      _sub = null;
      _isRecording = false;
      final out = List<double>.from(_buffer);
      _buffer.clear();
      return out;
    } catch (_) {
      _isRecording = false;
      return [];
    }
  }
}
