class UserProfile {
  final String username;
  final String email;
  final String role;
  final String? picture;

  UserProfile({
    required this.username,
    required this.email,
    required this.role,
    this.picture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      picture: json['picture']?.toString(),
    );
  }
}