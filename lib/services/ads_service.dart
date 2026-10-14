import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob integration.
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

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  // ---------- Banner ----------
  BannerAd createBanner(void Function() onLoaded) {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: kBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
    return _bannerAd!;
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ---------- Interstitial ----------
  void _loadInterstitial() {
    if (removeAdsPurchased) return;
    InterstitialAd.load(
      adUnitId: kInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> showInterstitial() async {
    if (removeAdsPurchased) return;
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
    await ad.show();
    _interstitialAd = null;
  }

  // ---------- Rewarded ----------
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: kRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  /// Shows a rewarded ad. Calls [onReward] with the reward amount when earned.
  Future<void> showRewarded(void Function(int amount) onReward) async {
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
    await ad.show(
      onUserEarnedReward: (a, reward) {
        onReward(reward.amount.toInt());
      },
    );
    _rewardedAd = null;
  }

  void dispose() {
    disposeBanner();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
