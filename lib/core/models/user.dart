enum UserRole { guest, user, creator, moderator, admin, superAdmin }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.role = UserRole.user,
    this.isVerified = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.trophies = 0,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final UserRole role;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final int trophies;
  bool get isCreator => role == UserRole.creator;

  UserProfile copyWith({
    String? id,
    String? displayName,
    bool? isFollowing,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      role: role,
      isVerified: isVerified,
      followersCount: followersCount,
      followingCount: followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
