import 'dart:convert';class GroupInfo {
  final String id;
  final String name;
  final String? color;

  const GroupInfo({
    required this.id,
    required this.name,
    this.color,
  });

  static const empty = GroupInfo(id: '', name: '', color: null);

  factory GroupInfo.fromJson(dynamic json) {
    if (json is String) {
      return GroupInfo(id: json, name: '', color: null);
    } else if (json is Map<String, dynamic>) {
      return GroupInfo(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        color: json['color']?.toString(),
      );
    }
    return empty;
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'color': color,
  };
}

class TripRecord {
  final String id;
  final String userId;
  final GroupInfo group; // ✅ non-null
  final String title;
  final String content;
  final DateTime date;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
    GroupInfo? group, // 입력은 nullable…
    this.content = '',
  }) : group = group ?? GroupInfo.empty; // ✅ …하지만 내부는 항상 non-null

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    return TripRecord(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      group: GroupInfo.fromJson(json['groupId']),
      title: json['title'] as String,
      content: (json['content'] ?? '') as String,
      date: DateTime.parse(json['date'] as String),
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static List<TripRecord> listFromPagedJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? []);
    return items.map((e) => TripRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      // 서버가 문자열을 기대하면 id만 보내세요:
      'groupId': group.id.isEmpty ? null : group.id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 👉 편의 게터: UI에서 그냥 record.groupName 써도 됨
  String get groupName => group.name;
  String? get groupColor => group.color;
}
