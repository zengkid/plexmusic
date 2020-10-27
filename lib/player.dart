import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'playlist.dart';

backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

play() async {
  if (AudioService.running) {
    AudioService.play();
  } else {
    AudioService.start(
      backgroundTaskEntrypoint: backgroundTaskEntrypoint,
    );
  }
}

pause() => AudioService.pause();

stop() => AudioService.stop();

skipToPrevious() => AudioService.skipToPrevious();

skipToNext() => AudioService.skipToNext();

playFromMediaId(String mediaId) => AudioService.playFromMediaId(mediaId);

playMediaItem(MediaItem mediaItem) => AudioService.playMediaItem(mediaItem);

class AudioPlayerTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    var sources = <AudioSource>[];
    for (var i = 0; i < playlist.length; i++) {
      var item = playlist[i];
      var url = item.extras['url'];
      var source = AudioSource.uri(Uri.parse(url), tag: item);
      sources.add(source);
    }

    _audioPlayer.playerStateStream.listen((v) {
      print(
          '####################### print playerStateStream: ${v?.processingState}');
    });
    _audioPlayer.sequenceStateStream.listen((v) {
      print(
          '####################### print sequenceStateStream: ${v?.currentSource?.tag}');
    });
    _audioPlayer.playbackEventStream.listen((v) {
      print(
          '####################### print playbackEventStream: ${v?.currentIndex},${v?.processingState}');
    });
    _audioPlayer.sequenceStream.listen((v) {
      print('####################### print sequenceStream: ${v}');
    });
    _audioPlayer.currentIndexStream.listen((v) {
      print('####################### print currentIndexStream: ${v}');
      updateTaskUI(_audioPlayer.playing);
    });
    _audioPlayer.loopModeStream.listen((v) {
      print('####################### print loopModeStream: ${v}');
    });

    var _playlist = ConcatenatingAudioSource(children: sources);

    await _audioPlayer.load(_playlist);

    _audioPlayer.setLoopMode(LoopMode.all);
    _audioPlayer.setShuffleModeEnabled(false);

    updateTaskUI(true, state: AudioProcessingState.connecting);

    _audioPlayer.play();

    updateTaskUI(true);
  }

  @override
  Future<Function> onPrepare() {
    print('onPrepare');
    updateTaskUI(true);
  }

  @override
  Future<void> onPlay() async {
    print('onPlay');
    _audioPlayer.play();
    updateTaskUI(true, position: _audioPlayer.position);
    await super.onPlay();
  }

  @override
  Future<void> onPause() async {
    print('onPause');
    _audioPlayer.pause();
    updateTaskUI(_audioPlayer.playing, position: _audioPlayer.position);
    await super.onPause();
  }

  @override
  Future<void> onStop() async {
    print('onStop');
    await _audioPlayer.stop();
    updateTaskUI(_audioPlayer.playing, state: AudioProcessingState.stopped);
    await super.onStop();
  }

  @override
  Future<void> onSkipToNext() async {
    print('onSkipToNext');
    await _audioPlayer.seekToNext();
    _audioPlayer.play();
    updateTaskUI(_audioPlayer.playing, position: _audioPlayer.position);
    await super.onSkipToNext();
  }

  @override
  Future<void> onSkipToPrevious() async {
    print('onSkipToPrevious');
    await _audioPlayer.seekToPrevious();
    _audioPlayer.play();
    updateTaskUI(_audioPlayer.playing, position: _audioPlayer.position);
    super.onSkipToPrevious();
  }

  @override
  Future<void> onSeekTo(Duration position) async {
    print('onSeekTo');
    _audioPlayer.seek(position);
    _audioPlayer.play();
    updateTaskUI(_audioPlayer.playing, position: _audioPlayer.position);
    await super.onSeekTo(position);
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    print('onPlayMediaItem : $mediaItem');
    var sequence = _audioPlayer.sequence;
    for (var i = 0; i < sequence.length; i++) {
      var item = sequence[i].tag as MediaItem;
      if (item.id == mediaItem.id) {
        await _audioPlayer.seek(Duration.zero, index: i);
      }
    }
    _audioPlayer.play();
    updateTaskUI(_audioPlayer.playing);
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    print('onSetRepeatMode = $repeatMode');
    var mode = LoopMode.values[repeatMode.index];
    await _audioPlayer.setLoopMode(mode);
    updateTaskUI(_audioPlayer.playing, position: _audioPlayer.position);
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    print('onSetShuffleMode : $shuffleMode');
    var enabled = AudioServiceShuffleMode.none != shuffleMode;
    _audioPlayer.setShuffleModeEnabled(enabled);

    updateTaskUI(_audioPlayer.playing, position: _audioPlayer.position);
  }

  @override
  Future<void> onUpdateMediaItem(MediaItem mediaItem) async {
    print('onUpdateMediaItem');
  }

  @override
  Future<void> onPlayFromMediaId(String mediaId) async {
    print('onPlayFromMediaId');
  }

  @override
  Future<void> onPrepareFromMediaId(String mediaId) async {
    print('onPrepareFromMediaId');
  }

  @override
  Future<List<MediaItem>> onLoadChildren(String parentMediaId) {
    print('onLoadChildren');
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) {
    print('onSkipToQueueItem');
  }

  void updateTaskUI(bool playing,
      {Duration position = Duration.zero,
      AudioProcessingState state = AudioProcessingState.ready}) {
    var currentIndex = _audioPlayer.currentIndex;
    var index = max(0, currentIndex);
    var audioSource = _audioPlayer.sequence[index];

    MediaItem mediaItem = audioSource.tag;
    var newItem = mediaItem.copyWith(duration: _audioPlayer.duration);
    AudioServiceBackground.setMediaItem(newItem);

    var control = playing ? MediaControl.pause : MediaControl.play;
    var repeatMode =
        AudioServiceRepeatMode.values[_audioPlayer.loopMode.index ?? 0];
    var shuffleMode = _audioPlayer.shuffleModeEnabled
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none;
    AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          control,
          MediaControl.skipToNext
        ],
        playing: playing,
        position: position,
        processingState: state,
        repeatMode: repeatMode,
        shuffleMode: shuffleMode);

    AudioServiceBackground.setQueue(playlist);
  }
}
