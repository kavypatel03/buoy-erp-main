import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToLowStocks;
  final VoidCallback? onNavigateToInventory;
  final VoidCallback? onNavigateToProduction;
  final VoidCallback? onNavigateToEmployees;

  const DashboardPage({
    super.key,
    this.onNavigateToLowStocks,
    this.onNavigateToInventory,
    this.onNavigateToProduction,
    this.onNavigateToEmployees,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentCarouselIndex = ValueNotifier<int>(1);
  Timer? _autoSlideTimer;
  Timer? _notificationPollTimer;
  Timer? _summaryRefreshTimer;
  final Set<String> _poppedNotificationIds = {};

  // Summary stats — start with '-' to show loading
  String _totalItems = '-';
  String _lowStockItems = '-';
  String _activeOrders = '-';
  String _clockedIn = '-';
  String _totalEmployees = '-';
  String _logsToday = '-';
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();

    // Auto-sliding carousel
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

    LocalNotificationService.requestPermission();

    // Notification polling every 15s
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollNotifications();
    });
    _pollNotifications();

    // Fetch summary immediately, then refresh every 30s
    _fetchSummary();
    _summaryRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchSummary();
    });
  }

  Future<void> _fetchSummary() async {
    final result = await DashboardService.getSummary();
    if (result['success'] && mounted) {
      final data = result['data'];
      setState(() {
        _totalItems = '${data['totalItems'] ?? 0}';
        _lowStockItems = '${data['lowStockItems'] ?? 0}';
        _activeOrders = '${data['activeOrders'] ?? 0}';
        _clockedIn = '${data['clockedInEmployees'] ?? 0}';
        _totalEmployees = '${data['totalEmployees'] ?? 0}';
        _logsToday = '${data['logsToday'] ?? 0}';
        _summaryLoading = false;
      });
    } else if (mounted) {
      setState(() => _summaryLoading = false);
    }
  }

  Future<void> _pollNotifications() async {
    final result = await NotificationService.getNotifications();
    if (result['success'] && mounted) {
      final List<dynamic> notifs = result['data'];
      for (var n in notifs) {
        if (n['is_read'] == false && !_poppedNotificationIds.contains(n['id'])) {
          _poppedNotificationIds.add(n['id']);
          LocalNotificationService.showNotification(
            id: (n['id'].hashCode.abs()) & 0x7FFFFFFF,
            title: n['title'] ?? 'New Notification',
            body: n['message'] ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _notificationPollTimer?.cancel();
    _summaryRefreshTimer?.cancel();
    _pageController.dispose();
    _currentCarouselIndex.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _summaryLoading = true);
    await _fetchSummary();
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ErpHeaderBar(title: 'Dashboard'),
              const SizedBox(height: 12),

              // Greeting Banner
              const _GreetingBanner(),
              const SizedBox(height: 20),

              // Feature carousel
              SizedBox(
                height: 165,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => _currentCarouselIndex.value = index,
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

              // Carousel dots
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
                          color: isActive ? const Color(0xFF5B3DF5) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Overview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (_summaryLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B3DF5)),
                      )
                    else
                      GestureDetector(
                        onTap: _handleRefresh,
                        child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF5B3DF5)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2x2 grid stat cards — now LIVE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _GridCard(
                            title: 'Inventory Items',
                            value: _totalItems,
                            unit: 'Total Items',
                            icon: Icons.inventory_2_rounded,
                            iconColor: const Color(0xFF5B3DF5),
                            iconBg: const Color(0x1F5B3DF5),
                            onTap: widget.onNavigateToInventory,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _GridCard(
                            title: 'Production',
                            value: _activeOrders,
                            unit: 'Active Orders',
                            icon: Icons.settings_suggest_rounded,
                            iconColor: const Color(0xFFFF8C00),
                            iconBg: const Color(0x1FFF8C00),
                            onTap: widget.onNavigateToProduction,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _GridCard(
                            title: 'Attendance',
                            value: _clockedIn,
                            unit: '$_totalEmployees Total Emp.',
                            icon: Icons.people_rounded,
                            iconColor: const Color(0xFF00B039),
                            iconBg: const Color(0x1F00B039),
                            onTap: widget.onNavigateToEmployees,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _GridCard(
                            title: 'Low Stock',
                            value: _lowStockItems,
                            unit: 'Need Restock',
                            icon: Icons.notifications_active_rounded,
                            iconColor: const Color(0xFFFF334B),
                            iconBg: const Color(0x1FFF334B),
                            isAlert: int.tryParse(_lowStockItems) != null && int.parse(_lowStockItems) > 0,
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
                    const SizedBox(height: 16),
                    // Extra wide card for process logs today
                    _GridCardWide(
                      title: 'Process Steps Logged Today',
                      value: _logsToday,
                      unit: 'Steps across all orders',
                      icon: Icons.playlist_add_check_rounded,
                      iconColor: const Color(0xFF5B3DF5),
                      iconBg: const Color(0x1F5B3DF5),
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

// ─── Greeting Banner ────────────────────────────────────────────────────────

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
              '${_greeting()} $_firstName 👋',
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

// ─── Smart Inventory Carousel Card ──────────────────────────────────────────

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
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 15),
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
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF5B3DF5)),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 11, color: Color(0xFF5B3DF5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          RepaintBoundary(
            child: SvgPicture.asset(AppAssets.factoryIllustration, height: 80, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

// ─── Carousel Card ──────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(buttonText, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: iconBg)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 11, color: iconBg),
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

// ─── Grid Stat Card ─────────────────────────────────────────────────────────

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
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                value,
                key: ValueKey(value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isAlert ? const Color(0xFFFF334B) : const Color(0xFF0F172A),
                ),
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

// ─── Wide Stat Card (full width) ────────────────────────────────────────────

class _GridCardWide extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _GridCardWide({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      useGradientBorder: true,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
                Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
