import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';

class MusicSettingsView extends GetView<SettingsController> {
  const MusicSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBF3A20),
        foregroundColor: Colors.white,
        title: const Text(AppStrings.musicSettings),
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
      body: Obx(() => ListView(
        children: [
          Obx(() {
            final selected = controller.availableRingtones.firstWhere(
              (r) => r['value'] == controller.selectedRingtone.value, 
              orElse: () => {'name': controller.selectedRingtone.value}
            );
            return _buildValueTile(
              'Print Music', 
              selected['name'],
              onTap: () => _showRingtoneDialog(context),
            );
          }),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildValueTile(
            'Music Tips Time(s)', 
            controller.musicTipsTime.value.toString(), 
            showArrow: false,
            onTap: () => _showNumericInputDialog(
              'Music Tips Time(s)', 
              controller.musicTipsTime.value, 
              (v) => controller.saveSetting('musicTipsTime', v)
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile(
            'Stop Error Tone', 
            controller.stopErrorTone.value, 
            (v) => controller.saveSetting('stopErrorTone', v)
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildSwitchTile(
            'Continue playing after processing order', 
            controller.continuePlaying.value, 
            (v) => controller.saveSetting('continuePlaying', v)
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
        ],
      )),
    );
  }

  void _showRingtoneDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: const Color(0xFFBF3A20),
              child: const Text(
                'Select Ringtone',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.availableRingtones.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ringtone = controller.availableRingtones[index];
                  final name = ringtone['name'] ?? 'Unknown';
                  final value = ringtone['value'] ?? '';
                  return Obx(() => ListTile(
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    trailing: controller.selectedRingtone.value == value 
                        ? const Icon(Icons.check_circle, color: Color(0xFFBF3A20)) 
                        : null,
                    onTap: () {
                      controller.saveSetting('selectedRingtone', value);
                      controller.playRingtone(value);
                    },
                  ));
                },
              ),
            ),
            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      controller.stopRingtone();
                      Get.back();
                    },
                    child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      controller.stopRingtone();
                      Get.back();
                    },
                    child: const Text('OK', style: TextStyle(color: Color(0xFFBF3A20))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNumericInputDialog(String title, int currentValue, ValueChanged<int> onSave) {
    final textController = TextEditingController(text: currentValue.toString());
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter value"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(textController.text);
              if (val != null) {
                onSave(val);
                Get.back();
              }
            }, 
            child: const Text('OK')
          ),
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

  Widget _buildValueTile(String title, String value, {bool showArrow = true, VoidCallback? onTap}) {
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
      onTap: onTap,
    );
  }
}
