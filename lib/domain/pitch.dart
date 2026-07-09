// On-device pitch (F0) analysis for accent training. Pure Dart.
//
// Pipeline: mic PCM -> f0Contour() -> toShape() (normalized, speaker-independent)
// -> accentScore() vs the native reference contour. This backs the shadowing
// screen's "how close was my pitch?" feedback. Mirrored & proven in
// tools/pitch_reference.mjs.

import 'dart:math' as math;

/// Estimate fundamental frequency (Hz) of one frame via autocorrelation with
/// parabolic interpolation for sub-sample accuracy. Returns -1 for unvoiced.
double estimateF0(List<double> buf, double sampleRate,
    {double minHz = 70, double maxHz = 500}) {
  final n = buf.length;
  double rms = 0;
  for (final s in buf) rms += s * s;
  rms = math.sqrt(rms / n);
  if (rms < 0.01) return -1;

  final minLag = (sampleRate / maxHz).floor();
  final maxLag = (sampleRate / minHz).ceil().clamp(1, n - 1);

  final c = List<double>.filled(maxLag + 2, 0);
  double best = 0;
  int bestLag = -1;
  for (var lag = minLag; lag <= maxLag; lag++) {
    double sum = 0;
    for (var i = 0; i < n - lag; i++) sum += buf[i] * buf[i + lag];
    c[lag] = sum;
    if (sum > best) {
      best = sum;
      bestLag = lag;
    }
  }
  if (bestLag <= 0) return -1;

  // Parabolic interpolation around the peak for finer frequency resolution.
  double refined = bestLag.toDouble();
  if (bestLag > minLag && bestLag < maxLag) {
    final a = c[bestLag - 1], b = c[bestLag], g = c[bestLag + 1];
    final denom = a - 2 * b + g;
    if (denom.abs() > 1e-9) refined = bestLag + 0.5 * (a - g) / denom;
  }
  final f = sampleRate / refined;
  return (f >= minHz && f <= maxHz) ? f : -1;
}

/// Sliding-window F0 contour across a whole signal. -1 marks unvoiced frames.
List<double> f0Contour(List<double> signal, double sampleRate,
    {int frame = 2048, int hop = 512}) {
  final out = <double>[];
  for (var start = 0; start + frame <= signal.length; start += hop) {
    out.add(estimateF0(signal.sublist(start, start + frame), sampleRate));
  }
  return out;
}

/// Normalize a contour to a speaker-independent shape: semitones relative to the
/// voiced-mean pitch. Unvoiced frames become null. This removes the difference
/// between a low male and high female voice, keeping only the melody.
List<double?> toShape(List<double> contour) {
  final voiced = contour.where((f) => f > 0).toList();
  if (voiced.isEmpty) return List.filled(contour.length, null);
  final mean = voiced.reduce((a, b) => a + b) / voiced.length;
  return contour
      .map((f) => f > 0 ? 12 * (math.log(f / mean) / math.ln2) : null)
      .toList();
}

/// Resample a nullable shape to [len] points (nearest-neighbour).
List<double?> _resample(List<double?> xs, int len) {
  if (xs.isEmpty) return List.filled(len, null);
  return List.generate(len, (i) {
    final j = (i * xs.length / len).floor().clamp(0, xs.length - 1);
    return xs[j];
  });
}

/// Accent similarity 0..100 between learner and reference contours.
/// Compares normalized shapes over overlapping voiced frames; higher is closer.
double accentScore(List<double> reference, List<double> learner) {
  final r = toShape(reference);
  final l = toShape(learner);
  final len = math.max(r.length, l.length);
  final rr = _resample(r, len), ll = _resample(l, len);

  double err = 0;
  int count = 0;
  for (var i = 0; i < len; i++) {
    if (rr[i] == null || ll[i] == null) continue;
    err += (rr[i]! - ll[i]!).abs();
    count++;
  }
  if (count == 0) return 0;
  final meanErr = err / count; // avg semitone deviation
  final score = (100 * (1 - meanErr / 6)).clamp(0, 100);
  return score.toDouble();
}
