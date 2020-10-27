import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../player.dart';

class PlayBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous),
          iconSize: 32.0,
          onPressed: skipToPrevious,
        ),
        StreamBuilder<PlaybackState>(
          stream: AudioService.playbackStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == AudioProcessingState.buffering) {
              return Container(
                margin: EdgeInsets.all(8.0),
                width: 48.0,
                height: 48.0,
                child: CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: Icon(Icons.play_arrow),
                iconSize: 48.0,
                onPressed: play,
              );
            } else if (processingState != AudioProcessingState.completed) {
              return IconButton(
                icon: Icon(Icons.pause),
                iconSize: 48.0,
                onPressed: pause,
              );
            } else {
              return IconButton(
                icon: Icon(Icons.replay),
                iconSize: 48.0,
                onPressed: () => AudioService.seekTo(Duration.zero),
              );
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.skip_next),
          iconSize: 32.0,
          onPressed: skipToNext,
        ),
      ],
    );
  }
}
