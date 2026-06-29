class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarPath,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarPath;

  bool get isAdmin => role == 'admin';

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      avatarPath: map['avatarPath'] as String?,
    );
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarPath,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
