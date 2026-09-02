import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/errors/app_result.dart';
import '../../../../core/errors/app_error.dart';

final class ProfileLocalDataSource {
  final SharedPreferences _prefs;

  ProfileLocalDataSource(this._prefs);

  static const _key = 'cached_profile';

  Future<AppResult<UserProfile>> getCachedProfile() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) {
        return Failure(const NotFoundError('No cached profile'));
      }
      return Success(UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (e) {
      return Failure(CacheError('Failed to read cached profile: $e'));
    }
  }

  Future<void> cacheProfile(UserProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clearCache() async {
    await _prefs.remove(_key);
  }
}
