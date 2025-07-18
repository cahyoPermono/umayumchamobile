
class Profile {
  final String id;
  final String email;
  final String role;
  final String? branchId;

  Profile({
    required this.id,
    required this.email,
    required this.role,
    this.branchId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? 'unknown@example.com',
      role: json['role'] as String? ?? 'authenticated',
      branchId: json['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'branch_id': branchId,
    };
  }
}
