import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';

/// State class for subscription status
class SubscriptionState {
  final bool isPro;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? expirationDate;
  final bool willRenew;

  const SubscriptionState({
    this.isPro = false,
    this.isLoading = false,
    this.errorMessage,
    this.expirationDate,
    this.willRenew = false,
  });

  SubscriptionState copyWith({
    bool? isPro,
    bool? isLoading,
    String? errorMessage,
    DateTime? expirationDate,
    bool? willRenew,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      expirationDate: expirationDate ?? this.expirationDate,
      willRenew: willRenew ?? this.willRenew,
    );
  }
}

/// Notifier for subscription state
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptionService;

  SubscriptionNotifier(this._subscriptionService) : super(const SubscriptionState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _subscriptionService.init();
    await checkProStatus();
  }

  /// Check if user has Pro access
  Future<void> checkProStatus() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final isPro = await _subscriptionService.isPro();
      final expirationDate = _subscriptionService.getProExpirationDate();
      final willRenew = _subscriptionService.willRenew();

      state = state.copyWith(
        isPro: isPro,
        isLoading: false,
        expirationDate: expirationDate,
        willRenew: willRenew,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final success = await _subscriptionService.restorePurchases();
      
      if (success) {
        await checkProStatus();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Nenhuma compra encontrada para restaurar',
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Refresh subscription status
  Future<void> refresh() async {
    await _subscriptionService.refreshCustomerInfo();
    await checkProStatus();
  }
}

/// Provider for SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for subscription state
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service);
});

/// Simple provider to check if user is Pro (for quick access)
final isProProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPro;
});
