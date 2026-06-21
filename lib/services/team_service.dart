import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team_detail.dart';
import '../models/team_member.dart';
import '../models/user_team_membership.dart';

class TeamService {
  TeamService._();

  static final TeamService instance = TeamService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Teams the user belongs to.
  ///
  /// [role] is read from [team_members.role]; team details come from the
  /// embedded [teams] relation.
  Future<List<UserTeamMembership>> fetchMembershipsForUser(String userId) async {
    final data = await _client
        .from('team_members')
        .select('id, role, teams(id, name)')
        .eq('user_id', userId)
        .order('name', referencedTable: 'teams');

    return data
        .map((row) => UserTeamMembership.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  /// Team summary and roster for the signed-in viewer.
  Future<TeamDetail> fetchTeamDetail({
    required String teamId,
    required String viewerUserId,
  }) async {
    try {
      final teamData = await _client
          .from('teams')
          .select('id, name')
          .eq('id', teamId)
          .maybeSingle();

      if (teamData == null) {
        throw const TeamDetailException('Team not found.');
      }

      final membershipData = await _client
          .from('team_members')
          .select('role')
          .eq('team_id', teamId)
          .eq('user_id', viewerUserId)
          .maybeSingle();

      if (membershipData == null) {
        throw const TeamDetailException('You do not have access to this team.');
      }

      final members = await fetchMembersForTeam(teamId);
      final team = Map<String, dynamic>.from(teamData);

      return TeamDetail(
        id: _asString(team['id']) ?? teamId,
        name: _asString(team['name']) ?? 'Team',
        viewerRole: _asString(membershipData['role']) ?? 'member',
        members: members,
      );
    } on TeamDetailException {
      rethrow;
    } on PostgrestException catch (error) {
      throw TeamDetailException(_messageFromPostgrest(error, 'Could not load team.'));
    } catch (error) {
      throw TeamDetailException('Could not load team: $error');
    }
  }

  /// Roster for [teamId] with profile fields from [users].
  Future<List<TeamMember>> fetchMembersForTeam(String teamId) async {
    final List<dynamic> data = await _fetchTeamMembersData(teamId);

    final members = data
        .map((row) => TeamMember.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: true);

    members.sort((a, b) {
      final roleCompare = _roleSortKey(a.role).compareTo(_roleSortKey(b.role));
      if (roleCompare != 0) {
        return roleCompare;
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return members;
  }

  static int _roleSortKey(String role) {
    return switch (role.toLowerCase()) {
      'owner' => 0,
      'admin' => 1,
      _ => 2,
    };
  }

  /// Adds an existing user to [teamId] by [username] (case-insensitive).
  Future<void> addMemberByUsername({
    required String teamId,
    required String username,
  }) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      throw const TeamDetailException('Username is required.');
    }

    final userId = await _client.rpc(
      'find_user_id_by_username',
      params: {'p_username': normalized},
    );

    if (userId == null) {
      throw const TeamDetailException('User not found.');
    }

    try {
      await _client.from('team_members').insert({
        'team_id': teamId,
        'user_id': userId,
        'role': 'member',
      });
    } on PostgrestException catch (error) {
      throw TeamDetailException(_mapMemberInsertError(error));
    }
  }

  Future<List<dynamic>> _fetchTeamMembersData(String teamId) async {
    try {
      return await _client
          .from('team_members')
          .select('role, user_id, users(id, username, full_name)')
          .eq('team_id', teamId);
    } on PostgrestException {
      return await _client
          .from('team_members')
          .select('role, user_id')
          .eq('team_id', teamId);
    }
  }

  static String? _asString(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static String _messageFromPostgrest(
    PostgrestException error,
    String fallback,
  ) {
    if (error.message.isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  static String _normalizeUsername(String username) {
    var value = username.trim();
    if (value.startsWith('@')) {
      value = value.substring(1);
    }
    return value;
  }

  static String _mapMemberInsertError(PostgrestException error) {
    final message = error.message.toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';
    final haystack = '$message $details';

    if (error.code == '23505' || haystack.contains('team_members_team_user_unique')) {
      return 'That user is already a member of this team.';
    }
    if (haystack.contains('row-level security')) {
      return 'You do not have permission to add members to this team.';
    }
    if (error.message.isNotEmpty) {
      return error.message;
    }
    return 'Could not add member. Please try again.';
  }

  /// Creates a team owned by [ownerId].
  ///
  /// The database trigger `teams_add_owner_membership` also inserts the owner
  /// into [team_members] with `role = 'owner'`.
  Future<void> createTeam({
    required String name,
    required String ownerId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const TeamCreateException('Team name is required.');
    }

    try {
      await _client.from('teams').insert({
        'name': trimmedName,
        'owner_id': ownerId,
      });
    } on PostgrestException catch (error) {
      throw TeamCreateException(
        error.message.isNotEmpty
            ? error.message
            : 'Could not create team. Please try again.',
      );
    }
  }
}

class TeamCreateException implements Exception {
  const TeamCreateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TeamDetailException implements Exception {
  const TeamDetailException(this.message);

  final String message;

  @override
  String toString() => message;
}