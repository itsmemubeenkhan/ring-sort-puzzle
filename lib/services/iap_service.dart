import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// In-app purchases for Ring Sort Puzzle.
/// Product IDs (must match Play Console exactly):
///   coin_pack_small  -> 500 coins  ($0.99)
///   coin_pack_medium -> 1500 coins ($1.99)
///   coin_pack_large  -> 4000 coins ($4.99)
///   remove_ads       -> one-time   ($2.99)
class IapService {
  static const String kCoinSmall = 'coin_pack_small';
  static const String kCoinMedium = 'coin_pack_medium';
  static const String kCoinLarge = 'coin_pack_large';
  static const String kRemoveAds = 'remove_ads';

  static const Set<String> kProductIds = {
    kCoinSmall,
    kCoinMedium,
    kCoinLarge,
    kRemoveAds,
  };

  /// Coins granted per product.
  static const Map<String, int> kCoinsForProduct = {
    kCoinSmall: 500,
    kCoinMedium: 1500,
    kCoinLarge: 4000,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  List<ProductDetails> products = [];

  /// Callbacks wired by the provider.
  void Function(String productId)? onPurchaseSuccess;
  void Function(String message)? onPurchaseError;

  final Set<String> _pendingProductIds = {};

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) return;

    final response = await _iap.queryProductDetails(kProductIds);
    if (response.error == null) {
      products = response.productDetails;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (e) => onPurchaseError?.call(e.toString()),
    );

    // Complete any pending purchases from a previous session.
    await _iap.restorePurchases();
  }

  ProductDetails? productFor(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    _pendingProductIds.add(product.id);
    // remove_ads is non-consumable; coin packs are consumable.
    if (product.id == kRemoveAds) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        onPurchaseSuccess?.call(p.productID);
        if (p.pendingCompletePurchase) {
          _iap.completePurchase(p);
        }
        _pendingProductIds.remove(p.productID);
      } else if (p.status == PurchaseStatus.error) {
        onPurchaseError?.call(p.error?.message ?? 'Purchase failed');
        _pendingProductIds.remove(p.productID);
      } else if (p.status == PurchaseStatus.canceled) {
        _pendingProductIds.remove(p.productID);
      }
    }
  }

  void dispose() => _sub?.cancel();
}
