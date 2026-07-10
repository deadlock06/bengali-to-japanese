// Persona agent (04 §2) — tone & relationship. Deterministic template
// selection: the same (persona, event, state, count) always yields the same
// line. NO shame or pressure copy ever; every persona softens automatically
// when the learner struggles (anxiety → reduce intensity).
//
// Relationship arc: week 1 formal → weeks 2–4 warmer → month 2+ mentor →
// month 4+ casual banter ONLY if the learner opted in (04 §Persona).

import 'agent_state.dart';

/// Moments the persona reacts to.
enum PersonaEvent { greeting, correctAnswer, wrongAnswer, lessonComplete }

/// Returns the persona's Bengali line for [event]. [rotation] is any
/// monotonically increasing counter (e.g. answers so far) used to vary lines
/// deterministically — no randomness, no variable-reward feel: the same
/// events always cycle the same fixed set (99 D-001).
///
/// [weekNumber] is weeks since the learner started (1-based). [casualOptIn]
/// gates the month-4+ banter register.
String personaLine(
  PersonaType persona,
  PersonaEvent event, {
  PsychState psych = PsychState.calibrating,
  int rotation = 0,
  int weekNumber = 1,
  bool casualOptIn = false,
}) {
  // Struggle/burnout → every persona drops intensity and goes gentle.
  final gentle =
      psych == PsychState.struggle || psych == PsychState.burnout;
  final formal = weekNumber <= 1 || persona == PersonaType.sensei;
  final lines = _lines(persona, event,
      gentle: gentle,
      formal: formal,
      casual: casualOptIn && weekNumber >= 16);
  return lines[rotation % lines.length];
}

List<String> _lines(
  PersonaType persona,
  PersonaEvent event, {
  required bool gentle,
  required bool formal,
  required bool casual,
}) {
  switch (event) {
    case PersonaEvent.greeting:
      return switch (persona) {
        PersonaType.sensei => formal
            ? const ['শুরু করা যাক। মনোযোগ দিন।', 'আজকের পাঠ প্রস্তুত।']
            : const ['শুরু করা যাক। মনোযোগ দাও।', 'আজকের পাঠ প্রস্তুত।'],
        PersonaType.didi => formal
            ? const ['চলুন, আজ একটু এগোই।', 'ফিরে এসেছেন — খুব ভালো লাগল!']
            : const ['চলো, আজ একটু এগোই।', 'ফিরে এসেছ — খুব ভালো লাগল!'],
        PersonaType.friend => casual
            ? const ['কி খবর! আজ কোনটা শিখবি?', 'চল শুরু করি!']
            : const ['চলো শুরু করি!', 'আজ নতুন কিছু শিখি?'],
        PersonaType.coach => const ['ওয়ার্মআপ শুরু। প্রস্তুত?', 'আজকের লক্ষ্য ঠিক করি।'],
      };

    case PersonaEvent.correctAnswer:
      if (gentle) {
        // Struggling learner just got one right — quiet, warm reinforcement.
        return switch (persona) {
          PersonaType.sensei => const ['সঠিক। এভাবেই।'],
          PersonaType.didi => const ['এই তো হচ্ছে! ধীরে ধীরেই হয়।'],
          PersonaType.friend => const ['দেখেছ? পেরেছ!'],
          PersonaType.coach => const ['ঠিক। নিজের গতিতে চলো।'],
        };
      }
      return switch (persona) {
        PersonaType.sensei =>
          const ['সঠিক।', 'ঠিক আছে। পরেরটায় মন দিন।', 'ভালো।'],
        PersonaType.didi =>
          const ['বাহ্, দারুণ!', 'একদম ঠিক!', 'খুব ভালো হচ্ছে!'],
        PersonaType.friend =>
          const ['সেরা!', 'একদম ঠিক! পরেরটা?', 'তুমি তো পারোই!'],
        PersonaType.coach =>
          const ['ঠিক! গতি ধরে রাখো।', 'ভালো। পরেরটা।', 'এই তো ফর্মে!'],
      };

    case PersonaEvent.wrongAnswer:
      // NEVER shaming — mistakes are information, in every register.
      if (gentle) {
        return switch (persona) {
          PersonaType.sensei => const ['সমস্যা নেই। আবার দেখা যাক।'],
          PersonaType.didi => const ['ঠিক আছে, একসাথে আরেকবার দেখি।'],
          PersonaType.friend => const ['কাছাকাছি ছিল! আরেকবার?'],
          PersonaType.coach => const ['থামো, শ্বাস নাও — তারপর আরেকবার।'],
        };
      }
      return switch (persona) {
        PersonaType.sensei =>
          const ['আবার দেখুন। ভুল শেখারই অংশ।', 'আরেকবার ভাবুন।'],
        PersonaType.didi =>
          const ['প্রায় হয়ে গিয়েছিল — আরেকবার দেখো।', 'সমস্যা নেই, আবার চেষ্টা করো।'],
        PersonaType.friend => const ['উফ, কাছেই ছিল! আবার যাই?', 'হয়নি? হবে!'],
        PersonaType.coach =>
          const ['ফোকাস — পরেরটা তোমার।', 'ঠিক আছে, আবার।'],
      };

    case PersonaEvent.lessonComplete:
      return switch (persona) {
        PersonaType.sensei => const ['পাঠ সম্পন্ন। ভালো কাজ।'],
        PersonaType.didi => const ['লেসন শেষ — আজ দারুণ করেছ!'],
        PersonaType.friend => const ['শেষ! দারুণ ছিল!'],
        PersonaType.coach => const ['সেশন শেষ। ভালো পারফরম্যান্স।'],
      };
  }
}

/// Bengali display name for the persona picker.
String personaNameBn(PersonaType p) => switch (p) {
      PersonaType.sensei => 'সেনসেই (গম্ভীর)',
      PersonaType.didi => 'দিদি/ভাই (আন্তরিক)',
      PersonaType.friend => 'বন্ধু (মজার)',
      PersonaType.coach => 'কোচ (গতিশীল)',
    };
