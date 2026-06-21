import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_provider.dart';
import '../models/user_team_membership.dart';
import '../services/team_service.dart';

part 'user_teams_provider.g.dart';

@riverpod
class UserTeamsController extends _$UserTeamsController {
  @override
  Future<List<UserTeamMembership>> build() async {
    final userId = ref.watch(authUserIdProvider);
    if (userId == null) {
      return const [];
    }

    ref.listen(authUserIdProvider, (previous, next) {
      if (previous != next) {
        ref.invalidateSelf();
      }
    });

    return TeamService.instance.fetchMembershipsForUser(userId);
  }

  Future<void> createTeam(String name) async {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId == null) {
      throw const TeamCreateException('Not signed in.');
    }

    await TeamService.instance.createTeam(
      name: name,
      ownerId: userId,
    );
    ref.invalidateSelf();
  }
}