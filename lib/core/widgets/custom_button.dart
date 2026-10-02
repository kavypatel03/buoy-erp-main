import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

enum CustomButtonVariant { primary, secondary, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final CustomButtonVariant variant;
  final bool isLoading;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    List<BoxShadow>? shadow;

    switch (variant) {
      case CustomButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        shadow = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case CustomButtonVariant.secondary:
        backgroundColor = const Color(0xFFF5F5F7);
        textColor = AppColors.primary;
        shadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case CustomButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        shadow = null;
        break;
    }

    return Container(
      width: width ?? double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: variant == CustomButtonVariant.outline
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
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
