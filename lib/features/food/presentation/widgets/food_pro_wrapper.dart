import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../features/subscription/presentation/paywall_screen.dart';
import '../../../../l10n/app_localizations.dart';

/// Wrapper de Acesso Pro para Micro-App de Comida
/// Duplicado de ProAccessWrapper para garantir Isolamento de Domínio
class FoodProWrapper extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String featureDescription;
  final IconData? featureIcon;

  const FoodProWrapper({
    super.key,
    required this.child,
    required this.featureName,
    this.featureDescription = 'Este recurso está disponível apenas para assinantes Pro',
    this.featureIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ Nota: SubscriptionProvider é "Shared Infrastructure" (admissível)
    final subscriptionState = ref.watch(subscriptionProvider);
    const bool screenshotMode = true; 

    if (subscriptionState.isPro || screenshotMode) {
      return child;
    }

    if (subscriptionState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Verificando assinatura...',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return _buildPaywallInvitation(context);
  }

  Widget _buildPaywallInvitation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.grey.shade900],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (featureIcon != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Icon(featureIcon, size: 64, color: Colors.green),
                  ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.drawerProTitle.toUpperCase(),
                          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(featureName, textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Text(featureDescription, textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: Text(l10n.paywallSubscribeButton, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
