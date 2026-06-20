import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_provider.dart';
import '../models/user_badge.dart';
import '../services/user_badge_service.dart';

part 'user_badges_provider.g.dart';

@riverpod
class UserBadgesController extends _$UserBadgesController {
  @override
  Future<List<UserBadge>> build() async {
    final authUser = ref.watch(authProvider).currentUser;
    if (authUser == null) {
      return const [];
    }

    ref.listen(authProvider, (previous, next) {
      if (previous?.currentUser?.id != next.currentUser?.id) {
        ref.invalidateSelf();
      }
    });

    return UserBadgeService.instance.fetchByUserId(authUser.id);
  }
}