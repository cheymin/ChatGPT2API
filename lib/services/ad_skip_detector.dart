import '../models/danmaku.dart';

/// 恰饭广告片段
class AdSegment {
  /// 开始时间（秒）
  final double start;

  /// 结束时间（秒）
  final double end;

  /// 命中弹幕数
  final int hitCount;

  const AdSegment({
    required this.start,
    required this.end,
    required this.hitCount,
  });

  /// 片段时长（秒）
  double get duration => end - start;

  @override
  String toString() => 'AdSegment(${start.toStringAsFixed(1)}-${end.toStringAsFixed(1)}s, $hitCount hits)';
}

/// 恰饭广告跳过检测器
///
/// 原理参考 BiliSmartSkip 插件：
/// 分析弹幕中"广告"、"恰饭"等关键词的时间分布，
/// 当某时间段内广告相关弹幕密度超过阈值时标记为广告片段。
class AdSkipDetector {
  AdSkipDetector._();

  /// 广告关键词列表
  static const List<String> _adKeywords = [
    '广告',
    '恰饭',
    '广而告之',
    'sponsor',
    'ad',
    '赞助',
    '推广',
    '恰了',
    '金主',
    '甲方',
    '业配',
    '植入',
    '硬广',
    '软广',
    '带货',
    '购物车',
    '优惠券',
    '折扣码',
    '折扣码',
    'promo',
    'promotion',
  ];

  /// 弹幕时间窗口大小（秒）
  static const double _windowSize = 10.0;

  /// 窗口内最少命中弹幕数才标记为广告
  static const int _minHitsPerWindow = 3;

  /// 合并相邻广告片段的间隔（秒）
  static const double _mergeGap = 5.0;

  /// 最短广告片段时长（秒），短于此长度的会被过滤
  static const double _minDuration = 5.0;

  /// 检测视频中的广告片段
  ///
  /// [danmakuList] 弹幕列表
  /// [videoDuration] 视频总时长（秒），可选
  static List<AdSegment> detect(
    List<Danmaku> danmakuList, {
    double? videoDuration,
  }) {
    if (danmakuList.isEmpty) return const [];

    // 1. 找出所有包含广告关键词的弹幕
    final adDanmakus = <Danmaku>[];
    for (final d in danmakuList) {
      final text = d.text.toLowerCase();
      for (final kw in _adKeywords) {
        if (text.contains(kw)) {
          adDanmakus.add(d);
          break;
        }
      }
    }

    if (adDanmakus.isEmpty) return const [];

    // 按时间排序
    adDanmakus.sort((a, b) => a.time.compareTo(b.time));

    // 2. 滑动窗口统计
    // 将时间轴按窗口大小分桶
    final maxTime = videoDuration ??
        adDanmakus.last.time + 30;

    final bucketCount = (maxTime / _windowSize).ceil();
    if (bucketCount <= 0) return const [];

    final buckets = List<int>.filled(bucketCount + 1, 0);

    for (final d in adDanmakus) {
      final idx = (d.time / _windowSize).floor();
      if (idx >= 0 && idx < buckets.length) {
        buckets[idx]++;
      }
    }

    // 3. 标记命中窗口
    final rawSegments = <AdSegment>[];
    int? segStart;

    for (int i = 0; i < buckets.length; i++) {
      if (buckets[i] >= _minHitsPerWindow) {
        segStart ??= i;
      } else {
        if (segStart != null) {
          rawSegments.add(AdSegment(
            start: segStart * _windowSize,
            end: i * _windowSize,
            hitCount: _sumRange(buckets, segStart, i),
          ));
          segStart = null;
        }
      }
    }
    if (segStart != null) {
      rawSegments.add(AdSegment(
        start: segStart * _windowSize,
        end: (buckets.length) * _windowSize.toDouble(),
        hitCount: _sumRange(buckets, segStart, buckets.length),
      ));
    }

    if (rawSegments.isEmpty) return const [];

    // 4. 合并相邻片段
    final merged = <AdSegment>[];
    for (final seg in rawSegments) {
      if (merged.isEmpty) {
        merged.add(seg);
      } else {
        final last = merged.last;
        if (seg.start - last.end <= _mergeGap) {
          merged[merged.length - 1] = AdSegment(
            start: last.start,
            end: seg.end,
            hitCount: last.hitCount + seg.hitCount,
          );
        } else {
          merged.add(seg);
        }
      }
    }

    // 5. 过滤太短的片段
    return merged
        .where((s) => s.duration >= _minDuration)
        .toList();
  }

  static int _sumRange(List<int> list, int start, int end) {
    int sum = 0;
    for (int i = start; i < end && i < list.length; i++) {
      sum += list[i];
    }
    return sum;
  }

  /// 格式化时间为 mm:ss
  static String formatTime(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }
}
