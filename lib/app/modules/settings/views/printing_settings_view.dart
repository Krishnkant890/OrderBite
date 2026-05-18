import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';
import '../../../resources/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrintingSettingsView extends StatefulWidget {
  const PrintingSettingsView({Key? key}) : super(key: key);

  @override
  State<PrintingSettingsView> createState() => _PrintingSettingsViewState();
}

class _PrintingSettingsViewState extends State<PrintingSettingsView> {
  final SettingsController controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(AppStrings.printingSettings, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
            ListTile(
              title: Text('Status', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<String>(
                  value: controller.status.value,
                  items: ['Active', 'Inactive'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp)))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.saveSetting('status', val);
                  },
                ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              title: Text('Printer Status', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<String>(
                  value: controller.printerStatus.value,
                  items: ['Online', 'Offline'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp)))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.saveSetting('printerStatus', val);
                  },
                ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            SwitchListTile(
              title: Text('Auto Print', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              value: controller.autoPrint.value,
              onChanged: (val) => controller.saveSetting('autoPrint', val),
              activeColor: AppColors.primary,
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              title: Text('Print Copy Count', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<int>(
                  value: controller.totalPrint.value,
                  items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(value: e, child: Text('$e', style: TextStyle(fontSize: 14.sp)))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.saveSetting('totalPrint', val);
                  },
                ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              title: Text('Timeout (seconds)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<int>(
                  value: controller.timeout.value,
                  items: [5, 10, 15, 30, 60].map((e) => DropdownMenuItem(value: e, child: Text('$e', style: TextStyle(fontSize: 14.sp)))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.saveSetting('timeout', val);
                  },
                ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              title: Text('Printer Type', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<String>(
                  value: controller.printerType.value,
                  items: ['Built-in printer', 'Bluetooth printer', 'No printer'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp)))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.saveSetting('printerType', val);
                  },
                ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              title: Text('Paper Size', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<String>(
                  value: controller.paperSize.value,
                  items: ['58mm', '80mm'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp)))).toList(),
                  onChanged: (val) {
                    if (val != null) controller.saveSetting('paperSize', val);
                  },
                ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            
            // Header Settings
            SwitchListTile(
              title: Text('Show Page Header', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              value: controller.isPageHeader.value,
              onChanged: (val) => controller.saveSetting('isPageHeader', val),
              activeColor: AppColors.primary,
            ),
            if (controller.isPageHeader.value)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Header Content',
                    labelStyle: TextStyle(fontSize: 12.sp),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  style: TextStyle(fontSize: 14.sp),
                  onChanged: (val) => controller.saveSetting('setHeadercontent', val),
                  controller: TextEditingController(text: controller.setHeadercontent.value)..selection = TextSelection.collapsed(offset: controller.setHeadercontent.value.length),
                ),
              ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            
            SwitchListTile(
              title: Text('Show Page Footer', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              value: controller.isPagefooter.value,
              onChanged: (val) => controller.saveSetting('isPagefooter', val),
              activeColor: AppColors.primary,
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            
            SwitchListTile(
              title: Text('Print Date & Time', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              value: controller.isPrintDateTime.value,
              onChanged: (val) => controller.saveSetting('isPrintDateTime', val),
              activeColor: AppColors.primary,
            ),
            if (controller.isPrintDateTime.value) ...[
              ListTile(
                title: Text('Date Format', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                trailing: DropdownButton<String>(
                    value: controller.setDateFormate.value,
                    items: ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp)))).toList(),
                    onChanged: (val) {
                      if (val != null) controller.saveSetting('setDateFormate', val);
                    },
                  ),
              ),
              ListTile(
                title: Text('Time Format', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                trailing: DropdownButton<String>(
                    value: controller.setTimeFormate.value,
                    items: ['HH:mm', 'hh:mm a'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp)))).toList(),
                    onChanged: (val) {
                      if (val != null) controller.saveSetting('setTimeFormate', val);
                    },
                  ),
              ),
            ],
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),

            if (controller.printerType.value == 'Bluetooth printer') ...[
              ListTile(
                title: Text('Bluetooth Devices', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  onPressed: () => controller.showBluetoothDeviceDialog(),
                  icon: Icon(Icons.search, size: 18.sp),
                  label: Text('Select Device', style: TextStyle(fontSize: 12.sp)),
                ),
              ),
              if (controller.deviceMACAddress.value.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(controller.selectedDeviceName.value),
                  subtitle: Text(controller.deviceMACAddress.value),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
            ],
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              leading: Icon(Icons.print_outlined, color: AppColors.primary, size: 24.sp),
              title: Text('Test Printer', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              subtitle: Text('Print a test receipt to verify connection', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
              onTap: () => controller.testPrint(),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              leading: Icon(Icons.history_edu_outlined, color: AppColors.primary, size: 24.sp),
              title: Text('Export Log', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              subtitle: Text('Upload app diagnostic logs to the server', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
              onTap: () => controller.exportLogToServer(),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
            ListTile(
              leading: Icon(Icons.remove_red_eye_outlined, color: AppColors.primary, size: 24.sp),
              title: Text('Receipt Preview', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              subtitle: Text('Preview the digital receipt format', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
              onTap: () => controller.showPreview(),
            ),
          ],
        );
      }),
    );
  }
}
