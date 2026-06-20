import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../widgets/centered_content_layout.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final email = ref.watch(authProvider).currentUser?.email;

    return SafeArea(
      top: false,
      child: CenteredContentLayout(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                Text(
                  'Your Library',
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium?.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  'Signed in placeholder — content archive coming soon.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                if (email != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ],
          ],
        ),
      ),
    );
  }
}