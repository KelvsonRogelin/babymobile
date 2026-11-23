import 'dart:math';

import '../models/video_entry.dart';

List<VideoEntry> getPlayableVideos(List<VideoEntry> videos) {
  return videos.where((video) => video.status == VideoStatus.active).toList();
}

VideoEntry? findVideoForDialedNumber(List<VideoEntry> videos, String dialedNumber) {
  for (final video in getPlayableVideos(videos)) {
    if (video.linkedPhoneNumber == dialedNumber) {
      return video;
    }
  }
  return null;
}

VideoEntry? selectRandomVideo(List<VideoEntry> videos, [Random? random]) {
  final playable = getPlayableVideos(videos);
  if (playable.isEmpty) return null;
  final source = random ?? Random();
  return playable[source.nextInt(playable.length)];
}

VideoEntry? selectVideoForDialedNumber(List<VideoEntry> videos, String dialedNumber, [Random? random]) {
  return findVideoForDialedNumber(videos, dialedNumber) ?? selectRandomVideo(videos, random);
}
