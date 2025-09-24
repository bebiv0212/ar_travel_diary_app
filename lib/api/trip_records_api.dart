import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/token_storage.dart';

class TripRecord {
  final String id;
  TripRecord(this.id);
  factory TripRecord.fromJson(Map<String, dynamic> j) =>
      TripRecord((j['_id'] ?? j['id']).toString());
}

bool _isValidObjectId(String? s) =>
    s != null && RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(s);

class TripRecordsApi {
  final http.Client _client;
  TripRecordsApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.read();
    if (token == null) throw Exception('인증 필요: 토큰이 없습니다.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// POST /api/trip-records
  /// 필수: title, date(로컬 자정→UTC)
  /// 선택: groupId(ObjectId), content, photoUrls
  Future<TripRecord> create({
    required String title,
    required DateTime date,
    String? groupId,
    String? content,
    List<String>? photoUrls,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/trip-records');
    final headers = await _authHeaders();

    // 로컬 자정으로 맞춰 UTC ISO8601로 전송
    final dateLocalMidnight = DateTime(date.year, date.month, date.day);
    final encodedDate = dateLocalMidnight.toUtc().toIso8601String();

    final body = <String, dynamic>{
      'title': title.trim(),
      'date': encodedDate,
      if (_isValidObjectId(groupId)) 'groupId': groupId, // ✅ 유효할 때만 포함
      if (content != null && content.trim().isNotEmpty) 'content': content.trim(),
      if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
    };

    if (kDebugMode) {
      debugPrint('[TripRecordsApi] POST $uri');
      debugPrint('[TripRecordsApi] headers: {Authorization: Bearer ****, Content-Type: application/json}');
      debugPrint('[TripRecordsApi] body: ${jsonEncode(body)}');
    }

    final res = await _client.post(uri, headers: headers, body: jsonEncode(body));

    if (kDebugMode) {
      debugPrint('[TripRecordsApi] status=${res.statusCode}');
      debugPrint('[TripRecordsApi] response=${res.body}');
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('여행 기록 생성 실패: ${res.statusCode} ${res.body}');
    }
    return TripRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
