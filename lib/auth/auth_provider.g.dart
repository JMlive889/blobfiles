// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Central auth state for the app. Subscribes to Supabase [AuthState] changes.

@ProviderFor(Auth)
final authProvider = AuthProvider._();

/// Central auth state for the app. Subscribes to Supabase [AuthState] changes.
final class AuthProvider extends $NotifierProvider<Auth, AuthState> {
  /// Central auth state for the app. Subscribes to Supabase [AuthState] changes.
  AuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authHash();

  @$internal
  @override
  Auth create() => Auth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authHash() => r'890e547e218584ce462d02b6f9d65e54d0df07f3';

/// Central auth state for the app. Subscribes to Supabase [AuthState] changes.

abstract class _$Auth extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Stable auth user id for data providers. Rebuilds only when the id changes.

@ProviderFor(authUserId)
final authUserIdProvider = AuthUserIdProvider._();

/// Stable auth user id for data providers. Rebuilds only when the id changes.

final class AuthUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Stable auth user id for data providers. Rebuilds only when the id changes.
  AuthUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return authUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$authUserIdHash() => r'629d96cdf76c8353c1bcf3114dbb9aac30f62a04';
