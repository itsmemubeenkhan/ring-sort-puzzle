import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// Home / menu screen with banner ad.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    if (!provider.removeAds) {
      _bannerAd = provider.ads.createBanner(() {
        if (mounted) setState(() => _bannerReady = true);
      });
    }
  }

  @override
  void dispose() {
    context.read<GameProvider>().ads.disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _logo(),
                    const SizedBox(height: 16),
                    const Text(
                      'RING SORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'PUZZLE',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _menuButton(
                      context,
                      label: 'PLAY',
                      icon: Icons.play_arrow,
                      color: Colors.green,
                      onTap: () => Navigator.pushNamed(context, '/levels'),
                    ),
                    const SizedBox(height: 12),
                    _menuButton(
                      context,
                      label: 'SHOP',
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text('${provider.coins}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/shop'),
                    ),
                    const SizedBox(height: 12),
                    _menuButton(
                      context,
                      label: provider.soundOn ? 'SOUND: ON' : 'SOUND: OFF',
                      icon: provider.soundOn
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Colors.blueGrey,
                      onTap: () => provider.toggleSound(),
                    ),
                  ],
                ),
              ),
            ),
            if (_bannerReady && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    // Original decorative logo: stacked colorful rings.
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.amberAccent,
    ];
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < colors.length; i++)
            Positioned(
              bottom: i * 22.0,
              child: Container(
                width: 140 - i * 16.0,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      colors[i].withValues(alpha: 0.7),
                      colors[i],
                    ],
                  ),
                  border:
                      Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Container(
                    height: 8,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A)
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 240,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
