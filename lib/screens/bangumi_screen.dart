import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/bangumi.dart';
import '../services/bili_dio.dart';
import '../utils/error_messages.dart';
import '../widgets/state_views.dart';

/// 番剧列表页面（对齐 PiliPlus 的番剧首页）
class BangumiScreen extends StatefulWidget {
  const BangumiScreen({super.key});

  @override
  State<BangumiScreen> createState() => _BangumiScreenState();
}

class _BangumiScreenState extends State<BangumiScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _tabs = const [
    Tab(text: '番剧'),
    Tab(text: '国创'),
    Tab(text: '纪录片'),
    Tab(text: '电影'),
    Tab(text: '电视剧'),
  ];

  // 各 tab 对应的 season_type：1=番剧 4=国创 3=纪录片 2=电影 5=电视剧 7=综艺
  static const _seasonTypes = [1, 4, 3, 2, 5];

  final Map<int, List<Bangumi>> _cache = {};
  final Map<int, bool> _loading = {};
  final Map<int, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _ensureLoaded(_tabController.index);
      }
    });
    _ensureLoaded(0);
  }

  Future<void> _ensureLoaded(int idx) async {
    if (_cache.containsKey(idx) || _loading[idx] == true) return;
    setState(() => _loading[idx] = true);
    try {
      final list = await _fetchBangumi(_seasonTypes[idx]);
      if (!mounted) return;
      setState(() {
        _cache[idx] = list;
        _loading[idx] = false;
        _errors.remove(idx);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[idx] = FunnyMessages.fromException(e);
        _loading[idx] = false;
      });
    }
  }

  Future<List<Bangumi>> _fetchBangumi(int seasonType) async {
    final resp = await BiliDio.instance.get(
      '/x/web-interface/wbi/index/top/feed/bangumi',
      query: {'season_type': seasonType, 'ps': 30},
      wbi: true,
    );
    if (resp['code'] != 0) {
      throw Exception(resp['message'] ?? '获取番剧列表失败');
    }
    final list = resp['data']?['list'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Bangumi.fromJson)
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('追剧', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (i) {
                if (_loading[i] == true) {
                  return const LoadingView(text: '加载中...');
                }
                if (_errors[i] != null) {
                  return ErrorView(
                    message: _errors[i]!,
                    onRetry: () {
                      _cache.remove(i);
                      _loading.remove(i);
                      _ensureLoaded(i);
                    },
                  );
                }
                final list = _cache[i] ?? const [];
                if (list.isEmpty) return const EmptyView(text: '暂无内容');
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, idx) =>
                      _BangumiCard(b: list[idx]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BangumiCard extends StatelessWidget {
  final Bangumi b;
  const _BangumiCard({required this.b});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('番剧 ${b.seasonId}：${b.title}')),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  b.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: b.coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.movie),
                          ),
                        )
                      : Container(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.movie),
                        ),
                  if (b.score > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          b.score.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            b.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (b.areas != null && b.areas!.isNotEmpty)
            Text(
              b.areas!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
