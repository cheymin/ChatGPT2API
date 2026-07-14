/// 番剧/影视模型
class Bangumi {
  final int seasonId;
  final String title;
  final String cover;
  final String? subtitle;
  final int? followCount;
  final int? viewCount;
  final double score;
  final String? areas;
  final String? styles;
  final int? pubDate;
  final int mediaType;

  Bangumi({
    required this.seasonId,
    required this.title,
    required this.cover,
    this.subtitle,
    this.followCount,
    this.viewCount,
    this.score = 0,
    this.areas,
    this.styles,
    this.pubDate,
    this.mediaType = 1,
  });

  factory Bangumi.fromJson(Map<String, dynamic> json) {
    final publish = json['publish'] is Map ? json['publish'] as Map : null;
    return Bangumi(
      seasonId: json['season_id'] as int? ?? 0,
      title: (json['title'] as String?) ?? '',
      cover: (json['cover'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      followCount: _parseInt(json['order'])?['follow'] ?? _parseInt(json['stat'])?['follow'],
      viewCount: _parseInt(json['order'])?['play'] ?? _parseInt(json['stat'])?['view'],
      score: (json['media_score'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0,
      areas: (json['areas'] as List?)
          ?.map((e) => e is Map ? e['name'] as String? : '')
          .join(' / '),
      styles: (json['styles'] as List?)
          ?.map((e) => e is Map ? e['name'] as String? : '')
          .join(' / '),
      pubDate: publish != null ? _parseInt(publish['pub_time']) : null,
      mediaType: _parseInt(json['type']) ?? 1,
    );
  }

  String get coverUrl {
    if (cover.isEmpty) return '';
    if (cover.startsWith('//')) return 'https:$cover';
    if (cover.startsWith('http')) return cover;
    return 'https:$cover';
  }
}

dynamic _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
