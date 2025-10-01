// lib/services/trip_record_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:joljak/core/token_storage.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/trip_record.dart';

const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',

  // 에뮬레이터: 10.0.2.2 / 실기기: PC LAN IP (예: 192.168.x.x)
  // defaultValue: 'http://10.0.2.2:4000', //에뮬레이터
  defaultValue: 'http://172.16.1.56:4000', //실기기 (config.dart처럼 http://~~:4000 물결 안쪽 수정후 사용)
);

class TripRecordService {
  final http.Client _client;
  final Future<String?> Function() _tokenProvider;

  TripRecordService({http.Client? client, Future<String?> Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? TokenStorage.read;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$kBaseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers() async {
    final t = await _tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  Future<T> _withTimeout<T>(Future<T> f) =>
      f.timeout(const Duration(seconds: 12));

  // GET /api/trip-records
  Future<({List<TripRecord> items, int page, int limit, int total})> fetchRecords({
    int page = 1,
    int limit = 20,
    String? groupId,
    String? month,
    String? q,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (groupId?.isNotEmpty == true) 'groupId': groupId!,
      if (month?.isNotEmpty == true) 'month': month!,
      if (q?.trim().isNotEmpty == true) 'q': q!.trim(),
    };
    try {
      final res = await _withTimeout(
        _client.get(_uri('/api/trip-records', query), headers: await _headers()),
      );
      if (res.statusCode == 401) throw Exception('인증이 필요합니다(401)');
      if (res.statusCode != 200) {
        throw Exception('불러오기 실패: ${res.statusCode} ${res.body}');
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final items = TripRecord.listFromPagedJson(map);
      return (
      items: items,
      page: (map['page'] ?? page) as int,
      limit: (map['limit'] ?? limit) as int,
      total: (map['total'] ?? items.length) as int,
      );
    } on TimeoutException {
      throw Exception('서버 응답이 지연됩니다. 네트워크를 확인해 주세요.');
    }
  }

  // POST /api/trip-records
  Future<TripRecord> createRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'date': date.toIso8601String(),
      if (content != null) 'content': content,
      // ★ 빈 문자열로 오면 null로 보내 그룹 미지정/해제 의미 유지
      if (groupId != null) 'groupId': groupId.isEmpty ? null : groupId, // ★
      if (photoUrls != null) 'photoUrls': photoUrls,
    };

    try {
      final res = await _withTimeout(
        _client.post(
          _uri('/api/trip-records'),
          headers: await _headers(),
          body: jsonEncode(body),
        ),
      );
      if (res.statusCode == 401) throw Exception('인증이 필요합니다(401)');
      if (res.statusCode != 201) {
        throw Exception('생성 실패: ${res.statusCode} ${res.body}');
      }
      return TripRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } on TimeoutException {
      throw Exception('생성 요청이 시간초과되었습니다.');
    }
  }

  // PUT /api/trip-records/:id
  Future<TripRecord> updateRecord({
    required String id,
    String? title,
    String? content,
    DateTime? date,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (date != null) 'date': date.toIso8601String(),
      // ★ 핵심: '' → null 로 변환해서 서버에 전달 (그룹 해제)
      if (groupId != null) 'groupId': groupId.isEmpty ? null : groupId, // ★
      if (photoUrls != null) 'photoUrls': photoUrls,
    };

    try {
      final res = await _withTimeout(
        _client.put(
          _uri('/api/trip-records/$id'),
          headers: await _headers(),
          body: jsonEncode(body),
        ),
      );
      if (res.statusCode == 401) throw Exception('인증이 필요합니다(401)');
      if (res.statusCode != 200) {
        throw Exception('수정 실패: ${res.statusCode} ${res.body}');
      }
      return TripRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } on TimeoutException {
      throw Exception('수정 요청이 시간초과되었습니다.');
    }
  }

  // DELETE /api/trip-records/:id
  Future<void> deleteRecord({required String id}) async {
    try {
      final res = await _withTimeout(
        _client.delete(_uri('/api/trip-records/$id'), headers: await _headers()),
      );
      if (res.statusCode == 401) throw Exception('인증이 필요합니다(401)');
      if (res.statusCode != 200) throw Exception('삭제 실패: ${res.statusCode}');
    } on TimeoutException {
      throw Exception('삭제 요청이 시간초과되었습니다.');
    }
  }
}
