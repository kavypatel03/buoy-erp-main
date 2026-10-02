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
  bool _isAutoLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    
    if (rememberMe) {
      final email = prefs.getString('saved_email') ?? '';
      final password = prefs.getString('saved_password') ?? '';
      
      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() => _isAutoLoggingIn = true);
        final result = await AuthService.login(email, password);
        if (result['success'] && mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (mounted) {
          setState(() => _isAutoLoggingIn = false);
        }
      }
    }
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
                        child: CircularProgressIndicator(),
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
                          CustomButton(
                            text: 'Register',
                            variant: CustomButtonVariant.secondary,
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
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
