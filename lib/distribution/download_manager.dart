import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'pack_models.dart';
import 'pack_verifier.dart';

class DownloadManager {
  final Dio _dio = Dio();
  static const int _chunkSize = 4 * 1024 * 1024;

  Future<void> downloadPack(ContentPack pack, PackDownloadState state, Function(int, int) onProgress) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/packs/${pack.id}_v${pack.version}.pack';
    final file = File(filePath);
    await file.create(recursive: true);

    state.status = 'downloading';
    for (int i = state.chunksDone; i < pack.chunks; i++) {
      final start = i * _chunkSize;
      final end = (i + 1 == pack.chunks) ? pack.sizeBytes - 1 : start + _chunkSize - 1;
      final response = await _dio.get(
        pack.url,
        options: Options(
          headers: {'Range': 'bytes=$start-$end'},
          responseType: ResponseType.bytes,
        ),
      );
      await file.writeAsBytes(response.data as List<int>, mode: FileMode.append);
      state.chunksDone = i + 1;
      state.bytesDone += (response.data as List<int>).length;
      onProgress(state.chunksDone, pack.chunks);
    }

    final bytes = await file.readAsBytes();
    if (!PackVerifier.verifySha256(bytes, pack.sha256)) {
      await file.delete();
      throw Exception('Pack verification failed');
    }
    state.status = 'completed';
  }
}
