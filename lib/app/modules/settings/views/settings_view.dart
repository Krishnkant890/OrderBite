import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_colors.dart';
import '../../../resources/app_strings.dart';
import 'html_settings_view.dart';
import 'printing_settings_view.dart';
import 'music_settings_view.dart';
import 'receipt_format_view.dart';
import 'general_settings_view.dart';
import 'server_settings_view.dart';
import 'response_view.dart';
import 'fcm_settings_view.dart';
import 'application_version_view.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Match the light grey background
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFBF3A20,
        ), // Matched dark orange/red from screenshot
        foregroundColor: Colors.white,
        title: const Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.isUnlocked.value) {
              return const SizedBox.shrink(); // Hide lock icon when unlocked
            }
            return IconButton(
              icon: const Icon(Icons.lock),
              onPressed: controller.showPasswordDialog,
            );
          }),
        ],
      ),
      body: Obx(() {
        final List<Widget> items = [];

        if (controller.isUnlocked.value) {
          // items.add(_buildItem(Icons.public, AppStrings.serverSettings));
          items.add(_buildItem(Icons.tune, AppStrings.htmlSettings));
        }

        items.add(
          _buildItem(Icons.print, AppStrings.printingSettings),
        ); // Solid icon
        items.add(
          _buildItem(Icons.music_note, AppStrings.musicSettings),
        ); // Solid icon
        items.add(
          _buildItem(Icons.receipt, AppStrings.receiptFormat),
        ); // Solid icon

        // if (controller.isUnlocked.value) {
        //   items.add(_buildItem(Icons.reply, AppStrings.response));
        // }

        items.add(_buildItem(Icons.edit_document, AppStrings.log));
        items.add(
          _buildItem(Icons.settings, AppStrings.generalSettings),
        ); // Solid icon
        items.add(
          _buildItem(Icons.delete, AppStrings.orderHistory),
        ); // Solid icon

        if (controller.isUnlocked.value) {
          items.add(
            _buildItem(Icons.info_outline, AppStrings.version),
          ); // Replaced theme with AppVersion
          // items.add(
          //   _buildItem(Icons.local_fire_department, AppStrings.fcmSettings),
          // );
          items.add(_buildItem(Icons.logout, AppStrings.logout));
        }
        return ListView(children: items);
      }),
    );
  }

  Widget _buildItem(IconData icon, String title) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: const Color(0xFFBF3A20),
          ), // Matched icon color
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          trailing: const Icon(Icons.arrow_right, color: Colors.grey),
          onTap: () {
            if (title == AppStrings.htmlSettings) {
              Get.to(() => const HtmlSettingsView());
            } else if (title == AppStrings.printingSettings) {
              Get.to(() => const PrintingSettingsView());
            } else if (title == AppStrings.musicSettings) {
              Get.to(() => const MusicSettingsView());
            } else if (title == AppStrings.receiptFormat) {
              Get.to(() => const ReceiptFormatView());
            } else if (title == AppStrings.generalSettings) {
              Get.to(() => const GeneralSettingsView());
            } else if (title == AppStrings.serverSettings) {
              Get.to(() => const ServerSettingsView());
            } else if (title == AppStrings.response) {
              Get.to(() => const ResponseView());
            } else if (title == AppStrings.fcmSettings) {
              Get.to(() => const FcmSettingsView());
            } else if (title == AppStrings.version) {
              Get.to(() => const ApplicationVersionView());
            } else if (title == AppStrings.logout) {
              Get.defaultDialog(
                title: AppStrings.logout,
                middleText: AppStrings.sureLogout,
                textConfirm: AppStrings.yes,
                textCancel: AppStrings.no,
                confirmTextColor: Colors.white,
                buttonColor: const Color(0xFFBF3A20),
                onConfirm: () {
                  // Stop monitoring service if exists
                  try {
                    // Try to get the service if it exists
                    final service =
                        Get.find(); // Note: adjust if OrderMonitoringService isn't in scope
                  } catch (e) {}
                  Get.offAllNamed('/login');
                },
              );
            }
          },
        ),
        const Divider(height: 1, color: Colors.grey, thickness: 0.5),
      ],
    );
  }
}
