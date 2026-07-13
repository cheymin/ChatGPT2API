import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/live.dart';
import '../services/bili_dio.dart';
import '../utils/error_messages.dart';
import '../widgets/state_views.dart';

/// 直播列表页面（对齐 PiliPlus 的直播首页）
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<LiveRoom> _rooms = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await _fetchRooms(_page);
      if (!mounted) return;
      setState(() {
        _rooms.addAll(rooms);
        _loading = false;
        _hasMore = rooms.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FunnyMessages.fromException(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _loadData();
  }

  Future<List<LiveRoom>> _fetchRooms(int page) async {
    final resp = await BiliDio.instance.get(
      '/x/web-interface/wbi/index/top/live',
      query: {'page': page, 'page_size': 30},
      wbi: true,
    );
    if (resp['code'] != 0) {
      throw Exception(resp['message'] ?? '获取直播列表失败');
    }
    final list = resp['data']?['list'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(LiveRoom.fromJson)
        .toList();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播间', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _rooms.clear();
          _hasMore = true;
          await _loadData();
        },
        child: _rooms.isEmpty && _loading
            ? const LoadingView(message: '正在加载直播列表...')
            : _rooms.isEmpty && _error != null
                ? ErrorView(
                    message: _error!,
                    onRetry: () {
                      _page = 1;
                      _rooms.clear();
                      _loadData();
                    },
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _rooms.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _rooms.length) {
                        return _loading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox();
                      }
                      return _LiveRoomCard(room: _rooms[i]);
                    },
                  ),
      ),
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  final LiveRoom room;
  const _LiveRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: 进入直播间
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('直播间 ${room.roomId}：${room.title}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: room.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: room.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: cs.surfaceContainerHighest,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.live_tv),
                          ),
                        )
                      : Container(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.live_tv),
                        ),
                ),
                // LIVE 标签
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: room.isLiving ? Colors.red : Colors.grey,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      room.isLiving ? 'LIVE' : '未开播',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // 在线人数
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(room.online),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          room.uname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ),
                      if (room.areaName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            room.areaName,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return '$n';
  }
}
