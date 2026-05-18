import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';

class ResponseView extends StatefulWidget {
  const ResponseView({Key? key}) : super(key: key);

  @override
  State<ResponseView> createState() => _ResponseViewState();
}

class _ResponseViewState extends State<ResponseView> {
  final SettingsController controller = Get.find<SettingsController>();

  bool autoResponse = false;
  bool supportModDate = false;
  bool displayCountdown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF3A20),
        foregroundColor: Colors.white,
        title: const Text(AppStrings.response),
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
          _buildSwitchTile('Auto Response', autoResponse, (v) => setState(() => autoResponse = v)),
          Container(height: 12, color: Colors.grey[200]),
          _buildValueTile('Repeat Reply', 'Update status', showArrow: false),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildValueTile('Accept Reply Type', 'List Items', showArrow: false),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile('Support modification date', supportModDate, (v) => setState(() => supportModDate = v)),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildTitleOnlyTile('Accept All Repast'),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildValueTile('Accept Items', '15 Minutes;20 Minutes;30 Minutes;40 M...', showArrow: true),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildValueTile('Reject Items', 'TOO BUSY;FOOD UNAVAILABLE;UNABL...', showArrow: true),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildValueTile('Submit Items', 'Prepared;On the way;Delivered', showArrow: true),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile('Display countdown prompt(waiting for confirm)', displayCountdown, (v) => setState(() => displayCountdown = v)),
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

  Widget _buildValueTile(String title, String value, {bool showArrow = true}) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {},
    );
  }
}
