import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/iap_service.dart';

/// Shop: coin packs (IAP), remove ads, rewarded ad for free coins.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Shop',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('${provider.coins}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Free Coins'),
          _rewardedAdCard(context, provider),
          const SizedBox(height: 20),
          _sectionTitle('Coin Packs'),
          _coinPackCard(context, provider, IapService.kCoinSmall,
              '500', 'Small Pack'),
          _coinPackCard(context, provider, IapService.kCoinMedium,
              '1,500', 'Medium Pack — Best Value'),
          _coinPackCard(context, provider, IapService.kCoinLarge,
              '4,000', 'Large Pack — Super Value'),
          const SizedBox(height: 20),
          _sectionTitle('Premium'),
          _removeAdsCard(context, provider),
          const SizedBox(height: 24),
          const Text(
            'Purchases are charged to your Google Play account. '
            'Coin packs are consumable. Remove Ads is a one-time purchase.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _rewardedAdCard(
      BuildContext context, GameProvider provider) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.play_circle_fill,
              color: Colors.greenAccent, size: 28),
        ),
        title: const Text('Watch Ad',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
            '+${PowerCosts.rewardedAdCoins} coins',
            style:
                const TextStyle(color: Colors.amberAccent)),
        trailing: ElevatedButton(
          onPressed: () async {
            await provider.watchAdForCoins();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Thanks! Coins added if the ad completed.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green),
          child: const Text('WATCH',
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _coinPackCard(BuildContext context, GameProvider provider,
      String productId, String coins, String title) {
    final product = provider.iap.productFor(productId);
    final price = product?.price ?? '...';
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.monetization_on,
              color: Colors.amber, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('$coins coins',
            style: const TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          onPressed: product == null
              ? null
              : () => provider.buyProduct(productId),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange),
          child: Text(price,
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _removeAdsCard(
      BuildContext context, GameProvider provider) {
    if (provider.removeAds) {
      return const Card(
        color: Color(0xFF1E293B),
        child: ListTile(
          leading: Icon(Icons.check_circle,
              color: Colors.greenAccent, size: 28),
          title: Text('Ads Removed',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          subtitle: Text('Enjoy an ad-free game!',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    final product =
        provider.iap.productFor(IapService.kRemoveAds);
    final price = product?.price ?? '...';
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.block,
              color: Colors.purpleAccent, size: 28),
        ),
        title: const Text('Remove Ads',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text(
            'No more banner or interstitial ads',
            style: TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          onPressed: product == null
              ? null
              : () => provider.buyProduct(IapService.kRemoveAds),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple),
          child: Text(price,
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
