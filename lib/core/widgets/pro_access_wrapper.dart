import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/subscription_provider.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../../l10n/app_localizations.dart';

/// Non-invasive wrapper to check Pro access
/// Shows paywall invitation if user is not Pro, otherwise shows the child content
class ProAccessWrapper extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String featureDescription;
  final IconData? featureIcon;

  const ProAccessWrapper({
    super.key,
    required this.child,
    required this.featureName,
    this.featureDescription = 'Este recurso está disponível apenas para assinantes Pro',
    this.featureIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);

    // ⚠️ MODO SCREENSHOT - TEMPORÁRIO! ⚠️
    // TODO: REVERTER ANTES DE PUBLICAR NA LOJA!
    // Forçando isPro = true para captura de telas
    const bool screenshotMode = true; // ← MUDAR PARA false ANTES DE PUBLICAR!
    
    // If Pro OR in screenshot mode, show the original content
    if (subscriptionState.isPro || screenshotMode) {
      return child;
    }

    // If loading, show loading indicator
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

    // If not Pro, show paywall invitation
    return _buildPaywallInvitation(context);
  }

  Widget _buildPaywallInvitation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Feature Icon
                if (featureIcon != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Icon(
                      featureIcon,
                      size: 64,
                      color: Colors.green,
                    ),
                  ),
                const SizedBox(height: 32),

                // Pro Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.drawerProTitle.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Feature Name (Title)
                Text(
                  featureName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Feature Description (Subtitle)
                Text(
                  featureDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                // Benefits List
                _buildBenefitItem(l10n.paywallBenefit1),
                _buildBenefitItem(l10n.paywallBenefit2),
                _buildBenefitItem(l10n.paywallBenefit3),
                _buildBenefitItem(l10n.paywallBenefit4),
                const SizedBox(height: 32),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n.paywallSubscribeButton,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Restore purchases link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaywallScreen(showRestoreFirst: true),
                      ),
                    );
                  },
                  child: Text(
                    l10n.paywallRestore,
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade300,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
