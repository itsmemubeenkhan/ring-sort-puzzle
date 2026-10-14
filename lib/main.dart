import 'dart:async';

import 'package:flutter/material.dart';
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

/// Becomes true after the first frame renders. Fatal errors are only shown
/// on screen while this is false; afterwards errors are just logged so a
/// late, non-fatal error can never nuke the running game UI.
bool _startupComplete = false;

/// Last-resort UI: turns a startup crash into a readable message (with the
/// actual error text) instead of Android's "keeps stopping" dialog.
void _reportFatal(Object error) {
  if (_startupComplete) return;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please take a screenshot of this message and send it to support:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$error',
                    style: const TextStyle(
                        color: Colors.amberAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportFatal(details.exception);
  };

  await runZonedGuarded<Future<void>>(() async {
    final storage = StorageService();
    try {
      await storage.init().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Storage failure must never kill startup (getters have defaults).
    }

    final sound = SoundService();
    sound.enabled = storage.soundOn;

    final ads = AdsService();
    ads.removeAdsPurchased = storage.removeAds;
    // Fire-and-forget: MobileAds.instance.initialize() can hang on some
    // devices, so it must never be awaited on the startup path. init() has
    // its own timeout, and every ad load waits for successful init anyway.
    unawaited(ads.init().catchError((_) {}));

    final iap = IapService();
    // Purchase callbacks are wired after provider creation (see below).

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startupComplete = true;
    });

    // IAP init deferred: it talks to Play Billing and must never block
    // startup either.
    unawaited(
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await iap.init().timeout(const Duration(seconds: 15));
        } catch (_) {}
      }).catchError((_) {}),
    );
  }, (error, stack) {
    _reportFatal(error);
  });
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
