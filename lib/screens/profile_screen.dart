import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../models/user_badge.dart';
import '../profile/profile_edit_provider.dart';
import '../models/user_team_membership.dart';
import '../profile/user_badges_provider.dart';
import '../profile/user_teams_provider.dart';
import '../profile/user_profile_provider.dart';
import '../services/team_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/username_validator.dart';
import '../widgets/centered_scroll_view.dart';
import '../widgets/team_image_placeholder.dart';

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
  bool _isCheckingUsername = false;
  String? _actionError;
  String? _usernameAvailabilityError;
  Timer? _usernameAvailabilityDebounce;

  @override
  void dispose() {
    _usernameAvailabilityDebounce?.cancel();
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _clearUsernameAvailabilityState() {
    _usernameAvailabilityDebounce?.cancel();
    _isCheckingUsername = false;
    _usernameAvailabilityError = null;
  }

  String? _usernameInlineError(String username) {
    return UsernameValidator.getUsernameError(username) ??
        _usernameAvailabilityError;
  }

  void _scheduleUsernameAvailabilityCheck({
    required String username,
    required String userId,
    required String savedUsername,
  }) {
    _usernameAvailabilityDebounce?.cancel();
    _usernameAvailabilityDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _checkUsernameAvailability(
        username: username,
        userId: userId,
        savedUsername: savedUsername,
      ),
    );
  }

  Future<void> _checkUsernameAvailability({
    required String username,
    required String userId,
    required String savedUsername,
  }) async {
    final trimmed = username.trim();
    final validatorError = UsernameValidator.getUsernameError(trimmed);
    if (validatorError != null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailabilityError = null;
      });
      return;
    }

    if (trimmed.toLowerCase() == savedUsername.trim().toLowerCase()) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailabilityError = null;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final available = await UserProfileService.instance.isUsernameAvailable(
        username: trimmed,
        userId: userId,
      );
      if (!mounted) {
        return;
      }

      final currentUsername = ref.read(profileEditProvider)?.username.trim();
      if (currentUsername != trimmed) {
        return;
      }

      setState(() {
        _isCheckingUsername = false;
        _usernameAvailabilityError =
            available ? null : 'That username is already taken.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailabilityError = null;
      });
    }
  }

  void _startEditing({
    required String username,
    required String fullName,
    required String bio,
  }) {
    setState(() {
      _actionError = null;
      _clearUsernameAvailabilityState();
    });
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
    setState(() {
      _actionError = null;
      _clearUsernameAvailabilityState();
    });
    ref.read(profileEditProvider.notifier).cancel();
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveChanges() async {
    final draft = ref.read(profileEditProvider);
    if (draft == null || _isSaving) {
      return;
    }

    final usernameError = _usernameInlineError(draft.username);
    if (usernameError != null || _isCheckingUsername) {
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
      final message = _messageFromError(error);
      setState(() {
        if (message == 'That username is already taken.') {
          _usernameAvailabilityError = message;
          _actionError = null;
        } else {
          _actionError = message;
        }
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
    if (error is TeamCreateException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    return 'Could not save profile. Please try again.';
  }

  void _openTeamDetail(UserTeamMembership membership) {
    context.push('/library/teams/${membership.teamId}');
  }

  Future<void> _showCreateTeamDialog() async {
    final teamName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CreateTeamDialog(),
    );

    if (teamName == null || teamName.trim().isEmpty || !mounted) {
      return;
    }

    try {
      await ref
          .read(userTeamsControllerProvider.notifier)
          .createTeam(teamName.trim());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team created')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileControllerProvider);
    final badgesAsync = ref.watch(userBadgesControllerProvider);
    final teamsAsync = ref.watch(userTeamsControllerProvider);
    final editDraft = ref.watch(profileEditProvider);
    final isEditing = editDraft != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!AuthService.instance.isAuthenticated) {
      return SafeArea(
        top: false,
        child: Center(
          child: Text(
            'You must be signed in to view your profile.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final authUser = AuthService.instance.currentUser!;

    if (profileAsync.isLoading && !profileAsync.hasValue) {
      return const SafeArea(
        top: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileAsync.hasError) {
      return SafeArea(
        top: false,
        child: Center(
          child: Text('Error: ${profileAsync.error}'),
        ),
      );
    }

    final profile = profileAsync.value;
    final savedUsername = profile?.username ??
        _readString(authUser.userMetadata?['username']) ??
        _usernameFromEmail(authUser.email);
    final usernameInlineError = isEditing
        ? _usernameInlineError(editDraft.username)
        : null;
    final canSave = isEditing &&
        usernameInlineError == null &&
        !_isCheckingUsername &&
        !_isSaving;

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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'My Teams',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Create Team',
                        onPressed: _showCreateTeamDialog,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileTeamsSection(
                    teamsAsync: teamsAsync,
                    onTeamTap: _openTeamDetail,
                  ),
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
                    errorText: usernameInlineError,
                    onChanged: (value) {
                      ref
                          .read(profileEditProvider.notifier)
                          .updateUsername(value);
                      setState(() => _usernameAvailabilityError = null);
                      _scheduleUsernameAvailabilityCheck(
                        username: value,
                        userId: authUser.id,
                        savedUsername: savedUsername,
                      );
                    },
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

class _CreateTeamDialog extends StatefulWidget {
  const _CreateTeamDialog();

  @override
  State<_CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<_CreateTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Team'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            hintText: 'Enter a team name',
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Team name is required';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _ProfileTeamsSection extends StatelessWidget {
  const _ProfileTeamsSection({
    required this.teamsAsync,
    required this.onTeamTap,
  });

  final AsyncValue<List<UserTeamMembership>> teamsAsync;
  final ValueChanged<UserTeamMembership> onTeamTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return teamsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Could not load teams.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return Text(
            'You don’t belong to any teams yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          children: [
            for (final membership in teams) ...[
              _ProfileTeamRow(
                membership: membership,
                onTap: () => onTeamTap(membership),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileTeamRow extends StatelessWidget {
  const _ProfileTeamRow({
    required this.membership,
    required this.onTap,
  });

  final UserTeamMembership membership;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const TeamImagePlaceholder(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.teamName,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      membership.roleLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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