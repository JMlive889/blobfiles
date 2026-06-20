// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_edit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `null` = viewing mode. Non-null = editing with draft field values.

@ProviderFor(ProfileEdit)
final profileEditProvider = ProfileEditProvider._();

/// `null` = viewing mode. Non-null = editing with draft field values.
final class ProfileEditProvider
    extends $NotifierProvider<ProfileEdit, ProfileEditDraft?> {
  /// `null` = viewing mode. Non-null = editing with draft field values.
  ProfileEditProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileEditProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileEditHash();

  @$internal
  @override
  ProfileEdit create() => ProfileEdit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileEditDraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileEditDraft?>(value),
    );
  }
}

String _$profileEditHash() => r'69aa459e78ba61e529699187cfb97aa9fedd7dae';

/// `null` = viewing mode. Non-null = editing with draft field values.

abstract class _$ProfileEdit extends $Notifier<ProfileEditDraft?> {
  ProfileEditDraft? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileEditDraft?, ProfileEditDraft?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileEditDraft?, ProfileEditDraft?>,
              ProfileEditDraft?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
