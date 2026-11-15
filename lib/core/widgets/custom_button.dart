import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

enum CustomButtonVariant { primary, secondary, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final bool isLoading;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor;
    Color textColor;
    List<BoxShadow>? shadow;

    Gradient? gradient;
    Border? border;

    switch (variant) {
      case CustomButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C4EF8), Color(0xFF5132E6)],
        );
        border = Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1.2,
        );
        shadow = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case CustomButtonVariant.secondary:
        backgroundColor = isDark
            ? const Color(0xFF1E1E2E).withValues(alpha: 0.70)
            : Colors.white.withValues(alpha: 0.75);
        textColor = isDark ? AppColors.primaryLight : AppColors.primary;
        border = Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        );
        shadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case CustomButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryLight : AppColors.primary;
        border = Border.all(color: AppColors.primary, width: 1.5);
        shadow = null;
        break;
    }

    if (onPressed == null) {
      backgroundColor = isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0);
      textColor = isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8);
      gradient = null;
      border = null;
      shadow = null;
    }

    return Container(
      width: width ?? double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        border: border,
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
