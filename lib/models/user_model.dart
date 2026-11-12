class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? nim;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phoneNumber,
    this.nim,
  });

  factory UserModel.guest() {
    return const UserModel(
      id: 'usr_mhs_01',
      name: 'Muhammad Naufal Fahrel',
      email: 'mhs@kampus.ac.id',
      role: 'Mahasiswa',
      avatarUrl: null,
      phoneNumber: '081234567890',
      nim: '22051204001',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'nim': nim,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'Mahasiswa',
      avatarUrl: map['avatarUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      nim: map['nim'] as String?,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    String? phoneNumber,
    String? nim,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nim: nim ?? this.nim,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: $role, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.avatarUrl == avatarUrl &&
        other.phoneNumber == phoneNumber &&
        other.nim == nim;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        role.hashCode ^
        avatarUrl.hashCode ^
        phoneNumber.hashCode ^
        nim.hashCode;
  }
}
