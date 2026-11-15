import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import 'change_password_page.dart';
import 'help_support_page.dart';
import 'my_profile_page.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../app/app.dart';
import '../../../../core/widgets/liquid_glass_toggle.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  int _currentSubIndex = 0;
  String _firstName = 'Admin user';
  String _email = 'admin@factory.com';
  String _occupation = 'Administrator';

  @override
  bool get wantKeepAlive => true;

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
        if (e != null && e.isNotEmpty) _email = e;
        final o = data['occupation']?.toString();
        if (o != null && o.isNotEmpty) _occupation = o;
      });
    }
  }

  bool get hasSubScreen => _currentSubIndex > 0;

  void popSubScreen() {
    if (_currentSubIndex > 0) setState(() => _currentSubIndex = 0);
  }

  void _navigateToSubIndex(int index) =>
      setState(() => _currentSubIndex = index);

  void _onBackToSettings() => setState(() => _currentSubIndex = 0);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    switch (_currentSubIndex) {
      case 1: return MyProfilePage(onBack: _onBackToSettings);
      case 2: return ChangePasswordPage(onBack: _onBackToSettings);
      case 3: return HelpSupportPage(onBack: _onBackToSettings);
      default: return _buildMainSettingsList(context);
    }
  }

  Widget _buildMainSettingsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.border;
    final initials = _firstName.isNotEmpty
        ? _firstName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              const ErpHeaderBar(title: 'Settings'),
              const SizedBox(height: 12),

              // ── Profile Banner ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C47FF), Color(0xFF4128C4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              )),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_firstName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 2),
                            Text(_email,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_occupation,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToSubIndex(1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Account Section ────────────────────────────────────────────
              _SectionLabel('Account'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    _buildTile(
                      context,
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primary,
                      title: 'My Profile',
                      subtitle: 'Edit your personal information',
                      onTap: () => _navigateToSubIndex(1),
                    ),
                    Divider(color: dividerColor, height: 1,
                        indent: 56, endIndent: 16),
                    _buildTile(
                      context,
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.warning,
                      title: 'Change Password',
                      subtitle: 'Update your security credentials',
                      onTap: () => _navigateToSubIndex(2),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Preferences Section ────────────────────────────────────────
              _SectionLabel('Preferences'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    _buildTile(
                      context,
                      icon: Icons.notifications_none_rounded,
                      iconColor: AppColors.info,
                      title: 'Notifications',
                      subtitle: 'View and manage alerts',
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                    ),
                    Divider(color: dividerColor, height: 1,
                        indent: 56, endIndent: 16),
                    _buildThemeToggleTile(context),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Support Section ────────────────────────────────────────────
              _SectionLabel('Support'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    _buildTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.success,
                      title: 'Help & Support',
                      subtitle: 'FAQs and contact us',
                      onTap: () => _navigateToSubIndex(3),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // ── Danger Zone ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildTile(
                    context,
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    titleColor: AppColors.error,
                    hideChevron: true,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await AuthService.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App version
              const Text(
                'Buoy ERP v1.0.0',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool hideChevron = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor ??
                              Theme.of(context).colorScheme.onSurface,
                        )),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (!hideChevron)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: isDark ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                const Text('Switch app appearance',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          LiquidGlassToggle(
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (val) {
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
