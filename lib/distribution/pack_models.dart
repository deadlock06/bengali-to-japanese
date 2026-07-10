class ContentPack {
  final String id;
  final int version;
  final int tier;
  final int sizeBytes;
  final String sha256;
  final int chunks;
  final List<String> dependsOn;
  final String url;
  final String titleBn;

  ContentPack({required this.id, required this.version, required this.tier, required this.sizeBytes, required this.sha256, required this.chunks, required this.dependsOn, required this.url, required this.titleBn});

  factory ContentPack.fromJson(Map<String, dynamic> json) => ContentPack(
    id: json['id'],
    version: json['version'],
    tier: json['tier'],
    sizeBytes: json['size_bytes'],
    sha256: json['sha256'],
    chunks: json['chunks'],
    dependsOn: List<String>.from(json['depends_on'] ?? []),
    url: json['url'],
    titleBn: json['title_bn'],
  );
}

class PackDownloadState {
  final String packId;
  final int targetVersion;
  final int chunksTotal;
  int chunksDone;
  int bytesDone;
  String status;
  String networkPolicy;

  PackDownloadState({required this.packId, required this.targetVersion, required this.chunksTotal, this.chunksDone = 0, this.bytesDone = 0, this.status = 'queued', this.networkPolicy = 'wifi_only'});
}
