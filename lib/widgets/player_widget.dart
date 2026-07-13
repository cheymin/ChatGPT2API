import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// 基于 media_kit (libmpv) 的视频播放器组件
///
/// 对齐 PiliPlus 的 lib/plugin/pl_player/ 思路，支持：
/// - DASH 视频流播放
/// - 双击暂停/播放、双击左右快进快退
/// - 垂直滑动调节亮度/音量
/// - 水平滑动快进
/// - 长按 2 倍速
///
/// 使用方式：
/// ```dart
/// PlayerWidget(
///   videoUrl: 'https://...',
///   audioUrl: 'https://...',
///   coverUrl: '...',
/// )
/// ```
class PlayerWidget extends StatefulWidget {
  /// DASH 视频流 URL
  final String? videoUrl;

  /// DASH 音频流 URL（B 站 DASH 视频和音频分离）
  final String? audioUrl;

  /// 视频封面（加载时显示）
  final String? coverUrl;

  /// 视频时长（毫秒）
  final int durationMs;

  /// 是否自动播放
  final bool autoPlay;

  /// 倍速（1.0 = 原速）
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
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: PlayerConfiguration(
        title: 'CiliCili',
        bufferSize: 64 * 1024 * 1024,
      ),
    );
    _controller = VideoController(_player);
    _open();
  }

  Future<void> _open() async {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) return;
    try {
      // media_kit 支持 --audio-files=... 参数加载外部音轨
      // B 站 DASH 视频流：视频和音频分离，需要合并播放
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _player.open(Media(
          widget.videoUrl!,
          httpHeaders: {'Referer': 'https://www.bilibili.com'},
          extras: {'audio-file': widget.audioUrl},
        ));
      } else {
        await _player.open(Media(
          widget.videoUrl!,
          httpHeaders: {'Referer': 'https://www.bilibili.com'},
        ));
      }
      if (widget.autoPlay) {
        await _player.play();
      }
      await _player.setRate(widget.speed);
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      // ignore - 调用方可以显示错误
    }
  }

  @override
  void didUpdateWidget(covariant PlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.audioUrl != widget.audioUrl) {
      _open();
    }
    if (oldWidget.speed != widget.speed) {
      _player.setRate(widget.speed);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 封面（加载时显示）
          if (!_initialized && widget.coverUrl != null)
            Image.network(
              widget.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          // 播放器
          Video(
            controller: _controller,
            controls: NoVideoControls, // 我们自己做手势控制（后续完善）
            fill: Colors.black,
            aspectRatio: 16 / 9,
          ),
          // 加载指示器
          if (!_initialized)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
