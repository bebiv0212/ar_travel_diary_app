import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';        // const String kBaseUrl = 'https://YOUR.API';
import '../core/token_storage.dart';  // TokenStorage.read() 로 Bearer 토큰 가져오기

class Group {
  final String id;
  final String name;
  final String? color; // '#RRGGBB' 문자열 가정
  Group({required this.id, required this.name, this.color});

  factory Group.fromJson(Map<String, dynamic> j) => Group(
    id: j['id'].toString(),
    name: j['name'] as String,
    color: j['color'] as String?,
  );
}

String colorToHex6(Color c) {
  final rgb = c.value & 0x00FFFFFF; // ARGB → RGB만
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class GroupApi {
  final http.Client _client;
  GroupApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.read();
    if (token == null) throw Exception('인증 필요: 토큰이 없습니다.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// POST /api/groups  (name 필수, color 선택)
  Future<Group> create({required String name, Color? color}) async {
    final uri = Uri.parse('$kBaseUrl/api/groups');
    final headers = await _authHeaders();
    final body = <String, dynamic>{'name': name};
    if (color != null) body['color'] = colorToHex6(color);

    final res = await _client.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('그룹 생성 실패: ${res.statusCode} ${res.body}');
    }
    return Group.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// (옵션) 내 그룹 목록
  Future<List<Group>> listMyGroups() async {
    final uri = Uri.parse('$kBaseUrl/api/groups');
    final headers = await _authHeaders();
    final res = await _client.get(uri, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('그룹 목록 실패: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('응답 형식이 올바르지 않습니다.');
  }
}
