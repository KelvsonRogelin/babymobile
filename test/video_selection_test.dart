import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:babymodile_flutter/src/models/video_entry.dart';
import 'package:babymodile_flutter/src/utils/video_selection.dart';

VideoEntry makeVideo(
  String id,
  VideoStatus status, {
  String title = 'video',
  String? linkedPhoneNumber,
}) {
  return VideoEntry(
    id: id,
    title: title,
    avatarId: '',
    linkedPhoneNumber: linkedPhoneNumber,
    status: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    filePath: '/tmp/$id.mp4',
    mimeType: 'video/mp4',
    durationMs: 5000,
    sizeBytes: 1234,
  );
}

void main() {
  test('sorteia apenas vídeos ativos', () {
    final chosen = selectRandomVideo([
      makeVideo('a', VideoStatus.inactive),
      makeVideo('b', VideoStatus.active),
      makeVideo('c', VideoStatus.blocked),
    ], Random(1));

    expect(chosen?.id, 'b');
  });

  test('retorna null quando não há vídeos ativos', () {
    final chosen = selectRandomVideo([
      makeVideo('a', VideoStatus.inactive),
      makeVideo('b', VideoStatus.blocked),
    ], Random(1));

    expect(chosen, isNull);
  });

  test('prioriza o vídeo ligado ao número especial', () {
    final chosen = selectVideoForDialedNumber(
      [
        makeVideo('a', VideoStatus.active),
        makeVideo('b', VideoStatus.active, linkedPhoneNumber: '123'),
      ],
      '123',
      Random(1),
    );

    expect(chosen?.id, 'b');
  });
}
