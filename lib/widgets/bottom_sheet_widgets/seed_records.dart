// lib/models/record.dart
class Record {
  final List<String> images;
  final String title;
  final String description;
  final DateTime date;
  final String location;

  Record({
    required this.images,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
  });

  factory Record.fromMap(Map<String, dynamic> m) => Record(
    images: (m['images'] as List).map((e) => e.toString()).toList(),
    title: m['title'] as String,
    description: m['description'] as String,
    date: m['date'] as DateTime,
    location: m['location'] as String,
  );
}



/// 샘플 레코드들 (로컬 하드코딩)
final List<Record> sampleRecords = [
  Record(
    images: [
      'https://picsum.photos/seed/jeju1/1200/800',
      'https://picsum.photos/seed/jeju2/1200/800',
      'https://picsum.photos/seed/jeju3/1200/800',
    ],
    title: '한라산 등반',
    description: '성판악 코스 / 구름 멋짐',
    date: DateTime(2025, 4, 12),
    location: 'Jeju Group',
  ),
  Record(
    images: [
      'https://picsum.photos/seed/seoul1/1200/800',
      'https://picsum.photos/seed/seoul2/1200/800',
    ],
    title: '서울 야경',
    description: '남산타워 근처 산책',
    date: DateTime(2025, 8, 30),
    location: 'Seoul Group',
  ),
];

/// 나중에 DB로 교체할 자리: 지금은 로컬 샘플을 Future로 반환
Future<List<Record>> fetchRecords() async {
  await Future.delayed(const Duration(milliseconds: 300)); // 로딩 느낌
  return sampleRecords;
}

