import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'printer_service.dart';
import 'print_queue_service.dart';
import 'api_service.dart';
import '../data/models/order_model.dart';
import '../data/models/print_settings.dart';
import 'logger_service.dart';
import '../widgets/new_order_popup.dart';
import '../widgets/order_details_dialog.dart';
import '../widgets/preparation_time_dialog.dart';
import '../widgets/rejection_reason_dialog.dart';


class OrderMonitoringService extends GetxService with WidgetsBindingObserver {
  final PrinterService _printerService = Get.find<PrinterService>();
  final PrintQueueService _printQueueService = Get.find<PrintQueueService>();
  final ApiService _apiService = Get.find<ApiService>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final isChecking = false.obs;
  final isOnline = true.obs;
  final isManuallyOffline = false.obs;
  final connectionType = "Unknown".obs;
  final connectionQuality = "Strong".obs; // Strong, Good, Weak, Offline
  final lastCheckTime = Rxn<DateTime>();
  final pendingOrders = <OrderModel>[].obs;
  
  // Trigger to notify other controllers (like HomeController) to refresh their lists
  final refreshOrdersTrigger = 0.obs;
  
  Timer? _timer;
  StreamSubscription? _connectivitySubscription;
  final Set<String> _printedOrderIds = {};
  final Set<String> _popupOrderIds = {};
  final PrintSettings _settings = PrintSettings(
    storeId: "", 
    userId: "",
    userName: "", 
    password: "", 
    apiUrl: "https://www.highwycombebites.com"
  );

  final rxStoreId = "Not Logged In".obs;
  final rxUserName = "".obs;

  String get currentStoreId => rxStoreId.value;
  String get currentUserName => rxUserName.value;
  PrintSettings get settings => _settings;

  void updateSettings(String storeId, String? userId, String? userName, String? password) {
    _settings.storeId = storeId;
    rxStoreId.value = storeId;
    if (userId != null) _settings.userId = userId;
    if (userName != null) {
      _settings.userName = userName;
      rxUserName.value = userName;
    }
    if (password != null) _settings.password = password;
    
    // Print user details as requested
    print("---------------------------------------");
    print("USER DETAILS UPDATED:");
    print("Store ID: $storeId");
    print("User ID (API): ${userId ?? _settings.userId}");
    print("User Name (UI): ${userName ?? _settings.userName}");
    print("Password: ${password ?? _settings.password}");
    print("API URL: ${_settings.apiUrl}");
    print("---------------------------------------");
  }

  void markOrderAsHandled(String orderNo) {
    pendingOrders.removeWhere((o) => o.orderNo == orderNo);
    if (pendingOrders.isEmpty) {
      _stopAlertSound();
    }
    refreshOrdersTrigger.value++;
  }

  void toggleManualStatus(bool isOffline) async {
    isManuallyOffline.value = isOffline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isManuallyOffline', isOffline);
    
    // Sync to server status
    _syncStatusToServer(!isOffline);

    if (isOffline) {
      pendingOrders.clear();
      _stopAlertSound();
    } else {
      _checkForNewOrders();
    }
  }

