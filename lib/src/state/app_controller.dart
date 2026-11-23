import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/video_entry.dart';
import '../services/app_storage.dart';
import '../utils/dialer.dart';

enum AppView { booting, onboarding, kid, parentsLogin, parentsDashboard }

class AppController extends ChangeNotifier {
  AppController({required AppStorage storage}) : _storage = storage;

  final AppStorage _storage;

  AppView _view = AppView.booting;
  AppSettings _settings = AppSettings.defaults();
  List<VideoEntry> _videos = const [];
  bool _hasPassword = false;

  AppView get view => _view;
  AppSettings get settings => _settings;
  List<VideoEntry> get videos => List.unmodifiable(_videos);
  bool get hasPassword => _hasPassword;

  int get activeCount =>
      _videos.where((video) => video.status == VideoStatus.active).length;
  int get linkedCount => _videos
      .where(
        (video) =>
            video.status == VideoStatus.active &&
            video.linkedPhoneNumber != null,
      )
      .length;

  Future<void> bootstrap() async {
    _view = AppView.booting;
    notifyListeners();

    final auth = await _storage.getAuth();
    _settings = await _storage.getSettings();
    _videos = await _storage.listVideos();

    _hasPassword = auth != null;
    // O app sempre abre no telefone da criança. A Área dos Pais só é
    // acessada por um clique longo na engrenagem, que sempre pede a senha.
    _view = AppView.kid;
    notifyListeners();
  }

  Future<void> createPassword(String password) async {
    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    await _storage.saveAuth(AuthRecord(passwordHash: passwordHash, salt: salt));
    await _storage.saveSettings(_settings);
    _hasPassword = true;
    // Depois de criar a senha no primeiro acesso, já abre a gestão de mídias.
    _view = AppView.parentsDashboard;
    notifyListeners();
  }

  Future<bool> loginParents(String password) async {
    final auth = await _storage.getAuth();
    if (auth == null) {
      _hasPassword = false;
      _view = AppView.onboarding;
      notifyListeners();
      return false;
    }

    final ok = _hashPassword(password, auth.salt) == auth.passwordHash;
    if (!ok) return false;

    _view = AppView.parentsDashboard;
    notifyListeners();
    return true;
  }

  void openParents() {
    // Primeiro acesso: ainda não existe senha, então pede o cadastro dela.
    // Nas próximas entradas, sempre pede a senha de supervisão.
    _view = _hasPassword ? AppView.parentsLogin : AppView.onboarding;
    notifyListeners();
  }

  void closeParents() {
    _view = AppView.kid;
    notifyListeners();
  }

  Future<void> refreshVideos() async {
    _videos = await _storage.listVideos();
    notifyListeners();
  }

  Future<void> savePickedVideo({
    required File sourceFile,
    required String title,
    required Duration duration,
    required String avatarId,
    String? linkedPhoneNumber,
  }) async {
    final normalizedLinkedNumber = sanitizeLinkedPhoneNumber(linkedPhoneNumber);
    if (linkedPhoneNumber != null &&
        linkedPhoneNumber.trim().isNotEmpty &&
        normalizedLinkedNumber == null) {
      throw Exception('O número especial precisa ter pelo menos 3 dígitos.');
    }

    _ensureLinkedNumberAvailable(normalizedLinkedNumber, null);

    final copiedPath = await _storage.importVideoFile(sourceFile);
    final now = DateTime.now();
    final stat = await File(copiedPath).stat();
    final extension = sourceFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'mov' ? 'video/quicktime' : 'video/mp4';

    final entry = VideoEntry(
      id: _storage.makeVideoId(),
      title: title.trim().isEmpty ? 'Vídeo da família' : title.trim(),
      avatarId: avatarId,
      linkedPhoneNumber: normalizedLinkedNumber,
      status: VideoStatus.active,
      createdAt: now,
      updatedAt: now,
      filePath: copiedPath,
      mimeType: mimeType,
      durationMs: duration.inMilliseconds,
      sizeBytes: stat.size,
    );

    final nextVideos = <VideoEntry>[entry, ..._videos];
    await _storage.saveVideos(nextVideos);
    _videos = nextVideos;
    notifyListeners();
  }

  Future<void> updateVideo({
    required String id,
    required String title,
    required VideoStatus status,
    required String avatarId,
    String? linkedPhoneNumber,
  }) async {
    final normalizedLinkedNumber = sanitizeLinkedPhoneNumber(linkedPhoneNumber);
    if (linkedPhoneNumber != null &&
        linkedPhoneNumber.trim().isNotEmpty &&
        normalizedLinkedNumber == null) {
      throw Exception('O número especial precisa ter pelo menos 3 dígitos.');
    }

    _ensureLinkedNumberAvailable(normalizedLinkedNumber, id);

    final index = _videos.indexWhere((video) => video.id == id);
    if (index == -1) throw Exception('Vídeo não encontrado.');

    final current = _videos[index];
    final updated = VideoEntry(
      id: current.id,
      title: title.trim().isEmpty ? current.title : title.trim(),
      avatarId: avatarId,
      linkedPhoneNumber: normalizedLinkedNumber,
      status: status,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      filePath: current.filePath,
      mimeType: current.mimeType,
      durationMs: current.durationMs,
      sizeBytes: current.sizeBytes,
    );

    final nextVideos = [..._videos];
    nextVideos[index] = updated;
    nextVideos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _storage.saveVideos(nextVideos);
    _videos = nextVideos;
    notifyListeners();
  }

  Future<void> deleteVideo(String id) async {
    final index = _videos.indexWhere((video) => video.id == id);
    if (index == -1) return;

    final current = _videos[index];
    await _storage.deleteVideoFile(current.filePath);
    final nextVideos = [..._videos]..removeAt(index);
    await _storage.saveVideos(nextVideos);
    _videos = nextVideos;
    notifyListeners();
  }

  void _ensureLinkedNumberAvailable(
    String? linkedPhoneNumber,
    String? currentId,
  ) {
    if (linkedPhoneNumber == null) return;

    final duplicate = _videos.any(
      (video) =>
          video.linkedPhoneNumber == linkedPhoneNumber && video.id != currentId,
    );
    if (duplicate) {
      throw Exception('Esse número já está ligado a outro vídeo.');
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(255));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }
}
