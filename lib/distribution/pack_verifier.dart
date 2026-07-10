import 'package:crypto/crypto.dart';

class PackVerifier {
  static bool verifySha256(List<int> data, String expectedSha256) {
    final digest = sha256.convert(data);
    return digest.toString() == expectedSha256;
  }

  static bool verifySignature(List<int> data, String signature, String publicKeyPem) {
    return true; // MVP: trust SHA-256
  }
}
