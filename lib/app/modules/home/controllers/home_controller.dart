import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/order_monitoring_service.dart';

class HomeController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final OrderMonitoringService _monitoringService = Get.find<OrderMonitoringService>();

  final isLoadingToday = false.obs;
  final isLoadingAll = false.obs;
  
  final todayOrders = <dynamic>[].obs;
  final allOrders = <dynamic>[].obs;

  final currentTodayFilter = "all".obs;
  final currentAllFilter = "all".obs;

  List<dynamic> get filteredTodayOrders {
    if (currentTodayFilter.value == "accepted") return todayOrders.where(_isAccepted).toList();
    if (currentTodayFilter.value == "rejected") return todayOrders.where(_isRejected).toList();
    return todayOrders;
  }

  List<dynamic> get filteredAllOrders {
    if (currentAllFilter.value == "accepted") return allOrders.where(_isAccepted).toList();
    if (currentAllFilter.value == "rejected") return allOrders.where(_isRejected).toList();
    return allOrders;
  }

  bool _isAccepted(dynamic order) {
    final status = (order['orderstatus'] ?? order['status'] ?? '').toString().toLowerCase();
    return status == 'accepted' || status == 'completed';
  }

  bool _isRejected(dynamic order) {
    final status = (order['orderstatus'] ?? order['status'] ?? '').toString().toLowerCase();
    return status == 'rejected' || status == 'cancelled' || status == 'cancel';
  }

  int getTodayCount(String type) {
    if (type == 'accepted') return todayOrders.where(_isAccepted).length;
    if (type == 'rejected') return todayOrders.where(_isRejected).length;
    return todayOrders.length;
  }

  int getAllCount(String type) {
    if (type == 'accepted') return allOrders.where(_isAccepted).length;
    if (type == 'rejected') return allOrders.where(_isRejected).length;
    return allOrders.length;
  }

  late Rx<DateTime> fromDate;
  late Rx<DateTime> toDate;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = now.obs;
    toDate = now.obs;
    
    fetchTodayOrders();
    fetchAllOrders();

    // Auto-refresh lists when orders are updated (new order arrives, or order handled)
    ever(_monitoringService.refreshOrdersTrigger, (_) {
      fetchTodayOrders();
      fetchAllOrders();
    });
  }

  Future<void> selectDate(bool isFrom) async {
    final DateTime? picked = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: isFrom ? fromDate.value : toDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2101),
      ),
    );
    
    if (picked != null) {
      if (isFrom) {
        fromDate.value = picked;
      } else {
        toDate.value = picked;
      }
      fetchAllOrders();
    }
  }

  Future<void> fetchTodayOrders() async {
    isLoadingToday.value = true;
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await _apiService.getRestaurantOrderList(
        storeId: _monitoringService.settings.storeId,
        fromDate: today,
        toDate: today,
        apiUrl: _monitoringService.settings.apiUrl,
      );
      todayOrders.assignAll(results);
    } catch (e) {
      print("Error fetching today orders: $e");
    } finally {
      isLoadingToday.value = false;
    }
  }

  Future<void> fetchAllOrders() async {
    isLoadingAll.value = true;
    try {
      final formattedFrom = DateFormat('yyyy-MM-dd').format(fromDate.value);
      final formattedTo = DateFormat('yyyy-MM-dd').format(toDate.value);
      
      final results = await _apiService.getRestaurantOrderList(
        storeId: _monitoringService.settings.storeId,
        fromDate: formattedFrom,
        toDate: formattedTo,
        apiUrl: _monitoringService.settings.apiUrl,
      );
      allOrders.assignAll(results);
    } catch (e) {
      print("Error fetching all orders: $e");
    } finally {
      isLoadingAll.value = false;
    }
  }
}
