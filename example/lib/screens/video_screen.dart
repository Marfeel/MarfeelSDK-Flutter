import 'dart:async';

import 'package:flutter/material.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

import '../data/articles.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _playing = false;
  int _currentTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    MultimediaTracking.initializeItem(
      id: videoItem.id,
      provider: videoItem.provider,
      providerId: videoItem.providerId,
      type: MultimediaType.video,
      metadata: MultimediaMetadata(
          title: videoItem.title, duration: videoItem.duration),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    setState(() => _playing = true);
    MultimediaTracking.registerEvent(
        id: videoItem.id,
        event: MultimediaEvent.play,
        eventTime: _currentTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentTime >= videoItem.duration) {
        _pause();
        MultimediaTracking.registerEvent(
            id: videoItem.id,
            event: MultimediaEvent.end,
            eventTime: _currentTime);
        return;
      }
      setState(() => _currentTime++);
      MultimediaTracking.registerEvent(
          id: videoItem.id,
          event: MultimediaEvent.updateCurrentTime,
          eventTime: _currentTime);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
    MultimediaTracking.registerEvent(
        id: videoItem.id,
        event: MultimediaEvent.pause,
        eventTime: _currentTime);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              color: Colors.black87,
              alignment: Alignment.center,
              child: Text(videoItem.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: _currentTime / videoItem.duration),
            const SizedBox(height: 4),
            Text(
                '${_formatTime(_currentTime)} / ${_formatTime(videoItem.duration)}',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: _playing ? _pause : _play,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  iconSize: 36,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _eventButton('Mute', MultimediaEvent.mute),
                _eventButton('Unmute', MultimediaEvent.unmute),
                _eventButton('Fullscreen', MultimediaEvent.fullScreen),
                _eventButton('Enter Viewport', MultimediaEvent.enterViewport),
                _eventButton('Leave Viewport', MultimediaEvent.leaveViewport),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventButton(String label, MultimediaEvent event) {
    return ElevatedButton(
      onPressed: () => MultimediaTracking.registerEvent(
          id: videoItem.id, event: event, eventTime: _currentTime),
      child: Text(label),
    );
  }
}
