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
      'Accept': 'application/json',
    };
  }

  /// POST /api/trip-records
  Future<TripRecord> create({
    required String title,
    required DateTime date,
    String? groupId,
    String? content,
    List<String>? photoUrls,
    double? lat, double? lng, // 선택: 좌표 같이 저장할 때
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/trip-records');
    final headers = await _authHeaders();

    final dateLocalMidnight = DateTime(date.year, date.month, date.day);
    final encodedDate = dateLocalMidnight.toUtc().toIso8601String();

    final body = <String, dynamic>{
      'title': title.trim(),
      'date': encodedDate,
      if (_isValidObjectId(groupId)) 'groupId': groupId,
      if (content != null && content.trim().isNotEmpty) 'content': content.trim(),
      if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
    };

    if (kDebugMode) {
      debugPrint('[TripRecordsApi] POST $uri');
      debugPrint('[TripRecordsApi] body=${_shortenJson(jsonEncode(body))}');
    }

    final res = await _client.post(uri, headers: headers, body: jsonEncode(body));
    if (kDebugMode) {
      debugPrint('[TripRecordsApi] status=${res.statusCode}');
      debugPrint('[TripRecordsApi] response=${_shortenJson(res.body)}');
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('여행 기록 생성 실패: ${res.statusCode} ${res.body}');
    }
    return TripRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// ✅ 사진 URL들을 기존 일기에 추가 (다단 폴백)
  ///  1) POST /api/trip-records/:id/photos
  ///  2) PATCH /api/trip-records/:id            (부분 업데이트 가정)
  ///  3) PUT   /api/trip-records/:id            (부분 업데이트 가정)
  ///  4) GET   /api/trip-records/:id → PUT(full) (full 문서 갱신)
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

    // 1) POST /:id/photos
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
      if (res1.statusCode == 200 || res1.statusCode == 201 || res1.statusCode == 204) return;
      if (kDebugMode) debugPrint('[TripRecordsApi] POST /photos 실패: ${res1.statusCode} ${_shortenJson(res1.body)}');
    } catch (e) {
      if (kDebugMode) debugPrint('[TripRecordsApi] POST /photos 예외: $e');
    }

    // 2) PATCH /:id
    try {
      final uri2 = Uri.parse('$kBaseUrl/api/trip-records/$recordId');
      final body2 = jsonEncode({'photoUrls': urls, 'merge': true});
      if (kDebugMode) debugPrint('[TripRecordsApi] PATCH $uri2 body=$body2');
      final res2 = await _client.patch(uri2, headers: headers, body: body2);
      if (res2.statusCode == 200 || res2.statusCode == 204) return;
      if (kDebugMode) debugPrint('[TripRecordsApi] PATCH 실패: ${res2.statusCode} ${_shortenJson(res2.body)}');
    } catch (e) {
      if (kDebugMode) debugPrint('[TripRecordsApi] PATCH 예외: $e');
    }

    // 3) PUT /:id (부분 업데이트 가정)
    try {
      final uri3 = Uri.parse('$kBaseUrl/api/trip-records/$recordId');
      final body3 = jsonEncode({'photoUrls': urls, 'merge': true});
      if (kDebugMode) debugPrint('[TripRecordsApi] PUT(partial) $uri3 body=$body3');
      final res3 = await _client.put(uri3, headers: headers, body: body3);
      if (res3.statusCode == 200 || res3.statusCode == 204) return;
      if (kDebugMode) debugPrint('[TripRecordsApi] PUT(partial) 실패: ${res3.statusCode} ${_shortenJson(res3.body)}');
    } catch (e) {
      if (kDebugMode) debugPrint('[TripRecordsApi] PUT(partial) 예외: $e');
    }

    // 4) GET → full PUT
    try {
      final getUri = Uri.parse('$kBaseUrl/api/trip-records/$recordId');
      if (kDebugMode) debugPrint('[TripRecordsApi] GET $getUri');
      final getRes = await _client.get(getUri, headers: headers);
      if (getRes.statusCode != 200) {
        throw Exception('GET 실패: ${getRes.statusCode} ${_shortenJson(getRes.body)}');
      }
      final dynamic doc = jsonDecode(getRes.body);
      if (doc is! Map<String, dynamic>) {
        throw Exception('GET 응답 형식 오류');
      }

      // 병합
      final Map<String, dynamic> full = Map<String, dynamic>.from(doc);
      final List<dynamic> existing = (full['photoUrls'] is List)
          ? List<dynamic>.from(full['photoUrls'] as List)
          : <dynamic>[];
      final merged = <String>{...existing.map((e) => e.toString()), ...urls}.toList();
      full['photoUrls'] = merged;

      if (thumbUrls != null && thumbUrls.isNotEmpty) {
        final List<dynamic> existingThumbs = (full['thumbUrls'] is List)
            ? List<dynamic>.from(full['thumbUrls'] as List)
            : <dynamic>[];
        final mergedThumbs = <String>{...existingThumbs.map((e) => e.toString()), ...thumbUrls}.toList();
        full['thumbUrls'] = mergedThumbs;
      }

      // 일부 서버는 PUT에서 _id/id 수정 불가 → 제거
      full.remove('_id');
      full.remove('id');

      final putUri = Uri.parse('$kBaseUrl/api/trip-records/$recordId');
      final putBody = jsonEncode(full);
      if (kDebugMode) {
        debugPrint('[TripRecordsApi] PUT(full) $putUri');
        debugPrint('[TripRecordsApi] PUT(full) body=${_shortenJson(putBody)}');
      }
      final putRes = await _client.put(putUri, headers: headers, body: putBody);
      if (putRes.statusCode == 200 || putRes.statusCode == 204) return;

      throw Exception('PUT(full) 실패: ${putRes.statusCode} ${_shortenJson(putRes.body)}');
    } catch (e) {
      throw Exception('일기 사진 추가 실패(모든 폴백 실패): $e');
    }
  }

  static String _shortenJson(String s, {int max = 400}) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...(${s.length} chars)';
  }
}
