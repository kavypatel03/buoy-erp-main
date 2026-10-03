import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../core/widgets/buoy_logo_widget.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // Start as false — page renders immediately, checks happen in background
  bool _isAutoLoggingIn = false;
  bool _isRegistrationEnabled = true; // optimistic default — page shows instantly
  bool _isCheckingStatus = true; // subtle loading state for the Register button only

  @override
  void initState() {
    super.initState();
    // Run both checks after first frame so the page never blocks on black screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRegistrationStatus();
      _checkAutoLogin();
    });
  }

  Future<void> _checkRegistrationStatus() async {
    final isEnabled = await AuthService.getRegistrationStatus();
    if (mounted) {
      setState(() {
        _isRegistrationEnabled = isEnabled;
        _isCheckingStatus = false;
      });
    }
  }

  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (rememberMe) {
        final email = prefs.getString('saved_email') ?? '';
        final password = prefs.getString('saved_password') ?? '';

        if (email.isNotEmpty && password.isNotEmpty) {
          if (mounted) setState(() => _isAutoLoggingIn = true);
          final result = await AuthService.login(email, password);
          if (result['success'] && mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
            return;
          }
        }
      }
    } catch (_) {
      // Silently ignore — just show the welcome page normally
    }
    if (mounted) setState(() => _isAutoLoggingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const BuoyLogoWidget(
                        fontSize: 22,
                        showAsCard: true,
                      ),
                    ),

                    Column(
                      children: [
                        const SizedBox(height: 20),
                        SvgPicture.asset(
                          AppAssets.factoryIllustration,
                          height: 210,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Factory ERP',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          AppConstants.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),

                    _isAutoLoggingIn
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Logging you in...', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              const SizedBox(height: 32),
                              CustomButton(
                                text: 'Login',
                                variant: CustomButtonVariant.primary,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Or',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Register button is always visible;
                              // disabled (greyed out) if registration is turned off by admin
                              Opacity(
                                opacity: (!_isCheckingStatus && !_isRegistrationEnabled) ? 0.45 : 1.0,
                                child: CustomButton(
                                  text: _isCheckingStatus
                                      ? 'Register'
                                      : _isRegistrationEnabled
                                          ? 'Register'
                                          : 'Register (Disabled by Admin)',
                                  variant: CustomButtonVariant.secondary,
                                  onPressed: () {
                                    // Always navigate to register page;
                                    // the page itself shows a disabled button when registration is off
                                    Navigator.pushNamed(context, '/register');
                                  },
                                ),
                              ),
                              if (!_isCheckingStatus && !_isRegistrationEnabled)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Registration is currently disabled by the administrator.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                    Padding(
                      padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
                      child: Column(
                        children: [
                          const Text(
                            AppConstants.footerMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              BuoyLogoWidget(fontSize: 11),
                              SizedBox(width: 6),
                              Text(
                                AppConstants.copyright,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
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
            );
          },
        ),
      ),
    );
  }
}
