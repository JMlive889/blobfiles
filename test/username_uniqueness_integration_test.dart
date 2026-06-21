import 'dart:io';

import 'package:blobfiles/config/supabase_config.dart';
import 'package:blobfiles/services/user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live Supabase username uniqueness test (two accounts required).
///
/// Run:
/// ```bash
/// BLOBFILES_TEST_EMAIL_1='user1@example.com' \
/// BLOBFILES_TEST_PASSWORD_1='secret' \
/// BLOBFILES_TEST_EMAIL_2='user2@example.com' \
/// BLOBFILES_TEST_PASSWORD_2='secret' \
/// flutter test test/username_uniqueness_integration_test.dart
/// ```
void main() {
  final email1 = Platform.environment['BLOBFILES_TEST_EMAIL_1'] ?? '';
  final password1 = Platform.environment['BLOBFILES_TEST_PASSWORD_1'] ?? '';
  final email2 = Platform.environment['BLOBFILES_TEST_EMAIL_2'] ?? '';
  final password2 = Platform.environment['BLOBFILES_TEST_PASSWORD_2'] ?? '';

  final hasCredentials = email1.isNotEmpty &&
      password1.isNotEmpty &&
      email2.isNotEmpty &&
      password2.isNotEmpty;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  });

  test(
    'second account cannot claim the first account username',
    () async {
      final client = Supabase.instance.client;
      final probeUsername =
          'uniq${DateTime.now().millisecondsSinceEpoch % 100000000}';

      await client.auth.signInWithPassword(email: email1, password: password1);
      final user1 = client.auth.currentUser;
      expect(user1, isNotNull, reason: 'Account 1 must sign in');

      await UserProfileService.instance.save(
        userId: user1!.id,
        username: probeUsername,
      );

      final availableForUser1 = await UserProfileService.instance
          .isUsernameAvailable(username: probeUsername, userId: user1.id);
      expect(availableForUser1, isTrue,
          reason: 'Owner can keep their own username');

      await client.auth.signOut();
      await client.auth.signInWithPassword(email: email2, password: password2);
      final user2 = client.auth.currentUser;
      expect(user2, isNotNull, reason: 'Account 2 must sign in');

      final availableForUser2 = await UserProfileService.instance
          .isUsernameAvailable(username: probeUsername, userId: user2!.id);
      expect(availableForUser2, isFalse,
          reason: 'RPC should report username as taken for other users');

      expect(
        () => UserProfileService.instance.save(
          userId: user2.id,
          username: probeUsername,
        ),
        throwsA(
          predicate(
            (error) =>
                error is UserProfileUpdateException &&
                error.message == 'That username is already taken.',
          ),
        ),
        reason: 'Save must reject duplicate username even on localhost',
      );

      await client.auth.signOut();
    },
    skip: hasCredentials ? false : 'Set BLOBFILES_TEST_EMAIL_1/2 and passwords',
  );
}