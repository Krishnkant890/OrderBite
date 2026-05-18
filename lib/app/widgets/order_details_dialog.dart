import 'package:flutter/material.dart';
import 'package:gc_any_order/app/services/api_service.dart';
import 'package:gc_any_order/app/services/order_monitoring_service.dart';
import 'package:gc_any_order/app/services/printer_service.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/app_colors.dart';
import 'preparation_time_dialog.dart';
import 'rejection_reason_dialog.dart';
import 'receipt_preview_dialog.dart';

class OrderDetailsDialog extends StatefulWidget {
  final String orderId;

  const OrderDetailsDialog({super.key, required this.orderId});

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  bool isLoading = true;
  bool isActionLoading = false;
  Map<String, dynamic>? orderDetails;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final apiService = Get.find<ApiService>();
      final monitor = Get.find<OrderMonitoringService>();
      final result = await apiService.getOrderDataById(
        orderId: widget.orderId,
        apiUrl: monitor.settings.apiUrl,
      );

      if (mounted) {
        setState(() {
          orderDetails = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Gradient/Solid Color
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 16.w, 20.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Details",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "#${widget.orderId}",
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (error != null)
              Padding(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16.h),
                    Text("Error: $error", textAlign: TextAlign.center),
                  ],
                ),
              )
            else if (orderDetails == null)
              const Center(child: Text("No details found"))
            else ...[
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: _buildDetailsContent(),
                ),
              ),
              
              _buildBottomActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent() {
    final data = orderDetails!;
    final customerName = data['custname'] ?? data['customer'] ?? data['name'] ?? "N/A";
    final total = _formatPrice(data['netpayamount'] ?? data['total'] ?? data['grandTotal'] ?? "0.00");
    final items = data['orderdetails'] as List? ?? data['orderdetail'] as List? ?? [];
    final status = (data['orderstatus'] ?? data['status'] ?? "pending").toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "CUSTOMER INFO",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        // Customer Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_outline, "Customer", customerName),
              const Divider(height: 20),
              _buildInfoRow(Icons.phone_outlined, "Phone", data['custmobile'] ?? "N/A"),
              const Divider(height: 20),
              _buildInfoRow(Icons.location_on_outlined, "Address", data['deliveryaddress'] ?? "N/A"),
            ],
          ),
        ),
        
        SizedBox(height: 24.h),
        const Text(
          "ORDER SUMMARY",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10),
        ),
        SizedBox(height: 12.h),
        
        // Order Items Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "${item['quantity'] ?? item['qty'] ?? '1'}x",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item['foodname'] ?? item['menuname'] ?? item['name'] ?? 'Item'}",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                          ),
                          if (item['modifiers'] != null && (item['modifiers'] as List).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                (item['modifiers'] as List).join(", "),
                                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      "£${_formatPrice(item['amount'] ?? item['price'])}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ],
                ),
              )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TOTAL AMOUNT",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    "£$total",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (data['instructions'] != null && data['instructions'].toString().isNotEmpty || 
            data['instructionofcooking'] != null && data['instructionofcooking'].toString().isNotEmpty) ...[
          SizedBox(height: 24.h),
          const Text(
            "INSTRUCTIONS",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Text(
              (data['instructions'] ?? data['instructionofcooking']).toString(),
              style: TextStyle(fontSize: 13.sp, color: Colors.orange.shade900, fontStyle: FontStyle.italic),
            ),
          ),
        ],
        
        SizedBox(height: 24.h),
        const Text(
          "PAYMENT & DELIVERY",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildInfoCard(Icons.payment, "Method", data['paymentmode'] ?? "N/A")),
            SizedBox(width: 12.w),
            Expanded(child: _buildInfoCard(Icons.calendar_today, "Date", data['orderdate'] ?? "N/A")),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              SizedBox(width: 6.w),
              Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final status = (orderDetails?['orderstatus'] ?? orderDetails?['status'] ?? "pending").toString().toLowerCase();
    final isPending = status == 'pending';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActionLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        showRejectionReasonDialog((reason) => _handleReject(reason));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                      ),
                      child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        showPreparationTimeDialog((mins) => _handleAccept(mins));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: const Text("ACCEPT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                
                // Common icons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (orderDetails != null) {
                        showReceiptPreview(_formatOrderForPrint(orderDetails!));
                      }
                    },
                    icon: Icon(Icons.remove_red_eye_outlined, color: Colors.orange.shade700),
                    tooltip: "Preview Receipt",
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: _handlePrint,
                    icon: const Icon(Icons.print, color: AppColors.primary),
                    tooltip: "Print Order",
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('pending')) return Colors.orange;
    if (status.contains('accept')) return Colors.green;
    if (status.contains('reject') || status.contains('cancel')) return Colors.red;
    return Colors.blue;
  }

  Future<void> _handleAccept(int mins) async {
    if (mounted) setState(() => isActionLoading = true);
    final apiService = Get.find<ApiService>();
    final monitor = Get.find<OrderMonitoringService>();
    final printer = Get.find<PrinterService>();
    
    try {
      bool success = await apiService.acceptOrder(
        widget.orderId, 
        mins, 
        monitor.settings
      );

      if (success) {
        monitor.markOrderAsHandled(widget.orderId);
        
        // Print Accepted Receipt
        if (orderDetails != null) {
          await printer.autoPrintOrder(_formatOrderForPrint(orderDetails!), status: PrintStatus.accepted, extraInfo: mins.toString());
        }

        Get.snackbar(
          "ORDER ACCEPTED",
          "Confirmed for $mins minutes",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade800,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("ERROR", "Failed to accept order");
      }
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  Future<void> _handleReject(String reason) async {
    if (mounted) setState(() => isActionLoading = true);
    final apiService = Get.find<ApiService>();
    final monitor = Get.find<OrderMonitoringService>();
    final printer = Get.find<PrinterService>();
    
    try {
      bool success = await apiService.rejectOrder(
        widget.orderId, 
        reason, 
        monitor.settings
      );

      if (success) {
        monitor.markOrderAsHandled(widget.orderId);
        
        // Print Rejected Receipt
        if (orderDetails != null) {
          await printer.autoPrintOrder(_formatOrderForPrint(orderDetails!), status: PrintStatus.rejected, extraInfo: reason);
        }

        Get.snackbar(
          "ORDER REJECTED",
          "Cancelled: $reason",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("ERROR", "Failed to reject order");
      }
    } finally {
      if (mounted) setState(() => isActionLoading = false);
    }
  }

  Map<String, dynamic> _formatOrderForPrint(Map<String, dynamic> data) {
    return {
      'id': widget.orderId,
      'storeName': data['restname'] ?? data['storeName'] ?? "",
      'name': data['name'] ?? data['custname'] ?? "",
      'date': data['orderdate'] ?? "",
      'type': data['ordertype'] ?? 'Order',
      'customer': data['custname'] ?? data['customer'] ?? "Walk-In",
      'address': data['deliveryaddress'],
      'phone': data['custmobile'],
      'total': '£${_formatPrice(data['netpayamount'] ?? data['total'] ?? "0.00")}',
      'service_charge': '£${_formatPrice(data['servicecharge'] ?? data['service_charge'] ?? "0.00")}',
      'delivery_charge': '£${_formatPrice(data['deliverycharge'] ?? data['delivery_charge'] ?? "0.00")}',
      'discount': '£${_formatPrice(data['discount'] ?? data['coupondiscount'] ?? "0.00")}',
      'payment_mode': data['paymentmode'] ?? 'Cash',
      'requested_for': data['requestedfor'] ?? 'As soon as possible',
      'previous_order': data['previousorder'] ?? data['previous_order'] ?? '0',
      'comments': data['instructions'] ?? data['instructionofcooking'],
      'accepted_for': data['acceptedfor'] ?? data['accepted_for'] ?? (data['status']?.toString().toLowerCase() == 'accepted' ? data['preparationtime'] : null),
      'accepted_time': data['acceptedtime'] ?? data['accepted_time'],
      'cancel_reason': data['cancelreason'] ?? data['cancel_reason'] ?? data['reason'],
      'items': (data['orderdetails'] as List? ?? data['orderdetail'] as List? ?? []).map((i) => {
        'name': i['foodname'] ?? i['menuname'] ?? i['name'] ?? "Item",
        'qty': i['quantity'] ?? i['qty'] ?? 1,
        'price': '£${_formatPrice(i['amount'] ?? i['price'])}',
        'modifiers': i['modifiers'] is List ? i['modifiers'] : null,
      }).toList(),
    };
  }

  String _formatPrice(dynamic price) {
    if (price == null) return "0.00";
    if (price is num) return price.toStringAsFixed(2);
    if (price is String) {
      double? val = double.tryParse(price.replaceAll('£', '').trim());
      if (val != null) return val.toStringAsFixed(2);
      return price;
    }
    return price.toString();
  }

  void _handlePrint() {
    if (orderDetails == null) return;
    Get.find<PrinterService>().autoPrintOrder(_formatOrderForPrint(orderDetails!));
  }
}

void showOrderDetailsDialog(String orderId) {
  Get.dialog(
    OrderDetailsDialog(orderId: orderId),
    barrierDismissible: true,
  );
}
