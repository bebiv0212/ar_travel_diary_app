import 'package:flutter/material.dart';
import 'package:joljak/api/group_api.dart';

class UiGroup { final String id, name; final Color color;
UiGroup({required this.id, required this.name, required this.color}); }

class GroupProvider with ChangeNotifier {
  final GroupApi _api; GroupProvider({GroupApi? api}) : _api = api ?? GroupApi();
  final List<UiGroup> _groups = []; List<UiGroup> get groups => List.unmodifiable(_groups);
  bool _loading = false; bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true; notifyListeners();
    try {
      final list = await _api.listMyGroups();
      _groups..clear()..addAll(list.map((g)=>UiGroup(
          id: g.id, name: g.name, color: _hexToColor(g.color))));
    } finally { _loading = false; notifyListeners(); }
  }

  Future<UiGroup> create(String name, Color color) async {
    final g = await _api.create(name: name, color: color);
    final ui = UiGroup(id: g.id, name: g.name, color: color);
    _groups.add(ui); notifyListeners(); return ui;
  }

  static Color _hexToColor(String? hex){ if(hex==null)return Colors.grey;
  var h = hex.replaceAll('#',''); if(h.length==6) h='FF$h'; return Color(int.parse(h,radix:16)); }
}
