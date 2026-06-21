// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_badges_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserBadgesController)
final userBadgesControllerProvider = UserBadgesControllerProvider._();

final class UserBadgesControllerProvider
    extends $AsyncNotifierProvider<UserBadgesController, List<UserBadge>> {
  UserBadgesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userBadgesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userBadgesControllerHash();

  @$internal
  @override
  UserBadgesController create() => UserBadgesController();
}

String _$userBadgesControllerHash() =>
    r'aaf5b4fd211ae0615986bbfda03456396a240d6b';

abstract class _$UserBadgesController extends $AsyncNotifier<List<UserBadge>> {
  FutureOr<List<UserBadge>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<UserBadge>>, List<UserBadge>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserBadge>>, List<UserBadge>>,
              AsyncValue<List<UserBadge>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
