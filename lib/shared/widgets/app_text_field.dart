import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool isMonetary;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool readOnly;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.isMonetary = false,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    Widget? prefix = prefixIcon;

    if (isMonetary) {
      prefix = Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Text(
          '₹',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navyPrimary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMd(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          keyboardType: isMonetary ? const TextInputType.numberWithOptions(decimal: true) : keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: isMonetary
              ? AppTypography.currencyLedger(color: AppColors.navyDark)
              : AppTypography.bodyMd(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            prefixIconConstraints: isMonetary ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.hairlineBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.hairlineBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.crimsonDanger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.crimsonDanger, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
