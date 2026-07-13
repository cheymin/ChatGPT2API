import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// B 站账号数据
class BiliAccount {
  final int? mid;
  final String? uname;
  final String? face;
  final String sessdata;
  final String biliJct;
  final String dedeUserId;
  final String buvid3;
  final String? buvid4;
  final int? level;

  const BiliAccount({
    this.mid,
    this.uname,
    this.face,
    required this.sessdata,
    required this.biliJct,
    required this.dedeUserId,
    required this.buvid3,
    this.buvid4,
    this.level,
  });

  bool get isLoggedIn => sessdata.isNotEmpty;

  Map<String, String> get cookieHeader => {
        'Cookie':
            'SESSDATA=$sessdata; bili_jct=$biliJct; DedeUserID=$dedeUserId; buvid3=$buvid3',
      };

  Map<String, dynamic> toJson() => {
        'mid': mid,
        'uname': uname,
        'face': face,
        'sessdata': sessdata,
        'biliJct': biliJct,
        'dedeUserId': dedeUserId,
        'buvid3': buvid3,
        'buvid4': buvid4,
        'level': level,
      };

  factory BiliAccount.fromJson(Map<String, dynamic> json) => BiliAccount(
        mid: json['mid'] as int?,
        uname: json['uname'] as String?,
        face: json['face'] as String?,
        sessdata: json['sessdata'] as String? ?? '',
        biliJct: json['biliJct'] as String? ?? '',
        dedeUserId: json['dedeUserId'] as String? ?? '',
        buvid3: json['buvid3'] as String? ?? '',
        buvid4: json['buvid4'] as String?,
        level: json['level'] as int?,
      );
}

/// 多账号管理器（对齐 PiliPlus AccountManager）
///
/// 支持多账号切换、添加、删除、设置当前活跃账号。
class AccountManager {
  AccountManager._();

  static const _kAccounts = 'bili_accounts';
  static const _kCurrentIndex = 'bili_current_account_index';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 所有账号
  static List<BiliAccount> get accounts {
    final raw = _prefs.getString(_kAccounts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(BiliAccount.fromJson)
          .toList(growable: true);
    } catch (_) {
      return const [];
    }
  }

  static set accounts(List<BiliAccount> value) {
    _prefs.setString(
      _kAccounts,
      jsonEncode(value.map((e) => e.toJson()).toList()),
    );
  }

  /// 当前活跃账号索引
  static int get currentIndex =>
      _prefs.getInt(_kCurrentIndex) ?? 0;

  static set currentIndex(int v) {
    _prefs.setInt(_kCurrentIndex, v);
  }

  /// 当前活跃账号（可能为空）
  static BiliAccount? get current {
    final list = accounts;
    if (list.isEmpty) return null;
    final idx = currentIndex;
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  /// 是否有任何账号
  static bool get hasAccount => accounts.isNotEmpty;

  /// 添加账号（若已存在同 mid 的则更新）
  static void addOrUpdate(BiliAccount acc) {
    final list = accounts;
    final i = list.indexWhere((a) => a.mid == acc.mid);
    if (i >= 0) {
      list[i] = acc;
    } else {
      list.add(acc);
    }
    accounts = list;
    if (i < 0) currentIndex = list.length - 1;
  }

  /// 删除账号
  static void remove(int mid) {
    final list = accounts;
    list.removeWhere((a) => a.mid == mid);
    accounts = list;
    if (currentIndex >= list.length) {
      currentIndex = list.isEmpty ? 0 : list.length - 1;
    }
  }

  /// 切换当前账号
  static void switchTo(int index) {
    if (index < 0 || index >= accounts.length) return;
    currentIndex = index;
  }

  /// 清除所有账号
  static Future<void> clearAll() async {
    await _prefs.remove(_kAccounts);
    await _prefs.remove(_kCurrentIndex);
  }
}
