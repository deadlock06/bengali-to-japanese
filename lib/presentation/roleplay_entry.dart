// Speak-tab entry to the roleplay scenarios (C2) — the "conversation corner":
// pick a scene, the sensei plays the other person. All lines verified.
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/scenario_repository.dart';
import 'scenario_screen.dart';

class RoleplayEntryCard extends StatelessWidget {
  const RoleplayEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Scenario>>(
      future: ScenarioRepository.load(),
      builder: (context, snap) {
        final list = snap.data;
        if (list == null) return const SizedBox(height: 4);
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: BhasagoTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF35E065), width: 1.2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎭 রোলপ্লে — সেনসেইয়ের সাথে সত্যিকারের কথোপকথন',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            const Text('সব লাইন তোমার শেখা — বেছে বেছে কথা চালাও',
                style: TextStyle(color: BhasagoTheme.muted, fontSize: 11)),
            const SizedBox(height: 10),
            Row(children: [
              for (final s in list) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ScenarioScreen(scenario: s))),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        foregroundColor: BhasagoTheme.text,
                        side: const BorderSide(
                            color: BhasagoTheme.pillOutline, width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 18)),
                      Text(s.titleBn,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                if (s != list.last) const SizedBox(width: 8),
              ],
            ]),
          ]),
        );
      },
    );
  }
}
