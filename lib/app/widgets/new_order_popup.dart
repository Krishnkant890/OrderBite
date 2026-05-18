import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/app_colors.dart';

class NewOrderPopup extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const NewOrderPopup({
    super.key, 
    required this.order, 
    required this.onAccept, 
    required this.onReject,
    required this.onViewDetails
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 24,
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
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
            // Header with pulsing icon animation effect
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: AppColors.accent,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 20.h),
            
            Text(
              "NEW ORDER RECEIVED!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Order ID: #${order['id']}",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Order Summary Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, "Customer", order['customer'] ?? "N/A"),
                  if (order['phone'] != null && order['phone'].toString().isNotEmpty) ...[
                    const Divider(height: 12),
                    _infoRow(Icons.phone_outlined, "Phone", order['phone']),
                  ],
                  if (order['address'] != null && order['address'].toString().trim().isNotEmpty) ...[
                    const Divider(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 18.sp, color: Colors.grey[600]),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            order['address'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 14.sp,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 12),
                  _infoRow(Icons.payments_outlined, "Amount", order['total'] ?? "£0.00"),
                  const Divider(height: 12),
                  _infoRow(Icons.moped_outlined, "Type", order['type'] ?? "Delivery"),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Actions Row: Accept and Reject
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.accent.withOpacity(0.4),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "ACCEPT",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15.sp,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onReject();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "REJECT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 15.sp,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey[600]),
        SizedBox(width: 10.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}

void showNewOrderPopup(Map<String, dynamic> order, {
  required VoidCallback onAccept, 
  required VoidCallback onReject,
  required VoidCallback onViewDetails
}) {
  Get.dialog(
    NewOrderPopup(
      order: order,
      onAccept: onAccept,
      onReject: onReject,
      onViewDetails: onViewDetails,
    ),
    barrierDismissible: false,
  );
}

