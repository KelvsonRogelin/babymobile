import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/video_entry.dart';
import '../services/app_sound_effects.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/device_layout.dart';
import '../widgets/contact_avatar_art.dart';
import '../widgets/toy_button.dart';
import '../widgets/toy_phone_shell.dart';
import '../widgets/video_player_card.dart';

class ParentsDashboardScreen extends StatefulWidget {
  const ParentsDashboardScreen({super.key});

  @override
  State<ParentsDashboardScreen> createState() => _ParentsDashboardScreenState();
}

class _ParentsDashboardScreenState extends State<ParentsDashboardScreen> {
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _linkedNumberController = TextEditingController();

  XFile? _pickedFile;
  Duration? _pickedDuration;
  String _selectedAvatarId = 'amigo';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _linkedNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(AppController controller, ImageSource source) async {
    setState(() => _error = null);
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: Duration(seconds: controller.settings.maxDurationSec),
      );
      if (file == null) return;

      final duration = await _measureDuration(file.path);
      if (duration.inSeconds > controller.settings.maxDurationSec) {
        setState(() {
          _error =
              'Esse vídeo passou de ${controller.settings.maxDurationSec} segundos. Escolha um vídeo menor.';
          _pickedFile = null;
          _pickedDuration = null;
        });
        return;
      }

