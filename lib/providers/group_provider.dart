import 'package:flutter/material.dart';
import 'package:joljak/api/group_api.dart';

class UiGroup {
  final String id;
  String name;
  Color color;
  UiGroup({required this.id, required this.name, required this.color});
}

class GroupProvider with ChangeNotifier {
  final GroupApi _api;
  GroupProvider({GroupApi? api}) : _api = api ?? GroupApi ();

  final List<UiGroup> _groups = [];
  List<UiGroup> get groups => List.unmodifiable(_groups);

  bool _loading = false;
  bool get isLoading => _loading;

  // ✅ 한 번만 불러오기용 플래그 (Stateless에서도 안전하게 호출)
  bool _loaded = false;
  bool get loaded => _loaded;

  // ✅ 에러 상태 보관(옵션)
  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.listMyGroups();
      _groups
        ..clear()
        ..addAll(list.map((g) => UiGroup(
          id: g.id,
          name: g.name,
          color: _hexToColor(g.color),
        )));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UiGroup> create(String name, Color color) async {
    final g = await _api.create(name: name, color: color); // ← GroupApi가 Color 받는 구현
    final ui = UiGroup(id: g.id, name: g.name, color: color);
    _groups.add(ui);
    notifyListeners();
    return ui;
  }

  /// ✅ 이름/색상 수정 (낙관적 업데이트)
  Future<void> update({
    required String id,
    required String name,
    required Color color,
  }) async {
    final i = _groups.indexWhere((e) => e.id == id);
    if (i < 0) return;

    // 백업
    final old = UiGroup(id: _groups[i].id, name: _groups[i].name, color: _groups[i].color);

    // 낙관적 반영
    _groups[i].name = name;
    _groups[i].color = color;
    notifyListeners();

    try {
      // GroupApi가 Color를 받는다면:
      await _api.update(id: id, name: name, color: color);

      // 만약 API가 hex 문자열을 기대한다면 위 줄 대신 아래 사용:
      // await _api.update(id: id, name: name, colorHex: _colorToHex(color));
    } catch (e) {
      // 롤백
      _groups[i].name = old.name;
      _groups[i].color = old.color;
      notifyListeners();
      rethrow;
    }
  }

  /// ✅ 삭제 (낙관적 업데이트)
  Future<void> delete(String id) async {
    final i = _groups.indexWhere((e) => e.id == id);
    if (i < 0) return;

    final removed = _groups.removeAt(i);
    notifyListeners();

    try {
      await _api.delete(id); // ← 엔드포인트에 맞게
    } catch (e) {
      _groups.insert(i, removed); // 롤백
      notifyListeners();
      rethrow;
    }
  }

  // ── helpers ─────────────────────────────────────────────
  static Color _hexToColor(String? hex) {
    if (hex == null) return Colors.grey;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }
}
