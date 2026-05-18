import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';
import '../../../resources/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ServerSettingsView extends StatefulWidget {
  const ServerSettingsView({Key? key}) : super(key: key);

  @override
  State<ServerSettingsView> createState() => _ServerSettingsViewState();
}

class _ServerSettingsViewState extends State<ServerSettingsView> {
  final SettingsController controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(AppStrings.serverSettings, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
          _buildValueTile('File Download Mode', 'php/jsp'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('IP Address', '217.182.168.93'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('IP Port', ''),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Request Url', 'https://www.highwycombebites.com/api/v1/pen...'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Callback Url', 'https://www.highwycombebites.com/api/v1/con...'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Restaurant ID', '1'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Username', 'gulzamir786@gmail.com'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Password', '123456'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Server time format', 'dd-MM-yyyy'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Web server', '|||'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Order Format', 'Gc Format'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
          _buildValueTile('Server Type', 'Default Server'),
          const Divider(height: 1, thickness: 0.5, color: AppColors.lightGrey),
        ],
      ),
    );
  }

  Widget _buildValueTile(String title, String value) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      trailing: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
        child: Text(
          value,
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          maxLines: 1,
        ),
      ),
      onTap: () {},
    );
  }
}
