import 'package:flutter/foundation.dart';

import 'team_member.dart';

@immutable
class TeamDetail {
  const TeamDetail({
    required this.id,
    required this.name,
    required this.viewerRole,
    required this.members,
  });

  final String id;
  final String name;
  final String viewerRole;
  final List<TeamMember> members;

  String get viewerRoleLabel {
    if (viewerRole.isEmpty) {
      return 'Member';
    }
    return viewerRole[0].toUpperCase() + viewerRole.substring(1).toLowerCase();
  }

  bool get canManageMembers {
    final role = viewerRole.toLowerCase();
    return role == 'owner' || role == 'admin';
  }
}