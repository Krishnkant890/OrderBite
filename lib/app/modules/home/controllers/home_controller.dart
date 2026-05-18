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
