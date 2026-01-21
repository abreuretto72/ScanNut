import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_view.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarHelper.showError(context, 'As senhas não coincidem.');
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await simpleAuthService.register(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        debugPrint('✅ [V113-AUTH] Auto-Login successful. Navigating to Home...');
        SnackBarHelper.showSuccess(context, 'Bem-vindo ao ScanNut! Login realizado com sucesso.');
        
        // Navigate to Home and clear navigation stack (Force session entry point)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeView()),
          (route) => false,
        );
      } else {
        debugPrint('❌ [V113-AUTH] Registration failed or already exists.');
        SnackBarHelper.showError(context, 'Este e-mail já está cadastrado.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Criar Conta',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Junte-se à comunidade ScanNut',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppDesign.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 48),

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
                  decoration: _buildInputDecoration(
                    hintText: 'exemplo@email.com',
                    prefixIcon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obrigatório';
                    if (!value.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password Field
                Text(
                  'Senha',
                  style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: Icons.lock_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obrigatório';
                    if (value.length < 6) return 'Senha muito curta';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Confirm Password Field
                Text(
                  'Confirmar Senha',
                  style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    hintText: 'Repita sua senha',
                    prefixIcon: Icons.lock_reset_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obrigatório';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                        'Cadastrar-se',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: AppDesign.textPrimaryDark.withOpacity(0.24)),
      prefixIcon: Icon(prefixIcon, color: AppDesign.textSecondaryDark.withOpacity(0.5), size: 20),
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
