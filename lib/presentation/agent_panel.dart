// AgentPanel — the visible face of the four-agent system inside a lesson.
// Renders: psych-state accent strip + Bengali rationale (explainability),
// a dismissible session advice banner, and the Scaffold agent's help offer.
//
// Invariants (01/09): everything here is a RECOMMENDATION. Every banner has
// an always-enabled dismiss/continue; nothing locks input or hides Skip.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agents/agent_state.dart';
import '../app/providers.dart';

/// 09 §state colors: FLOW green · STRUGGLE warm · BURNOUT calm blue ·
/// BOREDOM playful purple · calibrating neutral.
Color psychColor(PsychState s) => switch (s) {
      PsychState.calibrating => const Color(0xFF6B7280),
      PsychState.flow => const Color(0xFF00C853),
      PsychState.struggle => const Color(0xFFFF6D00),
      PsychState.burnout => const Color(0xFF2979FF),
      PsychState.boredom => const Color(0xFFAA00FF),
    };

class AgentPanel extends ConsumerStatefulWidget {
  /// Called when the learner accepts a hint/help offer (opens the hint UI).
  final VoidCallback onAcceptHint;
  const AgentPanel({super.key, required this.onAcceptHint});

  @override
  ConsumerState<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends ConsumerState<AgentPanel> {
  bool _adviceDismissed = false;
  AdviceKind? _dismissedKind;

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(agentBusProvider);
    final color = psychColor(agent.psych);

    // A new kind of advice re-arms the banner; dismissing sticks per kind.
    if (_dismissedKind != agent.advice.kind) _adviceDismissed = false;

    final showAdvice = agent.advice.kind != AdviceKind.continueSession &&
        !_adviceDismissed;
    final offer = agent.scaffold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Psych strip + one-line Bengali rationale (always explainable — 04).
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (agent.rationaleBn.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              agent.rationaleBn,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: .9)),
            ),
          ),
        if (showAdvice) _adviceBanner(agent.advice, color),
        if (offer != null) _scaffoldOffer(offer),
      ],
    );
  }

  Widget _adviceBanner(SessionAdvice advice, Color color) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: color.withValues(alpha: .12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(
            advice.kind == AdviceKind.shortBreak
                ? Icons.self_improvement
                : Icons.tips_and_updates_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(advice.messageBn, style: const TextStyle(fontSize: 12)),
          ),
          // Continuing is ALWAYS allowed — this only hides the banner.
          TextButton(
            onPressed: () => setState(() {
              _adviceDismissed = true;
              _dismissedKind = advice.kind;
            }),
            child: const Text('ঠিক আছে', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _scaffoldOffer(ScaffoldOffer offer) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: const Color(0xFF1A2230),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          const Icon(Icons.support_agent, size: 18, color: Color(0xFFFFC400)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(offer.promptBn, style: const TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              ref.read(agentBusProvider.notifier).dismissScaffold();
              widget.onAcceptHint();
            },
            child: const Text('হ্যাঁ, দেখাও', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () =>
                ref.read(agentBusProvider.notifier).dismissScaffold(),
            child: const Text('না, থাক', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}
