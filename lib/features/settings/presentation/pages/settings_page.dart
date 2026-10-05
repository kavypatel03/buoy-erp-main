import 'package:flutter/material.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import 'change_password_page.dart';
import 'help_support_page.dart';
import 'my_profile_page.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../app/app.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  int _currentSubIndex = 0; // 0: Main Settings, 1: My Profile, 2: Change Password, 3: Help & Support
  bool _isDarkMode = false;
  String _firstName = 'Admin user';
  String _email = 'admin@factory.com';
  String _occupation = 'Administrator';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final result = await ProfileService.getProfile();
    if (result['success'] && mounted) {
      final data = result['data'];
      setState(() {
        final fName = data['first_name']?.toString();
        final sName = data['surname']?.toString();
        if (fName != null && fName.isNotEmpty) {
          _firstName = fName + (sName != null && sName.isNotEmpty ? ' $sName' : '');
        }
        
        final e = data['email']?.toString();
        if (e != null && e.isNotEmpty) {
          _email = e;
        }

        final o = data['occupation']?.toString();
        if (o != null && o.isNotEmpty) {
          _occupation = o;
        }
      });
    }
  }

  bool get hasSubScreen => _currentSubIndex > 0;

  void popSubScreen() {
    if (_currentSubIndex > 0) {
      setState(() {
        _currentSubIndex = 0;
      });
    }
  }

  void _navigateToSubIndex(int index) {
    setState(() {
      _currentSubIndex = index;
    });
  }

  void _onBackToSettings() {
    setState(() {
      _currentSubIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentSubIndex) {
      case 1:
        return MyProfilePage(onBack: _onBackToSettings);
      case 2:
        return ChangePasswordPage(onBack: _onBackToSettings);
      case 3:
        return HelpSupportPage(onBack: _onBackToSettings);
      default:
        return _buildMainSettingsList(context);
    }
  }

  Widget _buildMainSettingsList(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              // Top Header Bar
              const ErpHeaderBar(title: 'Setting'),

              const SizedBox(height: 12),

              // User Info Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3DF5),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B3DF5).withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD600),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Container(
                            color: const Color(0xFFFCD34D),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _firstName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _occupation,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Settings Options Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  useGradientBorder: true,
                  borderRadius: 26,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    children: [
                      _buildOptionTile(
                        icon: Icons.person_outline_rounded,
                        title: 'My Profile',
                        onTap: () => _navigateToSubIndex(1),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      _buildOptionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        onTap: () => _navigateToSubIndex(2),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      _buildOptionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      _buildThemeToggleTile(),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      _buildOptionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () => _navigateToSubIndex(3),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      _buildOptionTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        textColor: const Color(0xFFFF334B),
                        iconColor: const Color(0xFFFF334B),
                        hideChevron: true,
                        onTap: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF0F172A),
    Color iconColor = const Color(0xFF64748B),
    bool hideChevron = false,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: hideChevron
          ? null
          : const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
      onTap: onTap,
      ),
    );
  }

  Widget _buildThemeToggleTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 22),
              SizedBox(width: 14),
              Text(
                'Theme Setting',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Switch(
                value: themeNotifier.value == ThemeMode.dark,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF5B3DF5),
                onChanged: (val) {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  setState(() {});
                },
              ),
              const SizedBox(width: 6),
              const Icon(Icons.nightlight_round_outlined, size: 18, color: Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }
}
