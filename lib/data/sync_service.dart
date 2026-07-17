// D1 — OPTIONAL cloud sync (Supabase, D-018 schema). Offline-first is untouched:
// the app fully works with sync OFF; enabling it just backs up progress to the
// cloud so it survives a phone loss / device switch. Anonymous auth (no email,
// no friction). RLS guards every row (auth.uid() = user_id) — the anon key is
// public by design. All failures degrade silently to offline (D-001/07).
//
// This slice syncs an IDEMPOTENT progress snapshot (profile + today's stats);
// per-card delta sync (srs_cards table) is the next increment.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'srs_local.dart';

// Public by design (RLS protects data). Override at build with --dart-define.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://lxulbdnjdgrgtnuqnvke.supabase.co');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4dWxiZG5qZGdyZ3RudXFudmtlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxOTIxMjksImV4cCI6MjA5OTc2ODEyOX0.dKBSdVc1agKTijNLls_V4Ha7WaENIytQ5zs01rAkkxQ');

enum SyncState { off, syncing, ok, error }

class SyncStatus {
  const SyncStatus(this.state, {this.lastSync, this.message = ''});
  final SyncState state;
  final DateTime? lastSync;
  final String message;
}

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _enabledKey = 'sync_enabled';
  static const _lastSyncKey = 'sync_last';
  bool _inited = false;

  /// Best-effort init at startup. Safe to call even if the user never turns
  /// sync on — it only prepares the client; nothing leaves the device yet.
  Future<void> init() async {
    if (_inited) return;
    try {
      // anonKey is the public JWT (a.k.a. publishable key) — correct here.
      // ignore: deprecated_member_use
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
      _inited = true;
    } catch (e) {
      debugPrint('sync init skipped: $e');
    }
  }

  SupabaseClient? get _sb => _inited ? Supabase.instance.client : null;

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  Future<DateTime?> lastSync() async {
    final v = (await SharedPreferences.getInstance()).getString(_lastSyncKey);
    return v == null ? null : DateTime.tryParse(v);
  }

  /// Turn sync ON: anonymous sign-in, then a first push. Returns a status the
  /// Settings screen shows verbatim (honest about what happened).
  Future<SyncStatus> enable(SrsLocal srs) async {
    await init();
    final sb = _sb;
    if (sb == null) {
      return const SyncStatus(SyncState.error,
          message: 'ক্লাউড এখন পৌঁছানো যাচ্ছে না — পরে আবার চেষ্টা করো।');
    }
    try {
      if (sb.auth.currentUser == null) {
        await sb.auth.signInAnonymously();
      }
    } catch (e) {
      // The project must have Anonymous sign-ins enabled (dashboard →
      // Authentication → Providers). Until then, sync just stays off.
      return const SyncStatus(SyncState.error,
          message: 'অ্যানোনিমাস লগইন এখনো চালু হয়নি — সিঙ্ক বন্ধ রইল। '
              '(অফলাইনে সব আগের মতোই চলছে।)');
    }
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, true);
    return syncNow(srs);
  }

  Future<void> disable() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, false);
    try {
      await _sb?.auth.signOut();
    } catch (_) {}
  }

  /// Push an idempotent progress snapshot. Never throws into the UI.
  Future<SyncStatus> syncNow(SrsLocal srs) async {
    if (!await isEnabled()) return const SyncStatus(SyncState.off);
    final sb = _sb;
    final uid = sb?.auth.currentUser?.id;
    if (sb == null || uid == null) {
      return const SyncStatus(SyncState.error, message: 'লগইন নেই — সিঙ্ক বন্ধ।');
    }
    try {
      final completed = await srs.lessonCompletionCount();
      final retained = await srs.retainedWordCount();
      final due = await srs.dueCount();
      final now = DateTime.now();
      final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      await sb.from('profiles').upsert({
        'user_id': uid,
        'last_sync': now.toUtc().toIso8601String(),
        'locale': 'bn',
      });
      await sb.from('daily_stats').upsert({
        'user_id': uid,
        'day': day,
        'xp': retained,      // retained words ≈ mastery signal
        'reviews': completed, // lessons completed (running)
        'minutes': due,       // due backlog snapshot
      });

      final p = await SharedPreferences.getInstance();
      await p.setString(_lastSyncKey, now.toIso8601String());
      return SyncStatus(SyncState.ok, lastSync: now);
    } catch (e) {
      debugPrint('syncNow failed: $e');
      return const SyncStatus(SyncState.error,
          message: 'সিঙ্ক করা গেল না — নেট চেক করে আবার চেষ্টা করো। '
              'তোমার ডেটা ডিভাইসে নিরাপদ আছে।');
    }
  }
}
