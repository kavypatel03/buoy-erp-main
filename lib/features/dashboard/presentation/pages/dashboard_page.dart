import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/local_notification_service.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToLowStocks;

  const DashboardPage({
    super.key,
    this.onNavigateToLowStocks,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentCarouselIndex = ValueNotifier<int>(1);
  Timer? _autoSlideTimer;
  Timer? _notificationPollTimer;
  final Set<String> _poppedNotificationIds = {};

  @override
  void initState() {
    super.initState();

    // Auto-sliding for top carousel
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.round() ?? 0) + 1;
        if (nextPage >= 3) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    // Request permission on app open (Dashboard load)
    LocalNotificationService.requestPermission();

    // Poll for new notifications every 15 seconds
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _pollNotifications();
    });
    
    // Initial poll
    _pollNotifications();
  }

  Future<void> _pollNotifications() async {
    final result = await NotificationService.getNotifications();
    print("🔔 Notification Poll Result: $result");
    if (result['success'] && mounted) {
      final List<dynamic> notifs = result['data'];
      for (var n in notifs) {
        if (n['is_read'] == false && !_poppedNotificationIds.contains(n['id'])) {
          _poppedNotificationIds.add(n['id']);
          print("🔔 Triggering Local Notification for: ${n['title']}");
          LocalNotificationService.showNotification(
            id: (n['id'].hashCode.abs()) & 0x7FFFFFFF, // Ensure valid 32-bit positive integer
            title: n['title'] ?? 'New Notification',
            body: n['message'] ?? '',
          );
          // Optionally mark as read on server if needed:
          // NotificationService.markAsRead(n['id']);
        }
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _notificationPollTimer?.cancel();
    _pageController.dispose();
    _currentCarouselIndex.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: const Color(0xFF5B3DF5),
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              const ErpHeaderBar(title: 'Dashboard'),

              const SizedBox(height: 12),

              // Greeting Banner
              const _GreetingBanner(),

              const SizedBox(height: 20),

              // Horizontal Feature Banners Carousel
              SizedBox(
                height: 165,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _currentCarouselIndex.value = index;
                  },
                  children: const [
                    _CarouselCard(
                      title: 'Warehouse Control',
                      subtitle: 'Manage stock transfers & bin locations.',
                      buttonText: 'Explore',
                      bgColor: Color(0xFFFFFBEB),
                      iconBg: Color(0xFFF59E0B),
                      icon: Icons.warehouse_rounded,
                    ),
                    _SmartInventoryCard(),
                    _CarouselCard(
                      title: 'Real-time Reports',
                      subtitle: 'Get insights to make smarter decisions.',
                      buttonText: 'Get Started',
                      bgColor: Color(0xFFF0FDF4),
                      iconBg: Color(0xFF10B981),
                      icon: Icons.bar_chart_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Page Indicator Dots (Only this small widget rebuilds on page swipe!)
              ValueListenableBuilder<int>(
                valueListenable: _currentCarouselIndex,
                builder: (context, activeIndex, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == activeIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF5B3DF5)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 4 Grid Action Cards (2x2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _GridCard(
                            title: 'Total Items',
                            value: '12',
                            unit: 'Categories',
                            icon: Icons.inventory_2_rounded,
                            iconColor: Color(0xFF5B3DF5),
                            iconBg: Color(0x1F5B3DF5),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _GridCard(
                            title: 'Processes',
                            value: '24',
                            unit: 'Active',
                            icon: Icons.settings_suggest_rounded,
                            iconColor: Color(0xFFFF334B),
                            iconBg: Color(0x1FFF334B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: _GridCard(
                            title: 'Attendance',
                            value: '10',
                            unit: 'Member Available',
                            icon: Icons.battery_charging_full_rounded,
                            iconColor: Color(0xFF00B039),
                            iconBg: Color(0x1F00B039),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _GridCard(
                            title: 'Low stock Items',
                            value: '5',
                            unit: 'Very Low',
                            icon: Icons.notifications_active_rounded,
                            iconColor: const Color(0xFFFF334B),
                            iconBg: const Color(0x1FFF334B),
                            isAlert: true,
                            onTap: () {
                              if (widget.onNavigateToLowStocks != null) {
                                widget.onNavigateToLowStocks!();
                              } else {
                                Navigator.pushNamed(context, '/low-stocks');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingBanner extends StatefulWidget {
  const _GreetingBanner();

  @override
  State<_GreetingBanner> createState() => _GreetingBannerState();
}

class _GreetingBannerState extends State<_GreetingBanner> {
  String _firstName = 'Admin';

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    final result = await ProfileService.getProfile();
    if (result['success'] && mounted) {
      final data = result['data'];
      final name = data['first_name'];
      if (name != null && name.toString().isNotEmpty) {
        setState(() => _firstName = name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C47FF), Color(0xFF4128C4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D5B3DF5),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning $_firstName 👋',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's what's happening today",
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartInventoryCard extends StatelessWidget {
  const _SmartInventoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3DF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart Inventory\nManagement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Track, Manage and optimize your inventory real-time.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: const [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B3DF5),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: Color(0xFF5B3DF5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          RepaintBoundary(
            child: SvgPicture.asset(
              AppAssets.factoryIllustration,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final Color bgColor;
  final Color iconBg;
  final IconData icon;

  const _CarouselCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.bgColor,
    required this.iconBg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: iconBg,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: iconBg,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isAlert;
  final VoidCallback? onTap;

  const _GridCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useGradientBorder: true,
        borderRadius: 22,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isAlert ? const Color(0xFFFF334B) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isAlert ? const Color(0xFFFF334B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
