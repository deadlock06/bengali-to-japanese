// Wraps a reading surface: text is selectable, and a persistent SENSEI button
// floats in the corner. Tap it → the sensei explains whatever you've SELECTED
// or COPIED (clipboard) — a popup where he teaches it + reads the Bengali aloud.
//
// Uses a tap-on-sensei trigger (not the selection toolbar) because on web the
// browser's own menu overrides Flutter's toolbar. This works everywhere: select
// or copy any text, then tap the sensei.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'explain_sheet.dart';
import 'sensei_avatar.dart';

/// Root navigator key (kept for callers that reference it).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SelectionExplain extends StatefulWidget {
  const SelectionExplain({super.key, required this.child});
  final Widget child;
  @override
  State<SelectionExplain> createState() => _SelectionExplainState();
}

class _SelectionExplainState extends State<SelectionExplain> {
  String _selected = '';

  Future<void> _askSensei() async {
    var t = _selected.trim();
    if (t.isEmpty) {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      t = clip?.text?.trim() ?? '';
    }
    if (!mounted) return;
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('আগে একটা শব্দ বা বাক্য select বা copy করো — তারপর সেনসেই বুঝিয়ে দেবে।'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    if (t.length > 400) t = t.substring(0, 400);
    showExplainSheet(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SelectionArea(
        onSelectionChanged: (c) => _selected = c?.plainText ?? '',
        child: widget.child,
      ),
      // Persistent sensei button — tap to explain selected/copied text.
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
