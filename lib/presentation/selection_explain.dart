// Wraps a reading surface: text is selectable, and a persistent SENSEI button
// floats in the corner. Tap it → the sensei explains whatever you've SELECTED
// or COPIED (clipboard) — a popup where he teaches it + reads the Bengali aloud.
//
// Uses a tap-on-sensei trigger (not the selection toolbar) because on web the
// browser's own menu overrides Flutter's toolbar. This works everywhere: select
// or copy any text, then tap the sensei.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/curriculum_service.dart';
import 'explain_sheet.dart';
import 'sensei_avatar.dart';

/// Root navigator key (kept for callers that reference it).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SelectionExplain extends ConsumerStatefulWidget {
  const SelectionExplain({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SelectionExplain> createState() => _SelectionExplainState();
}

class _SelectionExplainState extends ConsumerState<SelectionExplain> {
  String _captured = ''; // last non-empty selection (survives the tap)
  bool _visible = false;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _onSelection(String t) {
    final s = t.trim();
    if (s.isNotEmpty) {
      _hide?.cancel();
      if (!_visible || _captured != s) {
        setState(() {
          _captured = s;
          _visible = true;
        });
      }
    } else {
      // Selection cleared — likely a tap. Keep the sensei briefly so the tap
      // lands (tapping the button itself clears the selection).
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  Future<void> _askSensei() async {
    _hide?.cancel();
    var t = _captured.trim();
    if (t.isEmpty) {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      t = clip?.text?.trim() ?? '';
    }
    if (!mounted) return;
    setState(() => _visible = false);
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('আগে একটা শব্দ বা বাক্য select করো — তারপর সেনসেই বুঝিয়ে দেবে।'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    if (t.length > 400) t = t.substring(0, 400);
    showExplainSheet(context, t, curriculumHint: _curriculumHint());
  }

  /// Ties the explanation to the learner's live curriculum: the unit they're
  /// on now. Empty when the ontology isn't loaded (off-device / early).
  String _curriculumHint() {
    final units = ref.read(curriculumProvider).valueOrNull;
    if (units == null) return '';
    for (final u in units) {
      if (u.state == UnitProgress.current) {
        final title = u.titleBn.trim();
        if (title.isEmpty) return '';
        return 'প্রসঙ্গ: শিক্ষার্থী এখন কোর্সের "$title" (${u.level}) ইউনিটে আছে — '
            'পারলে ব্যাখ্যাটা সেই লেভেলের সাথে মিলিয়ে দাও।';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SelectionArea(
        onSelectionChanged: (c) => _onSelection(c?.plainText ?? ''),
        child: widget.child,
      ),
      // Sensei appears while text is selected (and for a moment after, so the
      // tap lands). Tap → he explains the captured text.
      if (_visible)
        Positioned(
          right: 16, bottom: 20,
          child: _SenseiFab(onTap: _askSensei),
        ),
    ]);
  }
}

class _SenseiFab extends StatelessWidget {
  const _SenseiFab({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4D7DF7),
      shape: const StadiumBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(8, 6, 14, 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 30, height: 36,
                child: SenseiAvatar(size: 30, accent: Color(0xFFEFE94B))),
            SizedBox(width: 6),
            Text('সেনসেই ব্যাখ্যা',
                style: TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w800, fontSize: 12.5)),
          ]),
        ),
      ),
    );
  }
}
