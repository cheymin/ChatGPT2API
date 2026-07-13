import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/bilibili_api.dart';
import '../utils/storage.dart';

/// 通过 WebView 打开 B 站登录页，登录后自动提取 Cookie
class WebViewLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const WebViewLoginScreen({super.key, this.onLoginSuccess});

  @override
  State<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends State<WebViewLoginScreen> {
  late final WebViewController _controller;
  final BilibiliApi _api = BilibiliApi();
  bool _checking = false;
  bool _loggedIn = false;

  /// B 站登录页 URL
  static const String _loginUrl = 'https://passport.bilibili.com/login';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // 登录成功后通常会跳转到 www.bilibili.com
          onNavigationRequest: (request) {
            if (request.url.contains('www.bilibili.com') && !_loggedIn) {
              _tryExtractCookies();
            }
            return NavigationDecision.navigate;
          },
          // 页面加载完成时也尝试一次（覆盖 SPA 不触发导航的情况）
          onPageFinished: (url) {
            if (url.contains('bilibili.com') && !_loggedIn) {
              _tryExtractCookies();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  /// 尝试从 WebView 中通过 JS 读取 document.cookie 提取登录凭据
  Future<void> _tryExtractCookies() async {
    if (_checking || _loggedIn) return;
    setState(() => _checking = true);

    try {
      // 等待 Cookie 写入完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 通过 JavaScript 读取 document.cookie
      // runJavaScriptReturningResult 返回值是 String（含引号）
      final raw = await _controller.runJavaScriptReturningResult(
        'document.cookie || ""',
      );

      final cookieStr = raw is String
          ? (raw.startsWith('"') && raw.endsWith('"')
              ? raw.substring(1, raw.length - 1)
              : raw)
          : raw.toString();

      String? sessdata;
      String? biliJct;
      String? dedeUserId;
      String? buvid3;

      // 解析 "k1=v1; k2=v2; ..." 格式
      for (final pair in cookieStr.split(';')) {
        final eq = pair.indexOf('=');
        if (eq <= 0) continue;
        final name = pair.substring(0, eq).trim();
        final value = pair.substring(eq + 1).trim();
        if (name == 'SESSDATA') {
          sessdata = value;
        } else if (name == 'bili_jct') {
          biliJct = value;
        } else if (name == 'DedeUserID') {
          dedeUserId = value;
        } else if (name == 'buvid3') {
          buvid3 = value;
        }
      }

      if (sessdata != null && sessdata.isNotEmpty) {
        _loggedIn = true;
        StorageService.sessdata = sessdata;
        if (biliJct != null) StorageService.biliJct = biliJct;
        if (dedeUserId != null) StorageService.dedeUserId = dedeUserId;
        if (buvid3 != null) StorageService.buvid3 = buvid3;

        // 验证登录是否有效
        final userInfo = await _api.getUserInfo();
        if (userInfo != null && userInfo['isLogin'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('登录成功！'),
                backgroundColor: Colors.green,
              ),
            );
            widget.onLoginSuccess?.call();
            Navigator.of(context).pop(true);
          }
        } else {
          // Cookie 提取到了但 API 验证失败，提示用户重试
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已提取 Cookie，但验证登录状态失败，请重试'),
                duration: Duration(seconds: 2),
              ),
            );
            _loggedIn = false;
          }
        }
      }
    } catch (_) {
      // 忽略错误，继续等待
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_checking,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('网页登录'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: _checking
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请在下方网页中登录哔哩哔哩账号，登录成功后自动提取凭据',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _tryExtractCookies,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('已登录?'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
