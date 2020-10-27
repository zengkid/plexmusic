import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player.dart';
import '../widgets/player_bar.dart';
import '../widgets/process_bar.dart';

class HomePage extends StatefulWidget {
  static String tag = 'home-page';

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<HomePage> {
  // AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  _init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    if (AudioService.running == null || !AudioService.running) {
      AudioService.start(
        backgroundTaskEntrypoint: backgroundTaskEntrypoint,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: StreamBuilder<MediaItem>(
                  stream: AudioService.currentMediaItemStream,
                  builder: (context, snapshot) {
                    MediaItem metadata = snapshot.data;
                    if (metadata == null) return SizedBox();
                    // final metadata = state.;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                                Center(child: Image.network(metadata.artUri)),
                          ),
                        ),
                        Text(metadata.album ?? '',
                            style: Theme.of(context).textTheme.headline6),
                        Text(metadata.title ?? ''),
                      ],
                    );
                  },
                ),
              ),
              PlayBar(),
              ProcessBar(),
              SizedBox(height: 8.0),
              Row(
                children: [
                  StreamBuilder<PlaybackState>(
                    stream: AudioService.playbackStateStream,
                    builder: (context, snapshot) {
                      final PlaybackState state = snapshot.data;
                      final AudioServiceRepeatMode loopMode =
                          state?.repeatMode ?? AudioServiceRepeatMode.all;
                      const icons = [
                        Icon(Icons.repeat, color: Colors.grey),
                        Icon(Icons.repeat_one, color: Colors.orange),
                        Icon(Icons.repeat, color: Colors.orange),
                      ];
                      const cycleModes = [
                        AudioServiceRepeatMode.none,
                        AudioServiceRepeatMode.one,
                        AudioServiceRepeatMode.all,
                      ];
                      final index = cycleModes.indexOf(loopMode);
                      return IconButton(
                        icon: icons[index],
                        onPressed: () {
                          AudioService.setRepeatMode(cycleModes[
                              (cycleModes.indexOf(loopMode) + 1) %
                                  cycleModes.length]);
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: Text(
                      "Playlist",
                      style: Theme.of(context).textTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  StreamBuilder<PlaybackState>(
                    stream: AudioService.playbackStateStream,
                    builder: (context, snapshot) {
                      final shuffleModeEnabled = snapshot.data?.shuffleMode !=
                              AudioServiceShuffleMode.none ??
                          false;
                      return IconButton(
                        icon: shuffleModeEnabled
                            ? Icon(Icons.shuffle, color: Colors.orange)
                            : Icon(Icons.shuffle, color: Colors.grey),
                        onPressed: () {
                          AudioService.setShuffleMode(shuffleModeEnabled
                              ? AudioServiceShuffleMode.none
                              : AudioServiceShuffleMode.all);
                        },
                      );
                    },
                  ),
                ],
              ),
              Container(
                height: 240.0,
                child: StreamBuilder<List<MediaItem>>(
                  stream: AudioService.queueStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final sequence = state ?? [];
                    return ListView.builder(
                      itemCount: sequence.length,
                      itemBuilder: (context, index) => Material(
                        color:
                            state[index].id == AudioService.currentMediaItem.id
                                ? Colors.grey.shade300
                                : null,
                        child: ListTile(
                          title: Text(sequence[index].title),
                          onTap: () {
                            AudioService.playMediaItem(state[index]);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_showSliderDialog({
  BuildContext context,
  String title,
  int divisions,
  double min,
  double max,
  String valueSuffix = '',
  Stream<double> stream,
  ValueChanged<double> onChanged,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
        stream: stream,
        builder: (context, snapshot) => Container(
          height: 100.0,
          child: Column(
            children: [
              Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                  style: TextStyle(
                      fontFamily: 'Fixed',
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0)),
              Slider(
                divisions: divisions,
                min: min,
                max: max,
                value: snapshot.data ?? 1.0,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AudioMetadata {
  final String album;
  final String title;
  final String artwork;

  AudioMetadata({this.album, this.title, this.artwork});
}
