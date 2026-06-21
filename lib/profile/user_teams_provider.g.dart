// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_teams_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserTeamsController)
final userTeamsControllerProvider = UserTeamsControllerProvider._();

final class UserTeamsControllerProvider
    extends
        $AsyncNotifierProvider<UserTeamsController, List<UserTeamMembership>> {
  UserTeamsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userTeamsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userTeamsControllerHash();

  @$internal
  @override
  UserTeamsController create() => UserTeamsController();
}

String _$userTeamsControllerHash() =>
    r'e1b0826ec200d2adbbe95172ab508747ee2fc9d6';

abstract class _$UserTeamsController
    extends $AsyncNotifier<List<UserTeamMembership>> {
  FutureOr<List<UserTeamMembership>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<UserTeamMembership>>,
              List<UserTeamMembership>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UserTeamMembership>>,
                List<UserTeamMembership>
              >,
              AsyncValue<List<UserTeamMembership>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
