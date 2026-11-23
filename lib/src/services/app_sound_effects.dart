import 'dart:async';

import 'package:flutter/services.dart';

/// Efeitos sonoros do telefone de brinquedo.
///
/// No Android os sons são gerados nativamente pelo `ToneGenerator`, então não
/// é preciso empacotar arquivos de áudio nem adicionar dependências. Nas
/// demais plataformas caímos nos sons do sistema.
class AppSoundEffects {
  static const MethodChannel _channel = MethodChannel(
    'babymodile/sound_effects',
  );

  static Timer? _ringingTimer;

  /// Clique curto e suave: botões, cards e abertura de telas.
  static void tap() {
    _play(
      'tap',
      durationMs: 90,
      haptic: HapticFeedback.lightImpact,
      fallback: SystemSoundType.click,
    );
  }

  /// Tom DTMF da tecla discada (o "barulhinho" de telefone de verdade).
  static void dialKey(String key) {
    unawaited(_playDialKeyAsync(key));
  }

  /// Apagar o último número digitado.
  static void erase() {
    _play(
      'erase',
      durationMs: 90,
      haptic: HapticFeedback.selectionClick,
      fallback: SystemSoundType.click,
    );
  }

  /// Início da ligação: tom de discagem.
  static void callStart() {
    _play('dialing', durationMs: 500, fallback: SystemSoundType.click);
  }

  /// "Trim... trim...": fica repetindo enquanto a chamada é completada.
  static void startRinging() {
    stopRinging();
    ringback();
    _ringingTimer = Timer.periodic(
      const Duration(milliseconds: 1100),
      (_) => ringback(),
    );
  }

  /// Para o "trim... trim..." (atendeu, encerrou ou saiu da tela).
  static void stopRinging() {
    _ringingTimer?.cancel();
    _ringingTimer = null;
    _stopNativeTone();
  }

  /// Um único toque do "trim... trim...".
  static void ringback() {
    _play('ringback', durationMs: 900, fallback: SystemSoundType.click);
  }

  /// A pessoa atendeu: som de chamada conectada.
  static void connected() {
    _play(
      'connected',
      durationMs: 260,
      haptic: HapticFeedback.mediumImpact,
      fallback: SystemSoundType.click,
    );
  }

  static void success() {
    _play(
      'success',
      durationMs: 260,
      haptic: HapticFeedback.mediumImpact,
      fallback: SystemSoundType.click,
    );
  }

  static void error() {
    _play(
      'error',
      durationMs: 320,
      haptic: HapticFeedback.heavyImpact,
      fallback: SystemSoundType.alert,
    );
  }

  static void hangUp() {
    _play(
      'hangUp',
      durationMs: 400,
      haptic: HapticFeedback.mediumImpact,
      fallback: SystemSoundType.alert,
    );
  }

  static void _play(
    String sound, {
    int durationMs = 160,
    Future<void> Function()? haptic,
    SystemSoundType? fallback,
  }) {
    unawaited(_playAsync(sound, durationMs, haptic, fallback));
  }

  static Future<void> _playAsync(
    String sound,
    int durationMs,
    Future<void> Function()? haptic,
    SystemSoundType? fallback,
  ) async {
    var played = false;

    try {
      played =
          await _channel.invokeMethod<bool>('play', {
            'sound': sound,
            'durationMs': durationMs,
          }) ??
          false;
    } catch (_) {}

    if (!played && fallback != null) {
      try {
        await SystemSound.play(fallback);
      } catch (_) {}
    }

    if (haptic != null) {
      try {
        await haptic();
      } catch (_) {}
    }
  }

  static Future<void> _playDialKeyAsync(String key) async {
    var played = false;

    try {
      played =
          await _channel.invokeMethod<bool>('playDialKey', {'key': key}) ??
          false;
    } catch (_) {}

    if (!played) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }

    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void _stopNativeTone() {
    unawaited(_stopNativeToneAsync());
  }

  static Future<void> _stopNativeToneAsync() async {
    try {
      await _channel.invokeMethod<bool>('stop');
    } catch (_) {}
  }
}
