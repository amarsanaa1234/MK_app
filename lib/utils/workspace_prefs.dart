import 'package:shared_preferences/shared_preferences.dart';

/// Device-local choices about which workspace to open after signing in.
///
/// Everything here is prefixed `ws_` so [clearSession] can wipe the rest of the saved state on log
/// out without forgetting which workspaces this phone has already chosen between.
class WorkspacePrefs {
  static const _prefix = 'ws_';
  static const _askEveryTimeKey = '${_prefix}ask_every_time';
  static String _chosenKey(String userId) => '${_prefix}chosen_$userId';

  /// "Ask me every time": always show Choose a workspace after signing in.
  static Future<bool> askEveryTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_askEveryTimeKey) ?? false;
  }

  static Future<void> setAskEveryTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askEveryTimeKey, value);
  }

  /// Whether this phone has already had [userId] pick a workspace once.
  static Future<bool> hasChosen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chosenKey(userId)) ?? false;
  }

  static Future<void> markChosen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chosenKey(userId), true);
  }

  /// Log out: clears saved state, but keeps the workspace choices above.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => !k.startsWith(_prefix)).toList()) {
      await prefs.remove(key);
    }
  }
}
