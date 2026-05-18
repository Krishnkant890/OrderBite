import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gc_any_order/app/resources/app_colors.dart';
import 'package:gc_any_order/app/services/api_service.dart';
import 'package:gc_any_order/app/services/order_monitoring_service.dart';
import 'package:gc_any_order/app/services/printer_service.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../widgets/order_card.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/order_details_dialog.dart';
import '../../../widgets/receipt_preview_dialog.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bool? shouldExit = await Get.dialog<bool>(
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(0xFFF4B400),
                  ),
                  SizedBox(height: 16.h),
                  Text('Exit or not?', style: TextStyle(fontSize: 18.sp)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF5350),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Get.back(result: false),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Get.back(result: true),
                          child: const Text(
                            'CONFIRM',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        return shouldExit ?? false;
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: false,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "Bites Orders",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 20.sp,
                ),
              ),
            ),
            actions: [
              Obx(() {
                final monitor = Get.find<OrderMonitoringService>();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: monitor.isManuallyOffline.value
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: monitor.isManuallyOffline.value
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        monitor.isManuallyOffline.value
                            ? "OFFLINE"
                            : "ONLINE",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: monitor.isManuallyOffline.value
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: !monitor.isManuallyOffline.value,
                        onChanged: (val) {
                          monitor.toggleManualStatus(!val);
                        },
                        activeColor: Colors.greenAccent,
                        activeTrackColor: Colors.green.withOpacity(0.3),
                        inactiveThumbColor: Colors.redAccent,
                        inactiveTrackColor: Colors.red.withOpacity(0.3),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                );
              }),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(100.h),
              child: Column(
                children: [
                  Obx(() {
                    final monitor = Get.find<OrderMonitoringService>();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: _getConnectionColor(
                              monitor.connectionQuality.value,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${monitor.connectionType.value} (${monitor.connectionQuality.value})",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                          if (monitor.lastCheckTime.value != null) ...[
                            SizedBox(width: 8.w),
                            Text(
                              "|  Sync: ${monitor.lastCheckTime.value!.hour}:${monitor.lastCheckTime.value!.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                          if (monitor.isChecking.value)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: "PENDING"),
                      Tab(text: "TODAY"),
                      Tab(text: "ALL"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              Obx(() {
                final monitor = Get.find<OrderMonitoringService>();
                final isManuallyOffline = monitor.isManuallyOffline.value;
                final isNetworkOffline = !monitor.isOnline.value;

                if (!isManuallyOffline && !isNetworkOffline) {
                  return const SizedBox.shrink();
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isNetworkOffline ? Colors.red.shade700 : const Color(0xFFE64A19), // Orange for manual offline
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNetworkOffline ? Icons.signal_wifi_off_rounded : Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isNetworkOffline
                                  ? "NO INTERNET CONNECTION"
                                  : "STORE IS OFFLINE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.sp,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              isNetworkOffline
                                  ? "Please check your WiFi or Mobile Data. Orders cannot be synced."
                                  : "You are offline, please come online for the new orders.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isManuallyOffline)
                        ElevatedButton(
                          onPressed: () => monitor.toggleManualStatus(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: isNetworkOffline ? Colors.red : const Color(0xFFE64A19),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text("GO ONLINE"),
                        ),
                    ],
                  ),
                );
              }),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPendingTab(), // Pending
                    _buildTodayTab(context), // Today
                    _buildAllTab(context), // All
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConnectionColor(String quality) {
    switch (quality) {
      case 'Strong':
        return Colors.greenAccent;
      case 'Good':
        return Colors.yellowAccent;
      case 'Weak':
        return Colors.orangeAccent;
      case 'Offline':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showStatsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow(
                Icons.check_circle_outline,
                "Accepted",
                "0",
                const Color(0xFF00897B),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.white),
              _buildStatRow(
                Icons.cancel,
                "Rejected",
                "0",
                const Color(0xFFD32F2F),
              ),
              _buildStatRow(
                Icons.file_copy_outlined,
                "All",
                "0",
                Colors.black54,
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String title,
    String count,
    Color iconColor, {
    Color? backgroundColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 24),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          Text(count, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return Column(
      children: [
        Expanded(child: _buildOrdersList()),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Bites Orders",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTab(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          if (controller.isLoadingToday.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.todayOrders.isEmpty) {
            return _buildNoRecordsView(
              onRefresh: () => controller.fetchTodayOrders(),
            );
          }
          return _buildStaticOrderList(controller.todayOrders);
        }),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () => _showStatsBottomSheet(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAllTab(BuildContext context) {
    return Column(
      children: [
        _buildDateHeader(),
        Expanded(
          child: Stack(
            children: [
              Obx(() {
                if (controller.isLoadingAll.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.allOrders.isEmpty) {
                  return _buildNoRecordsView(
                    onRefresh: () => controller.fetchAllOrders(),
                  );
                }
                return _buildStaticOrderList(controller.allOrders);
              }),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () => _showStatsBottomSheet(context),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    return Obx(() {
      final monitor = Get.find<OrderMonitoringService>();
      if (monitor.pendingOrders.isEmpty) {
        return _buildNoRecordsView(onRefresh: () => monitor.startMonitoring());
      }

      return ListView.builder(
        itemCount: monitor.pendingOrders.length,
        itemBuilder: (context, index) {
          final orderModel = monitor.pendingOrders[index];
          // Convert OrderModel to Map exactly how OrderCard expects it
          final Map<String, dynamic> orderData = orderModel.toMap();

          return OrderCard(
            order: orderData,
            onPrint: () {
              final printerService = Get.find<PrinterService>();
              printerService.autoPrintOrder(orderData);
            },
            onAccept: (mins) async {
              final apiService = Get.find<ApiService>();
              final monitor = Get.find<OrderMonitoringService>();
              final printer = Get.find<PrinterService>();
              
              // Show loader
              Get.showOverlay(
                asyncFunction: () async {
                  bool success = await apiService.acceptOrder(
                    orderModel.orderNo ?? "", 
                    mins, 
                    monitor.settings
                  );

                  if (success) {
                    monitor.markOrderAsHandled(orderModel.orderNo ?? "");
                    
                    // Print Accepted Receipt
                    await printer.autoPrintOrder(orderData, status: PrintStatus.accepted, extraInfo: mins.toString());

                    Get.snackbar(
                      "ORDER ACCEPTED",
                      "Confirmed for $mins minutes",
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green.shade800,
                      colorText: Colors.white,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 4),
                    );
                  } else {
                    Get.snackbar(
                      "ERROR", 
                      "Failed to accept order",
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red.shade800,
                      colorText: Colors.white,
                      icon: const Icon(Icons.error_outline, color: Colors.white),
                    );
                  }
                },
                loadingWidget: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            onReject: (reason) async {
              final apiService = Get.find<ApiService>();
              final monitor = Get.find<OrderMonitoringService>();
              final printer = Get.find<PrinterService>();
              
              // Show loader
              Get.showOverlay(
                asyncFunction: () async {
                  bool success = await apiService.updateOrderStatus(
                    orderModel.orderNo ?? "", 
                    monitor.settings,
                    "Rejected",
                    reason
                  );

                  if (success) {
                    monitor.markOrderAsHandled(orderModel.orderNo ?? "");
                    
                    // Print Rejected Receipt
                    await printer.autoPrintOrder(orderData, status: PrintStatus.rejected, extraInfo: reason);

                    Get.snackbar(
                      "ORDER REJECTED",
                      "Cancelled: $reason",
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red.shade900,
                      colorText: Colors.white,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 4),
                    );
                  } else {
                    Get.snackbar(
                      "ERROR", 
                      "Failed to reject order",
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red.shade800,
                      colorText: Colors.white,
                      icon: const Icon(Icons.error_outline, color: Colors.white),
                    );
                  }
                },
                loadingWidget: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            onStatusUpdate: (status) async {
              final apiService = Get.find<ApiService>();
              final monitor = Get.find<OrderMonitoringService>();
              
              bool success = await apiService.updateOrderStatus(
                orderModel.orderNo ?? "", 
                monitor.settings,
                "Accepted",
                status
              );

              if (success) {
                Get.snackbar(
                  "STATUS UPDATED",
                  "Order marked as $status",
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.blue.shade800,
                  colorText: Colors.white,
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  duration: const Duration(seconds: 4),
                );
              } else {
                Get.snackbar(
                  "ERROR", 
                  "Failed to update status",
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red.shade800,
                  colorText: Colors.white,
                  icon: const Icon(Icons.error_outline, color: Colors.white),
                );
              }
            },
          );
        },
      );
    });
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[300],
      child: Obx(() {
        final fromStr = DateFormat('dd/MM/yyyy').format(controller.fromDate.value);
        final toStr = DateFormat('dd/MM/yyyy').format(controller.toDate.value);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _dateItem("From:$fromStr", () => controller.selectDate(true)),
            _dateItem("To:$toStr", () => controller.selectDate(false)),
          ],
        );
      }),
    );
  }

  Widget _dateItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecordsView({VoidCallback? onRefresh}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            "No Records",
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRefresh ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticOrderList(List<dynamic> orders) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: ListTile(
            title: Text(
              "Order #${order['orderid'] ?? order['id'] ?? order['pkid'] ?? '---'}",
            ),
            subtitle: Text(
              "Total: £${_formatPrice(order['netpayamount'] ?? order['total'] ?? order['grandTotal'])}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order['orderdate'] ??
                      order['orderDate'] ??
                      order['datetime'] ??
                      "",
                ),
                IconButton(
                  icon: const Icon(Icons.print, size: 20),
                  onPressed: () {
                    try {
                      final Map<String, dynamic> orderData = {
                        'id': (order['orderid'] ?? order['id'] ?? order['pkid'] ?? '').toString(),
                        'date': (order['orderdate'] ?? order['orderDate'] ?? order['datetime'] ?? '').toString(),
                        'total': '£${order['netpayamount'] ?? order['total'] ?? order['grandTotal'] ?? '0.00'}',
                        'items': [], // items might be missing in summary list
                      };
                      final printerService = Get.find<PrinterService>();
                      printerService.autoPrintOrder(orderData);
                    } catch (e) {
                      print("Error preparing print data: $e");
                    }
                  },
                ),
              ],
            ),
            onTap: () => showOrderDetailsDialog((order['orderid'] ?? order['id'] ?? order['pkid']).toString()),
          ),
        );
      },
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return "0.00";
    if (price is num) return price.toStringAsFixed(2);
    if (price is String) {
      double? val = double.tryParse(price);
      if (val != null) return val.toStringAsFixed(2);
      return price;
    }
    return price.toString();
  }
}
