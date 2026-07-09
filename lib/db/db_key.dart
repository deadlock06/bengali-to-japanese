// SQLCipher passphrase provisioning. The 256-bit key is generated once per
// install with a CSPRNG and persisted in OS-backed secure storage (Android
// Keystore / iOS Keychain). It never leaves the device and is never logged.
// (T-101 / 07 security — user data encrypted at rest.)

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DbKey {
  static const _storageKey = 'sensei_db_key_v1';

  final FlutterSecureStorage _storage;

  DbKey({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Returns the DB passphrase, minting and storing one on first run.
  Future<String> obtain() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = _generate();
    await _storage.write(key: _storageKey, value: fresh);
    return fresh;
  }

  static String _generate() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes); // 256-bit key (~43 chars)
  }
}
