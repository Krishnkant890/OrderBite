import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';

class ReceiptFormatView extends StatefulWidget {
  const ReceiptFormatView({Key? key}) : super(key: key);

  @override
  State<ReceiptFormatView> createState() => _ReceiptFormatViewState();
}

class _ReceiptFormatViewState extends State<ReceiptFormatView> {
  final SettingsController controller = Get.find<SettingsController>();

  bool pageHeader = true;
  bool pageFooter = true;
  bool printDateTime = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF3A20),
        foregroundColor: Colors.white,
        title: const Text(AppStrings.receiptFormat),
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
          _buildSwitchTile('Page Header', pageHeader, (v) => setState(() => pageHeader = v)),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildIndentedSetContent('Set Content', 'Image'),
          Container(height: 12, color: Colors.grey[200]),
          _buildSwitchTile('Page Footer', pageFooter, (v) => setState(() => pageFooter = v)),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildIndentedSetContent('Set Content', 'Meatwala Wycombe\\n01494 513651'),
          Container(height: 12, color: Colors.grey[200]),
          _buildValueTile('Date Format', 'dd-MM-yyyy', showArrow: false),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildValueTile('Time Format', '24 Hour', showArrow: false),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile('Print Date Time', printDateTime, (v) => setState(() => printDateTime = v)),
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

  Widget _buildIndentedSetContent(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0), // Indent match with subsetting hierarchy
      child: ListTile(
        tileColor: Colors.white,
        title: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
        onTap: () {},
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
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          if (showArrow) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ]
        ],
      ),
      onTap: () {},
    );
  }
}
