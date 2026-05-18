import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resources/app_colors.dart';
import '../resources/app_strings.dart';
import 'preparation_time_dialog.dart';
import 'rejection_reason_dialog.dart';
import 'status_update_dialog.dart';
import 'order_details_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';


class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(int minutes) onAccept;
  final Function(String reason) onReject;
  final Function(String status)? onStatusUpdate;
  final Function()? onPrint;
  final Function()? onPrintLongPress;
  final Function()? onPreview;

  const OrderCard({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.onStatusUpdate,
    this.onPrint,
    this.onPrintLongPress,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 18.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Text(
                      "${AppStrings.orderIdPrefix}${order['id']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    if (onPrint != null)
                      IconButton(
                        onPressed: onPrint,
                        icon: Icon(Icons.print, size: 20.sp, color: AppColors.primary),
                      ),
                    if (onPreview != null)
                      IconButton(
                        onPressed: onPreview,
                        icon: Icon(Icons.remove_red_eye_outlined, size: 20.sp, color: Colors.orange),
                        tooltip: "Preview Receipt",
                      ),

                  ],
                ),

                Text(
                  order['time'] ?? order['date'] ?? "",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        order['customer'] ?? "Walk-In",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order['phone'] != null && order['phone'].toString().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14.sp, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          order['phone'],
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14.sp, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          order['address'],
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                Text(
                  "ITEMS",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ... (order['items'] as List).map((item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "${item['qty']}x",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOTAL AMOUNT",
                          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          order['total'] ?? "£0.00",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (onStatusUpdate != null) ...[
                          IconButton(
                            onPressed: () => showStatusUpdateDialog((status) {
                              onStatusUpdate!(status);
                            }),
                            icon: Icon(Icons.edit_calendar, size: 24.sp, color: Colors.orange),
                            tooltip: "Update Status",
                          ),
                          SizedBox(width: 4.w),
                        ],
                        OutlinedButton(
                          onPressed: () => showRejectionReasonDialog((reason) {
                            onReject(reason);
                          }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[100]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                          ),
                          child: Text(AppStrings.reject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () => showPreparationTimeDialog((mins) {
                            onAccept(mins);
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          ),
                          child: Text(AppStrings.accept, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showOrderDetailsDialog(order['id'].toString());
  }
}

