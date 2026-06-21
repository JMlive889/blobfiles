import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../utils/username_validator.dart';
import 'profile_edit_provider.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileController extends _$UserProfileController {
  @override
  Future<UserProfile?> build() async {
    final userId = ref.watch(authUserIdProvider);
    if (userId == null) {
      return null;
    }

    ref.listen(authUserIdProvider, (previous, next) {
      if (previous != next) {
        ref.invalidateSelf();
      }
    });

    return UserProfileService.instance.fetchById(userId);
  }

  Future<void> saveDraft(ProfileEditDraft draft) async {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId == null) {
      throw const AuthException('Not signed in.');
    }

    final username = draft.username.trim();
    final usernameError = UsernameValidator.getUsernameError(username);
    if (usernameError != null) {
      throw UserProfileUpdateException(usernameError);
    }

    final fullName = draft.fullName.trim();
    final bio = draft.bio.trim();
    final previous = state;

    try {
      final saved = await UserProfileService.instance.save(
        userId: userId,
        username: username,
        fullName: fullName.isEmpty ? null : fullName,
        bio: bio.isEmpty ? null : bio,
      );
      state = AsyncData(saved);
      ref.read(profileEditProvider.notifier).cancel();
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}