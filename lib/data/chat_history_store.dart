// Page-specific sensei chat history (offline, no network). Each chat surface
// passes a stable `chatKey` (e.g. 'lesson:<id>', 'kana:か', 'explain:<text>')
// and its conversation is saved/restored under that key — so a chat done on a
// specific page stays on that page. Stored in SharedPreferences as JSON;
// capped so it can't grow without bound. Purely a UX convenience: it holds the
// explanatory conversation, never grades or verified content (D-001).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChatTurn {
  const ChatTurn(this.mine, this.text);
  final bool mine;
  final String text;
  Map<String, dynamic> toJson() => {'m': mine, 't': text};
  static ChatTurn fromJson(Map j) =>
      ChatTurn(j['m'] == true, (j['t'] ?? '').toString());
}

class ChatHistoryStore {
  ChatHistoryStore._();
  static final ChatHistoryStore instance = ChatHistoryStore._();

  static const _prefix = 'chat_hist_';
  static const _maxTurns = 40; // keep the most recent 40 turns per surface

  String _k(String key) => '$_prefix$key';

  /// Restore the conversation for [key] in chronological order (oldest first).
  Future<List<ChatTurn>> load(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k(key));
      if (raw == null) return const [];
      final list = json.decode(raw) as List;
      return list
          .map((e) => ChatTurn.fromJson(e as Map))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Persist [turns] (chronological). Trims to the most recent [_maxTurns].
  Future<void> save(String key, List<ChatTurn> turns) async {
    try {
      final p = await SharedPreferences.getInstance();
      final trimmed = turns.length > _maxTurns
          ? turns.sublist(turns.length - _maxTurns)
          : turns;
      await p.setString(
          _k(key), json.encode(trimmed.map((t) => t.toJson()).toList()));
    } catch (_) {/* storage unavailable — chat just stays in-memory */}
  }

  Future<void> clear(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_k(key));
    } catch (_) {}
  }
}
