import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ContactAvatarPreset {
  const ContactAvatarPreset({
    required this.id,
    required this.label,
    required this.emoji,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.chipColor,
  });

  final String id;
  final String label;
  final String emoji;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color chipColor;
}

const contactAvatarPresets = <ContactAvatarPreset>[
  ContactAvatarPreset(
    id: 'papai',
    label: 'Papai',
    emoji: '👨',
    backgroundTop: Color(0xFF9DD9FF),
    backgroundBottom: Color(0xFF6AB8F7),
    chipColor: Color(0xFFFFE08A),
  ),
  ContactAvatarPreset(
    id: 'mamae',
    label: 'Mamãe',
    emoji: '👩',
    backgroundTop: Color(0xFFFFC6E5),
    backgroundBottom: Color(0xFFFF8CC9),
    chipColor: Color(0xFFFFF0A6),
  ),
  ContactAvatarPreset(
    id: 'avo',
    label: 'Avô',
    emoji: '👴',
    backgroundTop: Color(0xFFD6D6FF),
    backgroundBottom: Color(0xFFB6B8FF),
    chipColor: Color(0xFFFFE08A),
  ),
  ContactAvatarPreset(
    id: 'avo_mulher',
    label: 'Avó',
    emoji: '👵',
    backgroundTop: Color(0xFFFFD7E8),
    backgroundBottom: Color(0xFFFFB2D0),
    chipColor: Color(0xFFFFF0A6),
  ),
  ContactAvatarPreset(
    id: 'tio',
    label: 'Tio',
    emoji: '🧔',
    backgroundTop: Color(0xFFFFD3A0),
    backgroundBottom: Color(0xFFFFB56B),
    chipColor: Color(0xFFFFEAA8),
  ),
  ContactAvatarPreset(
    id: 'tia',
    label: 'Tia',
    emoji: '🙋‍♀️',
    backgroundTop: Color(0xFFE0C4FF),
    backgroundBottom: Color(0xFFC292FF),
    chipColor: Color(0xFFFFF0A6),
  ),
  ContactAvatarPreset(
    id: 'primo',
    label: 'Primo',
    emoji: '🧒',
    backgroundTop: Color(0xFFB9F0C7),
    backgroundBottom: Color(0xFF83E5A0),
    chipColor: Color(0xFFFFE08A),
  ),
  ContactAvatarPreset(
    id: 'prima',
    label: 'Prima',
    emoji: '👧',
    backgroundTop: Color(0xFFFFC7F0),
    backgroundBottom: Color(0xFFFF94DB),
    chipColor: Color(0xFFFFF0A6),
  ),
  ContactAvatarPreset(
    id: 'amigo',
    label: 'Amigo',
    emoji: '🧑',
    backgroundTop: Color(0xFFAEE9E7),
    backgroundBottom: Color(0xFF6FD5D1),
    chipColor: Color(0xFFFFE08A),
  ),
  ContactAvatarPreset(
    id: 'amiga',
    label: 'Amiga',
    emoji: '😊',
    backgroundTop: Color(0xFFFFD3B0),
    backgroundBottom: Color(0xFFFFB07A),
    chipColor: Color(0xFFFFF0A6),
  ),
];

ContactAvatarPreset contactAvatarPresetFor(String? avatarId, {String? title}) {
  final resolvedId = avatarId != null && avatarId.isNotEmpty
      ? avatarId
      : suggestContactAvatarId(title);
  return contactAvatarPresets.firstWhere(
    (preset) => preset.id == resolvedId,
    orElse: () => contactAvatarPresets.last,
  );
}

String suggestContactAvatarId(String? title) {
  final value = _normalize(title);
  if (value.contains('papai') || value.contains('pai')) return 'papai';
  if (value.contains('mamae') || value.contains('mae')) return 'mamae';
  if (value.contains('avo ') || value == 'avo' || value.contains('vovo')) {
    return 'avo';
  }
  if (value.contains('avo_') ||
      value.contains('avoh') ||
      value.contains('vovozinha')) {
    return 'avo_mulher';
  }
  if (value.contains('avó') || value.contains('vo ') || value == 'vo') {
    return 'avo_mulher';
  }
  if (value.contains('tio')) return 'tio';
  if (value.contains('tia')) return 'tia';
  if (value.contains('primo')) return 'primo';
  if (value.contains('prima')) return 'prima';
  if (value.contains('amiga')) return 'amiga';
  return 'amigo';
}

String _normalize(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('ã', 'a')
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}

class ContactAvatarArt extends StatelessWidget {
  const ContactAvatarArt({
    super.key,
    this.avatarId,
    this.title,
    required this.size,
    this.showLabel = true,
  });

  final String? avatarId;
  final String? title;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final preset = contactAvatarPresetFor(avatarId, title: title);
    final chipHeight = showLabel ? size * 0.24 : 0.0;
    final emojiSize = showLabel ? size * 0.42 : size * 0.48;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [preset.backgroundTop, preset.backgroundBottom],
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.12,
            right: size * 0.12,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: const BoxDecoration(
                color: Color(0x22FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: showLabel ? const Alignment(0, -0.2) : Alignment.center,
            child: Text(preset.emoji, style: TextStyle(fontSize: emojiSize)),
          ),
          if (showLabel)
            Positioned(
              left: size * 0.08,
              right: size * 0.08,
              bottom: size * 0.08,
              child: Container(
                height: chipHeight,
                decoration: BoxDecoration(
                  color: preset.chipColor,
                  borderRadius: BorderRadius.circular(size * 0.18),
                ),
                alignment: Alignment.center,
                child: Text(
                  preset.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ContactAvatarPicker extends StatelessWidget {
  const ContactAvatarPicker({
    super.key,
    required this.selectedAvatarId,
    required this.onChanged,
  });

  final String selectedAvatarId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contactAvatarPresets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final preset = contactAvatarPresets[index];
        final isSelected = preset.id == selectedAvatarId;

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onChanged(preset.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.green : Colors.white70,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.ink : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ContactAvatarArt(avatarId: preset.id, size: 70),
                const SizedBox(height: 8),
                Text(
                  preset.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
