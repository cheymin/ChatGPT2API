import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerWidget extends StatefulWidget {
  final String? videoUrl;
  final String? audioUrl;
  final String? coverUrl;
  final int durationMs;
  final bool autoPlay;
  final double speed;

  const PlayerWidget({
    super.key,
    this.videoUrl,
    this.audioUrl,
    this.coverUrl,
    this.durationMs = 0,
    this.autoPlay = true,
    this.speed = 1.0,
  });

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  Player? _player;
  VideoController? _controller;
  bool _initialized = false;
  bool _mediaKitReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initMediaKit();
  }

  Future<void> _initMediaKit() async {
    try {
      MediaKit.ensureInitialized();
      setState(() => _mediaKitReady = true);
      _createPlayer();
    } catch (e) {
      setState(() {
        _error = '播放器初始化失败: $e';
        _mediaKitReady = false;
      });
    }
  }

  void _createPlayer() {
    if (!_mediaKitReady || widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return;
    }
    try {
      _player = Player(
        configuration: PlayerConfiguration(
          title: 'CiliCili',
          bufferSize: 64 * 1024 * 1024,
        ),
      );
      _controller = VideoController(_player!);
      _open();
    } catch (e) {
      setState(() => _error = '播放器创建失败: $e');
    }
  }

  Future<void> _open() async {
    if (_player == null || widget.videoUrl == null || widget.videoUrl!.isEmpty) return;
    try {
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _player!.open(Media(
          widget.videoUrl!,
          httpHeaders: {'Referer': 'https://www.bilibili.com'},
          extras: {'audio-file': widget.audioUrl},
        ));
      } else {
        await _player!.open(Media(
          widget.videoUrl!,
          httpHeaders: {'Referer': 'https://www.bilibili.com'},
        ));
      }
      if (widget.autoPlay) {
        await _player!.play();
      }
      await _player!.setRate(widget.speed);
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = '播放失败: $e');
    }
  }

  @override
  void didUpdateWidget(covariant PlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_player != null && (oldWidget.videoUrl != widget.videoUrl || oldWidget.audioUrl != widget.audioUrl)) {
      _open();
    }
    if (_player != null && oldWidget.speed != widget.speed) {
      _player!.setRate(widget.speed);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_initialized && widget.coverUrl != null)
            Image.network(
              widget.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_mediaKitReady && _controller != null && _error == null)
            Video(
              controller: _controller!,
              controls: NoVideoControls,
              fill: Colors.black,
              aspectRatio: 16 / 9,
            ),
          if (!_initialized && _error == null)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
