import 'package:flutter/material.dart';
import '../game/game_logic.dart';
import '../models/level.dart';
import '../services/ads_service.dart';
import '../services/iap_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

/// Power-up costs (coins).
class PowerCosts {
  static const int undo = 10; // per use after 3 free per level
  static const int shuffle = 50;
  static const int extraPeg = 80;
  static const int magicSort = 100;
  static const int rewardedAdCoins = 30;
}

class GameProvider extends ChangeNotifier {
  final StorageService storage;
  final SoundService sound;
  final AdsService ads;
  final IapService iap;

  GameProvider({
    required this.storage,
    required this.sound,
    required this.ads,
    required this.iap,
  });

  // ---------- Economy ----------
  int get coins => storage.coins;
  int get maxLevelUnlocked => storage.maxLevelUnlocked;
  bool get removeAds => storage.removeAds;

  Future<void> _spendCoins(int amount) async {
    await storage.setCoins(storage.coins - amount);
    notifyListeners();
  }

  Future<void> _earnCoins(int amount) async {
    await storage.addCoins(amount);
    await sound.coin();
    notifyListeners();
  }

  // ---------- Level flow ----------
  int _currentLevel = 1;
  int get currentLevel => _currentLevel;

  GameLogic? _logic;
  GameLogic? get logic => _logic;

  int? _selectedPeg;
  int? get selectedPeg => _selectedPeg;

  int _moves = 0;
  int get moves => _moves;

  bool _won = false;
  bool get won => _won;

  void startLevel(int level) {
    _currentLevel = level;
    _logic = GameLogic.fromLevel(level);
    _selectedPeg = null;
    _moves = 0;
    _won = false;
    notifyListeners();
  }

  void restartLevel() {
    if (_logic == null) return;
    startLevel(_currentLevel);
    sound.tap();
  }

  /// Tap handler for a peg. Returns a status string for UI feedback.
  String tapPeg(int index) {
    final logic = _logic;
    if (logic == null || _won) return 'none';

    if (_selectedPeg == null) {
      if (logic.pegs[index].isEmpty) {
        sound.invalid();
        return 'empty';
      }
      _selectedPeg = index;
      sound.pickUp();
      notifyListeners();
      return 'selected';
    }

    if (_selectedPeg == index) {
      _selectedPeg = null;
      sound.tap();
      notifyListeners();
      return 'deselected';
    }

    final ok = logic.move(_selectedPeg!, index);
    if (ok) {
      _moves++;
      _selectedPeg = null;
      sound.place();
      if (logic.isWon) {
        _onWin();
      }
      notifyListeners();
      return _won ? 'won' : 'moved';
    } else {
      sound.invalid();
      _selectedPeg = null;
      notifyListeners();
      return 'invalid';
    }
  }

  Future<void> _onWin() async {
    _won = true;
    final reward = LevelGenerator.coinsForLevel(_currentLevel);
    await storage.addCoins(reward);
    await storage.incrementLevelsCompleted();
    if (_currentLevel >= storage.maxLevelUnlocked &&
        _currentLevel < LevelGenerator.maxLevels) {
      await storage.setMaxLevelUnlocked(_currentLevel + 1);
    }
    await sound.win();
    // Interstitial every 3 completions (unless ads removed).
    if (!storage.removeAds && storage.levelsCompleted % 3 == 0) {
      await ads.showInterstitial();
    }
    notifyListeners();
  }

  void nextLevel() {
    if (_currentLevel < LevelGenerator.maxLevels) {
      startLevel(_currentLevel + 1);
    }
  }

  // ---------- Powers ----------
  bool get canUndoFree => (_logic?.freeUndosLeft ?? 0) > 0;
  int get freeUndosLeft => _logic?.freeUndosLeft ?? 0;

  Future<String> useUndo() async {
    final logic = _logic;
    if (logic == null || logic.history.isEmpty) return 'nothing';
    if (logic.freeUndosLeft > 0) {
      logic.freeUndosLeft--;
      logic.undo();
      _moves = (_moves - 1).clamp(0, 9999);
      sound.tap();
      notifyListeners();
      return 'ok';
    }
    if (storage.coins < PowerCosts.undo) {
      sound.invalid();
      return 'no_coins';
    }
    await _spendCoins(PowerCosts.undo);
    logic.undo();
    _moves = (_moves - 1).clamp(0, 9999);
    sound.tap();
    notifyListeners();
    return 'ok';
  }

  Future<String> useShuffle() async {
    final logic = _logic;
    if (logic == null) return 'nothing';
    if (storage.coins < PowerCosts.shuffle) {
      sound.invalid();
      return 'no_coins';
    }
    await _spendCoins(PowerCosts.shuffle);
    logic.shuffle();
    _selectedPeg = null;
    sound.tap();
    notifyListeners();
    return 'ok';
  }

  Future<String> useExtraPeg() async {
    final logic = _logic;
    if (logic == null) return 'nothing';
    if (storage.coins < PowerCosts.extraPeg) {
      sound.invalid();
      return 'no_coins';
    }
    await _spendCoins(PowerCosts.extraPeg);
    logic.addExtraPeg();
    sound.tap();
    notifyListeners();
    return 'ok';
  }

  Future<String> useMagicSort() async {
    final logic = _logic;
    if (logic == null) return 'nothing';
    if (storage.coins < PowerCosts.magicSort) {
      sound.invalid();
      return 'no_coins';
    }
    final moved = logic.magicSort();
    if (!moved) {
      sound.invalid();
      return 'nothing';
    }
    await _spendCoins(PowerCosts.magicSort);
    _moves++;
    _selectedPeg = null;
    sound.place();
    if (logic.isWon) {
      await _onWin();
    }
    notifyListeners();
    return _won ? 'won' : 'ok';
  }

  // ---------- Rewarded ads ----------
  Future<void> watchAdForCoins() async {
    await ads.showRewarded((amount) async {
      // AdMob test rewarded default is 10; we grant our own amount.
      await _earnCoins(PowerCosts.rewardedAdCoins);
    });
    // Fallback: if ad wasn't ready, grant nothing (UI shows message).
  }

  // ---------- IAP ----------
  Future<void> buyProduct(String productId) async {
    final product = iap.productFor(productId);
    if (product == null) return;
    await iap.buy(product);
  }

  Future<void> handlePurchase(String productId) async {
    if (productId == IapService.kRemoveAds) {
      await storage.setRemoveAds(true);
      ads.removeAdsPurchased = true;
    } else {
      final coins = IapService.kCoinsForProduct[productId] ?? 0;
      if (coins > 0) await storage.addCoins(coins);
    }
    await sound.coin();
    notifyListeners();
  }

  Future<void> toggleSound() async {
    final next = !storage.soundOn;
    await storage.setSoundOn(next);
    sound.enabled = next;
    notifyListeners();
  }

  bool get soundOn => storage.soundOn;
}
