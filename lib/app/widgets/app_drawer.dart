import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gc_any_order/app/modules/order_report/views/order_report_view.dart';
import 'package:gc_any_order/app/services/order_monitoring_service.dart';
import '../resources/app_colors.dart';
import '../resources/app_strings.dart';
import '../services/logger_service.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _drawerItem(Icons.home_outlined, AppStrings.home, onTap: () => Get.back()),
          _drawerItem(Icons.settings_outlined, AppStrings.setting, onTap: () => Get.toNamed('/settings')),
          _drawerItem(Icons.file_download_outlined, "Export Logs", onTap: () => LoggerService.to.shareLogs()),
          _drawerItem(Icons.analytics_outlined, AppStrings.orderReport, onTap: () => Get.toNamed('/order-report')),

          const Divider(indent: 16, endIndent: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.communicate,
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          _drawerItem(Icons.policy_outlined, "Privacy Policy"),
          _drawerItem(Icons.info_outline, AppStrings.version),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Version 1.0.2",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.restaurant, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Welcome,",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Obx(() {
            final userName = Get.find<OrderMonitoringService>().currentUserName;
            final storeId = Get.find<OrderMonitoringService>().currentStoreId;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isNotEmpty ? userName : "User",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
    );
  }
}
