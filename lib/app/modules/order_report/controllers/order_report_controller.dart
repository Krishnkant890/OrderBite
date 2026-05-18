import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/order_monitoring_service.dart';

class OrderReportController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final OrderMonitoringService _monitoringService = Get.find<OrderMonitoringService>();

  final isLoading = false.obs;
  final orders = <dynamic>[].obs;
  
  final fromDate = DateTime.now().obs;
  final toDate = DateTime.now().obs;

  final status = "".obs; // All, Pending, Accepted, Rejected
  final selectedOrderType = "1".obs; // 1 for All or specific type
  final selectedPaymentMode = "1".obs; // 1 for All or specific mode

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final String formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate.value);
      final String formattedToDate = DateFormat('yyyy-MM-dd').format(toDate.value);
      
      final results = await _apiService.getRestaurantOrderList(
        storeId: _monitoringService.settings.storeId,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        apiUrl: _monitoringService.settings.apiUrl,
        status: status.value == "All" ? "" : status.value,
        orderType: selectedOrderType.value,
        paymentMode: selectedPaymentMode.value,
      );
      
      orders.assignAll(results);
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateFromDate(DateTime date) {
    fromDate.value = date;
  }

  void updateToDate(DateTime date) {
    toDate.value = date;
  }

  void updateStatus(String val) {
    status.value = val;
  }
}
