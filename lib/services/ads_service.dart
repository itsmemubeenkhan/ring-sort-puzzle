import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob integration.
///
/// CRITICAL: No ad object may be created/loaded before
/// `MobileAds.instance.initialize()` completes. Doing so crashes the app
/// natively on Android (the SDK throws inside the platform channel call).
/// Every load path below is therefore deferred until [init] finishes
/// successfully. If init fails or times out, ads stay disabled and the game
/// remains fully playable.
///
/// TODO(Mubeen): Replace the TEST ad unit IDs below with your real AdMob IDs
/// from https://apps.admob.com before publishing:
///   - create an AdMob app for Ring Sort Puzzle (Android)
///   - create a Banner ad unit  -> paste into kBannerAdUnitId
///   - create an Interstitial ad unit -> paste into kInterstitialAdUnitId
///   - create a Rewarded ad unit -> paste into kRewardedAdUnitId
/// The IDs below are Google's official TEST IDs (safe for development).
class AdsService {
  // ----- TODO: REPLACE WITH REAL AD UNIT IDs -----
  static const String kBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // TEST banner
  static const String kInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // TEST interstitial
  static const String kRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // TEST rewarded
  // ----------------------------------------------

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool removeAdsPurchased = false;
  bool _disposed = false;

  /// True only after MobileAds initialized successfully.
  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Completer<void> _ready = Completer<void>();
  /// Completes when [init] has finished (success or failure).
  Future<void> get ready => _ready.future;

  /// Initializes the Mobile Ads SDK. Never throws; never hangs longer than
  /// the timeout. Safe to call without awaiting.
  Future<void> init() async {
    try {
      await MobileAds.instance
          .initialize()
          .timeout(const Duration(seconds: 15));
      _initialized = true;
      _loadInterstitialNow();
      _loadRewardedNow();
    } catch (_) {
      // Ads stay disabled; the game must always remain playable.
      _initialized = false;
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Runs [fn] once the SDK is ready AND successfully initialized.
  /// If init failed, [fn] is silently dropped (ads disabled, no crash).
  void _whenReady(void Function() fn) {
    _ready.future.then((_) {
      if (_disposed || !_initialized) return;
      try {
        fn();
      } catch (_) {}
    });
  }

  // ---------- Banner ----------
  BannerAd createBanner(void Function() onLoaded) {
    _bannerAd?.dispose();
    final ad = BannerAd(
      adUnitId: kBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (a, _) => a.dispose(),
      ),
    );
    _bannerAd = ad;
    // The constructor is pure Dart and safe. load() touches the native SDK,
    // so it must wait for successful initialization.
    _whenReady(() {
      if (identical(_bannerAd, ad)) {
        unawaited(ad.load().catchError((_) {}));
      }
    });
    return ad;
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ---------- Interstitial ----------
  void _loadInterstitialNow() {
    if (_disposed || removeAdsPurchased) return;
    try {
      InterstitialAd.load(
        adUnitId: kInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitialAd = ad,
          onAdFailedToLoad: (_) => _interstitialAd = null,
        ),
      );
    } catch (_) {
      _interstitialAd = null;
    }
  }

  void _loadInterstitial() {
    if (_disposed || removeAdsPurchased) return;
    if (!_initialized) {
      _whenReady(_loadInterstitial);
      return;
    }
    _loadInterstitialNow();
  }

  Future<void> showInterstitial() async {
    if (removeAdsPurchased || _disposed) return;
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
    } catch (_) {}
    _interstitialAd = null;
  }

  // ---------- Rewarded ----------
  void _loadRewardedNow() {
    if (_disposed) return;
    try {
      RewardedAd.load(
        adUnitId: kRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => _rewardedAd = ad,
          onAdFailedToLoad: (_) => _rewardedAd = null,
        ),
      );
    } catch (_) {
      _rewardedAd = null;
    }
  }

  void _loadRewarded() {
    if (_disposed) return;
    if (!_initialized) {
      _whenReady(_loadRewarded);
      return;
    }
    _loadRewardedNow();
  }

  /// Shows a rewarded ad. Calls [onReward] with the reward amount when earned.
  Future<void> showRewarded(void Function(int amount) onReward) async {
    if (_disposed) return;
    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewarded();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadRewarded();
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (a, reward) {
          onReward(reward.amount.toInt());
        },
      );
    } catch (_) {}
    _rewardedAd = null;
  }

  void dispose() {
    _disposed = true;
    disposeBanner();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
