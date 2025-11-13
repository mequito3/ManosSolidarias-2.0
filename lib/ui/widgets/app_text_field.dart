import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enableObscureToggle = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool enableObscureToggle;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> with SingleTickerProviderStateMixin {
  late bool _obscure;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;

    // Animación para el toggle
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText && !widget.enableObscureToggle) {
      _obscure = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    _animationController.forward().then((_) {
      setState(() => _obscure = !_obscure);
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldObscure = widget.enableObscureToggle ? _obscure : widget.obscureText;

    // MEJORA: TextField profesional con mejor diseño
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: shouldObscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.darkText,
        fontWeight: FontWeight.w500, // MEJORA: Peso medium
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: AppColors.mediumText, // MEJORA: Usar color del sistema
          fontSize: 15,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.bluePrimary,
          fontWeight: FontWeight.w600, // MEJORA: Bold cuando está focused
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppColors.space20, // MEJORA: Espaciado del sistema
          vertical: AppColors.space16,
        ),
        // MEJORA: Border por defecto
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd), // MEJORA: Border radius del sistema
          borderSide: const BorderSide(color: AppColors.dividerColor, width: 1.5),
        ),
        // MEJORA: Border cuando está enabled
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.dividerColor, width: 1.5),
        ),
        // MEJORA: Border cuando está focused con sombra
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.bluePrimary, width: 2.5), // MEJORA: Más grueso
        ),
        // MEJORA: Border cuando hay error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        // MEJORA: Border cuando hay error y está focused
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2.5),
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        // MEJORA: Suffix icon mejorado
        suffixIcon: widget.enableObscureToggle
            ? Container(
                margin: const EdgeInsets.only(right: AppColors.space8),
                decoration: BoxDecoration(
                  color: _obscure
                      ? AppColors.bluePrimary.withValues(alpha: 0.1)
                      : AppColors.greenHope.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: IconButton(
                  tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, // MEJORA: Íconos rounded
                    color: _obscure ? AppColors.bluePrimary : AppColors.greenHope,
                    size: 22,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
