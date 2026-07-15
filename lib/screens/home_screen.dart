import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'about_screen.dart';
import 'bangumi_screen.dart';
import 'category_screen.dart';
import 'home_feed_screen.dart';
import 'live_screen.dart';
import 'mine_screen.dart';
import 'search_screen.dart';
import '../utils/theme.dart';
import '../widgets/video_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const <Widget>[
    HomeFeedScreen(),
    CategoryScreen(),
    LiveScreen(),
    BangumiScreen(),
    SearchScreen(),
    MineScreen(),
    AboutScreen(),
  ];

  final _navItems = const [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '首页'),
    (icon: Icons.category_outlined, activeIcon: Icons.category, label: '分区'),
    (icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: '直播'),
    (icon: Icons.movie_outlined, activeIcon: Icons.movie, label: '追剧'),
    (icon: Icons.search, activeIcon: Icons.search, label: '搜索'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
    (icon: Icons.info_outline, activeIcon: Icons.info, label: '关于'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGoogle = context.watch<ThemeProvider>().isGoogle;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          _buildSideNav(cs, isGoogle),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }

  Widget _buildSideNav(ColorScheme cs, bool isGoogle) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(
            color: cs.outlineVariant.withOpacity(0.3),
            width: isGoogle ? 1 : 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(cs),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = index),
                    borderRadius: BorderRadius.circular(isGoogle ? 12 : 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(isGoogle ? 12 : 10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'v3.0.2',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ColorScheme cs) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.play_arrow_rounded,
              color: cs.onPrimary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'CiliCili',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}
