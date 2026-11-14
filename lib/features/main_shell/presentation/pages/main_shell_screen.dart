import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/download_app_dialog.dart';
import '../../../../core/widgets/erp_bottom_nav_bar.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../hr_payroll/presentation/pages/employee_page.dart';
import '../../../inventory/presentation/pages/low_stocks_page.dart';
import '../../../production/presentation/pages/production_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  late final PageController _pageController;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;

  final GlobalKey<LowStocksPageState> _inventoryKey = GlobalKey<LowStocksPageState>();
  final GlobalKey<EmployeePageState> _employeeKey = GlobalKey<EmployeePageState>();
  final GlobalKey<ProductionPageState> _productionKey = GlobalKey<ProductionPageState>();
  final GlobalKey<SettingsPageState> _settingsKey = GlobalKey<SettingsPageState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    if (_currentIndex != 0) {
      _tabHistory.add(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.add(index);
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.add(index);
    });
  }

  bool get _isSubScreenActive {
    if (_currentIndex == 1 && _inventoryKey.currentState?.hasSubScreen == true) return true;
    if (_currentIndex == 2 && _employeeKey.currentState?.hasSubScreen == true) return true;
    if (_currentIndex == 3 && _productionKey.currentState?.hasSubScreen == true) return true;
    if (_currentIndex == 4 && _settingsKey.currentState?.hasSubScreen == true) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Step 1: Check if the active tab has a sub-page open
        if (_currentIndex == 4 && _settingsKey.currentState?.hasSubScreen == true) {
          _settingsKey.currentState?.popSubScreen();
          return;
        }
        if (_currentIndex == 3 && _productionKey.currentState?.hasSubScreen == true) {
          _productionKey.currentState?.popSubScreen();
          return;
        }
        if (_currentIndex == 2 && _employeeKey.currentState?.hasSubScreen == true) {
          _employeeKey.currentState?.popSubScreen();
          return;
        }
        if (_currentIndex == 1 && _inventoryKey.currentState?.hasSubScreen == true) {
          _inventoryKey.currentState?.popSubScreen();
          return;
        }

        // Step 2: If at tab root, pop back to the ACTUAL previous tab visited
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _currentIndex = _tabHistory.last;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentIndex);
          }
          return;
        }

        // Step 3: If only Home tab (0) remains in history, require double-back press to exit app
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit Buoy!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 90, left: 20, right: 20),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isDesktopWeb = constraints.maxWidth >= 840;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: isDesktopWeb
                  ? _buildWebDesktopLayout(context, isDark)
                  : _buildMobileLayout(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebDesktopLayout(BuildContext context, bool isDark) {
    const titles = ['Dashboard', 'Inventory', 'HR & Payroll', 'Factory & Production', 'Settings'];
    const icons = [
      Icons.dashboard_rounded,
      Icons.inventory_2_rounded,
      Icons.badge_rounded,
      Icons.precision_manufacturing_rounded,
      Icons.settings_rounded,
    ];

    final sidebarBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Row(
      children: [
        // Web Sidebar
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: sidebarBg,
            border: Border(right: BorderSide(color: border, width: 1.2)),
          ),
          child: Column(
            children: [
              // Branding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUOY ERP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FACTORY CLOUD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              const SizedBox(height: 12),

              // Navigation Links
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: titles.length,
                  itemBuilder: (context, i) {
                    final isSelected = _currentIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => _onTabTapped(i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icons[i],
                                size: 20,
                                color: isSelected ? AppColors.primary : textSecondary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  titles[i],
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Download App Card at Sidebar Bottom
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                        const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Mobile ERP App',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get the native Android APK for tablets & smartphones.',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => DownloadAppDialog.show(context),
                          icon: const Icon(Icons.download_rounded, size: 15, color: Colors.white),
                          label: const Text(
                            'Download APK',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Web Content Column
        Expanded(
          child: Column(
            children: [
              // Web Top Navigation Header
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: sidebarBg,
                  border: Border(bottom: BorderSide(color: border, width: 1.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      titles[_currentIndex],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Factory Global Sync',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Top Action: Download App Dialog Button
                    OutlinedButton.icon(
                      onPressed: () => DownloadAppDialog.show(context),
                      icon: const Icon(Icons.android_rounded, size: 17, color: Color(0xFF10B981)),
                      label: const Text(
                        'Download Android App',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: border, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Content Centered with Responsive Max Width
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1350),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        DashboardPage(
                          onNavigateToLowStocks: () => _onTabTapped(1),
                          onNavigateToInventory: () => _onTabTapped(1),
                          onNavigateToEmployees: () => _onTabTapped(2),
                          onNavigateToProduction: () => _onTabTapped(3),
                        ),
                        LowStocksPage(key: _inventoryKey),
                        EmployeePage(key: _employeeKey),
                        ProductionPage(key: _productionKey),
                        SettingsPage(key: _settingsKey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Slidable iPhone-style PageView with Bouncing Physics
        PageView(
          controller: _pageController,
          physics: _isSubScreenActive
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: [
            RepaintBoundary(
              child: DashboardPage(
                onNavigateToLowStocks: () => _onTabTapped(1),
                onNavigateToInventory: () => _onTabTapped(1),
                onNavigateToEmployees: () => _onTabTapped(2),
                onNavigateToProduction: () => _onTabTapped(3),
              ),
            ),
            RepaintBoundary(
              child: LowStocksPage(key: _inventoryKey),
            ),
            RepaintBoundary(
              child: EmployeePage(key: _employeeKey),
            ),
            RepaintBoundary(
              child: ProductionPage(key: _productionKey),
            ),
            RepaintBoundary(
              child: SettingsPage(key: _settingsKey),
            ),
          ],
        ),

        // Web Mobile Notice Banner (only shown on web browser on phones)
        if (kIsWeb)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: InkWell(
              onTap: () => DownloadAppDialog.show(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.android_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using Web? Tap to Download Android App APK',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.file_download_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),

        // Persistent Floating Bottom Navigation Bar
        Align(
          alignment: Alignment.bottomCenter,
          child: ErpBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            pageController: _pageController,
          ),
        ),
      ],
    );
  }
}
