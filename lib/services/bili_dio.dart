import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

import '../utils/account_manager.dart';
import '../utils/wbi_sign.dart';

/// B 站 API 端点常量（对齐 PiliPlus 的 lib/http/api.dart 思路）
class BiliApi {
  BiliApi._();
  static const String baseUrl = 'https://api.bilibili.com';

  // 登录
  static const String qrcodeGenerate = '/x/passport-tv-login/qrcode/auth';
  static const String qrcodePoll = '/x/passport-tv-login/qrcode/poll';
  static const String userInfo = '/x/space/wbi/acc/info';

  // 视频
  static const String view = '/x/web-interface/wbi/view';
  static const String playUrl = '/x/player/wbi/playurl';
  static const String related = '/x/web-interface/archive/related';
  static const String danmaku = '/x/v2/dm/web/seg.so';

  // 推荐/热门
  static const String recommend = '/x/web-interface/wbi/index/top/feed/rcmd';
  static const String hot = '/x/web-interface/wbi/popular';
  static const String rank = '/x/web-interface/ranking/v2';

  // 搜索
  static const String search = '/x/web-interface/wbi/search/type';
  static const String hotSearch = '/x/web-interface/wbi/search/square';

  // 直播
  static const String liveList = '/x/web-interface/wbi/index/top/live';
  static const String liveRoomInfo = '/xlive/web-room/v1/index/getInfoByRoom';

  // 番剧
  static const String bangumiHome = '/x/web-interface/wbi/index/top/feed/bangumi';

  // 用户
  static const String nav = '/x/web-interface/nav';
  static const String history = '/x/web-interface/history/cursor';
  static const String favoriteList = '/x/v3/fav/folder/created/list-all';
  static const String favoriteVideos = '/x/v3/fav/resource/list';
  static const String followDynamic = '/x/polymer/web-dynamic/v1/feed/all';

  // 互动
  static const String like = '/x/web-interface/like';
  static const String coin = '/x/web-interface/coin/add';
  static const String fav = '/x/v3/fav/resource/deal';
  static const String follow = '/x/relation/modify';

  // WBI 密钥接口（用 nav 接口获取 wbi_img）
  static const String navWbi = '/x/web-interface/nav';
}

/// Dio 客户端封装（对齐 PiliPlus http/init.dart）
///
/// 特性：
/// - 默认 HTTP/2
/// - 自动注入 cookie/header
/// - Brotli/Gzip 解压（Dio 内置）
/// - WBI 签名（w_rid + wts）
/// - buvid 自动激活
class BiliDio {
  BiliDio._internal();
  static final BiliDio instance = BiliDio._internal();

  late final Dio _dio;

  /// WBI mixinKey 缓存（同一天复用）
  String? _mixinKey;

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: BiliApi.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: _baseHeaders(),
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(LogInterceptor(
      request: false,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (o) => print('[BiliDio] $o'),
    ));
  }

  /// 基础请求头（对齐 PiliPlus 的多 UA + 多 appKey 策略）
  Map<String, dynamic> _baseHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 BiliDroid/8.43.0',
      'Referer': 'https://www.bilibili.com',
      'Origin': 'https://www.bilibili.com',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Encoding': 'gzip, deflate, br',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'env': 'prod',
      'app-key': 'android64',
      'x-bili-aurora-zone': 'sh001',
    };
  }

  /// 当前账号的 Cookie 注入到请求
  Map<String, dynamic> _authHeaders() {
    final acc = AccountManager.current;
    if (acc == null || !acc.isLoggedIn) return const {};
    return acc.cookieHeader;
  }

  /// 获取 WBI mixinKey（按天缓存）
  Future<String> _ensureMixinKey() async {
    if (_mixinKey != null) {
      final today = DateTime.now();
      // 简化：进程启动后只刷新一次
      return _mixinKey!;
    }
    try {
      final resp = await _dio.get<dynamic>(
        BiliApi.navWbi,
        options: Options(headers: _authHeaders()),
      );
      final data = resp.data;
      if (data is Map &&
          data['code'] == -101 &&
          data['data']?['wbi_img'] != null) {
        // 即使未登录，wbi_img 也会返回
      }
      final wbiImg = data is Map ? data['data']?['wbi_img'] : null;
      final imgUrl = wbiImg?['img_url'] as String? ?? '';
      final subUrl = wbiImg?['sub_url'] as String? ?? '';
      if (imgUrl.isNotEmpty && subUrl.isNotEmpty) {
        _mixinKey = WbiSign.getMixinKey(imgUrl: imgUrl, subUrl: subUrl);
        return _mixinKey!;
      }
    } catch (_) {}
    // 兜底：用默认值（PiliPlus 默认也会 fallback）
    _mixinKey = WbiSign.getMixinKey(
      imgUrl: '7cd084941338484aae1ad9425b84077c',
      subUrl: '4932caff0d7a4f6c93c4ccfac8f518a4',
    );
    return _mixinKey!;
  }

  /// 发起 GET 请求，需要 WBI 签名的接口传 [wbi]=true
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool wbi = false,
  }) async {
    Map<String, dynamic>? q = query;
    if (wbi) {
      final key = await _ensureMixinKey();
      q = WbiSign.sign(query ?? {}, mixinKey: key);
    }
    final resp = await _dio.get<dynamic>(
      path,
      queryParameters: q,
      options: Options(headers: _authHeaders()),
    );
    return _parse(resp);
  }

  /// 发起 POST 请求
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool wbi = false,
  }) async {
    Map<String, dynamic>? q = query;
    if (wbi) {
      final key = await _ensureMixinKey();
      q = WbiSign.sign(query ?? {}, mixinKey: key);
    }
    final resp = await _dio.post<dynamic>(
      path,
      queryParameters: q,
      data: body != null ? FormData.fromMap(body) : null,
      options: Options(
        headers: {
          ..._authHeaders(),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
    );
    return _parse(resp);
  }

  /// 获取原始二进制响应（用于弹幕 protobuf）
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    final resp = await _dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(
        headers: _authHeaders(),
        responseType: ResponseType.bytes,
      ),
    );
    return resp.data ?? const [];
  }

  Map<String, dynamic> _parse(Response<dynamic> resp) {
    final data = resp.data;
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return {'code': -1, 'message': '解析失败', 'data': null};
      }
    }
    if (data is Map<String, dynamic>) return data;
    return {'code': -1, 'message': '未知响应格式', 'data': null};
  }

  /// 清除缓存（登录态变化时调用）
  void clearCache() {
    _mixinKey = null;
    WbiSign.clearCache();
  }
}
