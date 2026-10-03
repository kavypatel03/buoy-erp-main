import 'package:flutter/material.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Logo in soft elevated glass card (matching nav screenshot 1:1)
          GestureDetector(
            onTap: onBackTap,
            child: Row(
              children: [
                if (onBackTap != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
                  ),
                const BuoyLogoWidget(size: 48),
              ],
            ),
          ),

          // Center: Title Chip Badge in soft elevated glass pill (matching nav screenshot 1:1)
          GlassContainer(
            borderRadius: 25,
            blur: 14,
            opacity: 0.95,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Right: Custom trailing widget OR Notification Bell
          trailing ?? GestureDetector(
            onTap: () {
              if (onNotificationPressed != null) {
                onNotificationPressed!();
              } else {
                final currentRoute = ModalRoute.of(context)?.settings.name;
                if (currentRoute != '/notifications') {
                  Navigator.pushNamed(context, '/notifications');
                }
              }
            },
            child: GlassContainer(
              width: 48,
              height: 48,
              isCircle: true,
              blur: 14,
              opacity: 0.95,
              border: isNotificationActive
                  ? Border.all(color: const Color(0xFF5B3DF5), width: 1.5)
                  : null,
              child: const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
