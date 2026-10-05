import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (_currentIndex != 0) {
      _tabHistory.add(_currentIndex);
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.add(index);
    });
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Persistent Page Content Body with GlobalKeys for nested navigation checking
              IndexedStack(
                index: _currentIndex,
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

              // + FAB button above the Settings nav icon — visible only on Inventory/Employee list screens
              if ((_currentIndex == 1 && _inventoryKey.currentState?.hasSubScreen != true) ||
                  (_currentIndex == 2 && _employeeKey.currentState?.hasSubScreen != true))
                Positioned(
                  right: 28,
                  bottom: 95,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex == 1) {
                        _inventoryKey.currentState?.goToAddNewItem();
                      } else if (_currentIndex == 2) {
                        _employeeKey.currentState?.goToAddNewEmployee();
                      }
                      setState(() {}); // refresh to hide FAB after navigating
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B3DF5).withValues(alpha: 0.15),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Color(0xFF5B3DF5),
                              size: 30,
                            ),
                          ),
                        ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
