// Reusable widgets. BilingualText is the heart of the "Bengali = bilingual"
// behaviour: in Bengali mode it renders the Bengali line with a dimmed English
// gloss beneath; in English/Japanese it renders a single line.

import 'package:flutter/material.dart';
import '../domain/models.dart';

class BilingualText extends StatelessWidget {
  final Tri text;
  final String lang;
  final TextStyle? primaryStyle;
  final TextAlign align;

  const BilingualText(
    this.text, {
    super.key,
    required this.lang,
    this.primaryStyle,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.lines(lang);
    final primary = primaryStyle ?? Theme.of(context).textTheme.bodyLarge;
    final gloss = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey.shade500);
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lines.first, style: primary, textAlign: align),
        if (lines.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(lines[1], style: gloss, textAlign: align),
          ),
      ],
    );
  }
}
