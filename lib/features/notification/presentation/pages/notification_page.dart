import 'package:flutter/material.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top Header Bar with Back Arrow Tap
              ErpHeaderBar(
                title: 'Notification',
                isNotificationActive: true,
                onBackTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 16),

              // Notification List Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      useGradientBorder: true,
                      borderRadius: 26,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item 1: Paper Stock is Very Low
                          _buildNotificationStockItem(
                            title: 'Paper Stock is Very Low',
                            subtitle: 'White - 150 GSM',
                            metric: '25',
                            unit: 'KG',
                            metricColor: const Color(0xFFFF334B),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(color: Color(0xFFF1F5F9), height: 1),
                          ),

                          // Item 2: Graphite Stock Alert
                          _buildNotificationStockItem(
                            title: 'Graphite Stock Alert',
                            subtitle: 'Synthetic Block',
                            metric: '150',
                            unit: 'KG',
                            metricColor: const Color(0xFFF59E0B),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(color: Color(0xFFF1F5F9), height: 1),
                          ),

                          // Item 3: Glue Stock Received
                          _buildNotificationStockItem(
                            title: 'B-7000 Glue Batch Received',
                            subtitle: 'Grey Adhesive',
                            metric: '200',
                            unit: 'KG',
                            metricColor: const Color(0xFF00B039),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationStockItem({
    required String title,
    required String subtitle,
    required String metric,
    required String unit,
    required Color metricColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              metric,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: metricColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: metricColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
