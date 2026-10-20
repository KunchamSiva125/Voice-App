class UserModel {
  final String id;
  final String name;
  final String username;
  final String role;
  final bool active;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.active,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'FAMILY_MEMBER',
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'active': active,
    };
  }
}
