import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'pack_models.dart';
import 'pack_verifier.dart';

class P2pImportManager {
  Future<bool> importPackFromFile(String sourcePath, ContentPack manifest) async {
    final file = File(sourcePath);
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();
    if (!PackVerifier.verifySha256(bytes, manifest.sha256)) return false;

    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/packs/${manifest.id}_v${manifest.version}.pack';
    await file.copy(destPath);
    return true;
  }
}
