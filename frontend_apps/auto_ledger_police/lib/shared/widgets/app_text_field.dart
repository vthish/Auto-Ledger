import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.borderRadius,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final double? borderRadius;

  InputBorder _withRadius(
    InputBorder? border,
    BorderRadius radius,
    BorderSide fallbackSide,
  ) {
    if (border is OutlineInputBorder) {
      return border.copyWith(
        borderRadius: radius,
      );
    }

    if (border is UnderlineInputBorder) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: border.borderSide,
      );
    }

    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: fallbackSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputTheme =
        Theme.of(context).inputDecorationTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final radiusValue = borderRadius;

    var decoration = InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
    );

    if (radiusValue != null) {
      final radius = BorderRadius.circular(radiusValue);

      decoration = decoration.copyWith(
        border: _withRadius(
          inputTheme.border,
          radius,
          BorderSide.none,
        ),
        enabledBorder: _withRadius(
          inputTheme.enabledBorder ?? inputTheme.border,
          radius,
          BorderSide.none,
        ),
        focusedBorder: _withRadius(
          inputTheme.focusedBorder ?? inputTheme.border,
          radius,
          BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: _withRadius(
          inputTheme.errorBorder,
          radius,
          BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: _withRadius(
          inputTheme.focusedErrorBorder ??
              inputTheme.errorBorder,
          radius,
          BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        disabledBorder: _withRadius(
          inputTheme.disabledBorder ??
              inputTheme.enabledBorder ??
              inputTheme.border,
          radius,
          BorderSide.none,
        ),
      );
    }

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: decoration,
    );
  }
}