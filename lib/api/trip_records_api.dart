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

  /// ✅ 업로드된 사진 URL들을 기존 일기에 추가
  /// 서버 구현에 따라 엔드포인트가 다를 수 있어, 1) POST /api/trip-records/:id/photos 우선,
  /// 실패 시 2) PATCH /api/trip-records/:id 로 폴백합니다.
  Future<void> addPhotos({
    required String recordId,
    required List<String> urls,
    List<String>? thumbUrls,
  }) async {
    if (!_isValidObjectId(recordId)) {
      throw ArgumentError('recordId 형식이 올바르지 않습니다.');
    }
    if (urls.isEmpty) return;

    final headers = await _authHeaders();

    // 1) 선호: POST /photos
    try {
      final uri1 = Uri.parse('$kBaseUrl/api/trip-records/$recordId/photos');
      final body1 = jsonEncode({
        'urls': urls,
        if (thumbUrls != null && thumbUrls.isNotEmpty) 'thumbUrls': thumbUrls,
      });

      if (kDebugMode) {
        debugPrint('[TripRecordsApi] POST $uri1 body=$body1');
      }

      final res1 = await _client.post(uri1, headers: headers, body: body1);
      if (res1.statusCode == 200 || res1.statusCode == 201 || res1.statusCode == 204) {
        return;
      } else {
        if (kDebugMode) {
          debugPrint('[TripRecordsApi] POST /photos 실패: ${res1.statusCode} ${res1.body}');
        }
        // 아래 폴백 시도
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TripRecordsApi] POST /photos 예외: $e');
      // 아래 폴백 시도
    }

    // 2) 폴백: PATCH /:id (photoUrls 병합)
    final uri2 = Uri.parse('$kBaseUrl/api/trip-records/$recordId');
    final body2 = jsonEncode({
      'photoUrls': urls,
      'merge': true, // 서버가 병합 모드를 지원한다면 활용
    });

    if (kDebugMode) {
      debugPrint('[TripRecordsApi] PATCH $uri2 body=$body2');
    }

    final res2 = await _client.patch(uri2, headers: headers, body: body2);
    if (!(res2.statusCode == 200 || res2.statusCode == 204)) {
      throw Exception('일기 사진 추가 실패: ${res2.statusCode} ${res2.body}');
    }
  }
}
