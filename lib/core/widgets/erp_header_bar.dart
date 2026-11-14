import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import 'buoy_logo_widget.dart';
import 'glass_container.dart';

class ErpHeaderBar extends StatelessWidget {
  final String title;
  final bool isNotificationActive;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onBackTap;
  final Widget? trailing;

  const ErpHeaderBar({
    super.key,
    required this.title,
    this.isNotificationActive = false,
    this.onNotificationPressed,
    this.onBackTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: Logo / Back ──────────────────────────────────────────────
          GestureDetector(
            onTap: onBackTap,
            child: Row(
              children: [
                if (onBackTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: iconColor),
                    ),
                  ),
                const BuoyLogoWidget(size: 48),
              ],
            ),
          ),

          // ── Center: Title pill ─────────────────────────────────────────────
          GlassContainer(
            borderRadius: 25,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: iconColor,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // ── Right: Notification or custom trailing ─────────────────────────
          trailing ??
              GestureDetector(
                onTap: () {
                  if (onNotificationPressed != null) {
                    onNotificationPressed!();
                  } else {
                    final currentRoute =
                        ModalRoute.of(context)?.settings.name;
                    if (currentRoute != '/notifications') {
                      Navigator.pushNamed(context, '/notifications');
                    }
                  }
                },
                child: GlassContainer(
                  width: 44,
                  height: 44,
                  isCircle: true,
                  border: isNotificationActive
                      ? Border.all(
                          color: AppColors.primary, width: 1.8)
                      : null,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            color: iconColor, size: 22),
                        if (isNotificationActive)
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
