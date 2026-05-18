import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';

class HtmlSettingsView extends StatefulWidget {
  const HtmlSettingsView({Key? key}) : super(key: key);

  @override
  State<HtmlSettingsView> createState() => _HtmlSettingsViewState();
}

class _HtmlSettingsViewState extends State<HtmlSettingsView> {
  final SettingsController controller = Get.find<SettingsController>();

  bool adjustPaperSize = false;
  bool htmlPrintOpt = false;
  bool supportNetworkImage = false;
  bool enlargeImage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF3A20),
        foregroundColor: Colors.white,
        title: const Text(AppStrings.htmlSettings),
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
      body: ListView(
        children: [
          _buildSwitchTile('Adjust paper size(Html)', adjustPaperSize, (v) => setState(() => adjustPaperSize = v)),
          Container(height: 12, color: Colors.grey[200]),
          _buildSwitchTile('Html Print Optimization', htmlPrintOpt, (v) => setState(() => htmlPrintOpt = v)),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile('Support Network Image', supportNetworkImage, (v) => setState(() => supportNetworkImage = v)),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile('Enlarge the image', enlargeImage, (v) => setState(() => enlargeImage = v)),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFBF3A20),
      ),
    );
  }
}
