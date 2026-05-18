import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';
import '../../../resources/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GeneralSettingsView extends StatefulWidget {
  const GeneralSettingsView({Key? key}) : super(key: key);

  @override
  State<GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<GeneralSettingsView> {
  final SettingsController controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(AppStrings.generalSettings, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        actions: [
          Obx(() {
            if (controller.isUnlocked.value) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.lock),
              onPressed: controller.showPasswordDialog,
            );
          }),
        ],
      ),
      body: Obx(() {
        return ListView(
          children: [
            _buildTitleOnlyTile('Remote Setting'),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildValueTile('INI Version', 'v0006', showArrow: false),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildSwitchTile('Overlay other apps', controller.overlayPermission.value, (v) => controller.toggleOverlayPermission(v)),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildSwitchTile('Order Status Tips', controller.orderStatusTips.value, (v) => controller.saveSetting('orderStatusTips', v)),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildSwitchTile('Keep screen on', controller.keepScreenOn.value, (v) => controller.saveSetting('keepScreenOn', v)),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildSwitchTile('Restart app', controller.restartApp.value, (v) => controller.saveSetting('restartApp', v)),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildValueTile('Language', 'Auto', showArrow: false),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            _buildValueTile('Font Size', 'Default', showArrow: false),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          ],
        );
      }),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: AppColors.primary,
      ),
    );
  }

  Widget _buildValueTile(String title, String value, {bool showArrow = true}) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
          if (showArrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ]
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildTitleOnlyTile(String title) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 12.sp, color: Colors.grey),
      onTap: () {},
    );
  }
}
