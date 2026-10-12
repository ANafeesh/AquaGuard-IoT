/// Represents an authenticated user or guest session in AquaGuard
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final bool isGuest;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isGuest = false,
    required this.createdAt,
  });

  String get initials {
    if (isGuest) return 'GT';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
    }
    return email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'AG';
  }

  static int min(int a, int b) => a < b ? a : b;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isGuest': isGuest,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? 'guest_uid',
      email: json['email'] as String? ?? 'guest@aquaguard.io',
      displayName: json['displayName'] as String? ?? 'Guest User',
      isGuest: json['isGuest'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory UserModel.guest() {
    return UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@aquaguard.local',
      displayName: 'Guest Observer',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }
}
