import 'package:flutter/material.dart';

class BottomSheetRecord extends StatefulWidget {
  const BottomSheetRecord({
    super.key,
    this.scrollController,
    this.images = const [],
    this.title = 'Title',
    this.description = 'Description',
    this.date,
    this.location = 'Group',
  });

  final ScrollController? scrollController;
  final List<String> images;
  final String title;
  final String description;
  final DateTime? date;
  final String location;

  @override
  State<BottomSheetRecord> createState() => _BottomSheetRecordState();
}

class _BottomSheetRecordState extends State<BottomSheetRecord> {
  final PageController _pageController = PageController();
  int _page = 0;

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = widget.date ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 사진 캐러셀 ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: widget.images.isEmpty
                      ? Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Text("사진"),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: widget.images.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (_, i) => Image.network(
                            widget.images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                ),

                // 2) 점 인디케이터: 이미지 수만큼 생성, 현재(_page)만 회색
                if (widget.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (i == _page) ? Colors.grey : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 타이틀/설명/날짜 + 위치 ───────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title.isEmpty ? "Title" : widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description.isEmpty
                        ? "Description"
                        : widget.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(dt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // 오른쪽 위치
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, size: 16, color: Colors.purple[700]),
                const SizedBox(width: 4),
                Text(
                  widget.location.isEmpty ? 'Group' : widget.location,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
