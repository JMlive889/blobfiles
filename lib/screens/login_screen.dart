import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../auth/oauth_return_handler.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

void _onXSignIn() {}

void _onForgotPassword() {}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignIn = true;
  bool _isSubmittingEmail = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _isEmailBusy => _isSubmittingEmail;
  bool get _isGoogleBusy => _isGoogleLoading;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleOAuthReturn();
      });
    }
  }

  void _handleOAuthReturn() {
    final message = OAuthReturnHandler.canceledMessageFromCurrentUrl();
    if (message == null) {
      return;
    }

    OAuthReturnHandler.cleanCurrentUrl();
    if (!mounted) {
      return;
    }

    setState(() {
      _isGoogleLoading = false;
      _infoMessage = message;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  Future<bool> _confirmGoogleRedirect() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Continue with Google?'),
          content: const Text(
            "You'll be redirected to Google to sign in.\n\n"
            'To cancel at any time, use your browser back button or close '
            "Google's sign-in page — you'll return here and can use email "
            'instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay on this page'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue to Google'),
            ),
          ],
        );
      },
    );

    return shouldContinue ?? false;
  }

  Future<void> _signInWithGoogle() async {
    _clearMessages();

    if (kIsWeb) {
      final shouldContinue = await _confirmGoogleRedirect();
      if (!shouldContinue || !mounted) {
        return;
      }
    } else {
      setState(() => _isGoogleLoading = true);
    }

    try {
      await AuthService.instance.signInWithGoogle();

      // Web OAuth redirects away; native completes in-process.
      if (!kIsWeb) {
        ref.read(authProvider.notifier).syncFromClient();
        if (!mounted) return;
        context.go('/library');
      }
    } catch (error) {
      if (!mounted) return;
      final message = AuthService.messageFromError(error);
      if (message == 'Google sign in was canceled.') {
        setState(() {
          _isGoogleLoading = false;
          _infoMessage =
              'Google sign in was canceled. You can try again or use email instead.';
        });
        return;
      }
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = message;
      });
    }
  }

  Future<void> _submit() async {
    _clearMessages();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmittingEmail = true);

    try {
      if (_isSignIn) {
        final response = await AuthService.instance.signIn(
          _emailController.text,
          _passwordController.text,
        );

        if (response.session == null) {
          if (!mounted) return;
          setState(() {
            _isSubmittingEmail = false;
            _errorMessage =
                'Sign in failed. Check your email and password, or confirm your email first.';
          });
          return;
        }
      } else {
        final response = await AuthService.instance.signUp(
          _emailController.text,
          _passwordController.text,
        );

        if (response.session == null) {
          if (!mounted) return;
          setState(() {
            _isSubmittingEmail = false;
            _infoMessage =
                'Account created. Check your email to confirm, then sign in.';
          });
          return;
        }
      }

      ref.read(authProvider.notifier).syncFromClient();

      if (!mounted) return;
      context.go('/library');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmittingEmail = false;
        _errorMessage = AuthService.messageFromError(error);
      });
      return;
    }

    if (mounted) {
      setState(() => _isSubmittingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _isEmailBusy ? null : () => context.go('/landing'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'blobfiles',
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium?.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 32),
                    _AuthModeToggle(
                      isSignIn: _isSignIn,
                      isEnabled: !_isEmailBusy && !_isGoogleBusy,
                      onChanged: (isSignIn) {
                        if (_isEmailBusy || _isGoogleBusy) return;
                        setState(() {
                          _isSignIn = isSignIn;
                          _errorMessage = null;
                          _infoMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    _SocialAuthButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: (_isEmailBusy || _isGoogleBusy)
                          ? null
                          : _signInWithGoogle,
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Redirects to Google. Use your browser back button to cancel.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SocialAuthButton(
                      label: 'Continue with X',
                      icon: Icons.close_rounded,
                      onPressed: (_isEmailBusy || _isGoogleBusy)
                          ? null
                          : _onXSignIn,
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null) ...[
                      _AuthMessageBanner(
                        message: _errorMessage!,
                        backgroundColor: colorScheme.error.withValues(alpha: 0.15),
                        foregroundColor: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_infoMessage != null) ...[
                      _AuthMessageBanner(
                        message: _infoMessage!,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.15),
                        foregroundColor: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isEmailBusy,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Enter your email';
                        }
                        if (!email.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                      textInputAction:
                          _isSignIn ? TextInputAction.done : TextInputAction.next,
                      enabled: !_isEmailBusy,
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Enter your password';
                        }
                        if (!_isSignIn && (value?.length ?? 0) < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignIn) ...[
                      const SizedBox(height: 16),
                      _AuthTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        enabled: !_isEmailBusy,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (_isSignIn) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isEmailBusy ? null : _onForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isEmailBusy ? null : _submit,
                        style: ElevatedButton.styleFrom(shape: AppTheme.shapeBorder),
                        child: _isEmailBusy
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Text(_isSignIn ? 'Sign In' : 'Create Account'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Your data is encrypted. We never store plain-text passwords.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthMessageBanner extends StatelessWidget {
  const _AuthMessageBanner({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.borderRadiusAll,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
            ),
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.isSignIn,
    required this.onChanged,
    required this.isEnabled,
  });

  final bool isSignIn;
  final ValueChanged<bool> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppTheme.borderRadiusAll,
          border: Border.all(color: colorScheme.outline),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _ToggleSegment(
                label: 'Sign In',
                isActive: isSignIn,
                onTap: isEnabled ? () => onChanged(true) : null,
              ),
            ),
            Expanded(
              child: _ToggleSegment(
                label: 'Create Account',
                isActive: !isSignIn,
                onTap: isEnabled ? () => onChanged(false) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: AppTheme.borderRadiusAll,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive
                ? colorScheme.onPrimary
                : textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(shape: AppTheme.shapeBorder),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      validator: validator,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}