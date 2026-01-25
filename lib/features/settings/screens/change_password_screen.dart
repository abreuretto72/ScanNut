import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = simpleAuthService.loggedUserEmail;
      if (email == null) {
        SnackBarHelper.showError(
            context, 'Usuário não identificado. Faça login novamente.');
        setState(() => _isLoading = false);
        return;
      }

      final error = await simpleAuthService.changePassword(
        email,
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      if (error == null) {
        // Success
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        SnackBarHelper.showSuccess(context, 'Senha alterada com sucesso.');
        Navigator.pop(context); // Optional: close screen on success
      } else {
        SnackBarHelper.showError(context, error);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erro ao alterar senha: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Digite a nova senha';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Precisa de pelo menos 1 letra maiúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Precisa de pelo menos 1 número';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        title: Text('Trocar Senha',
            style: GoogleFonts.poppins(
                color: AppDesign.textPrimaryDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppDesign.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Segurança',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppDesign.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sua nova senha deve ter no mínimo 8 caracteres, incluir uma letra maiúscula e um número.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppDesign.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 32),

              // Current Password
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Senha atual',
                obscure: _obscureCurrent,
                onToggleVisiblity: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (val) =>
                    (val?.isEmpty ?? true) ? 'Digite sua senha atual' : null,
              ),
              const SizedBox(height: 24),

              // New Password
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nova senha',
                obscure: _obscureNew,
                onToggleVisiblity: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 24),

              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmar nova senha',
                obscure: _obscureConfirm,
                onToggleVisiblity: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Salvar Alterações',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleVisiblity,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppDesign.textPrimaryDark.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: AppDesign.textSecondaryDark),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppDesign.textSecondaryDark,
            ),
            onPressed: onToggleVisiblity,
          ),
        ),
      ),
    );
  }
}
