import 'package:flutter/foundation.dart';

@immutable
class UserBadge {
  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.level,
    required this.earnedAt,
    this.source,
  });

  final String id;
  final String userId;
  final String badgeType;
  final int level;
  final DateTime earnedAt;
  final String? source;

  String get displayName {
    if (badgeType.isEmpty) {
      return 'Badge';
    }
    return badgeType
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeType: json['badge_type'] as String,
      level: json['level'] as int,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      source: json['source'] as String?,
    );
  }
}