import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Placeholder for a team image until storage buckets are wired up.
///
/// Pass [imageUrl] later when team avatars are stored in Supabase Storage.
class TeamImagePlaceholder extends StatelessWidget {
  const TeamImagePlaceholder({
    super.key,
    this.size = 64,
    this.imageUrl,
  });

  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppTheme.borderRadiusAll,
        border: Border.all(color: colorScheme.outline),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? null
          : Icon(
              Icons.groups_outlined,
              size: size * 0.42,
              color: colorScheme.onSurfaceVariant,
            ),
    );
  }
}