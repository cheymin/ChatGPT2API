import 'dart:convert';
import 'package:crypto/crypto.dart';

/// B 站 WBI 签名实现
///
/// 参考：https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/misc/sign/wbi.md
/// PiliPlus 的 lib/utils/wbi_sign.dart 也是同一实现思路。
///
/// 流程：
///   1. 从 userInfo 接口拿 img_url 和 sub_url，提取文件名拼接成 imgKey+subKey
///   2. 通过固定 _mixinKeyEncTab 表对 imgKey+subKey 重排，取前 32 字符 → mixinKey
///   3. 请求参数加 wts（秒级时间戳），按 key 排序 urlencode 拼接
///   4. w_rid = md5(queryStr + mixinKey)
class WbiSign {
  WbiSign._();

  /// 固定混淆表，对 imgKey+subKey 重排
  static const List<int> _mixinKeyEncTab = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
    33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40, 61,
    26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36,
    20, 34, 44, 52,
  ];

  /// 缓存当天的 mixinKey（key 为 "YYYY-MM-DD"）
  static String? _cachedMixinKey;
  static String? _cachedDate;

  /// 从 img_url + sub_url 提取并生成 mixinKey
  ///
  /// [imgUrl] 来自 userInfo.wbi_img.img_url
  /// [subUrl] 来自 userInfo.wbi_img.sub_url
  static String getMixinKey({required String imgUrl, required String subUrl}) {
    final today = _todayKey();
    if (_cachedDate == today && _cachedMixinKey != null) {
      return _cachedMixinKey!;
    }

    // 提取文件名（去扩展名）
    String extractFilename(String url) {
      // 7f9c5b9b5e5c7a5e5e5e5e5e5e5e5e5e.png → 7f9c5b9b5e5c7a5e5e5e5e5e5e5e5e5e
      final uri = Uri.tryParse(url);
      final last = uri?.pathSegments.isNotEmpty == true
          ? uri!.pathSegments.last
          : url.split('/').last;
      final dot = last.lastIndexOf('.');
      return dot > 0 ? last.substring(0, dot) : last;
    }

    final raw = extractFilename(imgUrl) + extractFilename(subUrl);
    // 用混淆表对 raw 的前 64 字符重排
    final sb = StringBuffer();
    for (final i in _mixinKeyEncTab) {
      if (i < raw.length) {
        sb.write(raw[i]);
      }
    }
    final key = sb.toString().substring(0, 32);
    _cachedMixinKey = key;
    _cachedDate = today;
    return key;
  }

  /// 对参数做 WBI 签名，返回带 wts 和 w_rid 的新 Map
  ///
  /// [mixinKey] 通过 [getMixinKey] 获取
  static Map<String, dynamic> sign(
    Map<String, dynamic> params, {
    required String mixinKey,
    int? wts,
  }) {
    final ts = wts ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final p = Map<String, dynamic>.from(params);
    p['wts'] = ts;

    // 按 key 字典序排序后 urlencode 拼接
    final keys = p.keys.toList()..sort();
    final sb = StringBuffer();
    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      final v = p[k];
      // 过滤 !'()* 等字符（B 站要求）
      final encoded = Uri.encodeQueryComponent(
        v?.toString() ?? '',
      );
      sb.write('$k=$encoded');
      if (i < keys.length - 1) sb.write('&');
    }
    final queryStr = sb.toString();
    final wRid = md5.convert(utf8.encode(queryStr + mixinKey)).toString();
    p['w_rid'] = wRid;
    return p;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 清除缓存（登录态变化时调用）
  static void clearCache() {
    _cachedMixinKey = null;
    _cachedDate = null;
  }
}
