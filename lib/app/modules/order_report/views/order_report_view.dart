import 'package:flutter/material.dart';
import 'package:gc_any_order/app/resources/app_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/order_report_controller.dart';
import '../../../widgets/order_details_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderReportView extends GetView<OrderReportController> {
  const OrderReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text("Order Report", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              // Implementation for printing report if needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(context),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.orders.isEmpty) {
                return _buildNoFoundCard();
              }
              return _buildOrderList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: controller.fromDate.value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) controller.updateFromDate(picked);
                      },
                      child: Obx(() => Column(
                        children: [
                          const Text("From Date", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            DateFormat('dd/MM/yyyy').format(controller.fromDate.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("-", style: TextStyle(fontSize: 24, color: Colors.grey)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: controller.toDate.value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) controller.updateToDate(picked);
                      },
                      child: Obx(() => Column(
                        children: [
                          const Text("To Date", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            DateFormat('dd/MM/yyyy').format(controller.toDate.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.status.value.isEmpty ? "All" : controller.status.value,
                      isExpanded: true,
                      items: ["All", "Pending", "Accepted", "Rejected"]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) controller.updateStatus(val == "All" ? "" : val);
                      },
                    ),
                  )),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => controller.fetchOrders(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      itemCount: controller.orders.length,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        final order = controller.orders[index];
        final String status = (order['status'] ?? "").toString().toLowerCase();
        
        Color statusColor = Colors.grey;
        if (status == 'accepted') statusColor = Colors.green;
        if (status == 'rejected') statusColor = Colors.red;
        if (status == 'pending') statusColor = Colors.orange;

        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: InkWell(
            onTap: () => showOrderDetailsDialog((order['id'] ?? order['pkid']).toString()),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #${order['orderid'] ?? order['id'] ?? order['pkid']}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['custname'] ?? "Walk-In",
                            style: TextStyle(color: Colors.grey[700], fontSize: 14.sp),
                          ),
                          Text(
                            order['orderDate'] ?? order['orderdate'] ?? "",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                          ),
                        ],
                      ),
                      Text(
                        "£${_formatPrice(order['total'] ?? order['grandTotal'] ?? order['netpayamount'])}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoFoundCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), // Very light red
        border: Border.all(color: Colors.red[100]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        "No found",
        style: TextStyle(color: Colors.black87, fontSize: 16),
      ),
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
