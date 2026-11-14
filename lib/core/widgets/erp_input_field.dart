import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

class ErpInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final dynamic prefixIcon; // Can be IconData or Widget
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const ErpInputField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  State<ErpInputField> createState() => _ErpInputFieldState();
}

class _ErpInputFieldState extends State<ErpInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget? _buildPrefix() {
    if (widget.prefixIcon == null) return null;
    if (widget.prefixIcon is IconData) {
      return Icon(
        widget.prefixIcon as IconData,
        size: 20,
        color: _isFocused ? AppColors.primary : const Color(0xFF94A3B8),
      );
    }
    if (widget.prefixIcon is Widget) {
      return widget.prefixIcon as Widget;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    final bgColor = isDarkMode
        ? AppColors.darkCard
        : const Color(0xFFF8FAFC);

    final borderColor = _isFocused
        ? (isDarkMode ? AppColors.primaryLight : AppColors.primary)
        : (isDarkMode ? AppColors.darkCardBorder : const Color(0xFFE2E8F0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? AppColors.primary.withValues(alpha: isDarkMode ? 0.25 : 0.08)
                      : Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.02),
                  blurRadius: _isFocused ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              validator: widget.validator,
              onChanged: widget.onChanged,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? AppColors.darkTextMuted
                      : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                prefixIcon: _buildPrefix(),
                suffixIcon: widget.suffixIcon,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
