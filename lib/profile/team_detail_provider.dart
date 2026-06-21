import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_provider.dart';
import '../models/team_detail.dart';
import '../services/team_service.dart';

part 'team_detail_provider.g.dart';

@riverpod
class TeamDetailController extends _$TeamDetailController {
  @override
  Future<TeamDetail> build(String teamId) async {
    final userId = ref.watch(authUserIdProvider);
    if (userId == null) {
      throw const TeamDetailException('Not signed in.');
    }

    return TeamService.instance.fetchTeamDetail(
      teamId: teamId,
      viewerUserId: userId,
    );
  }

  Future<void> addMemberByUsername(String username) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) {
      throw const TeamDetailException('Not signed in.');
    }

    await TeamService.instance.addMemberByUsername(
      teamId: teamId,
      username: username,
    );

    final updated = await TeamService.instance.fetchTeamDetail(
      teamId: teamId,
      viewerUserId: userId,
    );
    state = AsyncData(updated);
  }
}