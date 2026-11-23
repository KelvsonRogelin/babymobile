class AppSettings {
  const AppSettings({
    required this.quality,
    required this.maxDurationSec,
  });

  final String quality;
  final int maxDurationSec;

  factory AppSettings.defaults() {
    return const AppSettings(quality: 'mid', maxDurationSec: 30);
  }

  AppSettings copyWith({
    String? quality,
    int? maxDurationSec,
  }) {
    return AppSettings(
      quality: quality ?? this.quality,
      maxDurationSec: maxDurationSec ?? this.maxDurationSec,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'maxDurationSec': maxDurationSec,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      quality: (json['quality'] as String?) ?? 'mid',
      maxDurationSec: (json['maxDurationSec'] as num?)?.toInt() ?? 30,
    );
  }
}
