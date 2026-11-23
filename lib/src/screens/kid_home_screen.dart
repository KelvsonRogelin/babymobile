import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video_entry.dart';
import '../services/app_sound_effects.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/device_layout.dart';
import '../utils/dialer.dart';
import '../utils/video_selection.dart';
import '../widgets/baby_mascot.dart';
import '../widgets/contact_avatar_art.dart';
import '../widgets/toy_phone_shell.dart';
import '../widgets/video_player_card.dart';

class KidHomeScreen extends StatefulWidget {
  const KidHomeScreen({super.key});

  @override
  State<KidHomeScreen> createState() => _KidHomeScreenState();
}

class _KidHomeScreenState extends State<KidHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _dialKeys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '0',
    '',
  ];

  /// Cores do teclado: paleta da identidade aplicada em ciclo.
  static const _keyColors = [
    AppTheme.green,
    AppTheme.blue,
    AppTheme.yellow,
    AppTheme.lavender,
    AppTheme.orange,
    AppTheme.green,
    AppTheme.blue,
    AppTheme.yellow,
    AppTheme.lavender,
    Colors.transparent,
    AppTheme.green,
    Colors.transparent,
  ];

  String _dialValue = '';
  String _message = 'Digite um número grandão e aperte ligar.';
  VideoEntry? _currentVideo;
  bool _isWaitingAnswer = false;
  VideoEntry? _pendingVideo;
  Timer? _callDelayTimer;
  Timer? _parentsHoldTimer;

  late final AnimationController _callButtonController;
  late final Animation<double> _callButtonScale;
  late final Animation<double> _callButtonLift;

  bool get _isPlaying => _currentVideo != null;

  @override
  void initState() {
    super.initState();
    _callButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _callButtonScale = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(parent: _callButtonController, curve: Curves.easeInOut),
    );
    _callButtonLift = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _callButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _callDelayTimer?.cancel();
    _parentsHoldTimer?.cancel();
    AppSoundEffects.stopRinging();
    _callButtonController.dispose();
    super.dispose();
  }

  void _pressKey(String value) {
    if (value.isEmpty) return;
    AppSoundEffects.dialKey(value);
    setState(() {
      _dialValue = normalizeDialedNumber('$_dialValue$value');
      if (_dialValue.length > 12) {
        _dialValue = _dialValue.substring(0, 12);
      }
    });
  }

  void _eraseLastKey() {
    AppSoundEffects.erase();
    setState(() {
      if (_dialValue.isNotEmpty) {
        _dialValue = _dialValue.substring(0, _dialValue.length - 1);
      }
    });
  }

  List<VideoEntry> _contactsFor(AppController controller) {
    final contacts =
        controller.videos
            .where(
              (video) =>
                  video.status == VideoStatus.active &&
                  (video.linkedPhoneNumber?.isNotEmpty ?? false),
            )
            .toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
    return contacts;
  }

  void _startParentsAccessHold(AppController controller) {
    _parentsHoldTimer?.cancel();
    setState(() {
      _message = controller.hasPassword
          ? 'Segure a engrenagem por 3 segundos para abrir a área dos pais.'
          : 'Segure a engrenagem por 3 segundos para criar a senha dos pais.';
    });
    _parentsHoldTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      AppSoundEffects.success();
      controller.openParents();
    });
  }

  void _cancelParentsAccessHold() {
    _parentsHoldTimer?.cancel();
  }

  Future<void> _openGallery(AppController controller) async {
    final contacts = _contactsFor(controller);
    if (contacts.isEmpty) {
      AppSoundEffects.error();
      setState(
        () => _message =
            'A galeria ainda está vazia. Peça para um adulto salvar um vídeo com número especial.',
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ContactsGallerySheet(
          contacts: contacts,
          onCall: (entry) {
            Navigator.of(sheetContext).pop();
            _callContact(controller, entry);
          },
        );
      },
    );
  }

  Future<void> _callContact(AppController controller, VideoEntry entry) async {
    final number = entry.linkedPhoneNumber;
    if (number == null || number.isEmpty) return;

    setState(() => _dialValue = number);
    await _handleCall(controller, number: number);
  }

  Future<void> _handleCall(AppController controller, {String? number}) async {
    final target = normalizeDialedNumber(number ?? _dialValue);
    if (!isValidDialedNumber(target)) {
      AppSoundEffects.error();
      setState(() => _message = 'Ops! Digite pelo menos 3 números para ligar.');
      return;
    }

    final chosen = selectVideoForDialedNumber(controller.videos, target);
    if (chosen == null) {
      AppSoundEffects.error();
      setState(
        () => _message =
            'Ainda não tem nenhum vídeo prontinho. Peça para um adulto gravar um recadinho.',
      );
      return;
    }

    final exists = await File(chosen.filePath).exists();
    if (!exists) {
      AppSoundEffects.error();
      setState(
        () => _message =
            'Esse vídeo não está disponível agora. Tente outro depois.',
      );
      return;
    }

    final matched = findVideoForDialedNumber(controller.videos, target);
    AppSoundEffects.callStart();
    AppSoundEffects.startRinging();
    setState(() {
      _dialValue = target;
      _pendingVideo = chosen;
      _isWaitingAnswer = true;
      _message = matched != null
          ? 'Chamando ${formatDialedNumber(target)}... esse número conhece um vídeo especial!'
          : 'Chamando ${formatDialedNumber(target)}... surpresa!';
    });

    _callDelayTimer?.cancel();
    _callDelayTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted || !_isWaitingAnswer || _pendingVideo == null) return;
      AppSoundEffects.stopRinging();
      AppSoundEffects.connected();
      setState(() {
        _currentVideo = _pendingVideo;
        _pendingVideo = null;
        _isWaitingAnswer = false;
        _message = 'Atendeu! Olha o recadinho que chegou.';
      });
    });
  }

  void _hangUp() {
    AppSoundEffects.stopRinging();
    AppSoundEffects.hangUp();
    _callDelayTimer?.cancel();
    setState(() {
      _currentVideo = null;
      _pendingVideo = null;
      _isWaitingAnswer = false;
      _dialValue = '';
      _message = 'Ligação encerrada. Quer ligar de novo?';
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final layout = DeviceLayout.fromContext(context);

    if (_isWaitingAnswer) {
      return Scaffold(
        body: ToyPhoneShell(
          displayLabel: 'CHAMANDO...',
          displayValue: formatDialedNumber(_dialValue),
          displayMessage: _message,
          scrollable: false,
          body: Container(
            decoration: BoxDecoration(
              color: AppTheme.greenSoft,
              borderRadius: BorderRadius.circular(layout.sectionRadius),
            ),
            padding: EdgeInsets.all(layout.size(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(layout.size(28)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.size(18),
                    vertical: layout.size(layout.isCompactHeight ? 18 : 24),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: layout.size(
                          layout.isCompactHeight ? 110 : 140,
                          minScale: 0.9,
                          maxScale: 1.05,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _WaitingBubble(
                              color: AppTheme.blue,
                              size: layout.size(24),
                              delayMs: 0,
                            ),
                            SizedBox(width: layout.size(12)),
                            _WaitingBubble(
                              color: AppTheme.green,
                              size: layout.size(34),
                              delayMs: 200,
                            ),
                            SizedBox(width: layout.size(12)),
                            _WaitingBubble(
                              color: AppTheme.lavender,
                              size: layout.size(24),
                              delayMs: 400,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Trim... trim...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: layout.size(
                            26,
                            minScale: 0.92,
                            maxScale: 1.06,
                          ),
                        ),
                      ),
                      SizedBox(height: layout.size(8)),
                      Text(
                        'Espere um pouquinho para a outra pessoa atender.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: layout.size(
                            14,
                            minScale: 0.95,
                            maxScale: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: layout.size(16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: layout.roundButtonSize,
                    height: layout.roundButtonSize,
                    child: FilledButton(
                      onPressed: _hangUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(layout.size(28)),
                        ),
                      ),
                      child: Icon(
                        Icons.call_end_rounded,
                        color: AppTheme.ink,
                        size: layout.size(36),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isPlaying && _currentVideo != null) {
      return Scaffold(
        body: ToyPhoneShell(
          displayLabel: 'TOCANDO AGORA',
          displayValue: _currentVideo!.title,
          displayMessage: _message,
          scrollable: false,
          body: Container(
            decoration: BoxDecoration(
              color: AppTheme.mintDark,
              borderRadius: BorderRadius.circular(layout.sectionRadius),
            ),
            padding: EdgeInsets.all(layout.size(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(layout.size(26)),
                    ),
                    child: Center(
                      child: VideoPlayerCard(
                        filePath: _currentVideo!.filePath,
                        autoPlay: true,
                        onEnded: _hangUp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: layout.size(12)),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: layout.roundButtonSize,
                    height: layout.roundButtonSize,
                    child: FilledButton(
                      onPressed: _hangUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(layout.size(28)),
                        ),
                      ),
                      child: Icon(
                        Icons.call_end_rounded,
                        color: AppTheme.ink,
                        size: layout.size(36),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: ToyPhoneShell(
        header: _KidHeader(
          onPressStart: () => _startParentsAccessHold(controller),
          onPressEnd: _cancelParentsAccessHold,
        ),
        displayLabel: 'MEU TELEFONE',
        displayValue: formatDialedNumber(_dialValue),
        displayMessage: _message,
        scrollable: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.greenSoft,
                  borderRadius: BorderRadius.circular(layout.sectionRadius),
                ),
                padding: EdgeInsets.all(layout.size(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _KeypadGrid(
                        keys: _dialKeys,
                        colors: _keyColors,
                        onKey: _pressKey,
                      ),
                    ),
                    SizedBox(height: layout.size(14)),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = layout.size(12);
                        // Três controles na mesma linha dos números: o botão da
                        // galeria fica ao lado do botão de discar.
                        final controlSize = math.min(
                          layout.roundButtonSize,
                          (constraints.maxWidth - gap * 2) / 3,
                        );
                        return Row(
                          children: [
                            Expanded(
                              child: _ActionControl(
                                icon: Icons.backspace_rounded,
                                label: 'Apagar',
                                color: Colors.white,
                                size: controlSize,
                                onPressed: _eraseLastKey,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _callButtonController,
                                child: _ActionControl(
                                  icon: Icons.call_rounded,
                                  label: 'Ligar',
                                  color: AppTheme.green,
                                  size: controlSize,
                                  onPressed: () => _handleCall(controller),
                                ),
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -_callButtonLift.value),
                                    child: Transform.scale(
                                      scale: _callButtonScale.value,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: _ActionControl(
                                icon: Icons.photo_library_rounded,
                                label: 'Galeria',
                                color: AppTheme.blue,
                                size: controlSize,
                                onPressed: () => _openGallery(controller),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: layout.size(16)),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(layout.size(24)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: layout.size(16),
                vertical: layout.size(layout.isCompactHeight ? 8 : 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.activeCount == 0) ...[
                    BabyMascot(size: layout.size(36)),
                    SizedBox(width: layout.size(10)),
                  ],
                  Flexible(
                    child: Text(
                      controller.activeCount > 0
                          ? '${controller.activeCount} recadinhos prontos • ${controller.linkedCount} contatos na galeria'
                          : 'Ainda não tem recadinhos prontos. Peça para um adulto gravar um!',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: layout.size(
                          14,
                          minScale: 0.95,
                          maxScale: 1.04,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsGallerySheet extends StatelessWidget {
  const _ContactsGallerySheet({required this.contacts, required this.onCall});

  final List<VideoEntry> contacts;
  final ValueChanged<VideoEntry> onCall;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: layout.size(12),
          right: layout.size(12),
          bottom: layout.size(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.shell,
              borderRadius: BorderRadius.circular(layout.size(34)),
            ),
            padding: EdgeInsets.all(layout.size(16)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: layout.size(48),
                        height: layout.size(48),
                        decoration: BoxDecoration(
                          color: AppTheme.orange,
                          borderRadius: BorderRadius.circular(layout.size(18)),
                        ),
                        child: Icon(
                          Icons.photo_library_rounded,
                          color: AppTheme.ink,
                          size: layout.size(30),
                        ),
                      ),
                      SizedBox(width: layout.size(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Galeria de contatos',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: layout.largeTitleFont,
                              ),
                            ),
                            Text(
                              'Toque em um contato para ligar.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: layout.size(
                                  13,
                                  minScale: 0.95,
                                  maxScale: 1.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: layout.size(12)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final entry = contacts[index];
                      return _ContactOptionCard(
                        entry: entry,
                        onTap: () => onCall(entry),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingBubble extends StatefulWidget {
  const _WaitingBubble({
    required this.color,
    required this.size,
    required this.delayMs,
  });

  final Color color;
  final double size;
  final int delayMs;

  @override
  State<_WaitingBubble> createState() => _WaitingBubbleState();
}

class _WaitingBubbleState extends State<_WaitingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _liftAnimation;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _liftAnimation = Tween<double>(
      begin: 0,
      end: 16,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _startTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_liftAnimation.value),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ActionControl extends StatelessWidget {
  const _ActionControl({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.size,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// Diâmetro do botão. Quando nulo, usa o tamanho padrão do layout.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);
    final side = size ?? layout.roundButtonSize;

    return Column(
      children: [
        SizedBox(
          width: side,
          height: side,
          child: FilledButton(
            onPressed: () {
              AppSoundEffects.tap();
              onPressed();
            },
            style: FilledButton.styleFrom(
              backgroundColor: color,
              enableFeedback: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(layout.size(28)),
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.ink,
              size: math.min(layout.size(36), side * 0.44),
            ),
          ),
        ),
        SizedBox(height: layout.size(layout.isCompactHeight ? 4 : 8)),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: layout.size(
              layout.isCompactHeight ? 12 : 14,
              minScale: 0.95,
              maxScale: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cabeçalho da tela infantil: mascote, logotipo e saudação amigável.
class _KidHeader extends StatelessWidget {
  const _KidHeader({required this.onPressStart, required this.onPressEnd});

  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);
    final compactHeight = layout.isCompactHeight;

    return Row(
      children: [
        BabyMascot(size: compactHeight ? 44 : 56),
        SizedBox(width: layout.size(10)),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Baby',
                      style: TextStyle(color: AppTheme.mintDark),
                    ),
                    TextSpan(
                      text: 'modile',
                      style: TextStyle(color: AppTheme.green),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: layout.size(22, minScale: 0.95, maxScale: 1.06),
                  height: 1.1,
                  letterSpacing: -0.4,
                ),
              ),
              if (!compactHeight)
                Text(
                  'Oi! Vamos ligar para quem a gente ama?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: layout.size(12, minScale: 0.95, maxScale: 1.05),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: layout.size(8)),
        _ParentsAccessButton(
          onPressStart: onPressStart,
          onPressEnd: onPressEnd,
        ),
      ],
    );
  }
}

/// Botão discreto de acesso à Área dos Pais (exige pressão de 3 segundos).
class _ParentsAccessButton extends StatelessWidget {
  const _ParentsAccessButton({
    required this.onPressStart,
    required this.onPressEnd,
  });

  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);
    final side = layout.size(52);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: onPressEnd,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(layout.size(18)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(
          Icons.settings_rounded,
          color: AppTheme.textSecondary,
          size: layout.size(26),
        ),
      ),
    );
  }
}

/// Teclado numérico em grade de 3 colunas que se estica para preencher
/// a altura disponível, evitando rolagem.
class _KeypadGrid extends StatelessWidget {
  const _KeypadGrid({
    required this.keys,
    required this.colors,
    required this.onKey,
  });

  static const _columns = 3;

  final List<String> keys;
  final List<Color> colors;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);
    final gap = layout.keypadGap;
    final rows = (keys.length / _columns).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < _columns; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  Expanded(child: _cell(row * _columns + col)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell(int index) {
    if (index >= keys.length) return const SizedBox.shrink();
    final value = keys[index];
    if (value.isEmpty) return const SizedBox.shrink();
    return _KeypadButton(
      digit: value,
      color: colors[index],
      onPressed: () => onKey(value),
    );
  }
}

/// Tecla do teclado numérico: afunda suavemente ao ser pressionada.
class _KeypadButton extends StatefulWidget {
  const _KeypadButton({
    required this.digit,
    required this.color,
    required this.onPressed,
  });

  final String digit;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(layout.size(24)),
            boxShadow: _pressed ? const [] : AppTheme.cardShadow,
          ),
          child: Padding(
            padding: EdgeInsets.all(layout.size(6)),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.digit,
                  style: TextStyle(
                    color: AppTheme.mintDark,
                    fontWeight: FontWeight.w900,
                    fontSize: layout.keypadDigitFont,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactOptionCard extends StatelessWidget {
  const _ContactOptionCard({required this.entry, required this.onTap});

  final VideoEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        AppSoundEffects.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ContactAvatarArt(
              avatarId: entry.avatarId,
              title: entry.title,
              size: 56,
              showLabel: false,
            ),
            const SizedBox(height: 6),
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatDialedNumber(entry.linkedPhoneNumber ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
