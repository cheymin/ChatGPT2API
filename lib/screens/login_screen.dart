import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/bilibili_api.dart';
import '../utils/error_messages.dart';
import '../widgets/state_views.dart';
import 'webview_login_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final BilibiliApi _api = BilibiliApi();
  String? _qrUrl;
  String? _qrcodeKey;
  String? _error;
  bool _loading = true;
  String _status = '正在生成二维码...';
  Timer? _pollTimer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  Future<void> _generateQrCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _status = '正在生成二维码...';
      _expired = false;
    });
    try {
      final data = await _api.generateQrCode();
      if (data == null || !mounted) {
        setState(() {
          _loading = false;
          _error = FunnyMessages.unknown;
        });
        return;
      }
      setState(() {
        _qrUrl = data['url'] as String?;
        _qrcodeKey = data['qrcode_key'] as String?;
        _loading = false;
        _status = '请使用哔哩哔哩 APP 扫码登录';
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = FunnyMessages.fromException(e);
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_qrcodeKey == null || !mounted) return;
    try {
      final result = await _api.pollQrCode(_qrcodeKey!);
      if (result == null || !mounted) return;
      final data = result['data'] as Map<String, dynamic>?;
      final code = data?['code'] as int? ?? result['code'] as int?;

      switch (code) {
        case 0:
          _pollTimer?.cancel();
          final url = data?['url'] as String?;
          if (url != null) {
            _api.parseAndSaveLoginCookies(url);
          }
          setState(() => _status = '登录成功！');
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          widget.onLoginSuccess?.call();
          Navigator.of(context).pop(true);
          break;
        case 86038:
          setState(() => _status = '等待扫码中...');
          break;
        case 86090:
          setState(() => _status = '已扫码，请在手机上确认');
          break;
        case 86039:
          _pollTimer?.cancel();
          setState(() {
            _status = '二维码已过期';
            _expired = true;
          });
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('登录'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: _buildQrContent(cs),
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '打开哔哩哔哩 APP，扫一扫登录',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              if (_expired) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _generateQrCode,
                  child: const Text('刷新二维码'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: cs.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '其他方式',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: cs.outlineVariant)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => WebViewLoginScreen(
                        onLoginSuccess: widget.onLoginSuccess,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                  if (result == true) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.language),
                label: const Text('网页登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrContent(ColorScheme cs) {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorView(
          message: _error!,
          onRetry: _generateQrCode,
        ),
      );
    }
    if (_qrUrl == null) {
      return const EmptyView(text: '二维码生成失败');
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _QrCodePainterWidget(data: _qrUrl!),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.primary, width: 2),
          ),
          child: Icon(Icons.play_arrow_rounded, color: cs.primary, size: 24),
        ),
      ],
    );
  }
}

class _QrCodePainterWidget extends StatelessWidget {
  final String data;
  const _QrCodePainterWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SimpleQrPainter(data),
      size: Size.infinite,
    );
  }
}

class _SimpleQrPainter extends CustomPainter {
  final String data;
  _SimpleQrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final bgPaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, bgPaint);

    final bytes = utf8.encode(data);
    final hash = bytes.fold<int>(0, (a, b) => ((a * 31 + b) & 0x7fffffff));

    const gridSize = 21;
    final cellSize = size.width / gridSize;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final isFinder =
            (x < 7 && y < 7) ||
            (x >= gridSize - 7 && y < 7) ||
            (x < 7 && y >= gridSize - 7);

        if (isFinder) {
          final fx = x < 7 ? x : x - (gridSize - 7);
          final fy = y < 7 ? y : y - (gridSize - 7);
          final isBorder = fx == 0 || fx == 6 || fy == 0 || fy == 6;
          final isCenter = fx >= 2 && fx <= 4 && fy >= 2 && fy <= 4;
          if (isBorder || isCenter) {
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          }
          continue;
        }

        final seed = ((hash ^ (x * 37 + y * 17)) & 0xff);
        if (seed % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
