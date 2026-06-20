import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_edit_provider.g.dart';

/// Draft values while the profile screen is in edit mode.
@immutable
class ProfileEditDraft {
  const ProfileEditDraft({
    required this.username,
    required this.fullName,
    required this.bio,
  });

  final String username;
  final String fullName;
  final String bio;

  ProfileEditDraft copyWith({
    String? username,
    String? fullName,
    String? bio,
  }) {
    return ProfileEditDraft(
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
    );
  }
}

/// `null` = viewing mode. Non-null = editing with draft field values.
@riverpod
class ProfileEdit extends _$ProfileEdit {
  @override
  ProfileEditDraft? build() => null;

  bool get isEditing => state != null;

  void startEditing({
    required String username,
    required String fullName,
    required String bio,
  }) {
    state = ProfileEditDraft(
      username: username,
      fullName: fullName,
      bio: bio,
    );
  }

  void updateUsername(String value) {
    final draft = state;
    if (draft == null) {
      return;
    }
    state = draft.copyWith(username: value);
  }

  void updateFullName(String value) {
    final draft = state;
    if (draft == null) {
      return;
    }
    state = draft.copyWith(fullName: value);
  }

  void updateBio(String value) {
    final draft = state;
    if (draft == null) {
      return;
    }
    state = draft.copyWith(bio: value);
  }

  void cancel() {
    state = null;
  }
}