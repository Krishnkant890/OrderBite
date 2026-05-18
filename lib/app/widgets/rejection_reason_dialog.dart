import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../resources/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RejectionReasonDialog extends StatefulWidget {
  final Function(String reason) onSelected;

  const RejectionReasonDialog({super.key, required this.onSelected});

  @override
  State<RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<RejectionReasonDialog> {
  static const List<String> reasons = [
    "TOO BUSY",
    "FOOD UNAVAILABLE",
    "UNABLE TO DELIVER",
    "DONT DELIVER TO AREA",
    "UNKNOWN ADDRESS",
    "TIME UNAVAILABLE",
    "JAM-PLEASE REAORDER",
  ];

  String selectedReason = reasons[0];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 5,
      child: Container(
        padding: EdgeInsets.all(24.w),
        width: 0.9.sw,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.cancel_outlined, color: Colors.red, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rejection Reason",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Why is this order being rejected?",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // List of options
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: reasons.map((reason) => _buildListOption(reason)).toList(),
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      "CANCEL",
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Closes the popup first
                      widget.onSelected(selectedReason);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      "CONFIRM REJECT",
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildListOption(String reason) {
    bool isSelected = selectedReason == reason;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedReason = reason;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected ? Center(
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ) : null,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.red : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.red, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

void showRejectionReasonDialog(Function(String) onSelected) {
  Get.dialog(
    RejectionReasonDialog(onSelected: onSelected),
    barrierDismissible: true,
  );
}
