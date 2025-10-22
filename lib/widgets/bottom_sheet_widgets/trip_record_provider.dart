import 'package:flutter/foundation.dart';
import 'trip_record.dart';
import 'trip_record_service.dart';

class TripRecordProvider extends ChangeNotifier {
  final TripRecordService _service;
  TripRecordProvider({TripRecordService? service})
      : _service = service ?? TripRecordService();

  final List<TripRecord> _items = [];
  List<TripRecord> get items => List.unmodifiable(_items);

  bool _initialLoaded = false;
  bool get initialLoaded => _initialLoaded;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  int _page = 1;
  int _limit = 20;
  int _total = 0;
  String? _groupId;
  String? _month;
  String? _query;// 'YYYY-MM'

  bool get hasMore => _items.length < _total;
  String? get query => _query;

  void setFilters({String? groupId, String? month}) {
    _groupId = groupId;
    _month = month;
    refresh();
  }
  void setQuery(String? q, {bool refreshNow = true}) {
         final nq = (q?.trim().isEmpty ?? true) ? null : q!.trim();
        if (_query == nq) return;
        _query = nq;
        if (refreshNow) refresh();
      }



  Future<void> refresh() async {
    _page = 1;
    _items.clear();
    _total = 0;
    _error = null;
    _initialLoaded = false;
    notifyListeners();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final result = await _service.fetchRecords(
        page: _page,
        limit: _limit,
        groupId: _groupId,
        month: _month,
        q: _query,
      );

      if (_page == 1) {
        _items
          ..clear()
          ..addAll(result.items);
      } else {
        _items.addAll(result.items);
      }

      _total = result.total;
      _page += 1;
      _initialLoaded = true;
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('TripRecord load error: $e');
      }
      _error = e.toString(); // ❗️무한 로딩 방지: 에러 보관하고 진행
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 목록에서 삭제(필요 시 유지)
  Future<void> deleteById(String id) async {
    await _service.deleteRecord(id: id);
    _items.removeWhere((r) => r.id == id);
    _total = _total > 0 ? _total - 1 : 0;
    notifyListeners();
  }

  /// ✅ 새 기록 생성 후 즉시 목록 반영 (필터와 맞으면 0번에 insert)
  Future<TripRecord> createAndPrepend({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final created = await _service.createRecord(
      title: title,
      date: date,
      content: content,
      groupId: groupId,
      photoUrls: photoUrls,
    );

    final createdMonth =
        '${created.date.year.toString().padLeft(4, '0')}-${created.date.month.toString().padLeft(2, '0')}';
    final matchGroup =
        (_groupId == null || _groupId!.isEmpty) || (_groupId == created.group.name);
    final matchMonth =
        (_month == null || _month!.isEmpty) || (_month == createdMonth);

    if (_page == 1 && matchGroup && matchMonth) {
      _items.insert(0, created);
      _total += 1;
      notifyListeners();
    } else {
      await refresh(); // 필터에 안 맞으면 전체 새로고침
    }
    return created;
  }

  /// ✅ 기록 수정 후 목록에 반영 (없으면 새로고침)
  Future<TripRecord> updateRecord({
    required String id,
    String? title,
    String? content,
    DateTime? date,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final updated = await _service.updateRecord(
      id: id,
      title: title,
      content: content,
      date: date,
      groupId: groupId,
      photoUrls: photoUrls,
    );

    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = updated;
      notifyListeners();
    } else {
      await refresh(); // 목록에 없으면 전체 갱신
    }
    return updated;
  }
}
