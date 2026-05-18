import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../../resources/app_strings.dart';
import '../../../services/api_service.dart';
import '../../../services/order_monitoring_service.dart';
import '../../../services/printer_service.dart';
import '../../../services/logger_service.dart';
import '../../../widgets/receipt_preview_dialog.dart';

class SettingsController extends GetxController {
  final RxBool isUnlocked = false.obs;
  final TextEditingController passwordController = TextEditingController();
  final ApiService _apiService = Get.find<ApiService>();
  final OrderMonitoringService _monitoringService = Get.find<OrderMonitoringService>();

  // Printer Settings State
  final RxString printerType = 'Bluetooth printer'.obs;
  final RxString paperSize = '58mm'.obs;
  final RxBool autoPrint = false.obs;
  final RxInt timeout = 10.obs;
  // totalPrint is the new field replacing printCopyCount

  final RxList<BluetoothInfo> bluetoothDevices = <BluetoothInfo>[].obs;
  final RxString selectedDeviceMac = ''.obs;
  final RxString selectedDeviceName = ''.obs;
  final RxBool isScanning = false.obs;
  final RxString connectingMac = ''.obs;
  
  // Music Settings State
  final RxString selectedRingtone = 'mixkit-old-telephone-ring-1357.wav'.obs;
  final RxInt musicTipsTime = 0.obs;
  final RxBool stopErrorTone = false.obs;
  final RxBool continuePlaying = false.obs;
  
  // General Settings State
  final RxBool overlayPermission = false.obs;
  final RxBool orderStatusTips = true.obs;
  final RxBool keepScreenOn = false.obs;
  final RxBool restartApp = false.obs;
  
