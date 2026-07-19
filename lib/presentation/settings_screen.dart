import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agents/agent_state.dart';
import '../agents/persona.dart';
import '../app/providers.dart';
import '../data/export_service.dart';
import 'privacy_screen.dart';
import '../data/sync_service.dart';
import '../app/theme.dart';
import 'widgets.dart';
import '../domain/models.dart';

/// When (if ever) the learner asked for deletion — drives the grace-period UI.
final deletionRequestedProvider = FutureProvider<DateTime?>((ref) async {
  try {
    return await ref.read(srsProvider).deletionRequestedAt();
  } catch (_) {
    return null; // off-device DB
  }
});

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
          const SizedBox(height: 24),
          const _Section(
            title: 'টিউটর · Tutor persona',
            icon: Icons.face_outlined,
            child: _PersonaPicker(),
          ),
          const SizedBox(height: 24),
          // D1: OPTIONAL cloud sync — off by default, offline-first untouched.
          const _Section(
            title: 'ক্লাউড সিঙ্ক · Cloud sync',
            icon: Icons.cloud_outlined,
            child: _CloudSync(),
          ),
          const SizedBox(height: 24),
          // Data autonomy is a NON-NEGOTIABLE (00 §5): one-tap export, instant
          // delete with a 7-day grace, no support ticket — first-class UI.
          const _Section(
            title: 'তোমার ডেটা · Your data',
            icon: Icons.lock_person_outlined,
            child: _DataAutonomy(),
          ),
          const SizedBox(height: 24),
          // E1: privacy policy — one tap away, Bengali-first, honest.
          _Section(
            title: 'গোপনীয়তা · Privacy',
            icon: Icons.shield_outlined,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('গোপনীয়তা নীতি পড়ো'),
              subtitle: const Text('তোমার ডেটা কোথায় থাকে, কী যায়, কী যায় না'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyScreen())),
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
                const SizedBox(height: 8),
                // D-011: KanjiVG attribution (stroke data, CC BY-SA 3.0).
                Text(
                  'Stroke data: KanjiVG © Ulrich Apel, CC BY-SA 3.0',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Persona choice — persisted to app_meta 'persona' and pushed to the agent
/// bus. The learner picks; the agents only ever SUGGEST a switch (04).
class _PersonaPicker extends ConsumerWidget {
  const _PersonaPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(agentBusProvider).persona;
    return Column(children: [
      for (final p in PersonaType.values)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(personaNameBn(p)),
          trailing: selected == p
              ? const Icon(Icons.check_circle, color: Color(0xFF00C853))
              : const Icon(Icons.circle_outlined, color: Colors.white24),
          onTap: () async {
            ref.read(agentBusProvider.notifier).setPersona(p);
            try {
              await ref.read(srsProvider).setMeta('persona', p.name);
            } catch (_) {/* off-device DB */}
          },
        ),
    ]);
  }
}

/// 00 §5 data autonomy: one-tap ZIP export + delete with 7-day grace
/// (request / cancel; purge itself runs from the main() bootstrap check).
/// D1 — opt-in cloud sync toggle. Off by default; the copy makes clear the app
/// works fully offline and data is device-safe (D-001/07).
class _CloudSync extends ConsumerStatefulWidget {
  const _CloudSync();
  @override
  ConsumerState<_CloudSync> createState() => _CloudSyncState();
}

