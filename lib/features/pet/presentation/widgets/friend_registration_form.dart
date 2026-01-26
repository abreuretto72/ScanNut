import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/friend_model.dart';

class FriendRegistrationForm extends StatefulWidget {
  final Future<void> Function(FriendModel) onSave;

  const FriendRegistrationForm({super.key, required this.onSave});

  @override
  State<FriendRegistrationForm> createState() => _FriendRegistrationFormState();
}

class _FriendRegistrationFormState extends State<FriendRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerContactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final friend = FriendModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        gender: _genderController.text.trim(),
        age: _ageController.text.trim(),
        breed: _breedController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerContact: _ownerContactController.text.trim(),
        registeredAt: DateTime.now(),
      );
      await widget.onSave(friend);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppDesign.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.walkFriendManual,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.walkFriendManualDesc,
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildField(l10n.friendName, _nameController, isRequired: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(l10n.friendGender, _genderController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(l10n.friendAge, _ageController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(l10n.friendBreed, _breedController),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              _buildField(l10n.friendOwnerName, _ownerNameController),
              const SizedBox(height: 16),
              _buildField(l10n.friendOwnerContact, _ownerContactController, isPhone: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.commonSave,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isRequired = false, bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppDesign.primary),
        ),
        errorStyle: GoogleFonts.poppins(color: AppDesign.error),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return AppLocalizations.of(context)!.friendValidationError;
        }
        return null;
      },
    );
  }
}
