import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? status;
  final String? extraInfo;

  const ReceiptPreviewDialog({
    super.key, 
    required this.order,
    this.status,
    this.extraInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 300.w,
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "RECEIPT PREVIEW",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                padding: EdgeInsets.all(12.w),
                child: Column(
                  children: [
                    // Actual Logo from Assets
                    Image.asset(
                      'assets/images/printreceptlogo.png',
                      width: 180.w,
                      height: 100.h,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.restaurant, size: 30.sp, color: Colors.grey[600]),
                      ),
                    ),
                    Text(
                      "www.meatwala.co.uk",
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 4.h),
                    const Text(
                      "------------------------------------------",
                      style: TextStyle(color: Colors.black87),
                      maxLines: 1,
                    ),
                    SizedBox(height: 4.h),
                    
                    Text(
                      (order['name'] ?? order['storeName'] ?? "Meatwala").toString().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    _row("Ordered:", order['date'] ?? ""),
                    SizedBox(height: 8.h),
                    Text(
                      (order['type'] ?? "Delivery").toString().toUpperCase(),
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900),
                    ),
                    _row("Order No:", order['id'] ?? ""),
                    const Divider(thickness: 1, color: Colors.black87),
                    
                    ... (order['items'] as List).map((item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item['qty']}x ${item['name']}"),
                            Text("${item['price']}"),
                          ],
                        ),
                        if (item['modifiers'] != null)
                          ... (item['modifiers'] as List).map((mod) => Padding(
                            padding: EdgeInsets.only(left: 12.w),
                            child: Text(" -$mod", style: TextStyle(fontSize: 10.sp, color: Colors.grey[700])),
                          )),
                      ],
                    )),
                    
                    const Divider(thickness: 1, color: Colors.black87),
                    _row("Service Charge:", order['service_charge'] ?? "0.00"),
                    _row("Delivery Charge:", order['delivery_charge'] ?? "0.00"),
                    _row("Discount:", order['discount'] ?? "0.00"),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "TOTAL: ${order['total']}",
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(thickness: 1, color: Colors.black87),
                    
                    if (order['address'] != null) Text(order['address'], style: TextStyle(fontSize: 10.sp)),
                    if (order['phone'] != null) Text(order['phone'], style: TextStyle(fontSize: 10.sp)),
                    const Divider(thickness: 1, color: Colors.black87),
                    
                    _row("Payment:", order['payment_mode'] ?? "Cash"),
                    _row("Requested for:", ""),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        order['requested_for'] ?? "As soon as possible",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    if (status == "Accepted") ...[
                      const Divider(thickness: 1, color: Colors.black87),
                      const Text("Accepted for:"),
                      Text(
                        "$extraInfo Minutes",
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                    ] else if (status == "Rejected") ...[
                      const Divider(thickness: 1, color: Colors.black87),
                      const Text("REJECTED", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      Text("Reason: $extraInfo"),
                    ],
                    
                    SizedBox(height: 10.h),
                    const Text("Meatwala - Fresh Quality Meat", style: TextStyle(fontSize: 8)),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text("CLOSE PREVIEW"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10.sp)),
          Text(value, style: TextStyle(fontSize: 10.sp)),
        ],
      ),
    );
  }
}

void showReceiptPreview(Map<String, dynamic> order, {String? status, String? extraInfo}) {
  Get.dialog(ReceiptPreviewDialog(order: order, status: status, extraInfo: extraInfo));
}
