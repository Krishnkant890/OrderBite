import 'package:get/get.dart';
import '../services/printer_service.dart';
import '../services/print_queue_service.dart';
import '../services/order_monitoring_service.dart';
import '../services/api_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(ApiService(), permanent: true);
    Get.put(PrinterService(), permanent: true);
    Get.put(PrintQueueService(), permanent: true);
    Get.put(OrderMonitoringService(), permanent: true);
    
    // Start monitoring after services are ready
    Get.find<OrderMonitoringService>().startMonitoring();
  }
}
