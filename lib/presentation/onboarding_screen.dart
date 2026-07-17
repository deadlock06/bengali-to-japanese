// Bhasago — first-run language-select onboarding (v4 design). Step 4.
//
// Mirrors the onboarding screen in Home v4.dc.html: logo mark, three language
// cards (বাংলা / English / 日本語 — active = yellow), stadium "start" button.
//
// Wiring:
//  1. pubspec.yaml: add  shared_preferences: ^2.2.0
//  2. Drop into lib/presentation/onboarding_screen.dart
//  3. app/providers.dart: add localeChosenProvider (below, keep it there)
//  4. main.dart (step 3 TODO): home: chosen ? HomeShell() : OnboardingScreen()
//
// Persistence deliberately uses shared_preferences, NOT flutter_secure_storage:
// the chosen locale is not a secret; keep the Keystore for the DB key only.
//
// ── add to app/providers.dart ──────────────────────────────────────────────
// /// Whether the first-run language screen was completed.
// final localeChosenProvider = FutureProvider<bool>((_) async {
//   final p = await SharedPreferences.getInstance();
//   return p.getString('locale_chosen') != null;
// });
// ───────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/providers.dart';
import '../app/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  /// Called after the choice is persisted — the app swaps to HomeShell.
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _pending = 'bn'; // spec: Bengali-first default
  // C1 (D-015): step 0 = language, step 1 = GOAL. The goal only changes the
  // journey map's emphasis/recommendation — same DAG, no locks, changeable
  // anytime in Settings.
  int _step = 0;
  String _goal = 'ssw';

  static const _goals = [
    (code: 'ssw', icon: '🏭', title: 'জাপানে কাজ করব (SSW)',
     sub: 'JFT-Basic পাস → কাজের ভিসা — কাজের ভাষায় জোর'),
    (code: 'jlpt', icon: '🎓', title: 'JLPT পরীক্ষা দেব',
     sub: 'N5→N4 ধাপে ধাপে — ব্যাকরণ ও লিপিতে জোর'),
    (code: 'daily', icon: '🗾', title: 'দৈনন্দিন জীবনের জন্য',
     sub: 'কথা বলা, ঘোরা, বন্ধু বানানো — সহজ পথে'),
  ];

  static const _choices = [
    (code: 'bn', native: 'বাংলা', en: 'Bengali'),
    (code: 'en', native: 'English', en: 'English'),
    (code: 'ja', native: '日本語', en: 'Japanese'),
  ];

  Future<void> _accept() async {
    if (_step == 0) {
      ref.read(localeProvider.notifier).state = Locale(_pending);
      final p = await SharedPreferences.getInstance();
      await p.setString('locale_chosen', _pending);
      if (mounted) setState(() => _step = 1);
      return;
    }
    await setGoal(_goal);
    ref.invalidate(goalProvider);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 26),
              // logo mark — yellow tile with 語
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: BhasagoColors.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('語',
                        style: TextStyle(
                            fontFamily: 'Zen Kaku Gothic New',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111111))),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(child: Text('Bhasago', style: text.headlineMedium)),
              const SizedBox(height: 2),
              Center(
                child: Text(
                    _step == 0
                        ? 'ভাষা বেছে নাও · Select language · 言語を選択'
                        : 'তোমার লক্ষ্য কী? — পথ একটাই, জোরটা বদলায়',
                    style: text.bodySmall),
              ),
              const SizedBox(height: 26),
              if (_step == 0)
                for (final c in _choices) ...[
                  _LangCard(
                    native: c.native,
                    en: c.en,
                    selected: _pending == c.code,
                    onTap: () => setState(() => _pending = c.code),
                  ),
                  const SizedBox(height: 9),
                ]
              else
                for (final g in _goals) ...[
                  _LangCard(
                    native: '${g.icon}  ${g.title}',
                    en: g.sub,
                    selected: _goal == g.code,
                    onTap: () => setState(() => _goal = g.code),
                  ),
                  const SizedBox(height: 9),
                ],
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BhasagoColors.ink,
                  foregroundColor: const Color(0xFF111111),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _accept,
                // Trilingual on purpose: the user hasn't picked a language yet.
                child: Text(_step == 0
                    ? 'চলো শুরু করি · Let\'s start · はじめよう'
                    : 'যাত্রা শুরু ⛩️'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final String native;
  final String en;
  final bool selected;
  final VoidCallback onTap;
  const _LangCard(
      {required this.native,
      required this.en,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? const Color(0xFF111111) : BhasagoColors.ink;
    final sub = selected ? BhasagoColors.yellowDim : BhasagoColors.inkDim;
    return Material(
      color: selected ? BhasagoColors.yellow : BhasagoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? BhasagoColors.yellow : BhasagoColors.outline,
                width: 1.5),
          ),
          child: Row(
            children: [
              // Flexible column: language cards stay one-line; the longer
              // goal cards (C1) wrap title + subtitle without overflowing.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(native,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: fg)),
                    Text(en,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, fontFamily: 'Archivo', color: sub)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
