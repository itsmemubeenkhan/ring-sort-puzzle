import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: coins, unlocked levels, settings.
class StorageService {
  static const _kCoins = 'rsp_coins';
  static const _kMaxLevel = 'rsp_max_level';
  static const _kRemoveAds = 'rsp_remove_ads';
  static const _kSoundOn = 'rsp_sound_on';
  static const _kLevelsCompleted = 'rsp_levels_completed';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get coins => _prefs.getInt(_kCoins) ?? 100; // starter coins
  Future<void> setCoins(int v) => _prefs.setInt(_kCoins, v);
  Future<void> addCoins(int v) => setCoins(coins + v);

  /// Highest level unlocked (1-based). Level 1 always unlocked.
  int get maxLevelUnlocked => _prefs.getInt(_kMaxLevel) ?? 1;
  Future<void> setMaxLevelUnlocked(int v) => _prefs.setInt(_kMaxLevel, v);

  int get levelsCompleted => _prefs.getInt(_kLevelsCompleted) ?? 0;
  Future<void> incrementLevelsCompleted() =>
      _prefs.setInt(_kLevelsCompleted, levelsCompleted + 1);

  bool get removeAds => _prefs.getBool(_kRemoveAds) ?? false;
  Future<void> setRemoveAds(bool v) => _prefs.setBool(_kRemoveAds, v);

  bool get soundOn => _prefs.getBool(_kSoundOn) ?? true;
  Future<void> setSoundOn(bool v) => _prefs.setBool(_kSoundOn, v);
}
