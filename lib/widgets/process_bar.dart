import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'seek_bar.dart';

class ProcessBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, snapshot) {
        final duration = snapshot.data?.duration ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: AudioService.positionStream,
          builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero;
            if (position > duration) {
              position = duration;
            }
            return SeekBar(
              duration: duration,
              position: position,
              onChangeEnd: (newPosition) {
                AudioService.seekTo(newPosition);
              },
            );
          },
        );
      },
    );
  }
}
