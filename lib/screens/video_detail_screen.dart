import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/danmaku.dart';
import '../models/video.dart';
import '../services/ad_skip_detector.dart';
import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';
import '../widgets/video_card.dart';

class VideoDetailScreen extends StatefulWidget {
  final String bvid;

  const VideoDetailScreen({super.key, required this.bvid});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final BilibiliApi _api = BilibiliApi();
  Video? _video;
  List<Video> _relatedVideos = [];
  VideoPlayUrl? _playUrl;
  List<Map<String, dynamic>> _comments = [];

  bool _loading = true;
  bool _loadingPlayUrl = false;
  bool _loadingComments = false;
  String? _error;

  int _currentQuality = 64;

  // ===== 恰饭广告跳过相关 =====
  /// 检测到的广告片段
  List<AdSegment> _adSegments = [];
  /// 是否正在加载弹幕以检测广告
  bool _loadingAdSegments = false;
  /// 是否开启自动跳过（仅在已集成真实播放器时生效）
  bool _autoSkipAds = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final video = await _api.getVideoDetail(widget.bvid);
      final related = await _api.getRelatedVideos(widget.bvid);
      if (!mounted) return;
      setState(() {
        _video = video;
        _relatedVideos = related;
        _loading = false;
      });
      if (video != null && video.cid != null) {
        _loadPlayUrl();
        // 异步加载弹幕并检测广告片段
        _loadAdSegments(video.cid!, videoDuration: video.duration?.toDouble());
      }
      if (video != null && video.aid != null) {
        _loadComments(video.aid!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FunnyMessages.fromException(e);
        _loading = false;
      });
    }
  }

  /// 加载弹幕并检测恰饭广告片段
  Future<void> _loadAdSegments(int cid, {double? videoDuration}) async {
    setState(() => _loadingAdSegments = true);
    try {
      final List<Danmaku> danmakuList = await _api.getDanmaku(cid);
      if (!mounted) return;
      final segments = AdSkipDetector.detect(
        danmakuList,
        videoDuration: videoDuration,
      );
      setState(() {
        _adSegments = segments;
        _loadingAdSegments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdSegments = false);
    }
  }

  Future<void> _loadPlayUrl() async {
    if (_video?.cid == null) return;
    setState(() => _loadingPlayUrl = true);
    try {
      final url = await _api.getPlayUrl(
        widget.bvid,
        _video!.cid!,
        qn: _currentQuality,
      );
      if (!mounted) return;
      setState(() {
        _playUrl = url;
        _loadingPlayUrl = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlayUrl = false);
    }
  }

  Future<void> _loadComments(int aid) async {
    setState(() => _loadingComments = true);
    try {
      final list = await _api.getComments(aid);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _openInBrowser() async {
    final url = 'https://www.bilibili.com/video/${widget.bvid}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(_video?.title ?? '视频详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadVideo)
              : _video == null
                  ? const EmptyView()
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlayer(),
                  const SizedBox(height: 16),
                  _buildAdSkipPanel(),
                  const SizedBox(height: 16),
                  Text(
                    _video!.title ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${AppTheme.formatCount(_video!.view ?? 0)}播放',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${AppTheme.formatCount(_video!.danmaku ?? 0)}弹幕',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _video!.pubDateFormatted,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUpInfo(),
                  const SizedBox(height: 16),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildDesc(),
                  const SizedBox(height: 16),
                  _buildComments(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: _buildRelated(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _video!.coverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _video!.coverUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            if (_loadingPlayUrl)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if (!_loadingPlayUrl && _playUrl == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline,
                        size: 64, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 12),
                    const Text('视频播放需要在浏览器中打开',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('在浏览器中打开'),
                    ),
                  ],
                ),
              ),
          ].whereType<Widget>().toList(),
        ),
      ),
    );
  }

  /// 构建恰饭广告跳过面板
  Widget _buildAdSkipPanel() {
    final cs = Theme.of(context).colorScheme;

    if (_loadingAdSegments) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '正在分析弹幕识别恰饭片段...',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    if (_adSegments.isEmpty) {
      // 静默显示"未检测到广告"信息
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '未检测到恰饭片段（基于弹幕关键词密度分析）',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fast_forward, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '检测到 ${_adSegments.length} 个恰饭片段',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              // 自动跳过开关
              InkWell(
                onTap: () {
                  setState(() => _autoSkipAds = !_autoSkipAds);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_autoSkipAds
                          ? '已开启自动跳过恰饭片段'
                          : '已关闭自动跳过恰饭片段'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _autoSkipAds
                        ? cs.primary.withOpacity(0.15)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _autoSkipAds ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoSkipAds
                            ? Icons.toggle_on
                            : Icons.toggle_off_outlined,
                        size: 18,
                        color: _autoSkipAds ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '自动跳过',
                        style: TextStyle(
                          fontSize: 11,
                          color: _autoSkipAds
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 时间轴可视化
          _buildAdTimeline(cs),
          const SizedBox(height: 10),
          // 片段列表
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _adSegments.asMap().entries.map((entry) {
              final i = entry.key;
              final seg = entry.value;
              return InkWell(
                onTap: () {
                  // 显示该片段的详细信息
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '片段 ${i + 1}: ${AdSkipDetector.formatTime(seg.start)}'
                        ' - ${AdSkipDetector.formatTime(seg.end)}'
                        '（${seg.duration.toStringAsFixed(0)}秒，${seg.hitCount}条弹幕命中）',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}. ${AdSkipDetector.formatTime(seg.start)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建广告时间轴可视化
  Widget _buildAdTimeline(ColorScheme cs) {
    final totalDuration = (_video?.duration ?? 0).toDouble();
    if (totalDuration <= 0) {
      return Text(
        '视频时长未知，无法显示时间轴',
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间轴条
              SizedBox(
                height: 8,
                width: width,
                child: Stack(
                  children: [
                    // 背景条
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // 广告片段标记
                    ..._adSegments.map((seg) {
                      final left = (seg.start / totalDuration) * width;
                      final segWidth =
                          (seg.duration / totalDuration) * width;
                      return Positioned(
                        left: left,
                        width: segWidth.clamp(2.0, width - left),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('00:00',
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  Text(AdSkipDetector.formatTime(totalDuration),
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpInfo() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accountColor(_video!.upName ?? 'up'),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _video!.upName?.characters.first ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _video!.upName ?? '未知UP主',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${AppTheme.formatCount(_video!.coin ?? 0)} 硬币',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('关注'),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.thumb_up_outlined, '点赞', _video!.like ?? 0),
          _buildStatItem(Icons.star_border, '收藏', _video!.favorite ?? 0),
          _buildStatItem(Icons.currency_lira_outlined, '投币', _video!.coin ?? 0),
          _buildStatItem(Icons.share, '分享', _video!.share ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 22, color: cs.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          AppTheme.formatCount(count),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
      ],
    );
  }

  Widget _buildDesc() {
    final cs = Theme.of(context).colorScheme;
    final desc = _video!.description?.trim();
    if (desc == null || desc.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('视频简介',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    final cs = Theme.of(context).colorScheme;
    if (_loadingComments) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const LoadingView(),
      );
    }
    if (_comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 40, color: cs.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('还没有评论，快来抢沙发！',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment_outlined,
                  size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '评论 ${_comments.length > 0 ? "(${_comments.length})" : ""}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_comments.take(20).map((c) => _buildCommentItem(cs, c))),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ColorScheme cs, Map<String, dynamic> comment) {
    final member = comment['member'] as Map<String, dynamic>?;
    final content = comment['content'] as Map<String, dynamic>?;
    final uname = member?['uname'] as String? ?? '匿名用户';
    final avatar = member?['avatar'] as String?;
    final message = content?['message'] as String? ?? '';
    final likeCount = _safeParseInt(comment['like']);
    final replyCount = _safeParseInt(comment['rcount']);
    final ctime = _safeParseInt(comment['ctime']);

    String timeStr = '';
    if (ctime != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ctime * 1000);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) {
        timeStr = '${diff.inDays}天前';
      } else if (diff.inHours > 0) {
        timeStr = '${diff.inHours}小时前';
      } else if (diff.inMinutes > 0) {
        timeStr = '${diff.inMinutes}分钟前';
      } else {
        timeStr = '刚刚';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accountColor(uname),
              shape: BoxShape.circle,
            ),
            child: avatar != null && avatar.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          uname.characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      uname.characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      uname,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      likeCount != null && likeCount > 0
                          ? AppTheme.formatCount(likeCount)
                          : '点赞',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      replyCount != null && replyCount > 0
                          ? AppTheme.formatCount(replyCount)
                          : '回复',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelated() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            '相关视频',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _relatedVideos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final video = _relatedVideos[index];
              return _buildRelatedItem(video);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedItem(Video video) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoDetailScreen(bvid: video.bvid!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 120,
                height: 72,
                child: CachedNetworkImage(
                  imageUrl: video.coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: cs.surfaceContainerHighest),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.upName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                  Text(
                    '${AppTheme.formatCount(video.view ?? 0)}播放',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