  // New Printing Fields
  final RxString status = 'Active'.obs;
  final RxString printerStatus = 'Online'.obs;
  final RxInt totalPrint = 1.obs; // mapped to totalPrint in API
  final RxBool isPageHeader = true.obs;
  final RxString setHeadercontent = ''.obs;
  final RxBool isPagefooter = true.obs;
  final RxString setDateFormate = 'dd/MM/yyyy'.obs;
  final RxString setTimeFormate = 'HH:mm'.obs;
  final RxBool isPrintDateTime = true.obs;
  final RxString deviceMACAddress = ''.obs; // mapped from selectedDeviceMac
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxList<Map<String, dynamic>> availableRingtones = <Map<String, dynamic>>[
    {'name': 'Ringtone 1', 'value': '2 ringtone-1356.wav'},
    {'name': 'Ringtone 2', 'value': '3 ringtone-030-437513.mp3.mpeg'},
    {'name': 'Ringtone 3', 'value': '4ringtone-091-496417.mp3.mpeg'},
    {'name': 'Ringtone 4', 'value': 'mixkit-old-telephone-ring-1357.wav'},
    {'name': 'None', 'value': 'none'}
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings().then((_) {
      fetchPrintingSettings();
      fetchRingtones();
      checkOverlayPermission();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String savedPrinter = prefs.getString('printerType') ?? 'Bluetooth printer';
    if (savedPrinter == 'Bluetooth') savedPrinter = 'Bluetooth printer';
    if (savedPrinter == 'Built-in') savedPrinter = 'Built-in printer';
    printerType.value = savedPrinter;
    
    paperSize.value = prefs.getString('paperSize') ?? '58mm';
    autoPrint.value = prefs.getBool('autoPrint') ?? false;
    timeout.value = prefs.getInt('timeout') ?? 10;
    // totalPrint replaced printCopyCount
    selectedDeviceMac.value = prefs.getString('selectedDeviceMac') ?? '';
    selectedDeviceName.value = prefs.getString('selectedDeviceName') ?? '';
    
    // Music settings
    selectedRingtone.value = prefs.getString('selectedRingtone') ?? 'mixkit-old-telephone-ring-1357.wav';
    musicTipsTime.value = prefs.getInt('musicTipsTime') ?? 0;
    stopErrorTone.value = prefs.getBool('stopErrorTone') ?? false;
    continuePlaying.value = prefs.getBool('continuePlaying') ?? false;
    
    // General settings
    overlayPermission.value = prefs.getBool('overlayPermission') ?? false;
    orderStatusTips.value = prefs.getBool('orderStatusTips') ?? true;
    keepScreenOn.value = prefs.getBool('keepScreenOn') ?? false;
    restartApp.value = prefs.getBool('restartApp') ?? false;

    // New Printing Fields
    status.value = prefs.getString('status') ?? 'Active';
    printerStatus.value = prefs.getString('printerStatus') ?? 'Online';
    totalPrint.value = prefs.getInt('totalPrint') ?? 1;
    isPageHeader.value = prefs.getBool('isPageHeader') ?? true;
    setHeadercontent.value = prefs.getString('setHeadercontent') ?? '';
    isPagefooter.value = prefs.getBool('isPagefooter') ?? true;
    setDateFormate.value = prefs.getString('setDateFormate') ?? 'dd/MM/yyyy';
    setTimeFormate.value = prefs.getString('setTimeFormate') ?? 'HH:mm';
    isPrintDateTime.value = prefs.getBool('isPrintDateTime') ?? true;
    deviceMACAddress.value = prefs.getString('selectedDeviceMac') ?? '';
  }

  Future<void> saveSetting(String key, dynamic value, {bool syncToServer = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) prefs.setString(key, value);
    if (value is bool) prefs.setBool(key, value);
    if (value is int) prefs.setInt(key, value);
    
    // update observables
    if (key == 'printerType') printerType.value = value;
    if (key == 'paperSize') paperSize.value = value;
    if (key == 'autoPrint') autoPrint.value = value;
    if (key == 'timeout') timeout.value = value;
    // totalPrint replaced printCopyCount
    if (key == 'selectedDeviceMac') selectedDeviceMac.value = value;
    if (key == 'selectedDeviceName') selectedDeviceName.value = value;
    
    if (key == 'selectedRingtone') selectedRingtone.value = value;
    if (key == 'musicTipsTime') musicTipsTime.value = value;
    if (key == 'stopErrorTone') stopErrorTone.value = value;
    if (key == 'continuePlaying') continuePlaying.value = value;
    
    if (key == 'overlayPermission') overlayPermission.value = value;
    if (key == 'orderStatusTips') orderStatusTips.value = value;
    if (key == 'keepScreenOn') keepScreenOn.value = value;
    if (key == 'restartApp') restartApp.value = value;

    if (key == 'status') status.value = value;
    if (key == 'printerStatus') printerStatus.value = value;
    if (key == 'totalPrint') totalPrint.value = value;
    if (key == 'isPageHeader') isPageHeader.value = value;
    if (key == 'setHeadercontent') setHeadercontent.value = value;
    if (key == 'isPagefooter') isPagefooter.value = value;
    if (key == 'setDateFormate') setDateFormate.value = value;
    if (key == 'setTimeFormate') setTimeFormate.value = value;
    if (key == 'isPrintDateTime') isPrintDateTime.value = value;
    if (key == 'selectedDeviceMac') deviceMACAddress.value = value;

    // Sync printing settings to server if any of them changed
    if (syncToServer && [
      'printerType', 'paperSize', 'autoPrint', 'timeout', 'totalPrint', 
      'selectedDeviceMac', 'selectedDeviceName', 'status', 'printerStatus',
      'isPageHeader', 'setHeadercontent', 'isPagefooter',
      'setDateFormate', 'setTimeFormate', 'isPrintDateTime'
    ].contains(key)) {
      _syncPrintingSettingsToServer();
    }
  }

  Future<void> _syncPrintingSettingsToServer() async {
    final storeId = _monitoringService.settings.storeId;
    if (storeId.isEmpty || storeId == "Not Logged In") {
      print("Skipping printing settings sync: User not logged in.");
      return;
    }

    try {
      final response = await _apiService.savePrintingSettings(
        storeId: storeId,
        printerType: printerType.value,
        paperSize: paperSize.value,
        autoPrint: autoPrint.value,
        timeout: timeout.value,
        totalPrint: totalPrint.value,
        selectedDeviceMac: selectedDeviceMac.value,
        selectedDeviceName: selectedDeviceName.value,
        status: status.value,
        printerStatus: printerStatus.value,
        music: selectedRingtone.value,
        isPageHeader: isPageHeader.value,
        setHeadercontent: setHeadercontent.value,
        isPagefooter: isPagefooter.value,
        setDateFormate: setDateFormate.value,
        setTimeFormate: setTimeFormate.value,
        isPrintDateTime: isPrintDateTime.value,
        apiUrl: _monitoringService.settings.apiUrl,
      );

      if (response != null && response['success'] == 'INSERTED') {
        print("Printing settings synced to server successfully. PKID: ${response['pkid']}");
      }
    } catch (e) {
      print("Error syncing printing settings: $e");
    }
  }

  Future<void> fetchPrintingSettings() async {
    final storeId = _monitoringService.settings.storeId;
    if (storeId.isEmpty || storeId == "Not Logged In") return;

    try {
      final data = await _apiService.getPrintingSettings(
        storeId: storeId,
        apiUrl: _monitoringService.settings.apiUrl,
      );

      if (data != null) {
        if (data['printerType'] != null) {
          saveSetting('printerType', data['printerType'], syncToServer: false);
        }
        if (data['paperSize'] != null) {
          saveSetting('paperSize', data['paperSize'], syncToServer: false);
        }
        if (data['autoPrint'] != null) {
          saveSetting('autoPrint', data['autoPrint'] is bool ? data['autoPrint'] : data['autoPrint'] == "1", syncToServer: false);
        }
        if (data['deviceMACAddress'] != null && data['deviceMACAddress'].toString().isNotEmpty) {
          saveSetting('selectedDeviceMac', data['deviceMACAddress'], syncToServer: false);
        }
        if (data['status'] != null) {
          saveSetting('status', data['status'], syncToServer: false);
          _monitoringService.isManuallyOffline.value = (data['status'] == 'Inactive');
        }
        if (data['printerStatus'] != null) saveSetting('printerStatus', data['printerStatus'], syncToServer: false);
        if (data['totalPrint'] != null) saveSetting('totalPrint', data['totalPrint'] is int ? data['totalPrint'] : int.tryParse(data['totalPrint'].toString()) ?? 1, syncToServer: false);
        if (data['isPageHeader'] != null) saveSetting('isPageHeader', data['isPageHeader'] is bool ? data['isPageHeader'] : data['isPageHeader'] == 1, syncToServer: false);
        if (data['setHeadercontent'] != null) saveSetting('setHeadercontent', data['setHeadercontent'], syncToServer: false);
        if (data['isPagefooter'] != null) saveSetting('isPagefooter', data['isPagefooter'] is bool ? data['isPagefooter'] : data['isPagefooter'] == 1, syncToServer: false);
        if (data['setDateFormate'] != null) saveSetting('setDateFormate', data['setDateFormate'], syncToServer: false);
        if (data['setTimeFormate'] != null) saveSetting('setTimeFormate', data['setTimeFormate'], syncToServer: false);
        if (data['isPrintDateTime'] != null) saveSetting('isPrintDateTime', data['isPrintDateTime'] is bool ? data['isPrintDateTime'] : data['isPrintDateTime'] == 1, syncToServer: false);
        // If there's a device name or status, we could handle it too
      }
    } catch (e) {
      print("Error fetching printing settings: $e");
    }
  }

  Future<void> fetchRingtones() async {
    final storeId = _monitoringService.settings.storeId;
    if (storeId.isEmpty || storeId == "Not Logged In") return;

    try {
      final data = await _apiService.getPrintingAppMusic(
        apiUrl: _monitoringService.settings.apiUrl,
      );

      if (data.isNotEmpty) {
        availableRingtones.value = data;
      }
    } catch (e) {
      print("Error fetching ringtones: $e");
    }
  }

  Future<void> scanBluetoothDevices() async {
    isScanning.value = true;
    try {
      // First ensure permissions are granted (Android 12+)
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      
      final bool isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isEnabled) {
        Get.snackbar(
          'Bluetooth Disabled', 
          'Please turn on Bluetooth to scan for devices.', 
          backgroundColor: Colors.orange, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
        );
        return;
      }
      
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      bluetoothDevices.value = devices;
    } catch (e) {
      Get.snackbar('Error', 'Failed to scan devices. Ensure Bluetooth is enabled.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> connectToBluetoothDevice(String macAddress, String name) async {
    connectingMac.value = macAddress;
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (result) {
        saveSetting('selectedDeviceMac', macAddress);
        saveSetting('selectedDeviceName', name);
        Get.snackbar(
          'Connected', 
          'Successfully connected to $name', 
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
        );
      } else {
        Get.snackbar(
          'Connection Failed', 
          'Could not connect to $name', 
          backgroundColor: Colors.red, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect. Ensure the printer is on.', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      connectingMac.value = '';
    }
  }

  void showBluetoothDeviceDialog() {
    scanBluetoothDevices(); // auto-scan when opened
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFFE64A19), // Orange header
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Text('Select Device', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Text('Paired devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Obx(() {
                      if (bluetoothDevices.isEmpty && !isScanning.value) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No Paired Devices Found.', textAlign: TextAlign.center),
                        );
                      }
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: bluetoothDevices.length,
                        itemBuilder: (context, index) {
                          final device = bluetoothDevices[index];
                          final isConnecting = connectingMac.value == device.macAdress;
                          return InkWell(
                            onTap: () async {
                              if (connectingMac.value.isNotEmpty) return;
                              await connectToBluetoothDevice(device.macAdress, device.name);
                              if (selectedDeviceMac.value == device.macAdress) {
                                Get.back(); // close dialog on success
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(device.name.isEmpty ? 'Unknown Device' : device.name, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(device.macAdress, style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  if (isConnecting)
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    
                    Container(
                      color: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Text('Available devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Obx(() {
                      if (isScanning.value) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFFE64A19))),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Device discovery limited by OS.\nPlease pair new printers via your tablet Bluetooth Settings first, then scan again.', 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: isScanning.value ? null : scanBluetoothDevices,
                    child: Text(isScanning.value ? 'Scanning...' : 'Scan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void unlockSettings() {
    if (passwordController.text == '1234') { // Using 1234 as default for this demo
      isUnlocked.value = true;
      Get.back(); // close dialog
      passwordController.clear();
    } else {
      Get.back(); // close dialog before showing error
      Get.snackbar(
        AppStrings.error,
        AppStrings.incorrectPassword,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showPasswordDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.enterPassword,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: AppStrings.password,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        passwordController.clear();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B6071),
                        side: const BorderSide(color: Color(0xFF6B6071)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: unlockSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B6071),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(AppStrings.unlock),
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

  Future<void> playRingtone(String fileName) async {
    if (fileName == 'none') return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('ringtone/$fileName'));
    } catch (e) {
      print("Error playing ringtone: $e");
    }
  }

  Future<void> stopRingtone() async {
    await _audioPlayer.stop();
  }

  void testPrint() {
    Get.find<PrinterService>().testPrint();
  }

  void showPreview() {
    final mockOrder = {
      'id': '499',
      'name': "K's Peri Peri & Pizza",
      'date': '23-01-26 05:05 PM',
      'type': 'Delivery',
      'customer': 'Test Customer',
      'address': '1, High Wycombe HP13, UK',
      'phone': '+918962514599',
      'total': '£17.47',
      'service_charge': '£3.00',
      'delivery_charge': '£1.00',
      'discount': '£0.00',
      'payment_mode': 'Cash',
      'requested_for': 'As soon as possible',
      'comments': 'Please ring the bell',
      'items': [
        {
          'qty': 1, 
          'name': 'Chicken Fillet Boneless', 
          'price': '£4.49',
          'modifiers': ['With 500g', 'Medium Curry Size', 'Small Pasta Size', 'Tikka Boti']
        },
        {
          'qty': 1, 
          'name': 'Chicken Fillet Boneless', 
          'price': '£4.49',
          'modifiers': ['With 500g', 'Medium Curry Size', 'Small Pasta Size', 'Tikka Boti']
        },
      ],
    };
    showReceiptPreview(mockOrder, status: "Accepted", extraInfo: "15");
  }

  Future<void> checkOverlayPermission() async {
    overlayPermission.value = await Permission.systemAlertWindow.isGranted;
  }

  void toggleOverlayPermission(bool value) async {
    if (value) {
      final status = await Permission.systemAlertWindow.request();
      if (status.isGranted) {
        saveSetting('overlayPermission', true);
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
      } else {
        overlayPermission.value = false;
      }
    } else {
      saveSetting('overlayPermission', false);
      Get.snackbar(
        "Info", 
        "To fully disable, please revoke 'Appear on top' permission in system settings.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blueGrey,
        colorText: Colors.white,
      );
    }
  }

  Future<void> exportLogToServer() async {
    final storeId = _monitoringService.settings.storeId;
    if (storeId.isEmpty || storeId == "Not Logged In") {
      Get.snackbar("Error", "Please login first to export logs", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      final logService = Get.find<LoggerService>();
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/app_logs.txt');

      if (!await logFile.exists()) {
        Get.snackbar("Error", "No log file found to export", backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      Get.showOverlay(
        asyncFunction: () async {
          final success = await _apiService.saveLog(
            storeId: storeId,
            logFile: logFile,
            apiUrl: _monitoringService.settings.apiUrl,
          );

          if (success) {
            Get.snackbar("Success", "Logs exported to server successfully", backgroundColor: Colors.green, colorText: Colors.white);
          } else {
            Get.snackbar("Error", "Failed to export logs to server", backgroundColor: Colors.red, colorText: Colors.white);
          }
        },
        loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }
}
