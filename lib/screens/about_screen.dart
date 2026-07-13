import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/error_messages.dart';
import '../utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String projectUrl = 'https://github.com/cheymin/CiliCili';
  static const String author = 'Cheymin';
  static const String version = '3.0.0';
  static const String appName = 'CiliCili';
  static const String buildDate = '2026-07-13';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGoogle = context.watch<ThemeProvider>().isGoogle;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('关于',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 560,
            child: Column(
              children: [
                _buildLogo(cs),
                const SizedBox(height: 20),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'v$version',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '一个免费开源的第三方哔哩哔哩电视客户端',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 32),
                _buildCard(
                  cs,
                  isGoogle,
                  children: [
                    _buildInfoRow('作者', author),
                    _buildDivider(cs),
                    _buildInfoRow('项目地址', projectUrl, isLink: true),
                    _buildDivider(cs),
                    _buildInfoRow('构建日期', buildDate),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  cs,
                  isGoogle,
                  children: [
                    _buildInfoRow('数据来源', 'Bilibili 官方 API'),
                    _buildDivider(cs),
                    _buildInfoRow(
                        '声明', '本项目仅供学习交流，请勿用于商业用途。'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _openProjectUrl,
                      icon: const Icon(Icons.code, size: 18),
                      label: const Text('查看源码'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showUpdateDialog(context),
                      icon: const Icon(Icons.update, size: 18),
                      label: const Text('检查更新'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Made with ❤️ by Cheymin',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme cs) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.play_arrow_rounded, color: cs.onPrimary, size: 56),
    );
  }

  Widget _buildCard(ColorScheme cs, bool isGoogle,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(isGoogle ? 12 : 10),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.3),
          width: isGoogle ? 1 : 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return InkWell(
        onTap: isLink ? _openProjectUrl : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isLink ? cs.primary : cs.onSurface,
                    fontWeight: isLink ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 14,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDivider(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 96),
      child: Divider(height: 1, thickness: 0.5, color: cs.outlineVariant.withOpacity(0.3)),
    );
  }

  Future<void> _openProjectUrl() async {
    final uri = Uri.parse(projectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('检查更新'),
        content: Text(FunnyMessages.unknown),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }
}
