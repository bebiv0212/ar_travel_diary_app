class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;

  User({required this.id, required this.email, this.name, this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'].toString(),
    email: j['email'] as String,
    name: j['name'] as String?,
    avatarUrl: j['avatarUrl'] as String?,
  );
}
