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
  await storage.init();

  final sound = SoundService();
  sound.enabled = storage.soundOn;

  final ads = AdsService();
  ads.removeAdsPurchased = storage.removeAds;
  await ads.init();

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

  // Init IAP after first frame to avoid blocking startup.
  Future.delayed(const Duration(seconds: 1), () => iap.init());
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
