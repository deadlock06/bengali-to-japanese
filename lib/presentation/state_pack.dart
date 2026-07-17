// StatePack (C3 / docs 09) — the ONE reusable loading / empty / error / offline
// surface, in Bold Ink. Every screen that awaits data uses this so states look
// consistent and never leave the learner staring at a bare spinner or a raw
// exception. Bengali-first copy; warm, never blaming (D-001).
import 'package:flutter/material.dart';

import '../app/theme.dart';

enum StateKind { loading, empty, error, offline }

class StatePack extends StatelessWidget {
  const StatePack._(this.kind,
      {this.titleBn, this.bodyBn, this.emoji, this.accent, this.onRetry});

  final StateKind kind;
  final String? titleBn, bodyBn, emoji;
  final Color? accent;
  final VoidCallback? onRetry;

  /// Loading — a calm branded spinner + optional line (no jargon, no drama).
  const StatePack.loading({Key? key, String? bn, Color? accent})
      : this._(StateKind.loading, titleBn: bn, accent: accent);

  /// Empty — nothing here YET, framed as a next step, never a dead end.
  const StatePack.empty(
      {Key? key, required String title, String? body, String emoji = '🌱'})
      : this._(StateKind.empty, titleBn: title, bodyBn: body, emoji: emoji);

  /// Error — something went wrong; offer a retry, keep it human.
  const StatePack.error(
      {Key? key, String? title, String? body, VoidCallback? onRetry})
      : this._(StateKind.error,
            titleBn: title, bodyBn: body, emoji: '😅', onRetry: onRetry);

  /// Offline — a feature needs the network; reassure that the core works offline.
  const StatePack.offline({Key? key, String? title, String? body})
      : this._(StateKind.offline, titleBn: title, bodyBn: body, emoji: '📡');

  @override
  Widget build(BuildContext context) {
    final a = accent ?? BhasagoTheme.text;
    if (kind == StateKind.loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 30, height: 30,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: accent ?? BhasagoColors.yellow),
          ),
          if (titleBn != null) ...[
            const SizedBox(height: 14),
            Text(titleBn!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: BhasagoTheme.muted, fontSize: 12.5)),
          ],
        ]),
      );
    }
    final title = titleBn ??
        switch (kind) {
          StateKind.empty => 'এখানে এখনো কিছু নেই',
          StateKind.error => 'কিছু একটা ভুল হলো',
          StateKind.offline => 'এই অংশে ইন্টারনেট লাগে',
          StateKind.loading => '',
        };
    final body = bodyBn ??
        switch (kind) {
          StateKind.error => 'আবার চেষ্টা করে দেখো — সমস্যা না থাকলে ঠিক হয়ে যাবে।',
          StateKind.offline =>
            'বাকি সব — পাঠ, লেখা, রিভিউ — ইন্টারনেট ছাড়াই চলে। শুধু এই অংশটুকু পরে।',
          _ => '',
        };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: a, fontSize: 15, fontWeight: FontWeight.w800)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: BhasagoTheme.muted, fontSize: 12.5, height: 1.5)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('আবার চেষ্টা'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: BhasagoTheme.text,
                  side: const BorderSide(color: BhasagoTheme.pillOutline, width: 1.4),
                  shape: const StadiumBorder()),
            ),
          ],
        ]),
      ),
    );
  }
}
