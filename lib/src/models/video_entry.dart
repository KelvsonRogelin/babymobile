enum VideoStatus { active, inactive, blocked }

class VideoEntry {
  const VideoEntry({
    required this.id,
    required this.title,
    required this.avatarId,
    required this.linkedPhoneNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.filePath,
    required this.mimeType,
    required this.durationMs,
    required this.sizeBytes,
  });

  final String id;
  final String title;
  final String avatarId;
  final String? linkedPhoneNumber;
  final VideoStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String filePath;
  final String mimeType;
  final int durationMs;
  final int sizeBytes;

  bool get isPlayable => status == VideoStatus.active;

  VideoEntry copyWith({
    String? title,
    String? avatarId,
    String? linkedPhoneNumber,
    VideoStatus? status,
    DateTime? updatedAt,
    String? filePath,
    String? mimeType,
    int? durationMs,
    int? sizeBytes,
  }) {
    return VideoEntry(
      id: id,
      title: title ?? this.title,
      avatarId: avatarId ?? this.avatarId,
      linkedPhoneNumber: linkedPhoneNumber,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'avatarId': avatarId,
      'linkedPhoneNumber': linkedPhoneNumber,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'filePath': filePath,
      'mimeType': mimeType,
      'durationMs': durationMs,
      'sizeBytes': sizeBytes,
    };
  }

  factory VideoEntry.fromJson(Map<String, dynamic> json) {
    return VideoEntry(
      id: json['id'] as String,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Vídeo da família',
      avatarId: (json['avatarId'] as String?) ?? '',
      linkedPhoneNumber: json['linkedPhoneNumber'] as String?,
      status: VideoStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => VideoStatus.active,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      filePath: json['filePath'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'video/mp4',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