      setState(() {
        _pickedFile = file;
        _pickedDuration = duration;
      });
    } catch (_) {
      setState(() {
        _error = 'Não consegui abrir esse vídeo agora.';
      });
    }
  }

  Future<Duration> _measureDuration(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
  }

  Future<void> _saveNewVideo(AppController controller) async {
    if (_pickedFile == null || _pickedDuration == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await controller.savePickedVideo(
        sourceFile: File(_pickedFile!.path),
        title: _titleController.text,
        duration: _pickedDuration!,
        avatarId: _selectedAvatarId,
        linkedPhoneNumber: _linkedNumberController.text,
      );

      setState(() {
        _titleController.clear();
        _linkedNumberController.clear();
        _pickedFile = null;
        _pickedDuration = null;
        _selectedAvatarId = 'amigo';
      });
    } catch (error) {
      setState(() {
        _error = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Não consegui salvar esse vídeo.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showPreview(VideoEntry entry) async {
    if (!await File(entry.filePath).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse vídeo não está disponível agora.')),
      );
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SheetCard(
          title: entry.title,
          child: VideoPlayerCard(filePath: entry.filePath),
        );
      },
    );
  }

  Future<void> _showEditSheet(
    AppController controller,
    VideoEntry entry,
  ) async {
    final titleController = TextEditingController(text: entry.title);
    final linkedController = TextEditingController(
      text: entry.linkedPhoneNumber ?? '',
    );
    var status = entry.status;
    var avatarId = entry.avatarId.isEmpty
        ? suggestContactAvatarId(entry.title)
        : entry.avatarId;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return _SheetCard(
              title: 'Editar vídeo',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nome do vídeo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: _inputDecoration('Ex.: Vovó mandando beijo'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Avatar do contato',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ContactAvatarArt(
                      avatarId: avatarId,
                      title: titleController.text,
                      size: 94,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ContactAvatarPicker(
                    selectedAvatarId: avatarId,
                    onChanged: (value) {
                      setStateSheet(() => avatarId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status na galeria',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<VideoStatus>(
                    initialValue: status,
                    decoration: _inputDecoration(''),
                    items: const [
                      DropdownMenuItem(
                        value: VideoStatus.active,
                        child: Text('Ativo no sorteio'),
                      ),
                      DropdownMenuItem(
                        value: VideoStatus.inactive,
                        child: Text('Inativo'),
                      ),
                      DropdownMenuItem(
                        value: VideoStatus.blocked,
                        child: Text('Bloqueado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateSheet(() => status = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Número especial (opcional)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkedController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Ex.: 123'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: const Text(
                      'Só vídeos ativos entram no sorteio. Se houver número especial, ele tem prioridade.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE3E3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ToyButton(
                          label: 'Cancelar',
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ToyButton(
                          label: 'Salvar',
                          color: AppTheme.green,
                          onPressed: () async {
                            try {
                              await controller.updateVideo(
                                id: entry.id,
                                title: titleController.text,
                                status: status,
                                avatarId: avatarId,
                                linkedPhoneNumber: linkedController.text,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            } catch (exception) {
                              setStateSheet(() {
                                error = exception.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    linkedController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final layout = DeviceLayout.fromContext(context);

    return Scaffold(
      body: ToyPhoneShell(
        leftIcon: IconButton(
          onPressed: () {
            AppSoundEffects.tap();
            controller.closeParents();
          },
          icon: const Icon(Icons.phone_rounded, color: AppTheme.ink),
        ),
        displayLabel: 'ÁREA DOS PAIS',
        displayValue: 'Galeria',
        displayMessage: 'Grave, envie e organize os vídeos da família.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lavender,
                borderRadius: BorderRadius.circular(layout.sectionRadius),
              ),
              padding: EdgeInsets.all(layout.size(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Gravar ou enviar vídeo',
                    style: TextStyle(
                      color: AppTheme.cream,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: layout.size(6)),
                  const Text(
                    'Use a câmera do celular ou a galeria. O limite segue em 30 segundos.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: layout.size(12)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.yellow,
                      borderRadius: BorderRadius.circular(layout.size(28)),
                    ),
                    padding: EdgeInsets.all(layout.size(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_pickedFile != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              layout.size(24),
                            ),
                            child: VideoPlayerCard(filePath: _pickedFile!.path),
                          ),
                          SizedBox(height: layout.size(12)),
                          Text(
                            'Prévia pronta • ${_pickedDuration?.inSeconds ?? 0}s',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: layout.size(12)),
                        ] else ...[
                          Container(
                            height: layout.size(
                              layout.isCompactHeight ? 140 : 180,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(
                                layout.size(24),
                              ),
                            ),
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(layout.size(16)),
                            child: const Text(
                              'Escolha um vídeo da câmera ou da galeria para ver a prévia aqui.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: layout.size(12)),
                        ],
                        TextField(
                          controller: _titleController,
                          decoration: _inputDecoration(
                            'Nome do vídeo (opcional)',
                          ),
                        ),
                        SizedBox(height: layout.size(12)),
                        const Text(
                          'Escolha o avatar do contato',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: layout.size(8)),
                        Center(
                          child: ContactAvatarArt(
                            avatarId: _selectedAvatarId,
                            title: _titleController.text,
                            size: layout.size(94, minScale: 0.9, maxScale: 1.0),
                          ),
                        ),
                        SizedBox(height: layout.size(12)),
                        ContactAvatarPicker(
                          selectedAvatarId: _selectedAvatarId,
                          onChanged: (value) {
                            setState(() => _selectedAvatarId = value);
                          },
                        ),
                        SizedBox(height: layout.size(12)),
                        TextField(
                          controller: _linkedNumberController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Número especial (opcional)',
                          ),
                        ),
                        SizedBox(height: layout.size(8)),
                        const Text(
                          'Se esse número for digitado, este vídeo toca certinho. Outros números continuam sorteando.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (_error != null) ...[
                          SizedBox(height: layout.size(12)),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE3E3),
                              borderRadius: BorderRadius.circular(
                                layout.size(20),
                              ),
                            ),
                            padding: EdgeInsets.all(layout.size(12)),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFB42318),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: layout.size(16)),
                        _ResponsiveButtonPair(
                          compact: layout.isCompactWidth,
                          first: ToyButton(
                            label: 'Gravar',
                            color: AppTheme.green,
                            icon: Icons.videocam_rounded,
                            onPressed: _saving
                                ? null
                                : () => _pickVideo(
                                    controller,
                                    ImageSource.camera,
                                  ),
                          ),
                          second: ToyButton(
                            label: 'Enviar',
                            color: AppTheme.blue,
                            icon: Icons.upload_rounded,
                            onPressed: _saving
                                ? null
                                : () => _pickVideo(
                                    controller,
                                    ImageSource.gallery,
                                  ),
                          ),
                        ),
                        SizedBox(height: layout.size(12)),
                        _ResponsiveButtonPair(
                          compact: layout.isCompactWidth,
                          first: ToyButton(
                            label: _pickedFile == null
                                ? 'Limpar'
                                : 'Trocar vídeo',
                            color: Colors.white,
                            icon: _pickedFile == null
                                ? Icons.refresh_rounded
                                : Icons.swap_horiz_rounded,
                            onPressed: () {
                              setState(() {
                                if (_pickedFile == null) {
                                  _titleController.clear();
                                  _linkedNumberController.clear();
                                  _selectedAvatarId = 'amigo';
                                  _error = null;
                                } else {
                                  _pickedFile = null;
                                  _pickedDuration = null;
                                  _selectedAvatarId = 'amigo';
                                  _error = null;
                                }
                              });
                            },
                          ),
                          second: ToyButton(
                            label: _saving ? 'Salvando...' : 'Salvar',
                            color: AppTheme.green,
                            icon: Icons.save_rounded,
                            onPressed: _pickedFile != null && !_saving
                                ? () => _saveNewVideo(controller)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: layout.size(16)),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.yellow,
                borderRadius: BorderRadius.circular(layout.sectionRadius),
              ),
              padding: EdgeInsets.all(layout.size(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Galeria de vídeos',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: layout.largeTitleFont,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Números especiais tocam vídeos certos. Outros números válidos sorteiam.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: layout.size(12)),
                  _ResponsiveButtonPair(
                    compact: layout.isCompactWidth,
                    first: _StatCard(
                      label: 'Vídeos ativos',
                      value: '${controller.activeCount}',
                    ),
                    second: _StatCard(
                      label: 'Na galeria',
                      value: '${controller.videos.length}',
                    ),
                  ),
                  SizedBox(height: layout.size(16)),
                  if (controller.videos.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(layout.size(28)),
                      ),
                      padding: EdgeInsets.all(layout.size(20)),
                      child: const Text(
                        'Sua galeria ainda está vazia. Grave ou envie o primeiro vídeo para começar.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...controller.videos.map(
                      (video) => Padding(
                        padding: EdgeInsets.only(bottom: layout.size(12)),
                        child: _VideoCard(
                          video: video,
                          onPreview: () => _showPreview(video),
                          onEdit: () => _showEditSheet(controller, video),
                          onDelete: () async {
                            await controller.deleteVideo(video.id);
                          },
                        ),
                      ),
                    ),
                  SizedBox(height: layout.size(8)),
                  ToyButton(
                    label: 'Sair',
                    color: AppTheme.green,
                    icon: Icons.logout_rounded,
                    onPressed: controller.closeParents,
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

class _ResponsiveButtonPair extends StatelessWidget {
  const _ResponsiveButtonPair({
    required this.compact,
    required this.first,
    required this.second,
  });

  final bool compact;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          SizedBox(height: layout.size(12)),
          second,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: layout.size(12)),
        Expanded(child: second),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(22)),
      borderSide: BorderSide.none,
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(layout.size(24)),
      ),
      padding: EdgeInsets.all(layout.size(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: layout.size(12, minScale: 0.95, maxScale: 1.05),
            ),
          ),
          SizedBox(height: layout.size(8)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: layout.size(32, minScale: 0.9, maxScale: 1.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  final VideoEntry video;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);
    final statusColor = switch (video.status) {
      VideoStatus.active => AppTheme.green,
      VideoStatus.inactive => AppTheme.orange,
      VideoStatus.blocked => AppTheme.danger,
    };

    final duration = Duration(milliseconds: video.durationMs);
    final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(layout.size(28)),
      ),
      padding: EdgeInsets.all(layout.size(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContactAvatarArt(
                avatarId: video.avatarId,
                title: video.title,
                size: layout.size(70, minScale: 0.9, maxScale: 1.0),
              ),
              SizedBox(width: layout.size(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: layout.size(
                          18,
                          minScale: 0.95,
                          maxScale: 1.05,
                        ),
                      ),
                    ),
                    SizedBox(height: layout.size(4)),
                    Text(
                      '$mm:$ss • ${(video.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: layout.size(8)),
                    Text(
                      video.linkedPhoneNumber != null
                          ? 'Número especial: ${video.linkedPhoneNumber}'
                          : 'Sem número especial',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: layout.size(12),
                  vertical: layout.size(8),
                ),
                child: Text(
                  switch (video.status) {
                    VideoStatus.active => 'Ativo',
                    VideoStatus.inactive => 'Inativo',
                    VideoStatus.blocked => 'Bloqueado',
                  },
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: layout.size(12)),
          ToyButton(
            label: 'Prévia',
            color: AppTheme.blue,
            icon: Icons.play_arrow_rounded,
            onPressed: onPreview,
          ),
          SizedBox(height: layout.size(8)),
          ToyButton(
            label: 'Editar',
            color: AppTheme.lavender,
            icon: Icons.edit_rounded,
            onPressed: onEdit,
          ),
          SizedBox(height: layout.size(8)),
          ToyButton(
            label: 'Excluir',
            color: AppTheme.danger,
            icon: Icons.delete_rounded,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: layout.largeTitleFont,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: layout.size(12)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.yellow,
                      borderRadius: BorderRadius.circular(layout.size(28)),
                    ),
                    padding: EdgeInsets.all(layout.size(16)),
                    child: child,
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
