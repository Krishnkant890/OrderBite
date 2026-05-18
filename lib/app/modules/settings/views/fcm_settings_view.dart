import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';

class FcmSettingsView extends StatefulWidget {
  const FcmSettingsView({Key? key}) : super(key: key);

  @override
  State<FcmSettingsView> createState() => _FcmSettingsViewState();
}

class _FcmSettingsViewState extends State<FcmSettingsView> {
  final SettingsController controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF3A20),
        foregroundColor: Colors.white,
        title: const Text(AppStrings.fcmSettings),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Cloud Messaging',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 16),
            
            const Text('Connection server interval(minutes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Duration: 0', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text(
              'Note: Setting to 0 indicates to stop requesting new orders at regular intervals, whereas setting to a specified duration indicates to request new orders at regular intervals.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 16),
            
            const Text('Configuration of FCM (required)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRedErrorText('App ID: ', 'Not set, resulting in FCM being unusable.'),
            const SizedBox(height: 8),
            _buildRedErrorText('Project ID: ', 'Not set, resulting in FCM being unusable.'),
            const SizedBox(height: 8),
            _buildRedErrorText('Api Key: ', 'Not set, resulting in FCM being unusable.'),
            
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 16),
            const Text('Topic:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 16),
            
            const Text('Configuration for sending token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            textLine('Send URL:', Colors.grey),
            const SizedBox(height: 8),
            textLine('Request Method: POST', Colors.black87),
            const SizedBox(height: 8),
            textLine('Content Type: application/json', Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildRedErrorText(String prefix, String error) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16),
        children: [
          TextSpan(text: prefix, style: const TextStyle(color: Colors.grey)),
          TextSpan(text: error, style: const TextStyle(color: Color(0xFFD32F2F))),
        ],
      ),
    );
  }

  Widget textLine(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 16, color: color));
  }
}
