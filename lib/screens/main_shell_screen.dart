import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import 'create_screen.dart';
import 'library_screen.dart';
import 'new_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.child,
    this.initialIndex = 1,
  });

  /// Nested route content from [ShellRoute] (profile, templates, help, etc.).
  final Widget child;

  /// 0 = New, 1 = Library, 2 = Create
  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _tabs = [
    _MainTab(
      label: 'New',
      icon: Icons.public,
    ),
    _MainTab(
      label: 'Library',
      icon: Icons.video_library,
    ),
    _MainTab(
      label: 'Create',
      icon: Icons.add_circle,
    ),
  ];

  late int _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);

  String _currentPath(BuildContext context) {
    return GoRouterState.of(context).uri.path;
  }

  bool _isSecondaryRoute(BuildContext context) {
    final path = _currentPath(context);
    return path == '/library/profile' ||
        path == '/library/templates' ||
        path == '/library/help';
  }

  String? _secondaryTitle(String path) {
    return switch (path) {
      '/library/profile' => 'Profile Settings',
      '/library/templates' => 'Templates',
      '/library/help' => 'Help',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final path = _currentPath(context);
    final isSecondary = _isSecondaryRoute(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isSecondary
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/library'),
              )
            : null,
        title: Text(
          isSecondary
              ? (_secondaryTitle(path) ?? _tabs[_currentIndex].label)
              : _tabs[_currentIndex].label,
        ),
        actions: [
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _MainMenuDrawer(
        onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
      ),
      body: SizedBox.expand(
        child: isSecondary
            ? widget.child
            : IndexedStack(
                index: _currentIndex,
                children: const [
                  NewScreen(),
                  LibraryScreen(),
                  CreateScreen(),
                ],
              ),
      ),
      bottomNavigationBar: ColoredBox(
        color: colorScheme.surface,
        child: SafeArea(
          top: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outline, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                _scaffoldKey.currentState?.closeEndDrawer();
                if (_isSecondaryRoute(context)) {
                  context.go('/library');
                }
                setState(() => _currentIndex = index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: colorScheme.surface,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              items: [
                for (final tab in _tabs)
                  BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    activeIcon: Icon(
                      tab.icon,
                      color: colorScheme.primary,
                    ),
                    label: tab.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainMenuDrawer extends ConsumerWidget {
  const _MainMenuDrawer({required this.onClose});

  final VoidCallback? onClose;

  void _closeAndNavigate(BuildContext context, String path) {
    onClose?.call();
    context.go(path);
  }

  Future<void> _logout(WidgetRef ref) async {
    onClose?.call();
    await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final email = ref.watch(authProvider).currentUser?.email;
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Drawer(
      width: drawerWidth.clamp(280, 360),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Material(
        color: colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'Menu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (email != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  email,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            _DrawerMenuTile(
              icon: Icons.person_outline,
              label: 'Profile Settings',
              onTap: () => _closeAndNavigate(context, '/library/profile'),
            ),
            _DrawerMenuTile(
              icon: Icons.dashboard_customize_outlined,
              label: 'Templates',
              onTap: () => _closeAndNavigate(context, '/library/templates'),
            ),
            _DrawerMenuTile(
              icon: Icons.help_outline,
              label: 'Help',
              onTap: () => _closeAndNavigate(context, '/library/help'),
            ),
            const Spacer(),
            Divider(height: 1, color: colorScheme.outline),
            _DrawerMenuTile(
              icon: Icons.logout,
              label: 'Logout',
              iconColor: colorScheme.error,
              textColor: colorScheme.error,
              fontWeight: FontWeight.w600,
              onTap: () => _logout(ref),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.fontWeight = FontWeight.w500,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        icon,
        color: iconColor ?? colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor ?? colorScheme.onSurface,
          fontSize: 16,
          fontWeight: fontWeight,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MainTab {
  const _MainTab({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}