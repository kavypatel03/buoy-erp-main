import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/glass_container.dart';

class ChangePasswordPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ChangePasswordPage({
    super.key,
    this.onBack,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              // Header
              ErpHeaderBar(
                title: 'Change Password',
                onBackTap: widget.onBack ?? () => Navigator.pop(context),
              ),

              const SizedBox(height: 16),

              // Change Password Container Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  useGradientBorder: true,
                  borderRadius: 26,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Change Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Enter Old Password
                      ErpInputField(
                        label: 'Enter Old Password',
                        hintText: 'Enter your old password',
                        controller: _oldPasswordController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 16),

                      // Enter New Password
                      ErpInputField(
                        label: 'Enter New Password',
                        hintText: 'Password should contain atleast 8 character',
                        controller: _newPasswordController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      ErpInputField(
                        label: 'Confirm Password',
                        hintText: 'Re-enter new password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 12),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Forgot password ?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5B3DF5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Update Password Button
                      CustomButton(
                        text: 'Update Password',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password Changed Successfully!')),
                          );
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            Navigator.pop(context);
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
}
