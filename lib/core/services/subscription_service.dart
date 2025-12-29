import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to manage RevenueCat subscriptions
/// Handles Pro access verification, purchases, and restoration
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String _proEntitlementId = 'pro_access';
  bool _isInitialized = false;
  CustomerInfo? _currentCustomerInfo;

  /// Initialize RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final apiKey = dotenv.env['REVENUECAT_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('⚠️ RevenueCat API key not found in .env');
        return;
      }

      // Configure RevenueCat
      await Purchases.configure(
        PurchasesConfiguration(apiKey)
          ..appUserID = null, // Let RevenueCat generate anonymous ID
      );

      // Set debug logs in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully');

      // Load initial customer info
      await refreshCustomerInfo();
    } catch (e, stack) {
      debugPrint('❌ Error initializing RevenueCat: $e\n$stack');
    }
  }

  /// Check if user has Pro access
  Future<bool> isPro() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _currentCustomerInfo = customerInfo;
      
      final hasProAccess = customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;
      debugPrint('🔐 Pro Access: $hasProAccess');
      return hasProAccess;
    } catch (e) {
      debugPrint('❌ Error checking Pro status: $e');
      return false;
    }
  }

  /// Refresh customer info from RevenueCat
  Future<CustomerInfo?> refreshCustomerInfo() async {
    if (!_isInitialized) return null;

    try {
      _currentCustomerInfo = await Purchases.getCustomerInfo();
      return _currentCustomerInfo;
    } catch (e) {
      debugPrint('❌ Error refreshing customer info: $e');
      return null;
    }
  }

  /// Get current customer info (cached)
  CustomerInfo? get currentCustomerInfo => _currentCustomerInfo;

  /// Get available offerings (subscription packages)
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        debugPrint('⚠️ No current offering available');
      }
      return offerings;
    } catch (e) {
      debugPrint('❌ Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      _currentCustomerInfo = purchaserInfo.customerInfo;
      
      final isPro = purchaserInfo.customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;
      debugPrint('✅ Purchase completed. Pro status: $isPro');
      return isPro;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('ℹ️ User cancelled purchase');
      } else {
        debugPrint('❌ Purchase error: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      _currentCustomerInfo = customerInfo;
      
      final isPro = customerInfo.entitlements.all[_proEntitlementId]?.isActive ?? false;
      debugPrint('✅ Purchases restored. Pro status: $isPro');
      return isPro;
    } catch (e) {
      debugPrint('❌ Error restoring purchases: $e');
      return false;
    }
  }

  /// Get subscription expiration date (if any)
  DateTime? getProExpirationDate() {
    final entitlement = _currentCustomerInfo?.entitlements.all[_proEntitlementId];
    final expiration = entitlement?.expirationDate; // Might be String or DateTime depending on version
    
    if (expiration is String) {
      return DateTime.tryParse(expiration);
    } else if (expiration is DateTime) {
      return expiration;
    }
    return null;
  }

  /// Check if subscription will renew
  bool willRenew() {
    final entitlement = _currentCustomerInfo?.entitlements.all[_proEntitlementId];
    return entitlement?.willRenew ?? false;
  }

  /* 
  /// Get subscription period type (monthly, annual, etc.)
  String? getSubscriptionPeriod() {
    final entitlement = _currentCustomerInfo?.entitlements.all[_proEntitlementId];
    // periodType is not available in EntitlementInfo in this version
    return null; 
  }
  */
}
