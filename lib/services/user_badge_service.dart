import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_badge.dart';

class UserBadgeService {
  UserBadgeService._();

  static final UserBadgeService instance = UserBadgeService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<UserBadge>> fetchByUserId(String userId) async {
    final data = await _client
        .from('user_badges')
        .select('id, user_id, badge_type, level, earned_at, source')
        .eq('user_id', userId)
        .order('badge_type');

    return data
        .map((row) => UserBadge.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}