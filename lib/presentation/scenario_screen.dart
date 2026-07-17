// Roleplay screen (C2) — the sensei plays the NPC (🏪 দোকানদার / 🩺 ডাক্তার /
// 💼 interviewer); the learner answers by choosing among VERIFIED taught lines.
// Every line has bundled audio. D-001: any choice is fine, quit/restart free,
// no scoring — completing the conversation IS the win.
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/audio_service.dart';
import '../data/scenario_repository.dart';

const _green = Color(0xFF35E065);

class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key, required this.scenario});
  final Scenario scenario;
  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _Line {
  const _Line(this.mine, this.jp, this.bn);
  final bool mine;
  final String jp, bn;
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final List<_Line> _log = [];
  late ScenarioNode _node;

  @override
  void initState() {
    super.initState();
    _enter(widget.scenario.start, first: true);
  }

  void _enter(ScenarioNode n, {bool first = false}) {
    _node = n;
    _log.add(_Line(false, n.npcJp, n.npcBn));
    AudioService.instance.play('${widget.scenario.id}_${n.id}');
    if (!first) setState(() {});
  }

  void _choose(ScenarioChoice c) {
    setState(() => _log.add(_Line(true, c.jp, c.bn)));
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _enter(widget.scenario.node(c.next));
    });
  }

  void _restart() => setState(() {
        _log.clear();
        _enter(widget.scenario.start, first: true);
      });

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    return Scaffold(
      backgroundColor: BhasagoTheme.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 20, color: BhasagoTheme.muted)),
              Text(s.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.titleBn,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('সেনসেই এখন ${s.npcBn} 🎭',
                      style: const TextStyle(color: BhasagoTheme.muted, fontSize: 11)),
                ]),
              ),
              IconButton(
                  tooltip: 'আবার শুরু',
                  onPressed: _restart,
                  icon: const Icon(Icons.replay, size: 19, color: BhasagoTheme.muted)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BhasagoTheme.outline)),
                  child: Text('🎬 ${s.settingBn}',
                      style: const TextStyle(
                          fontSize: 12, height: 1.5, color: BhasagoTheme.muted)),
                ),
                for (final l in _log) _bubble(l),
                if (_node.isEnd) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _green, width: 1.4)),
                    child: Text(_node.endBn,
                        style: const TextStyle(fontSize: 12.5, height: 1.6)),
                  ),
                ],
              ],
            ),
          ),
          // The learner's verified choices (any is fine — D-001).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _node.isEnd
                ? FilledButton(
                    onPressed: _restart,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: _green,
                        foregroundColor: const Color(0xFF111111),
                        shape: const StadiumBorder()),
                    child: const Text('🎭 আবার খেলি',
                        style: TextStyle(fontWeight: FontWeight.w800)))
                : Column(children: [
                    for (final c in _node.choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: () => _choose(c),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: BhasagoTheme.text,
                              side: const BorderSide(
                                  color: BhasagoTheme.pillOutline, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: Column(children: [
                            Text(c.jp,
                                style: const TextStyle(
                                    fontFamily: 'ZenKakuGothicNew',
                                    fontSize: 14.5, fontWeight: FontWeight.w800)),
                            Text(c.bn,
                                style: const TextStyle(
                                    fontSize: 10.5, color: BhasagoTheme.muted)),
                          ]),
                        ),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(_Line l) => Align(
        alignment: l.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: l.mine ? _green : const Color(0xFF1A1A1A),
            border: l.mine ? null : Border.all(color: BhasagoTheme.outline),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(l.mine ? 16 : 4),
              bottomRight: Radius.circular(l.mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                l.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(l.jp,
                  style: TextStyle(
                      fontFamily: 'ZenKakuGothicNew',
                      fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.4,
                      color: l.mine ? const Color(0xFF111111) : BhasagoTheme.text)),
              Text(l.bn,
                  style: TextStyle(
                      fontSize: 10.5, height: 1.4,
                      color: l.mine
                          ? const Color(0xB3111111)
                          : BhasagoTheme.muted)),
            ],
          ),
        ),
      );
}
