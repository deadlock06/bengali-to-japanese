import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';
import 'widgets.dart';
import '../domain/models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'ভাষা · Language',
            icon: Icons.translate,
            child: Column(
              children: [
                _LocaleTile(
                  title: 'বাংলা (Bengali)',
                  subtitle: 'Bilingual mode enabled',
                  selected: currentLocale.languageCode == 'bn',
                  onTap: () => ref.read(localeProvider.notifier).state = const Locale('bn'),
                ),
                _LocaleTile(
                  title: 'English',
                  subtitle: 'Standard interface',
                  selected: currentLocale.languageCode == 'en',
                  onTap: () => ref.read(localeProvider.notifier).state = const Locale('en'),
                ),
                _LocaleTile(
                  title: '日本語 (Japanese)',
                  subtitle: 'Full immersion',
                  selected: currentLocale.languageCode == 'ja',
                  onTap: () => ref.read(localeProvider.notifier).state = const Locale('ja'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'প্রাকদর্শন · Preview',
            icon: Icons.visibility_outlined,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bilingual Text Example:',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  BilingualText(
                    const Tri(
                      en: 'Nice to meet you.',
                      bn: 'আপনার সাথে দেখা করে ভালো লাগল।',
                      ja: 'はじめまして。',
                    ),
                    lang: currentLocale.languageCode,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text(
                  'Bhasago',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                ),
                Text(
                  'Version 0.1.0 (Internal SENSEI)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF00C853)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _LocaleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LocaleTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: selected
        ? const Icon(Icons.check_circle, color: Color(0xFF00C853))
        : const Icon(Icons.circle_outlined, color: Colors.white24),
      onTap: onTap,
    );
  }
}
