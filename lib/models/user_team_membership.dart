import 'package:flutter/foundation.dart';

@immutable
class UserTeamMembership {
  const UserTeamMembership({
    required this.teamId,
    required this.teamName,
    required this.role,
  });

  final String teamId;
  final String teamName;
  final String role;

  String get roleLabel {
    if (role.isEmpty) {
      return 'Member';
    }
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  factory UserTeamMembership.fromJson(Map<String, dynamic> json) {
    final team = Map<String, dynamic>.from(json['teams'] as Map);

    return UserTeamMembership(
      teamId: team['id'] as String,
      teamName: team['name'] as String,
      role: json['role'] as String,
    );
  }
}