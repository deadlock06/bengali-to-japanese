// Scenario/roleplay trees (C2, 13_MASTER_VISION stage 7) — VERIFIED scripted
// dialogues; the sensei plays the other role. Deterministic: the tree IS the
// content, the LLM authors nothing. D-001: every choice is a fine choice —
// branches steer, never punish.
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ScenarioChoice {
  const ScenarioChoice({required this.jp, required this.bn, required this.next});
  final String jp, bn, next;
  static ScenarioChoice fromJson(Map j) => ScenarioChoice(
      jp: j['jp'] as String, bn: j['bn'] as String, next: j['next'] as String);
}

class ScenarioNode {
  const ScenarioNode(
      {required this.id, required this.npcJp, required this.npcBn,
       this.choices = const [], this.endBn = ''});
  final String id, npcJp, npcBn, endBn;
  final List<ScenarioChoice> choices;
  bool get isEnd => endBn.isNotEmpty;
  static ScenarioNode fromJson(Map j) => ScenarioNode(
        id: j['id'] as String,
        npcJp: j['npc_jp'] as String,
        npcBn: j['npc_bn'] as String,
        choices: ((j['choices'] as List?) ?? const [])
            .map((c) => ScenarioChoice.fromJson(c as Map))
            .toList(),
        endBn: (j['end_bn'] ?? '') as String,
      );
}

class Scenario {
  const Scenario(
      {required this.id, required this.titleBn, required this.npcBn,
       required this.emoji, required this.settingBn, required this.nodes});
  final String id, titleBn, npcBn, emoji, settingBn;
  final List<ScenarioNode> nodes;
  ScenarioNode node(String id) => nodes.firstWhere((n) => n.id == id);
  ScenarioNode get start => nodes.first;

  static Scenario fromJson(Map j) {
    assert(j['verified'] == true, 'Refusing unverified scenario ${j['id']}');
    return Scenario(
      id: j['id'] as String,
      titleBn: (j['title'] as Map)['bn'] as String,
      npcBn: (j['npc'] as Map)['bn'] as String,
      emoji: (j['npc'] as Map)['emoji'] as String,
      settingBn: j['setting_bn'] as String,
      nodes: (j['nodes'] as List)
          .map((n) => ScenarioNode.fromJson(n as Map))
          .toList(),
    );
  }
}

class ScenarioRepository {
  static const files = [
    'assets/content/scenario_konbini.json',
    'assets/content/scenario_clinic.json',
    'assets/content/scenario_interview.json',
  ];

  static Future<List<Scenario>> load() async {
    final out = <Scenario>[];
    for (final f in files) {
      out.add(Scenario.fromJson(
          json.decode(await rootBundle.loadString(f)) as Map));
    }
    return out;
  }
}
