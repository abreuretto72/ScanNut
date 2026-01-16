import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/simple_auth_service.dart';
import '../presentation/register_screen.dart';
import '../../home/presentation/home_view.dart';
import '../../../core/theme/app_design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _checkBiometrics(); // 🚀 V123: Auto-Trigger
  }

  Future<void> _checkBiometrics() async {
    // Small delay to ensure UI builds
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Check if user has biometrics enabled
    if (simpleAuthService.isBiometricEnabled) {
       debugPrint('🧬 [V123-AUTH] Biometrics Enabled. Triggering prompt automatically...');
       
       setState(() => _isLoading = true);
       final result = await simpleAuthService.authenticateWithBiometrics();
       setState(() => _isLoading = false);

       if (mounted) {
          _handleAuthResult(result);
       }
    }
  }

  void _handleAuthResult(AuthResult result) {
      // 🛡️ Race Condition Fix: If manual login is in progress (isLoading) 
      // or user is already logged in, ignore stale biometric errors.
      if (!mounted || _isLoading || simpleAuthService.isUserLoggedIn) return;
      
      switch (result) {
        case AuthResult.success:
           debugPrint('✅ [V128-AUTH] Auto-trigger Success. Navigating...');
           // Ensure clean state before navigating
           setState(() => _errorMessage = null);
           Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeView()),
           );
           break;
        case AuthResult.missingKey:
           setState(() {
              _errorMessage = null; 
           });
           // 🛡️ User reported frozen SnackBar. Using Dialog for critical auth warning.
           _showBiometricResetDialog();
           break;
        case AuthResult.failed:
           // Do nothing, maybe user cancelled
           break;
        case AuthResult.unavailable:
           break;
      }
  }

  void _showBiometricResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppDesign.warning, width: 1)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: AppDesign.warning),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "Autenticação", 
                style: GoogleFonts.poppins(
                  color: AppDesign.textPrimaryDark, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ],
        ),
        content: Text(
          'Por favor, faça login manual uma vez para reativar a chave de segurança da biometria.',
          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.accent, 
              foregroundColor: Colors.black
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK, Entendi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; 
    });
    
    final success = await simpleAuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() => _errorMessage = null); // Ensure clean state
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      } else {
        setState(() {
          _errorMessage = 'E-mail ou senha incorretos.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen height to adjust layout dynamically
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      resizeToAvoidBottomInset: true, // Ensure KB pushes layout up
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Better for forms
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 24 : 40),
                        
                        // Logo/Header (Responsive)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: AppDesign.accent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              height: isSmallScreen ? 48 : 72, // Reduced size
                              width: isSmallScreen ? 48 : 72,
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        Center(
                          child: Text(
                            'ScanNut',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 24 : 32,
                              fontWeight: FontWeight.bold,
                              color: AppDesign.textPrimaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Center(
                          child: Text(
                            'Sua nutrição inteligente começa aqui',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppDesign.textSecondaryDark,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 48),

                        // Email Field
                        Text(
                          'E-mail',
                          style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next, // Improve UX
                          decoration: _buildInputDecoration(
                            hintText: 'exemplo@email.com',
                            prefixIcon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Por favor, insira seu e-mail';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          'Senha',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done, // Improve UX
                          onFieldSubmitted: (_) => _handleLogin(), // Allow submit on enter
                          decoration: _buildInputDecoration(
                            hintText: 'Sua senha segura',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppDesign.textSecondaryDark.withOpacity(0.5),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Por favor, insira sua senha';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Remember Me Checkbox
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                activeColor: AppDesign.accent,
                                checkColor: Colors.black,
                                side: const BorderSide(color: AppDesign.textPrimaryDark, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              child: Text(
                                'Manter conectado',
                                style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: _errorMessage != null ? 16 : (isSmallScreen ? 24 : 32)),

                        // Error Message Display
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppDesign.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppDesign.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppDesign.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                      color: AppDesign.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesign.accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                'Entrar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                        
                        if (simpleAuthService.isBiometricEnabled) ...[
                           SizedBox(height: isSmallScreen ? 12 : 16),
                           OutlinedButton.icon(
                              onPressed: () async {
                                 // Clear manual error before biometric attempt
                                 setState(() {
                                    _errorMessage = null; 
                                    _isLoading = true;
                                 });
                                 
                                 final result = await simpleAuthService.authenticateWithBiometrics();
                                 
                                 setState(() => _isLoading = false);
                                 
                                 _handleAuthResult(result);
                              },
                              icon: const Icon(Icons.fingerprint, color: AppDesign.accent),
                              label: Text('Entrar com Biometria', style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
                              style: OutlinedButton.styleFrom(
                                 side: BorderSide(color: AppDesign.accent.withOpacity(0.5)),
                                 padding: const EdgeInsets.symmetric(vertical: 12),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                           ),
                        ],

                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Register Link
                        Padding(
                          padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Não tem uma conta? ',
                                style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: Text(
                                  'Cadastrar-se',
                                  style: GoogleFonts.poppins(
                                    color: AppDesign.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: AppDesign.textPrimaryDark.withOpacity(0.24)),
      prefixIcon: Icon(prefixIcon, color: AppDesign.textSecondaryDark.withOpacity(0.5), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppDesign.textPrimaryDark.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppDesign.textPrimaryDark.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppDesign.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppDesign.error, width: 1),
      ),
    );
  }
}