  Future<void> _syncStatusToServer(bool online) async {
    if (_settings.storeId.isEmpty || _settings.storeId == "Not Logged In") return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Fetch all other settings to avoid overwriting with defaults
      // For simplicity, we can use the ones stored in SharedPreferences
      await _apiService.savePrintingSettings(
        storeId: _settings.storeId,
        printerType: prefs.getString('printerType') ?? 'Built-in printer',
        paperSize: prefs.getString('paperSize') ?? '58mm',
        autoPrint: prefs.getBool('autoPrint') ?? true,
        timeout: prefs.getInt('timeout') ?? 10,
        totalPrint: prefs.getInt('totalPrint') ?? 1,
        selectedDeviceMac: prefs.getString('selectedDeviceMac') ?? '',
        selectedDeviceName: prefs.getString('selectedDeviceName') ?? '',
        status: online ? 'Active' : 'Inactive',
        printerStatus: 'Online',
        music: prefs.getString('selectedRingtone') ?? 'mixkit-old-telephone-ring-1357.wav',
        isPageHeader: prefs.getBool('isPageHeader') ?? true,
        setHeadercontent: prefs.getString('setHeadercontent') ?? '',
        isPagefooter: prefs.getBool('isPagefooter') ?? true,
        setDateFormate: prefs.getString('setDateFormate') ?? 'dd/MM/yyyy',
        setTimeFormate: prefs.getString('setTimeFormate') ?? 'HH:mm',
        isPrintDateTime: prefs.getBool('isPrintDateTime') ?? true,
        apiUrl: _settings.apiUrl,
      );
    } catch (e) {
      LoggerService.to.log("Error syncing status to server: $e");
    }
  }

  void startMonitoring() async {
    final prefs = await SharedPreferences.getInstance();
    isManuallyOffline.value = prefs.getBool('isManuallyOffline') ?? false;

    // Register observer
    WidgetsBinding.instance.addObserver(this);

    // Initial check
    final results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkForNewOrders();
    });
    
    // Physical network check
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectivityStatus(results);
    });

    _checkForNewOrders(); // Initial check
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final bool hasConnection = results.any((result) => result != ConnectivityResult.none);
    
    if (results.isNotEmpty) {
      final result = results.first;
      if (result == ConnectivityResult.wifi) {
        connectionType.value = "WiFi";
      } else if (result == ConnectivityResult.mobile) {
        connectionType.value = "Mobile";
      } else if (result == ConnectivityResult.none) {
        connectionType.value = "None";
        connectionQuality.value = "Offline";
      } else {
        connectionType.value = "Other";
      }
    }

    if (isOnline.value && !hasConnection) {
      // Just disconnected
      _playAlertSound();
      Get.snackbar(
        "Network Error",
        "You are disconnected from the network. Please check your internet.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
    
    isOnline.value = hasConnection;
    if (!hasConnection) {
      connectionType.value = "None";
      connectionQuality.value = "Offline";
    }
  }

  @override
  void onClose() {
    stopMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LoggerService.to.log("App resumed - triggering immediate order check...");
      _checkForNewOrders();
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    _stopAlertSound();
  }

  Future<void> _checkForNewOrders() async {
    if (isChecking.value || isManuallyOffline.value) return;
    
    isChecking.value = true;
    final stopwatch = Stopwatch()..start();
    try {
      final List<OrderModel> newOrders = await _apiService.getPendingOrders(_settings);
      stopwatch.stop();
      _updateConnectionQuality(stopwatch.elapsedMilliseconds);
      
      isOnline.value = true;
      lastCheckTime.value = DateTime.now();
      
      // Instead of replacing, we only add new orders that aren't already in our list
      for (var order in newOrders) {
        String orderNo = order.orderNo ?? "";
        bool alreadyExists = pendingOrders.any((o) => o.orderNo == orderNo);
        
        if (!alreadyExists) {
          pendingOrders.add(order);
          refreshOrdersTrigger.value++; // Refresh lists when a new order arrives
          _playAlertSound(); // Play sound for new order
          LoggerService.to.log("NEW ORDER RECEIVED: #${order.orderNo}");
          
          // Auto-print only new orders if setting is enabled
          if (orderNo.isNotEmpty && !_printedOrderIds.contains(orderNo)) {
            final prefs = await SharedPreferences.getInstance();
            final autoPrint = prefs.getBool('autoPrint') ?? true; // Default to true for "no manual interference"
            
            if (autoPrint) {
              LoggerService.to.log(">>> AUTO-PRINTING NEW ORDER #$orderNo");
              Get.snackbar(
                "NEW ORDER #$orderNo",
                "Total: £${order.total.toStringAsFixed(2)}\nAutomatically sending to printer...",
                backgroundColor: Colors.green.shade800,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 6),
                icon: const Icon(Icons.print, color: Colors.white, size: 30),
                mainButton: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
                boxShadows: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                ],
              );
              _printQueueService.addToQueue(order.toMap());
            }
            
            _printedOrderIds.add(orderNo);
          }

          // Show Global Popup for new orders
          if (orderNo.isNotEmpty && !_popupOrderIds.contains(orderNo)) {
            _popupOrderIds.add(orderNo);
            final orderData = order.toMap();
            
            showNewOrderPopup(
              orderData, 
              onViewDetails: () {
                showOrderDetailsDialog(orderNo);
              },
              onAccept: () {
                showPreparationTimeDialog((mins) async {
                  Get.showOverlay(
                    asyncFunction: () async {
                      try {
                        bool success = await _apiService.acceptOrder(orderNo, mins, _settings);
                        if (success) {
                          if (Get.isDialogOpen ?? false) Get.back(); // Close NewOrderPopup
                          markOrderAsHandled(orderNo);
                          // This will now print ONLY the time slip as per new logic in PrinterService
                          await _printerService.autoPrintOrder(orderData, status: PrintStatus.accepted, extraInfo: mins.toString());
                          
                          Get.snackbar(
                            "ORDER ACCEPTED",
                            "Confirmed for $mins minutes",
                            backgroundColor: Colors.green.shade800,
                            colorText: Colors.white,
                          );
                        }
                      } catch (e) {
                        LoggerService.to.log("Error accepting from popup: $e");
                      }
                    },
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                });
              },
              onReject: () {
                showRejectionReasonDialog((reason) async {
                  Get.showOverlay(
                    asyncFunction: () async {
                      try {
                        bool success = await _apiService.rejectOrder(orderNo, reason, _settings);
                        if (success) {
                          if (Get.isDialogOpen ?? false) Get.back(); // Close NewOrderPopup
                          markOrderAsHandled(orderNo);
                          // This will now print ONLY the rejection reason slip
                          await _printerService.autoPrintOrder(orderData, status: PrintStatus.rejected, extraInfo: reason);

                          Get.snackbar(
                            "ORDER REJECTED",
                            "Reason: $reason",
                            backgroundColor: Colors.red.shade800,
                            colorText: Colors.white,
                          );
                        }
                      } catch (e) {
                        LoggerService.to.log("Error rejecting from popup: $e");
                      }
                    },
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                });
              },
            );
          }
        }
      }
    } catch (e) {
      isOnline.value = false;
      connectionQuality.value = "Offline";
      LoggerService.to.log("Monitoring Error: $e");
    } finally {
      isChecking.value = false;
    }

  }

  void _updateConnectionQuality(int latencyMs) {
    if (latencyMs < 300) {
      connectionQuality.value = "Strong";
    } else if (latencyMs < 800) {
      connectionQuality.value = "Good";
    } else {
      connectionQuality.value = "Weak";
    }
  }

  Future<void> _playAlertSound() async {
    if (_audioPlayer.state == PlayerState.playing) return;
    try {
      // Get selected ringtone from settings if available
      String ringtone = '2 ringtone-1356.wav';
      try {
        final prefs = await SharedPreferences.getInstance();
        ringtone = prefs.getString('selectedRingtone') ?? ringtone;
      } catch (_) {}

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('ringtone/$ringtone'));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  Future<void> _stopAlertSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print("Error stopping sound: $e");
    }
  }

}
