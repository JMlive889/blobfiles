import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import '../models/user_badge.dart';
import '../profile/profile_edit_provider.dart';
import '../profile/user_badges_provider.dart';
import '../profile/user_profile_provider.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/username_validator.dart';
import '../widgets/centered_scroll_view.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;
  String? _actionError;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _startEditing({
    required String username,
    required String fullName,
    required String bio,
  }) {
    setState(() => _actionError = null);
    ref.read(profileEditProvider.notifier).startEditing(
          username: username,
          fullName: fullName,
          bio: bio,
        );
    _usernameController.text = username;
    _fullNameController.text = fullName;
    _bioController.text = bio;
  }

  void _cancelEditing() {
    setState(() => _actionError = null);
    ref.read(profileEditProvider.notifier).cancel();
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveChanges() async {
    final draft = ref.read(profileEditProvider);
    if (draft == null || _isSaving) {
      return;
    }

    final usernameError = UsernameValidator.getUsernameError(draft.username);
    if (usernameError != null) {
      setState(() => _actionError = usernameError);
      return;
    }

    setState(() {
      _isSaving = true;
      _actionError = null;
    });

    try {
      await ref.read(userProfileControllerProvider.notifier).saveDraft(draft);
      if (!mounted) {
        return;
      }
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _actionError = _messageFromError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _messageFromError(Object error) {
    if (error is UserProfileUpdateException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    return 'Could not save profile. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profileAsync = ref.watch(userProfileControllerProvider);
    final badgesAsync = ref.watch(userBadgesControllerProvider);
    final editDraft = ref.watch(profileEditProvider);
    final isEditing = editDraft != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (auth.isLoading) {
      return const SafeArea(
        top: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final authUser = auth.currentUser;
    if (authUser == null) {
      return SafeArea(
        top: false,
        child: Center(
          child: Text(
            'No user signed in.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (profileAsync.isLoading && !profileAsync.hasValue) {
      return const SafeArea(
        top: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileAsync.hasError && !profileAsync.hasValue) {
      return SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load profile.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(userProfileControllerProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = profileAsync.value;
    final usernameError = isEditing
        ? UsernameValidator.getUsernameError(editDraft.username)
        : null;
    final canSave = isEditing && usernameError == null && !_isSaving;

    return SafeArea(
      top: false,
      child: Builder(
        builder: (context) {
          final metadata = authUser.userMetadata ?? {};
          final username = profile?.username ??
              _readString(metadata['username']) ??
              _usernameFromEmail(authUser.email);
          final fullName = profile?.fullName ??
              _readString(metadata['full_name']) ??
              _readString(metadata['name']);
          final avatarUrl = profile?.avatarUrl ??
              _readString(metadata['avatar_url']) ??
              _readString(metadata['picture']);
          final bio = profile?.bio ?? _readString(metadata['bio']);
          final email = authUser.email;

          return CenteredScrollView(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileActionBar(
                  isEditing: isEditing,
                  isSaving: _isSaving,
                  canSave: canSave,
                  onEdit: () => _startEditing(
                    username: username,
                    fullName: fullName ?? '',
                    bio: bio ?? '',
                  ),
                  onCancel: _cancelEditing,
                  onSave: _saveChanges,
                ),
                if (_actionError != null) ...[
                  const SizedBox(height: 8),
                  _ProfileErrorBanner(message: _actionError!),
                ],
                const SizedBox(height: 8),
                Center(
                  child: _ProfileAvatar(
                    avatarUrl: avatarUrl,
                    showChangeButton: isEditing,
                    onChangePhoto: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo upload coming soon.'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (!isEditing) ...[
                  Text(
                    fullName ?? 'Your Profile',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '@$username',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    label: 'Username',
                    value: username,
                  ),
                  _ProfileField(
                    label: 'Email',
                    value: email ?? 'Not set',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    label: 'Full name',
                    value: fullName ?? 'Not set',
                  ),
                  _ProfileField(
                    label: 'Bio',
                    value: bio ?? 'Not set',
                    multiline: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Badges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileBadgesSection(badgesAsync: badgesAsync),
                ] else ...[
                  Text(
                    'Edit Profile',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'yourname',
                    enabled: !_isSaving,
                    errorText: usernameError,
                    onChanged: ref.read(profileEditProvider.notifier).updateUsername,
                  ),
                  _ProfileField(
                    label: 'Email',
                    value: email ?? 'Not set',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTextField(
                    controller: _fullNameController,
                    label: 'Full name',
                    hint: 'Your name',
                    enabled: !_isSaving,
                    onChanged: ref.read(profileEditProvider.notifier).updateFullName,
                  ),
                  _ProfileTextField(
                    controller: _bioController,
                    label: 'Bio',
                    hint: 'Tell us about yourself',
                    enabled: !_isSaving,
                    maxLines: 4,
                    onChanged: ref.read(profileEditProvider.notifier).updateBio,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String _usernameFromEmail(String? email) {
    if (email == null || !email.contains('@')) {
      return 'user';
    }
    return email.split('@').first;
  }
}

class _ProfileActionBar extends StatelessWidget {
  const _ProfileActionBar({
    required this.isEditing,
    required this.isSaving,
    required this.canSave,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final bool isEditing;
  final bool isSaving;
  final bool canSave;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Edit profile',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: isSaving ? null : onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave ? onSave : null,
          style: FilledButton.styleFrom(shape: AppTheme.shapeBorder),
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.15),
        borderRadius: AppTheme.borderRadiusAll,
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    this.avatarUrl,
    this.showChangeButton = false,
    this.onChangePhoto,
  });

  final String? avatarUrl;
  final bool showChangeButton;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(
                  Icons.person_outline,
                  size: 56,
                  color: colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        if (showChangeButton) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onChangePhoto,
            style: OutlinedButton.styleFrom(shape: AppTheme.shapeBorder),
            child: const Text('Change photo'),
          ),
        ],
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
            maxLines: multiline ? null : 1,
            overflow: multiline ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProfileBadgesSection extends StatelessWidget {
  const _ProfileBadgesSection({required this.badgesAsync});

  final AsyncValue<List<UserBadge>> badgesAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return badgesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Could not load badges.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      data: (badges) {
        if (badges.isEmpty) {
          return Text(
            'No badges yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          children: [
            for (final badge in badges) ...[
              _ProfileBadgeRow(badge: badge),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileBadgeRow extends StatelessWidget {
  const _ProfileBadgeRow({required this.badge});

  final UserBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            badge.displayName,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        _BadgeLevelDots(
          level: badge.level,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

class _BadgeLevelDots extends StatelessWidget {
  const _BadgeLevelDots({
    required this.level,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int level;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final clampedLevel = level.clamp(1, 3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var dot = 1; dot <= 3; dot++) ...[
          if (dot > 1) const SizedBox(width: 6),
          Icon(
            dot <= clampedLevel ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: dot <= clampedLevel ? activeColor : inactiveColor,
          ),
        ],
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int maxLines;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          errorBorder: OutlineInputBorder(
            borderRadius: AppTheme.borderRadiusAll,
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppTheme.borderRadiusAll,
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
        ),
      ),
    );
  }
}