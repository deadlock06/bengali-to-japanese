// Wraps a reading surface so text is selectable, and shows a floating
// "ব্যাখ্যা করো" button whenever text is selected → the sensei explains it
// (AI dictionary) in a popup, with Bengali audio.
//
// Uses a floating button (not the selection toolbar) because on web the
// browser's own context menu overrides Flutter's custom toolbar — the floating
// button works reliably on web AND mobile.
import 'package:flutter/material.dart';

import 'explain_sheet.dart';

/// Root navigator key (kept for callers that already reference it).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SelectionExplain extends StatefulWidget {
  const SelectionExplain({super.key, required this.child});
  final Widget child;
  @override
  State<SelectionExplain> createState() => _SelectionExplainState();
}

class _SelectionExplainState extends State<SelectionExplain> {
  String _selected = '';

  void _open() {
    final t = _selected.trim();
    if (t.isNotEmpty) showExplainSheet(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SelectionArea(
        onSelectionChanged: (c) {
          final t = c?.plainText ?? '';
          if (t != _selected) setState(() => _selected = t);
        },
        // Keep a toolbar 'ব্যাখ্যা' too where it works (mobile long-press).
        contextMenuBuilder: (ctx, state) => AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ...state.contextMenuButtonItems,
            if (_selected.trim().isNotEmpty)
              ContextMenuButtonItem(
                  label: 'ব্যাখ্যা',
                  onPressed: () { state.hideToolbar(); _open(); }),
          ],
        ),
        child: widget.child,
      ),
      // Floating explain button — appears while text is selected.
      if (_selected.trim().isNotEmpty)
        Positioned(
          left: 16, right: 16, bottom: 20,
          child: Center(
            child: Material(
              color: const Color(0xFF4D7DF7),
              borderRadius: BorderRadius.circular(999),
              elevation: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _open,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF111111)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _selected.trim().length > 18
                            ? '「${_selected.trim().substring(0, 18)}…」 ব্যাখ্যা'
                            : '「${_selected.trim()}」 ব্যাখ্যা করো',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
