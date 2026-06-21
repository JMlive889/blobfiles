import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/centered_scroll_view.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CenteredScrollView(
          scrollable: false,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 16),
                    Text(
                      'Your Content Archive • Clip • Organize • Share',
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          shape: AppTheme.shapeBorder,
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Browse Outside'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('How it Works'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const _Footer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppTheme.borderRadiusAll,
            border: Border.all(
              color: colorScheme.outline,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.folder_copy_rounded,
            size: 36,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'blobfiles',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.bodyMedium;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Terms', style: linkStyle),
        ),
        Text(
          '•',
          style: linkStyle?.copyWith(color: colorScheme.outline),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Privacy Policy', style: linkStyle),
        ),
      ],
    );
  }
}