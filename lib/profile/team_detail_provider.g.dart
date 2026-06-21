// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeamDetailController)
final teamDetailControllerProvider = TeamDetailControllerFamily._();

final class TeamDetailControllerProvider
    extends $AsyncNotifierProvider<TeamDetailController, TeamDetail> {
  TeamDetailControllerProvider._({
    required TeamDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamDetailControllerHash();

  @override
  String toString() {
    return r'teamDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TeamDetailController create() => TeamDetailController();

  @override
  bool operator ==(Object other) {
    return other is TeamDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamDetailControllerHash() =>
    r'58fb8bc5305787c46fcd86a12466282ce7a3771a';

final class TeamDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TeamDetailController,
          AsyncValue<TeamDetail>,
          TeamDetail,
          FutureOr<TeamDetail>,
          String
        > {
  TeamDetailControllerFamily._()
    : super(
        retry: null,
        name: r'teamDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamDetailControllerProvider call(String teamId) =>
      TeamDetailControllerProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamDetailControllerProvider';
}

abstract class _$TeamDetailController extends $AsyncNotifier<TeamDetail> {
  late final _$args = ref.$arg as String;
  String get teamId => _$args;

  FutureOr<TeamDetail> build(String teamId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TeamDetail>, TeamDetail>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TeamDetail>, TeamDetail>,
              AsyncValue<TeamDetail>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
