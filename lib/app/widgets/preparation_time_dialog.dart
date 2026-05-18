import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../resources/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PreparationTimeDialog extends StatefulWidget {
  final Function(int minutes) onSelected;

  const PreparationTimeDialog({super.key, required this.onSelected});

  @override
  State<PreparationTimeDialog> createState() => _PreparationTimeDialogState();
}

class _PreparationTimeDialogState extends State<PreparationTimeDialog> {
  int selectedMinutes = 20;

  final List<int> timeOptions = [10, 15, 20, 25, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(24.w),
        width: 0.9.sw,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.timer_outlined, color: AppColors.primary, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Preparation Time",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Select duration for this order",
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
                  children: timeOptions.map((mins) => _buildListOption(mins)).toList(),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Closes the popup first
                      widget.onSelected(selectedMinutes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "CONFIRM",
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildListOption(int mins) {
    bool isSelected = selectedMinutes == mins;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMinutes = mins;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
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
                  color: isSelected ? AppColors.primary : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected ? Center(
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ) : null,
            ),
            SizedBox(width: 16.w),
            Text(
              "$mins Minutes",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

void showPreparationTimeDialog(Function(int) onSelected) {
  Get.dialog(
    PreparationTimeDialog(onSelected: onSelected),
    barrierDismissible: true,
  );
}
