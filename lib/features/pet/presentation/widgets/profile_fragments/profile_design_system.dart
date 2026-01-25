import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_design.dart';

class ProfileDesignSystem {
  static Widget buildSectionTitle(String title, {IconData? icon}) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppDesign.petPink, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppDesign.petPink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: GoogleFonts.poppins(
        color: AppDesign.petPink,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    double? fontSize,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: fontSize ?? 14),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white30, size: 18),
        filled: true,
        fillColor: AppDesign.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppDesign.petPink, width: 1),
        ),
        errorStyle: const TextStyle(color: AppDesign.error),
      ),
      validator: validator,
      onChanged: (v) => onChanged?.call(),
    );
  }

  static Widget buildOptionSelector({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> options,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: (value == null || !options.contains(value)) ? null : value,
      items: options
          .map((opt) => DropdownMenuItem(
                value: opt,
                child: Text(opt, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppDesign.surfaceDark,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white30, size: 18),
        filled: true,
        fillColor: AppDesign.backgroundDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  static Widget buildDetailRow(String label, String value,
      {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  static Widget buildDatePicker({
    required BuildContext context,
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppDesign.petPink,
                      onPrimary: Colors.black,
                      surface: AppDesign.surfaceDark,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) onDateSelected(date);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: Icon(icon, color: Colors.white30, size: 18),
              filled: true,
              fillColor: AppDesign.backgroundDark,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : 'Selecionar data',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const Icon(Icons.calendar_today,
                    color: Colors.white30, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
