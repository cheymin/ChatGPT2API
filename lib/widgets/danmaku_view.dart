import 'dart:async';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';

import '../models/danmaku.dart';

/// 弹幕控制器封装（对齐 PiliPlus 的弹幕引擎思路）
///
/// 基于 canvas_danmaku 实现：
/// - 滚动/顶部/底部三种模式
/// - 会员彩色弹幕
/// - 弹幕大小、不透明度、显示区域、速度调节
/// - 暂停/继续
/// - 跳转到指定时间点（弹幕同步）
class DanmakuControllerWidget extends StatefulWidget {
  /// 弹幕列表
  final List<Danmaku> danmakuList;

  /// 当前播放时间（秒）
  final Stream<double> positionStream;

  /// 是否正在播放
  final Stream<bool> playingStream;

  /// 弹幕大小倍数（1.0 = 默认）
  final double fontSizeScale;

  /// 不透明度（0-1）
  final double opacity;

  /// 显示区域占比（0-1，0.5 = 屏幕一半）
  final double displayArea;

  /// 弹幕速度倍数
  final double speed;

  const DanmakuControllerWidget({
    super.key,
    required this.danmakuList,
    required this.positionStream,
    required this.playingStream,
    this.fontSizeScale = 1.0,
    this.opacity = 1.0,
    this.displayArea = 0.8,
    this.speed = 1.0,
  });

  @override
  State<DanmakuControllerWidget> createState() => _DanmakuControllerState();
}

class _DanmakuControllerState extends State<DanmakuControllerWidget> {
  late final DanmakuController _controller;
  StreamSubscription<double>? _posSub;
  StreamSubscription<bool>? _playSub;

  @override
  void initState() {
    super.initState();
    _controller = DanmakuController(
      config: DanmakuConfig(
        fontSize: 16 * widget.fontSizeScale,
        opacity: widget.opacity,
        area: widget.displayArea,
        duration: 8 ~/ widget.speed,
      ),
    );

    _posSub = widget.positionStream.listen((pos) {
      // 同步弹幕时间
      _controller.updateTime(pos * 1000);
    });
    _playSub = widget.playingStream.listen((playing) {
      if (playing) {
        _controller.resume();
      } else {
        _controller.pause();
      }
    });

    _loadDanmaku();
  }

  void _loadDanmaku() {
    final items = <DanmakuItem>[];
    for (final d in widget.danmakuList) {
      final color = Color(
        0xFF000000 | (d.color & 0xFFFFFF),
      );
      DanmakuItemType type = DanmakuItemType.scroll;
      if (d.mode == 4) {
        type = DanmakuItemType.bottom;
      } else if (d.mode == 5) {
        type = DanmakuItemType.top;
      }
      items.add(DanmakuItem(
        text: d.text,
        color: color,
        time: d.time,
        type: type,
      ));
    }
    _controller.addItems(items);
  }

  @override
  void didUpdateWidget(covariant DanmakuControllerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.danmakuList != widget.danmakuList) {
      _controller.clear();
      _loadDanmaku();
    }
    if (oldWidget.fontSizeScale != widget.fontSizeScale ||
        oldWidget.opacity != widget.opacity ||
        oldWidget.displayArea != widget.displayArea ||
        oldWidget.speed != widget.speed) {
      _controller.updateConfig(DanmakuConfig(
        fontSize: 16 * widget.fontSizeScale,
        opacity: widget.opacity,
        area: widget.displayArea,
        duration: 8 ~/ widget.speed,
      ));
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _playSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DanmakuView(_controller);
  }
}
