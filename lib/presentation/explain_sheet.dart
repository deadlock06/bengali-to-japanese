// Copy-anywhere "ব্যাখ্যা": opens the ONE sensei chat box (same as the AI
// Classroom), seeded with the selected/copied text. The sensei explains it in
// his teaching style, reads it aloud in Bengali, and you can keep asking
// follow-ups — tied to what you're currently learning (curriculumHint).
// Explanatory only — no grading (D-001).
import 'package:flutter/material.dart';

import 'sensei_chat_sheet.dart';

Future<void> showExplainSheet(BuildContext context, String text,
    {String curriculumHint = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SenseiChatSheet(
      accent: const Color(0xFF4D7DF7),
      moodLabel: 'ব্যাখ্যা',
      seedText: text,
      curriculumHint: curriculumHint,
    ),
  );
}
