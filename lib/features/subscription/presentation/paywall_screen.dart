import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import '../../../l10n/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final bool showRestoreFirst;

  const PaywallScreen({
    Key? key,
    this.showRestoreFirst = false,
  }) : super(key: key);

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selectedPackage;
  bool _isLoading = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    if (widget.showRestoreFirst) {
      _restorePurchases();
    }
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final service = ref.read(subscriptionServiceProvider);
    final offerings = await service.getOfferings();
    
    if (mounted) {
      setState(() {
        _offerings = offerings;
        // Default to annual if available, otherwise monthly
        if (offerings?.current != null) {
          _selectedPackage = offerings!.current!.annual ?? offerings.current!.monthly;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseSelectedPackage() async {
    if (_selectedPackage == null) return;

    setState(() => _isLoading = true);
    
    final service = ref.read(subscriptionServiceProvider);
    final success = await service.purchasePackage(_selectedPackage!);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Refresh provider state
        await ref.read(subscriptionProvider.notifier).refresh();
        if (mounted) {
           final l10n = AppLocalizations.of(context)!;
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.paywallSuccess)),
          );
          Navigator.of(context).pop(); // Close paywall
        }
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallError)),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(subscriptionProvider.notifier).restorePurchases();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallRestoreSuccess)),
        );
        Navigator.of(context).pop();
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallRestoreFail)),
        );
      }
    }
  }

  static const Color _scanNutProColor = Color(0xFFFADADD);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image / Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _scanNutProColor.withOpacity(0.4),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scanNutProColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _scanNutProColor, width: 2),
                      ),
                      child: const Icon(Icons.star, color: _scanNutProColor, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                    Text(
                    l10n.paywallTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paywallSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Packages
                  if (_isLoading && _offerings == null)
                    const Center(child: CircularProgressIndicator(color: _scanNutProColor))
                  else if (_offerings?.current != null) ...[
                    if (_offerings!.current!.annual != null)
                      _buildPackageOption(_offerings!.current!.annual!, isBestValue: true),
                    const SizedBox(height: 12),
                    if (_offerings!.current!.monthly != null)
                      _buildPackageOption(_offerings!.current!.monthly!),
                  ] else
                    Center(
                      child: Text(
                        l10n.paywallLoadingOfferings,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  
                  const Spacer(flex: 2),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _purchaseSelectedPackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scanNutProColor,
                      foregroundColor: Colors.black, // Dark text on light pink for contrast
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: _scanNutProColor.withOpacity(0.3),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                        )
                      : Text(
                          _selectedPackage == null 
                              ? l10n.paywallSelectPlan 
                              : l10n.paywallSubscribeButton,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Restore & Terms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : _restorePurchases,
                        child: Text(
                          l10n.paywallRestore,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '•',
                        style: GoogleFonts.poppins(color: Colors.white24),
                      ),
                      TextButton(
                        onPressed: () {
                           // Implement Terms & Conditions logic/link here if needed
                        },
                        child: Text(
                          l10n.paywallTerms,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageOption(Package package, {bool isBestValue = false}) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedPackage == package;
    final product = package.storeProduct;
    
    return InkWell(
      onTap: () => setState(() => _selectedPackage = package),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _scanNutProColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? _scanNutProColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Radio Circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _scanNutProColor : Colors.white54,
                  width: 2,
                ),
                color: isSelected ? _scanNutProColor : null,
              ),
              child: isSelected 
                ? const Icon(Icons.check, size: 16, color: Colors.black) // Dark icon on pink
                : null,
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        package.packageType == PackageType.annual ? l10n.paywallYearly : l10n.paywallMonthly,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _scanNutProColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.paywallBestValue,
                            style: GoogleFonts.poppins(
                              color: Colors.black, // Dark text on pink
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.priceString,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (package.packageType == PackageType.annual)
                  Text(
                    '${(product.price / 12).toStringAsFixed(2)} ${l10n.paywallPerMonth}',
                     style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
