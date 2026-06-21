import 'package:blobfiles/services/user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileService._parseAvailability', () {
    test('accepts bool true/false', () {
      expect(UserProfileService.parseAvailabilityForTest(true), isTrue);
      expect(UserProfileService.parseAvailabilityForTest(false), isFalse);
    });

    test('accepts string true/false from PostgREST', () {
      expect(UserProfileService.parseAvailabilityForTest('true'), isTrue);
      expect(UserProfileService.parseAvailabilityForTest('false'), isFalse);
    });

    test('treats null and unknown values as unavailable', () {
      expect(UserProfileService.parseAvailabilityForTest(null), isFalse);
      expect(UserProfileService.parseAvailabilityForTest(1), isFalse);
    });
  });

  group('UserProfileService unique violation mapping', () {
    test('detects users_username_lower_idx in message', () {
      expect(
        UserProfileService.isUsernameUniqueViolationForTest(
          code: '23505',
          message: 'duplicate key value violates unique constraint',
          details: 'Key (lower(username))=(taken) already exists.',
        ),
        isTrue,
      );
    });

    test('detects legacy users_username_idx', () {
      expect(
        UserProfileService.isUsernameUniqueViolationForTest(
          code: '23505',
          message:
              'duplicate key value violates unique constraint "users_username_idx"',
          details: null,
        ),
        isTrue,
      );
    });

    test('ignores unrelated unique violations', () {
      expect(
        UserProfileService.isUsernameUniqueViolationForTest(
          code: '23505',
          message: 'duplicate key value violates unique constraint',
          details: 'Key (short_id)=(user_1) already exists.',
        ),
        isFalse,
      );
    });
  });
}