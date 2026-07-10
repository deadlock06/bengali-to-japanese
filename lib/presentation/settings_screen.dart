// Settings — language, tutor persona, and DATA AUTONOMY (01 constitution):
// one-tap offline export (ZIP) and deletion with a 7-day grace period the
// learner can cancel anytime. No support ticket, no account, no friction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agents/agent_state.dart';
import '../agents/persona.dart';
import '../app/providers.dart';
import '../data/export_service.dart';

/// How long a deletion request stays cancellable before the purge.
const kDeletionGraceDays = 7;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DateTime? _deletionRequestedAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  /// Loads persisted choices and — if a deletion grace period has fully
  /// elapsed — completes the purge the learner asked for.
  Future<void> _loadState() async {
    try {
      final srs = ref.read(srsProvider);
      final requested = await srs.deletionRequestedAt();
      if (requested != null &&
          DateTime.now().difference(requested).inDays >= kDeletionGraceDays) {
        await srs.purgeAllData();
        if (mounted) setState(() => _deletionRequestedAt = null);
        return;
      }
      final persona = await srs.getMeta('persona');
      if (persona != null) {
        final type = PersonaType.values
            .where((p) => p.name == persona)
            .firstOrNull;
        if (type != null) {
          ref.read(agentBusProvider.notifier).setPersona(type);
        }
      }
      if (mounted) setState(() => _deletionRequestedAt = requested);
    } catch (_) {/* device-only DB may be absent off-device */}
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final agent = ref.watch(agentBusProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_deletionRequestedAt != null) _deletionPendingBanner(),
        _section('ভাষা · Language'),
        Card(
          child: RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (v) =>
                ref.read(localeProvider.notifier).state = Locale(v ?? 'bn'),
            child: Column(children: [
              for (final (label, code) in const [
                ('বাংলা (English gloss সহ)', 'bn'),
                ('English', 'en'),
                ('日本語', 'ja'),
              ])
                RadioListTile<String>(title: Text(label), value: code),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _section('তোমার টিউটর · Your tutor'),
        Card(
          child: RadioGroup<PersonaType>(
            groupValue: agent.persona,
            onChanged: (v) {
              if (v == null) return;
              ref.read(agentBusProvider.notifier).setPersona(v);
              // Best-effort persistence; the bus holds it for the session.
              ref
                  .read(srsProvider)
                  .setMeta('persona', v.name)
                  .catchError((_) {});
            },
            child: Column(children: [
              for (final p in PersonaType.values)
                RadioListTile<PersonaType>(
                  title: Text(personaNameBn(p)),
                  subtitle: Text(
                      personaLine(p, PersonaEvent.greeting,
                          psych: PsychState.flow, weekNumber: 2),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  value: p,
                ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _section('তোমার ডেটা · Your data'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('ডেটা এক্সপোর্ট · Export everything (ZIP)'),
              subtitle: const Text('JSON + CSV — এক ট্যাপে, অফলাইনে',
                  style: TextStyle(fontSize: 12)),
              trailing: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _busy ? null : _export,
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFFF6D00)),
              title: const Text('সব ডেটা মুছে ফেলো · Delete all data'),
              subtitle: Text(
                  '$kDeletionGraceDays দিনের মধ্যে মত বদলালে ফিরিয়ে আনা যাবে',
                  style: const TextStyle(fontSize: 12)),
              enabled: _deletionRequestedAt == null,
              onTap: _deletionRequestedAt == null ? _confirmDeletion : null,
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _section('স্বীকৃতি · Attribution'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stroke-order data: KanjiVG',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      '© Ulrich Apel, CC BY-SA 3.0 — kanjivg.tagaini.net\n'
                      'Kana stroke animations derive from KanjiVG path data.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ]),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _deletionPendingBanner() {
    final requested = _deletionRequestedAt!;
    final daysLeft = kDeletionGraceDays -
        DateTime.now().difference(requested).inDays;
    return Card(
      color: const Color(0xFF3A2A12),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Icon(Icons.hourglass_top, color: Color(0xFFFFAB00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                'ডেটা মুছে যাবে $daysLeft দিনের মধ্যে। মত বদলেছ? এক ট্যাপে বাতিল করো।',
                style: const TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(srsProvider).cancelDeletion();
              } catch (_) {}
              if (mounted) setState(() => _deletionRequestedAt = null);
            },
            child: const Text('বাতিল · Cancel'),
          ),
        ]),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final file =
          await ExportService(ref.read(srsProvider)).exportZip();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('এক্সপোর্ট হয়েছে · saved:\n${file.path}'),
        duration: const Duration(seconds: 6),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('এক্সপোর্ট করা গেল না · export failed')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সব ডেটা মুছে ফেলবে?'),
        content: Text(
            'তোমার সব কার্ড, রিভিউ আর অগ্রগতি মুছে যাবে।\n\n'
            '$kDeletionGraceDays দিনের মধ্যে মত বদলালে এখান থেকেই বাতিল করা যাবে। '
            'তার আগে চাইলে ডেটা এক্সপোর্ট করে রেখো।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('থাক · Keep my data')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছে ফেলো · Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(srsProvider).requestDeletion();
      if (mounted) {
        setState(() => _deletionRequestedAt = DateTime.now());
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('অনুরোধ রাখা গেল না · could not request deletion')));
    }
  }
}
