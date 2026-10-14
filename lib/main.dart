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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  try {
    await storage.init().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Storage failure must never kill startup.
  }

  final sound = SoundService();
  try {
    sound.enabled = storage.soundOn;
  } catch (_) {}

  final ads = AdsService();
  try {
    ads.removeAdsPurchased = storage.removeAds;
  } catch (_) {}
  // NOTE: ads.init() is intentionally NOT awaited here.
  // MobileAds.instance.initialize() can hang indefinitely on some devices
  // (no Play services / blocked network), which used to freeze the app on
  // the splash screen forever. It now runs after the first frame, guarded
  // by a timeout, so startup can never block on ads.

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

  // Post-startup async init, fully guarded: failures/timeouts are swallowed
  // so the game always remains playable.
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await ads.init().timeout(const Duration(seconds: 15));
    } catch (_) {}
    try {
      await iap.init().timeout(const Duration(seconds: 15));
    } catch (_) {}
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
