import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/video_entry.dart';
import '../utils/dialer.dart';

class AuthRecord {
  const AuthRecord({
    required this.passwordHash,
    required this.salt,
  });

  final String passwordHash;
  final String salt;
}

class AppStorage {
  static const _authKey = 'toyphone.auth';
  static const _settingsKey = 'toyphone.settings';
  static const _videosKey = 'toyphone.videos';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<AuthRecord?> getAuth() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_authKey);
    if (raw == null || raw.isEmpty) return null;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AuthRecord(
      passwordHash: json['passwordHash'] as String? ?? '',
      salt: json['salt'] as String? ?? '',
    );
  }

  Future<void> saveAuth(AuthRecord record) async {
    final prefs = await _prefs;
    await prefs.setString(
      _authKey,
      jsonEncode({
        'passwordHash': record.passwordHash,
        'salt': record.salt,
      }),
    );
  }

  Future<AppSettings> getSettings() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return AppSettings.defaults();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<VideoEntry>> listVideos() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_videosKey);
    if (raw == null || raw.isEmpty) return <VideoEntry>[];

    final data = jsonDecode(raw) as List<dynamic>;
    final entries = data
        .map((item) => VideoEntry.fromJson(item as Map<String, dynamic>))
        .where((entry) => entry.filePath.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return entries;
  }

  Future<void> saveVideos(List<VideoEntry> videos) async {
    final prefs = await _prefs;
    final encoded = videos.map((video) => video.toJson()).toList();
    await prefs.setString(_videosKey, jsonEncode(encoded));
  }

  Future<Directory> _videosDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'videos'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> importVideoFile(File sourceFile) async {
    final directory = await _videosDirectory();
    final extension = p.extension(sourceFile.path);
    final fileName = '${_makeId()}${extension.isNotEmpty ? extension : '.mp4'}';
    final target = File(p.join(directory.path, fileName));
    await sourceFile.copy(target.path);
    return target.path;
  }

  Future<void> deleteVideoFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String makeVideoId() => _makeId();

  String normalizeLinkedPhoneNumber(String? value) {
    return sanitizeLinkedPhoneNumber(value) ?? '';
  }

  String _makeId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(255));
    final suffix = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
