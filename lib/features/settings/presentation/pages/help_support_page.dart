import 'package:flutter/material.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';

class HelpSupportPage extends StatelessWidget {
  final VoidCallback? onBack;

  const HelpSupportPage({
    super.key,
    this.onBack,
  });

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
                title: 'Help & Support',
                onBackTap: onBack ?? () => Navigator.pop(context),
              ),

              const SizedBox(height: 16),

              // Main Help & Support Card Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  useGradientBorder: true,
                  borderRadius: 26,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Common Issues
                      Text(
                        'Common Issues',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildHelpText('1. Unable to log in? Check your username and password.'),
                      const SizedBox(height: 10),
                      _buildHelpText('2. Stock data not updating? Refresh the application and check your internet connection.'),
                      const SizedBox(height: 10),
                      _buildHelpText('3. Report not generating? Verify the selected date range and available data.'),

                      const SizedBox(height: 24),

                      // Contact Support Guides
                      Text(
                        'Contact Support',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildHelpText('1. Manage inventory items and stock levels from the Inventory module.'),
                      const SizedBox(height: 10),
                      _buildHelpText('2. Monitor warehouse stock movements in the Warehouse module.'),

                      const SizedBox(height: 24),

                      // Contact Details
                      Text(
                        'Contact Support',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildContactRow(context, Icons.email_outlined, 'kavypatel5323@gmail.com'),
                      const SizedBox(height: 12),
                      _buildContactRow(context, Icons.phone_in_talk_outlined, '+91-98799-74411, +91-94260-24009'),
                      const SizedBox(height: 12),
                      _buildContactRow(context, Icons.access_time_rounded, 'Mon-Sat, 9:00 AM - 6:00 PM'),
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

  Widget _buildHelpText(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: Color(0xFF64748B),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          detail,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
