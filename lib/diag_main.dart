import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/shop_screen.dart';
import 'services/ads_service.dart';
import 'services/iap_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';

/// DIAGNOSTIC entrypoint (temporary).
///
/// Opens a diagnostic screen FIRST (proving engine + Dart work), with buttons
/// to test each native component one by one. The on-screen log shows exactly
/// which step crashes the app. The game itself can be launched with ads/IAP
/// fully suppressed.
final ValueNotifier<List<String>> diagLog = ValueNotifier<List<String>>([]);

void dlog(String s) {
  diagLog.value = [...diagLog.value, s];
}

bool _busy = false;

Future<void> diagTestAds() async {
  if (_busy) return;
  _busy = true;
  try {
    dlog('▶ AdMob: MobileAds.initialize() start...');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 25));
      dlog('✓ AdMob initialize OK');
    } catch (e) {
      dlog('✗ AdMob initialize FAILED: $e');
      return;
    }
    dlog('▶ AdMob: loading test banner...');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final done = Completer<void>();
    final ad = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Google test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          dlog('✓ Banner loaded OK');
          if (!done.isCompleted) done.complete();
        },
        onAdFailedToLoad: (a, e) {
          dlog('✗ Banner load failed: ${e.message}');
          a.dispose();
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    try {
      await ad.load();
      await done.future.timeout(const Duration(seconds: 25));
    } catch (e) {
      dlog('✗ Banner FAILED: $e');
    }
    try {
      await ad.dispose();
    } catch (_) {}
  } finally {
    _busy = false;
  }
}

Future<void> diagTestIap() async {
  if (_busy) return;
  _busy = true;
  try {
    dlog('▶ IAP: isAvailable() start...');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      final v = await InAppPurchase.instance
          .isAvailable()
          .timeout(const Duration(seconds: 25));
      dlog('✓ IAP isAvailable = $v');
    } catch (e) {
      dlog('✗ IAP FAILED: $e');
    }
  } finally {
    _busy = false;
  }
}

Future<void> bootGame() async {
  if (_busy) return;
  _busy = true;
  try {
    dlog('▶ Game boot: storage...');
    final storage = StorageService();
    try {
      await storage.init().timeout(const Duration(seconds: 5));
      dlog('✓ Storage OK');
    } catch (e) {
      dlog('✗ Storage FAILED (continuing with defaults): $e');
    }

    final sound = SoundService();
    sound.enabled = storage.soundOn;

    final ads = AdsService();
    // Diagnostic: suppress ALL ads in the game. No ad init, no ad loads.
    ads.removeAdsPurchased = true;

    final iap = IapService();

    dlog('▶ Game boot: runApp...');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) {
              final provider = GameProvider(
                storage: storage,
                sound: sound,
                ads: ads,
                iap: iap,
              );
              iap.onPurchaseSuccess = (productId) {
                provider.handlePurchase(productId);
              };
              iap.onPurchaseError = (_) {};
              return provider;
            },
          ),
        ],
        child: const RingSortApp(),
      ),
    );
    dlog('✓ Game launched');
  } finally {
    _busy = false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    dlog('DART ERROR: ${details.exception}');
    FlutterError.presentError(details);
  };

  await runZonedGuarded<Future<void>>(() async {
    dlog('✓ Engine + Dart OK (diagnostic started)');
    dlog('Neeche button dabao, ek ek karke test karo.');
    runApp(const DiagApp());
  }, (error, stack) {
    dlog('ZONE ERROR: $error');
  });
}

class DiagApp extends StatelessWidget {
  const DiagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text('Ring Sort — Diagnostic'),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: diagLog,
                    builder: (context, lines, _) => ListView.builder(
                      itemCount: lines.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          lines[i],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: diagTestAds,
                      child: const Text('1. Test AdMob'),
                    ),
                    ElevatedButton(
                      onPressed: diagTestIap,
                      child: const Text('2. Test IAP'),
                    ),
                    ElevatedButton(
                      onPressed: bootGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('3. Open Game'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Agar app band ho jaye to dobara kholo aur batao kis button par band hui thi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RingSortApp extends StatelessWidget {
  const RingSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ring Sort Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/levels': (_) => const LevelSelectScreen(),
        '/game': (_) => const GameScreen(),
        '/shop': (_) => const ShopScreen(),
      },
    );
  }
}
