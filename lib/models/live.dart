/// 直播间模型
class LiveRoom {
  final int roomId;
  final int uid;
  final String uname;
  final String title;
  final String cover;
  final int online;
  final int liveStatus;
  final String areaName;
  final String? face;
  final int? attention;
  final int? area;

  LiveRoom({
    required this.roomId,
    required this.uid,
    required this.uname,
    required this.title,
    required this.cover,
    required this.online,
    required this.liveStatus,
    required this.areaName,
    this.face,
    this.attention,
    this.area,
  });

  bool get isLiving => liveStatus == 1;

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      roomId: json['roomid'] as int? ?? 0,
      uid: json['uid'] as int? ?? 0,
      uname: json['uname'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cover: (json['cover'] as String?) ?? (json['pic'] as String?) ?? '',
      online: json['online'] as int? ?? 0,
      liveStatus: json['live_status'] as int? ??
          json['live_status'] as int? ??
          0,
      areaName: (json['area_name'] as String?) ??
          (json['area_v2_name'] as String?) ??
          '',
      face: json['face'] as String?,
      attention: json['attention'] as int?,
      area: json['area'] as int? ?? json['area_v2_id'] as int?,
    );
  }

  String get coverUrl {
    if (cover.isEmpty) return '';
    if (cover.startsWith('//')) return 'https:$cover';
    if (cover.startsWith('http')) return cover;
    return 'https:$cover';
  }
}

/// 直播流地址
class LiveStreamInfo {
  final int qn;
  final String desc;
  final String url;

  LiveStreamInfo({
    required this.qn,
    required this.desc,
    required this.url,
  });

  factory LiveStreamInfo.fromJson(Map<String, dynamic> json) {
    return LiveStreamInfo(
      qn: json['qn'] as int? ?? 0,
      desc: json['desc'] as String? ?? '',
      url: (json['url'] as String?) ?? '',
    );
  }
}