class _CloudSyncState extends ConsumerState<_CloudSync> {
  bool _on = false;
  bool _busy = false;
  String _msg = '';
  DateTime? _last;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final on = await SyncService.instance.isEnabled();
      final last = await SyncService.instance.lastSync();
      if (mounted) setState(() { _on = on; _last = last; });
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() { _busy = true; _msg = ''; });
    if (v) {
      final st = await SyncService.instance.enable(ref.read(srsProvider));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _on = st.state != SyncState.error;
        _last = st.lastSync ?? _last;
        _msg = st.state == SyncState.ok
            ? 'সিঙ্ক চালু — তোমার অগ্রগতি ক্লাউডে ব্যাকআপ হলো।'
            : st.message;
      });
    } else {
      await SyncService.instance.disable();
      if (!mounted) return;
      setState(() { _busy = false; _on = false; _msg = 'সিঙ্ক বন্ধ।'; });
    }
  }

  Future<void> _syncNow() async {
    setState(() { _busy = true; _msg = ''; });
    final st = await SyncService.instance.syncNow(ref.read(srsProvider));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _last = st.lastSync ?? _last;
      _msg = st.state == SyncState.ok ? 'সিঙ্ক হলো ✓' : st.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _on,
        onChanged: _busy ? null : _toggle,
        activeThumbColor: BhasagoColors.green,
        title: const Text('ক্লাউডে অগ্রগতি ব্যাকআপ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: const Text(
            'ঐচ্ছিক — ফোন বদলালেও অগ্রগতি থাকবে। অ্যাপ ইন্টারনেট ছাড়াই পুরো চলে।',
            style: TextStyle(fontSize: 11.5, color: BhasagoTheme.muted)),
      ),
      if (_on && !_busy)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _syncNow,
            icon: const Icon(Icons.sync, size: 16),
            label: Text(_last == null
                ? 'এখন সিঙ্ক করো'
                : 'এখন সিঙ্ক করো (শেষ: ${_ago(_last!)})'),
            style: TextButton.styleFrom(foregroundColor: BhasagoColors.green),
          ),
        ),
      if (_busy) const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: BhasagoColors.green)),
      ),
      if (_msg.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_msg, style: const TextStyle(fontSize: 11.5, color: BhasagoTheme.muted)),
        ),
    ]);
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'এইমাত্র';
    if (d.inHours < 1) return '${d.inMinutes} মিনিট আগে';
    if (d.inDays < 1) return '${d.inHours} ঘণ্টা আগে';
    return '${d.inDays} দিন আগে';
  }
}

class _DataAutonomy extends ConsumerWidget {
  const _DataAutonomy();

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requested = ref.watch(deletionRequestedProvider).valueOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.archive_outlined, size: 18),
        label: const Text('সব ডেটা এক্সপোর্ট করো (ZIP)'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final f =
                await ExportService(ref.read(srsProvider)).exportZip();
            messenger.showSnackBar(
                SnackBar(content: Text('এক্সপোর্ট হয়েছে: ${f.path}')));
          } catch (e) {
            messenger.showSnackBar(
                SnackBar(content: Text('এক্সপোর্ট হয়নি: $e')));
          }
        },
      ),
      const SizedBox(height: 10),
      if (requested == null)
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('সব ডেটা মুছে ফেলো (৭ দিনের সময়সীমা)'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: const Color(0xFFF06EB7)),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (dctx) => AlertDialog(
                title: const Text('সব ডেটা মুছে ফেলবে?'),
                content: const Text(
                    '৭ দিন পর সব শেখার ডেটা স্থায়ীভাবে মুছে যাবে। এর মধ্যে যেকোনো সময় বাতিল করা যায়।'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dctx, false),
                      child: const Text('থাক')),
                  TextButton(
                      onPressed: () => Navigator.pop(dctx, true),
                      child: const Text('মুছে ফেলো')),
                ],
              ),
            );
            if (ok == true) {
              try {
                await ref.read(srsProvider).requestDeletion();
              } catch (_) {}
              ref.invalidate(deletionRequestedProvider);
            }
          },
        )
      else ...[
        Text(
          'মুছে ফেলার অনুরোধ: ${_date(requested)} — ${_date(requested.add(const Duration(days: 7)))} তারিখে স্থায়ীভাবে মুছে যাবে।',
          style: const TextStyle(fontSize: 12, color: Color(0xFFF06EB7)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          onPressed: () async {
            try {
              await ref.read(srsProvider).cancelDeletion();
            } catch (_) {}
            ref.invalidate(deletionRequestedProvider);
          },
          child: const Text('বাতিল করো — ডেটা রাখো'),
        ),
      ],
    ]);
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
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
