import 'package:flutter/material.dart';
import 'package:gc_any_order/app/services/order_monitoring_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gc_any_order/app/services/api_service.dart';
import '../../../resources/app_strings.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final emailController = TextEditingController(); 
  final passwordController = TextEditingController();
  final _apiService = Get.find<ApiService>();
  final _monitoringService = Get.find<OrderMonitoringService>();

  final isPrivacyChecked = false.obs;

  @override
  void onReady() {
    super.onReady();
    _checkPrivacyAndPermissions();
  }

  Future<void> _checkPrivacyAndPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAgreed = prefs.getBool('hasAgreedPrivacy') ?? false;

    if (!hasAgreed) {
      _showPrivacyPolicyDialog();
    } else {
      _requestAppPermissions();
    }
  }

  void _showPrivacyPolicyDialog() {
    isPrivacyChecked.value = false;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle viewing privacy policy (e.g. open WebView)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00694A), // Dark green color from screenshot
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      'Click to view the privacy\nagreement',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(() => Checkbox(
                    value: isPrivacyChecked.value,
                    onChanged: (val) {
                      isPrivacyChecked.value = val ?? false;
                    },
                    activeColor: const Color(0xFF00694A),
                  )),
                  const Expanded(
                    child: Text(
                      'I have read and agreed to the\nprivacy agreement',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, thickness: 0.5, height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  Container(width: 0.5, height: 50, color: Colors.grey),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        if (isPrivacyChecked.value) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('hasAgreedPrivacy', true);
                          Get.back();
                          _requestAppPermissions();
                        } else {
                          Get.snackbar(
                            'Agreement Required', 
                            'Please check the privacy agreement box first.',
                            backgroundColor: Colors.white,
                            colorText: Colors.black,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('CONFIRM', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _requestAppPermissions() async {
    // Array of permissions matching the screenshots
    final permissions = [
      Permission.notification,
      Permission.phone,
      Permission.bluetoothConnect, // Represents nearby devices
      Permission.location,
    ];

    // Request them sequentially or as a batch. SharedPreferences can track if we asked before,
    // but permission_handler handles this cleanly with OS dialogs.
    for (var perm in permissions) {
      if (await perm.isDenied) {
        await perm.request();
      }
    }
  }

  Future<void> login() async {
    if (emailController.text.isEmpty) {
      Get.snackbar(AppStrings.error, AppStrings.pleaseEnterId);
      return;
    }
    if (passwordController.text.isEmpty) {
      Get.snackbar(AppStrings.error, "Please enter your password");
      return;
    }

    isLoading.value = true;

    try {
      final apiUrl = _monitoringService.settings.apiUrl;
      final result = await _apiService.login(
        emailController.text,
        passwordController.text,
        apiUrl,
      );

      if (result != null) {
        bool isSuccess = result['success'] == '1' || result['success'] == 1;

        if (isSuccess) {
          // Assuming result contains storeId/restaurantId. If not, we might need to adapt.
          // For now, let's use the email/ID as storeId if not explicitly provided in response.
          String storeId = result['pkid']?.toString() ?? result['storeId']?.toString() ?? result['id']?.toString() ?? emailController.text;
          String userId = emailController.text; // The ID used for login/API
          String userName = result['name']?.toString() ?? result['username']?.toString() ?? emailController.text;

          _monitoringService.updateSettings(
            storeId,
            userId,
            userName,
            passwordController.text,
          );

          // Save to preferences for auto-login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('storeId', storeId);
          await prefs.setString('userId', userId);
          await prefs.setString('userName', userName);
          await prefs.setString('password', passwordController.text);

          Get.offAllNamed('/home');
        } else {
          String errorMessage = result['returnmsg']?.toString() ?? AppStrings.loginFailed;
          Get.snackbar(
            AppStrings.error,
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          AppStrings.error,
          AppStrings.loginFailed,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        "An error occurred during login: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
