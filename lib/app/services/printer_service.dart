import 'dart:typed_data';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'logger_service.dart';
import 'package:flutter/services.dart';


import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

enum PrintStatus { newOrder, accepted, rejected }

class PrinterService extends GetxService {
  bool isConnected = false;
  bool hasInternalPosPrinter = false;
  static const MethodChannel _nativePrinterChannel = MethodChannel('printer');

  @override
  void onInit() {
    super.onInit();
    _initSunmi();
    _checkDeviceDefaults();
  }

  Future<void> _checkDeviceDefaults() async {
    try {
      final Map<dynamic, dynamic> deviceInfo = await _nativePrinterChannel.invokeMethod('getDeviceInfo');
      final manufacturer = deviceInfo['manufacturer']?.toString().toUpperCase() ?? "";
      final model = deviceInfo['model']?.toString().toUpperCase() ?? "";
      
      if (manufacturer.contains("GOODCOM") || model.contains("GT90")) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString('paperSize') == null) {
          await prefs.setString('paperSize', '80mm');
          print("Defaulted paper size to 80mm for $manufacturer $model");
        }
      }
    } catch (e) {
      LoggerService.to.log("Error checking device defaults: $e");

    }
  }

  Future<void> _initSunmi() async {
    try {
      final bool? result = await SunmiPrinter.bindingPrinter();
      hasInternalPosPrinter = result ?? false;
      LoggerService.to.log("INTERNAL PRINTER: POS service status: $hasInternalPosPrinter");

    } catch (e) {
      LoggerService.to.log("INTERNAL PRINTER: Initialization error: $e");

      hasInternalPosPrinter = false;
    }
  }

  Future<void> connectToPrinter(String macAddress) async {
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    isConnected = result;
  }

  Future<bool> printReceipt(List<int> bytes, Map<String, dynamic> order, {PrintStatus status = PrintStatus.newOrder, String? extraInfo}) async {
    bool success = false;
    String method = "";
    final orderId = order['id'] ?? 'Unknown';

    try {
      LoggerService.to.log("PRINT START: Processing Order #$orderId (Status: $status)");

      // 1. Try POS/Sunmi first
      if (hasInternalPosPrinter) {
        try {
          LoggerService.to.log("PRINT METHOD: Attempting Sunmi POS print...");
          await SunmiPrinter.initPrinter();
          
          if (status == PrintStatus.newOrder) {
            await SunmiPrinter.startTransactionPrint(true);
            
            // Logo
            try {
              final ByteData data = await rootBundle.load('assets/images/printreceptlogo.png');
              final Uint8List imgBytes = data.buffer.asUint8List();
              await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
              await SunmiPrinter.printImage(imgBytes);
            } catch (e) {
              LoggerService.to.log("Sunmi Logo Error: $e");
            }

            await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
            await SunmiPrinter.printText("www.meatwala.co.uk", style: SunmiTextStyle(fontSize: 20));
            // Store Name: Font A, Center, Bold, Double size
            await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
            await SunmiPrinter.printText("${(order['name'] ?? order['storeName'] ?? 'Meatwala').toString().toUpperCase()}", style: SunmiTextStyle(bold: true, fontSize: 36));
            
            await SunmiPrinter.printText("Ordered:${order['date']}");
            await SunmiPrinter.printText("${(order['type'] ?? 'Delivery')}", style: SunmiTextStyle(bold: true, fontSize: 32));
            await SunmiPrinter.printText("Order No: $orderId", style: SunmiTextStyle(bold: true));
            await SunmiPrinter.line();
            
            // Item list
            for (var item in order['items']) {
              await SunmiPrinter.printRow(cols: [
                SunmiColumn(text: "${item['qty']} x ${item['name']}", width: 9, style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 20)),
                SunmiColumn(text: "${item['price']}", width: 3, style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT, fontSize: 20)),
              ]);
              if (item['modifiers'] != null) {
                for (var mod in item['modifiers']) {
                  await SunmiPrinter.printText("-$mod", style: SunmiTextStyle(fontSize: 18));
                }
              }
            }
            
            await SunmiPrinter.line();
            // Section headers: Bold
            await SunmiPrinter.printRow(cols: [
              SunmiColumn(text: "Service Charge:", width: 8),
              SunmiColumn(text: "${order['service_charge'] ?? '0.00'}", width: 4, style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
            ]);
            await SunmiPrinter.printRow(cols: [
              SunmiColumn(text: "Delivery Charge:", width: 8),
              SunmiColumn(text: "${order['delivery_charge'] ?? '0.00'}", width: 4, style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
            ]);
            await SunmiPrinter.printRow(cols: [
              SunmiColumn(text: "Discount:", width: 8),
              SunmiColumn(text: "${order['discount'] ?? '0.00'}", width: 4, style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT)),
            ]);
            
            // Totals: Bold + Larger
            await SunmiPrinter.printRow(cols: [
              SunmiColumn(text: "Total:", width: 6, style: SunmiTextStyle(bold: true, fontSize: 24)),
              SunmiColumn(text: "${order['total']}", width: 6, style: SunmiTextStyle(bold: true, fontSize: 24, align: SunmiPrintAlign.RIGHT)),
            ]);
            await SunmiPrinter.line();

            await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
            if (order['customer'] != null) await SunmiPrinter.printText("${order['customer']}");
            if (order['address'] != null) await SunmiPrinter.printText("${order['address']}");
            if (order['phone'] != null && order['phone'].toString().isNotEmpty) {
              await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
              await SunmiPrinter.printText("${order['phone']}", style: SunmiTextStyle(bold: true, fontSize: 32));
              await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
            }
            await SunmiPrinter.line();

            final paymentMode = (order['payment_mode'] ?? 'N/A').toString();
            if (paymentMode.toLowerCase() != 'cash') {
              await SunmiPrinter.printText("Order Paid", style: SunmiTextStyle(bold: true, fontSize: 24));
            }
            await SunmiPrinter.printText("Payment: $paymentMode");
            await SunmiPrinter.line();
            
            await SunmiPrinter.printText("Requested for:");
            final String reqFor = (order['requested_for'] != null && order['requested_for'].toString().trim().isNotEmpty) 
                ? order['requested_for'].toString() 
                : 'As soon as possible';
            await SunmiPrinter.printText(reqFor, style: SunmiTextStyle(bold: true, fontSize: 24));
            await SunmiPrinter.line();

            
            await SunmiPrinter.printText("Comments:");
            if (order['comments'] != null && order['comments'].toString().isNotEmpty) {
              await SunmiPrinter.printText("${order['comments']}");
            }
            await SunmiPrinter.line();

            if (order['accepted_for'] != null && order['accepted_for'].toString().isNotEmpty) {
               await SunmiPrinter.printText("Accepted for:");
               await SunmiPrinter.printText("${order['accepted_for']}", style: SunmiTextStyle(bold: true, fontSize: 24));
               if (order['accepted_time'] != null) await SunmiPrinter.printText("${order['accepted_time']}");
               await SunmiPrinter.line();
            }

            if (order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty) {
               await SunmiPrinter.printText("Order Cancel:");
               await SunmiPrinter.printText("${order['cancel_reason']}", style: SunmiTextStyle(bold: true, fontSize: 24));
               await SunmiPrinter.line();
            }

          } else {
            // Status Slips: Only print status/reason
            await SunmiPrinter.startTransactionPrint(true);
            await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
            await SunmiPrinter.printText("ORDER STATUS UPDATE", style: SunmiTextStyle(bold: true));
            await SunmiPrinter.printText("Order No: $orderId");
            await SunmiPrinter.line();
            
            if (status == PrintStatus.accepted) {
              await SunmiPrinter.printText("ACCEPTED", style: SunmiTextStyle(bold: true, fontSize: 36));
              await SunmiPrinter.printText("Preparation Time:", style: SunmiTextStyle(fontSize: 20));
              await SunmiPrinter.printText("${extraInfo ?? 'Confirmed'} Minutes", style: SunmiTextStyle(bold: true, fontSize: 32));
            } else if (status == PrintStatus.rejected) {
              await SunmiPrinter.printText("REJECTED", style: SunmiTextStyle(bold: true, fontSize: 36));
              await SunmiPrinter.printText("Reason:", style: SunmiTextStyle(fontSize: 20));
              await SunmiPrinter.printText("${extraInfo ?? 'N/A'}", style: SunmiTextStyle(bold: true, fontSize: 28));
            }
          }

          await SunmiPrinter.line();
          await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
          await SunmiPrinter.printText("Meatwala - Fresh Quality Meat", style: SunmiTextStyle(fontSize: 18));
          
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.cut();
          await SunmiPrinter.exitTransactionPrint(true);
          
          success = true;
          method = "Sunmi POS";
          LoggerService.to.log("PRINT SUCCESS: Order #$orderId via $method");
        } catch (e) {
          LoggerService.to.log("PRINT FAILURE: Sunmi method failed: $e");
        }
      }

      // Fallback to raw bytes for other printers
      if (!success) {
        // Try Native POS (GT90 / GT90EZ etc.)
        try {
          LoggerService.to.log("PRINT METHOD: Attempting Native POS Channel print...");
          final dynamic nativeResponse = await _nativePrinterChannel.invokeMethod('printReceipt', {
            'bytes': Uint8List.fromList(bytes),
          }).timeout(const Duration(seconds: 10));

          if (nativeResponse != null) {
            success = true;
            method = "Internal POS SDK ($nativeResponse)";
            LoggerService.to.log("PRINT SUCCESS: Order #$orderId via $method");
          }
        } catch (e) {
          LoggerService.to.log("PRINT ERROR: Native POS attempt failed: $e");
        }
      }

      // Try Bluetooth if still not success
      if (!success) {
        LoggerService.to.log("PRINT METHOD: Attempting Bluetooth fallback...");
        bool bluetoothConnected = await PrintBluetoothThermal.connectionStatus;
        if (bluetoothConnected) {
          success = await PrintBluetoothThermal.writeBytes(bytes);
          method = "Bluetooth Printer";
          if (success) LoggerService.to.log("PRINT SUCCESS: Order #$orderId via $method");
        }
      }

      return success;
    } catch (e) {
      LoggerService.to.log("PRINT ERROR: Order #$orderId - Unexpected exception: $e");
      return false;
    }
  }

  Future<void> showPrinterDiagnostics({String? error}) async {
    try {
      final Map<dynamic, dynamic> deviceInfo = await _nativePrinterChannel.invokeMethod('getDeviceInfo');
      final prefs = await SharedPreferences.getInstance();
      
      final String settingsInfo = """
--- PRINTER SETTINGS ---
Printer Type: ${prefs.getString('printerType') ?? 'Not Set'}
Paper Size: ${prefs.getString('paperSize') ?? '58mm'}
Auto Print: ${prefs.getBool('autoPrint') ?? false}
Print Copies: ${prefs.getInt('totalPrint') ?? 1}
Connected Mac: ${prefs.getString('selectedDeviceMac') ?? 'None'}

--- DEVICE INFO ---
Model: ${deviceInfo['model']}
Manufacturer: ${deviceInfo['manufacturer']}
Brand: ${deviceInfo['brand']}
Device: ${deviceInfo['device']}
Product: ${deviceInfo['product']}
Hardware: ${deviceInfo['hardware']}
Android Ver: ${deviceInfo['version'] ?? 'Unknown'}

--- STATUS ---
Internal POS Ready: $hasInternalPosPrinter
Error: ${error ?? 'None'}
""";

      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Printer Diagnostics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.green),
                        onPressed: () async {
                          final bytes = await generateDiagnosticsReceipt(settingsInfo);
                          await printReceipt(bytes, {'id': 'DIAG'});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: settingsInfo));
                          Get.snackbar("Copied", "Diagnostic info copied to clipboard", 
                            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.black87, colorText: Colors.white);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    settingsInfo,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      print("Error showing diagnostics: $e");
    }
  }

  Future<List<int>> generateOrderReceipt(Map<String, dynamic> order) async {
    final profile = await CapabilityProfile.load();
    final prefs = await SharedPreferences.getInstance();
    final is80mm = (prefs.getString('paperSize') ?? '58mm') == '80mm';
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header Layout: Logo -> Website -> Line -> Store Name
    try {
      final ByteData data = await rootBundle.load('assets/images/printreceptlogo.png');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final img.Image? image = img.decodeImage(imgBytes);
      if (image != null) {
        bytes += generator.image(image, align: PosAlign.center);
      }
    } catch (e) {
      LoggerService.to.log("Bluetooth Logo Error: $e");
    }

    bytes += generator.text("www.meatwala.co.uk", styles: const PosStyles(align: PosAlign.center));
    // Store Name: Font A, Left, Bold, Double size
    bytes += generator.text("${(order['name'] ?? order['storeName'] ?? 'Meatwala')}", 
        styles: const PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2, width: PosTextSize.size2, fontType: PosFontType.fontA));
    
    bytes += generator.text("Ordered:${order['date']}", styles: const PosStyles(fontType: PosFontType.fontA));
    bytes += generator.text("${(order['type'] ?? 'Delivery')}", 
        styles: const PosStyles(bold: true, height: PosTextSize.size2, fontType: PosFontType.fontA));
    bytes += generator.text("Order No: ${order['id']}", styles: const PosStyles(fontType: PosFontType.fontA));
    bytes += generator.hr(ch: '-');
    
    // Item list
    for (var item in order['items']) {
      bytes += generator.row([
        PosColumn(text: "${item['qty']} x ${item['name']}", width: 9, styles: const PosStyles(fontType: PosFontType.fontA)),
        PosColumn(text: "${item['price']}", width: 3, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
      ]);
      if (item['modifiers'] != null) {
        for (var mod in item['modifiers']) {
          bytes += generator.text("-$mod", styles: const PosStyles(fontType: PosFontType.fontA));
        }
      }
    }

    bytes += generator.hr(ch: '-');
    bytes += generator.row([
      PosColumn(text: "Service Charge:", width: 8, styles: const PosStyles(fontType: PosFontType.fontA)),
      PosColumn(text: "${order['service_charge'] ?? '0.00'}", width: 4, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Delivery Charge:", width: 8, styles: const PosStyles(fontType: PosFontType.fontA)),
      PosColumn(text: "${order['delivery_charge'] ?? '0.00'}", width: 4, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Discount", width: 8, styles: const PosStyles(fontType: PosFontType.fontA)),
      PosColumn(text: "${order['discount'] ?? '0.00'}", width: 4, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
    ]);
    
    // Total
    bytes += generator.row([
      PosColumn(text: "Total:", width: 6, styles: const PosStyles(bold: true, fontType: PosFontType.fontA)),
      PosColumn(text: "${order['total']}", width: 6, styles: const PosStyles(align: PosAlign.right, bold: true, fontType: PosFontType.fontA)),
    ]);
    bytes += generator.hr(ch: '-');

    if (order['customer'] != null) bytes += generator.text("${order['customer']}", styles: const PosStyles(fontType: PosFontType.fontA));
    if (order['address'] != null) bytes += generator.text("${order['address']}", styles: const PosStyles(fontType: PosFontType.fontA));
    if (order['phone'] != null && order['phone'].toString().isNotEmpty) {
      bytes += generator.text("${order['phone']}", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2, fontType: PosFontType.fontA));
    }
    bytes += generator.hr(ch: '-');

    final paymentMode = (order['payment_mode'] ?? 'N/A').toString();
    if (paymentMode.toLowerCase() != 'cash') {
      bytes += generator.text("Order Paid", styles: const PosStyles(bold: true, fontType: PosFontType.fontA));
    }
    bytes += generator.text("Payment: $paymentMode", styles: const PosStyles(fontType: PosFontType.fontA));
    bytes += generator.hr(ch: '-');

    bytes += generator.text("Requested for:", styles: const PosStyles(fontType: PosFontType.fontA));
    final String reqForBytes = (order['requested_for'] != null && order['requested_for'].toString().trim().isNotEmpty) 
        ? order['requested_for'].toString() 
        : 'As soon as possible';
    bytes += generator.text(reqForBytes, 
        styles: const PosStyles(bold: true, height: PosTextSize.size1, fontType: PosFontType.fontA));
    bytes += generator.hr(ch: '-');

    
    bytes += generator.text("Comments:", styles: const PosStyles(fontType: PosFontType.fontA));
    if (order['comments'] != null && order['comments'].toString().isNotEmpty) {
      bytes += generator.text("${order['comments']}", styles: const PosStyles(fontType: PosFontType.fontA));
    }
    bytes += generator.hr(ch: '-');

    if (order['accepted_for'] != null && order['accepted_for'].toString().isNotEmpty) {
       bytes += generator.text("Accepted for:", styles: const PosStyles(fontType: PosFontType.fontA));
       bytes += generator.text("${order['accepted_for']}", styles: const PosStyles(bold: true, height: PosTextSize.size1, fontType: PosFontType.fontA));
       if (order['accepted_time'] != null) bytes += generator.text("${order['accepted_time']}", styles: const PosStyles(fontType: PosFontType.fontA));
       bytes += generator.hr(ch: '-');
    }

    if (order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty) {
       bytes += generator.text("Order Cancel:", styles: const PosStyles(fontType: PosFontType.fontA));
       bytes += generator.text("${order['cancel_reason']}", styles: const PosStyles(bold: true, height: PosTextSize.size1, fontType: PosFontType.fontA));
       bytes += generator.hr(ch: '-');
    }

    bytes += generator.feed(1);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> generateStatusSlip(String orderNo, PrintStatus status, String? info) async {
    final profile = await CapabilityProfile.load();
    final prefs = await SharedPreferences.getInstance();
    final is80mm = (prefs.getString('paperSize') ?? '58mm') == '80mm';
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text("ORDER STATUS UPDATE", styles: const PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA));
    bytes += generator.text("Order No: $orderNo", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA));
    bytes += generator.hr();
    
    if (status == PrintStatus.accepted) {
      bytes += generator.text("ACCEPTED", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, fontType: PosFontType.fontA));
      bytes += generator.text("Preparation Time:", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA));
      bytes += generator.text("${info ?? 'Confirmed'} Minutes", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, fontType: PosFontType.fontA));
    } else if (status == PrintStatus.rejected) {
      bytes += generator.text("REJECTED", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, fontType: PosFontType.fontA));
      bytes += generator.text("Reason:", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA));
      bytes += generator.text("${info ?? 'N/A'}", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, fontType: PosFontType.fontA));
    }

    bytes += generator.hr();
    bytes += generator.text("Meatwala - Fresh Quality Meat", styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    bytes += generator.feed(1);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> generateDiagnosticsReceipt(String info) async {
    final profile = await CapabilityProfile.load();
    final prefs = await SharedPreferences.getInstance();
    final is80mm = (prefs.getString('paperSize') ?? '58mm') == '80mm';
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text("PRINTER DIAGNOSTICS", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text("Date: ${DateTime.now().toString()}", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.text(info, styles: const PosStyles(fontType: PosFontType.fontB));
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  Future<bool> autoPrintOrder(Map<String, dynamic> order, {PrintStatus status = PrintStatus.newOrder, String? extraInfo}) async {
    final orderId = order['id'] ?? 'Unknown';
    LoggerService.to.log("PRINTER AUTO-PRINT: Starting for Order #$orderId (Status: $status)");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final copyCount = prefs.getInt('totalPrint') ?? 1;
      
      List<int> bytes;
      if (status == PrintStatus.newOrder) {
        bytes = await generateOrderReceipt(order);
      } else {
        bytes = await generateStatusSlip(orderId, status, extraInfo);
      }
      
      bool allSuccess = true;
      for (int i = 0; i < copyCount; i++) {
        if (i > 0) await Future.delayed(const Duration(milliseconds: 500));
        LoggerService.to.log("PRINTER AUTO-PRINT: Printing copy ${i + 1} of $copyCount");
        
        final bool success = await printReceipt(bytes, order, status: status, extraInfo: extraInfo)
            .timeout(const Duration(seconds: 15), onTimeout: () {
              LoggerService.to.log("PRINTER TIMEOUT: Order #$orderId copy ${i+1} print operation exceeded 15s");
              return false;
            });
        if (!success) allSuccess = false;
      }
      
      return allSuccess;
    } catch (e) {
      LoggerService.to.log("PRINTER ERROR: Unexpected exception printing Order #$orderId: $e");
      return false;
    }
  }

  Future<void> testPrint() async {
    try {
      final Map<String, dynamic> testOrder = {
        'id': 'TEST-${DateTime.now().millisecond}',
        'date': DateTime.now().toString().split('.')[0],
        'total': '£0.00',
        'items': [
          {'qty': 1, 'name': 'TEST PRINT'},
          {'qty': 1, 'name': 'PRINTER WORKING'},
        ],
      };
      
      final bytes = await generateOrderReceipt(testOrder);
      await printReceipt(bytes, testOrder);
      await showPrinterDiagnostics();
    } catch (e) {
      LoggerService.to.log("Error in testPrint: $e");
      Get.snackbar("Test Failed", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


}
