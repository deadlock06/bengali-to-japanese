// Wraps the whole app so text ANYWHERE is selectable, and adds a "ব্যাখ্যা"
// (Explain) button to the copy/selection toolbar. Selecting text → tap ব্যাখ্যা
// → the sensei explains it (AI dictionary) in a popup, with Bengali audio.
import 'package:flutter/material.dart';

import 'explain_sheet.dart';

/// Root navigator — lets the selection toolbar (which lives above the app's
/// Navigator) open the explain sheet on the right overlay.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SelectionExplain extends StatefulWidget {
  const SelectionExplain({super.key, required this.child});
  final Widget child;
  @override
  State<SelectionExplain> createState() => _SelectionExplainState();
}

class _SelectionExplainState extends State<SelectionExplain> {
  String _selected = '';

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      onSelectionChanged: (c) => _selected = c?.plainText ?? '',
      contextMenuBuilder: (ctx, state) {
        final sel = _selected.trim();
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ...state.contextMenuButtonItems, // Copy / Select all (unchanged)
            if (sel.isNotEmpty)
              ContextMenuButtonItem(
                label: 'ব্যাখ্যা',
                onPressed: () {
                  state.hideToolbar();
                  final nav = appNavigatorKey.currentContext;
                  if (nav != null) showExplainSheet(nav, sel);
                },
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
