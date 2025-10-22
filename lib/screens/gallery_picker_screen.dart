import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 갤러리에서 사진 선택 화면
/// - 안드로이드/에뮬레이터: /sdcard/Android/data/<package>/files/uploads/*** 스캔
/// - Windows 데스크톱: 주어진 PC 로컬 경로 스캔(개발 편의)
class GalleryPickerScreen extends StatefulWidget {
  const GalleryPickerScreen({super.key, this.maxPick = 10});

  final int maxPick;

  /// 사용 예: final files = await GalleryPickerScreen.open(context, maxPick: 10);
  static Future<List<File>?> open(BuildContext context, {int maxPick = 10}) {
    return Navigator.of(context).push<List<File>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GalleryPickerScreen(maxPick: maxPick),
      ),
    );
  }

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  final List<File> _allImages = [];
  final Set<String> _selectedPaths = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // 스캔할 확장자
  static const _exts = ['.jpg', '.jpeg', '.png', '.webp'];

  Future<void> _loadImages() async {
    setState(() {
      _loading = true;
      _error = null;
      _allImages.clear();
      _selectedPaths.clear();
    });

    try {
      Directory uploadsDir;

      // ✅ Windows 데스크톱에서만 로컬 경로 직접 사용 (개발용)
      if (Platform.isWindows) {
        uploadsDir = Directory(
          r'C:\Users\LSH\Desktop\ar-memo-backend-master\ar-memo-backend\src\uploads',
        );
      } else {
        // ✅ 안드로이드: 앱 전용 외부 폴더(/sdcard/Android/data/<package>/files/)
        final ext = await getExternalStorageDirectory();
        if (ext == null) {
          setState(() {
            _loading = false;
            _error = '저장소 폴더를 찾을 수 없습니다.';
          });
          return;
        }
        uploadsDir = Directory(p.join(ext.path, 'uploads'));
      }

      if (!await uploadsDir.exists()) {
        setState(() {
          _loading = false;
          _error = '사진 폴더가 없습니다:\n${uploadsDir.path}';
        });
        return;
      }

      // 하위 날짜 폴더까지 재귀적으로 스캔
      final imgs = <File>[];
      await for (final ent in uploadsDir.list(recursive: true, followLinks: false)) {
        if (ent is File) {
          final ext = p.extension(ent.path).toLowerCase();
          if (_exts.contains(ext)) {
            imgs.add(ent);
          }
        }
      }

      // 최신 파일이 먼저 보이도록 정렬(수정시각 역순)
      imgs.sort((a, b) {
        final at = a.statSync().modified.millisecondsSinceEpoch;
        final bt = b.statSync().modified.millisecondsSinceEpoch;
        return bt.compareTo(at);
      });

      setState(() {
        _allImages.addAll(imgs);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '사진을 불러오지 못했습니다: $e';
      });
    }
  }

  void _toggleSelect(File f) {
    final path = f.path;
    final selected = _selectedPaths.contains(path);

    if (!selected && _selectedPaths.length >= widget.maxPick) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 ${widget.maxPick}장까지 선택할 수 있어요.')),
      );
      return;
    }

    setState(() {
      if (selected) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _confirm() {
    final files = _allImages.where((f) => _selectedPaths.contains(f.path)).toList();
    Navigator.of(context).pop(files);
  }

  @override
  Widget build(BuildContext context) {
    final selCount = _selectedPaths.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 선택'),
        actions: [
          if (_allImages.isNotEmpty)
            TextButton(
              onPressed: selCount > 0 ? _confirm : null,
              child: Text('완료 ($selCount/${widget.maxPick})'),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadImages,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_allImages.isEmpty) {
      return const Center(child: Text('표시할 사진이 없습니다.'));
    }

    // 반응형 그리드
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cross = (w / 110).floor().clamp(3, 6); // 타일폭 대략 100~110
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _allImages.length,
          itemBuilder: (_, i) => _Tile(
            file: _allImages[i],
            selected: _selectedPaths.contains(_allImages[i].path),
            onTap: () => _toggleSelect(_allImages[i]),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    if (_allImages.isEmpty) return const SizedBox.shrink();

    final selCount = _selectedPaths.length;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selCount > 0 ? '$selCount개 선택됨' : '사진을 선택하세요',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.icon(
              onPressed: selCount > 0 ? _confirm : null,
              icon: const Icon(Icons.check),
              label: const Text('가져오기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.file,
    required this.selected,
    required this.onTap,
  });

  final File file;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
            ),
          ),
        ),
        if (selected)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 18, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
