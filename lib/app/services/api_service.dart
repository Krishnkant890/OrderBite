import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../data/models/order_model.dart';
import '../data/models/print_settings.dart';
import 'logger_service.dart';


class ApiService {
  final http.Client _client = http.Client();

  Future<List<OrderModel>> getPendingOrders(PrintSettings settings) async {
    List<OrderModel> orders = [];
    try {
      final String url = "${settings.apiUrl}/api/v1/pendingorder?a=${settings.storeId}&u=${settings.userId}&p=${settings.password}";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(Uri.parse(url));
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode != 200 && response.statusCode != 206) return orders;

      final String apiText = response.body;
      if (apiText.isEmpty) return orders;

      // Handle JSON response
      if (apiText.trim().startsWith('{')) {
        try {
          final data = jsonDecode(apiText);
          if (data['orderlists'] != null) {
            final list = data['orderlists'] as List;
            for (var item in list) {
              orders.add(_parseJsonOrder(item));
            }
          }
          return orders;
        } catch (e) {
          print("Error parsing JSON pending orders: $e");
        }
      }

      // Handle legacy string response
      final List<String> rawOrders = apiText.split(RegExp(r'[\n\r]+'));
      for (var raw in rawOrders) {
        if (raw.trim().isEmpty) continue;
        final parsed = _parseOrder(raw);
        if (parsed != null) {
          orders.add(parsed);
        }
      }
    } catch (e) {
      LoggerService.to.log("ApiService Error: $e");
    }

    return orders;
  }

  OrderModel _parseJsonOrder(Map<String, dynamic> json) {
    return OrderModel(
      storeName: json['restname']?.toString() ?? "",
      orderDate: json['orderdate']?.toString() ?? "",
      orderType: json['ordertype']?.toString() ?? "",
      orderNo: json['orderid']?.toString() ?? "",
      customerName: json['custname']?.toString() ?? "Walk-In",
      address: json['deliveryaddress']?.toString() ?? "",
      phone: json['custmobile']?.toString() ?? "",
      paymentMode: json['paymentmode']?.toString() ?? "",
      total: double.tryParse(json['netpayamount']?.toString() ?? "0") ?? 0.0,
      serviceCharge: double.tryParse(json['servicecharges']?.toString() ?? "0") ?? 0.0,
      deliveryCharge: double.tryParse(json['deliverycharges']?.toString() ?? "0") ?? 0.0,
      discount: double.tryParse(json['coupondiscount']?.toString() ?? "0") ?? 0.0,
      requestedFor: json['customerreqtime']?.toString() ?? "As soon as possible",
      items: [], // JSON snippet doesn't show items, would need another field if available
    );
  }

  OrderModel? _parseOrder(String raw) {
    try {
      String trimmedRaw = raw.trim();
      if (!trimmedRaw.startsWith("#") || !trimmedRaw.endsWith("#")) return null;

      trimmedRaw = trimmedRaw.replaceAll("#", "");
      final List<String> parts = trimmedRaw.split(';');

      String safe(int i) => i < parts.length ? parts[i].trim() : "";

      // ===== HEADER =====
      // Date format in C#: "dd-MM-yy hh:mm tt"
      String dateStr = safe(1);
      String formattedDate = "";
      try {
        DateTime date = DateFormat("dd-MM-yy hh:mm a").parse(dateStr);
        formattedDate = DateFormat("dd-MM-yyyy HH:mm").format(date);
      } catch (e) {
        formattedDate = dateStr; // Fallback
      }

      final order = OrderModel(
        storeName: safe(0).replaceFirst(RegExp(r'^\d+\*'), '').trim(),
        orderDate: formattedDate,
        orderType: safe(2),
        orderNo: _extractOrderNo(safe(3)),
      );

      int index = 3;

      // ===== ITEMS =====
      while (index < parts.length) {
        if (_isChargeStart(parts, index)) break;

        final item = OrderItem();
        String value = safe(index);

        if (value.startsWith("*")) {
          final split = value.split('*').where((s) => s.isNotEmpty).toList();
          if (split.isNotEmpty) {
            item.qty = _parseInt(split.length >= 2 ? split[1] : split[0], 1);
          }
        } else {
          item.qty = _parseInt(value, 1);
        }

        item.name = safe(index + 1);
        item.price = _parseDecimal(safe(index + 2));

        String mod = safe(index + 3);
        if (mod.isNotEmpty) {
          item.modifiers.addAll(
            mod.replaceAll("&", ",")
               .split(',')
               .where((s) => s.trim().isNotEmpty)
               .map((s) => s.trim()),
          );
        }

        order.items.add(item);
        index += 4;
      }

      // ===== CHARGES =====
      order.serviceCharge = _parseDecimal(safe(index));
      order.deliveryCharge = _parseDecimal(safe(index + 1));
      order.discount = _parseDecimal(safe(index + 2));
      order.total = _parseDecimal(safe(index + 3));

      // ===== CUSTOMER =====
      order.customerName = safe(index + 4);
      order.address = safe(index + 5);

      // dynamic detection (safe)
      order.phone = parts.firstWhere((x) => x.contains("+"), orElse: () => "");
      
      order.paymentMode = parts.firstWhere(
        (x) => x.toLowerCase() == "cash" || x.toLowerCase() == "card",
        orElse: () => "",
      );

      order.requestedFor = parts.firstWhere(
        (x) => x.toLowerCase().contains("soon") || x.toLowerCase().contains("min"),
        orElse: () => "",
      );

      order.previousOrder = safe(index + 12).replaceAll("*", "").trim();
      order.comments = safe(index + 13);

      return order;
    } catch (e) {
      print("ParseOrder Error: $e");
      return null;
    }
  }

  bool _isChargeStart(List<String> parts, int index) {
    if (index + 3 >= parts.length) return false;
    return _isDecimal(parts[index]) &&
           _isDecimal(parts[index + 1]) &&
           _isDecimal(parts[index + 2]) &&
           _isDecimal(parts[index + 3]) &&
           parts[index].trim().startsWith("*");
  }

  bool _isDecimal(String value) {
    value = value.replaceAll("*", "").trim();
    return double.tryParse(value) != null;
  }

  String _extractOrderNo(String value) {
    if (value.isEmpty) return "";
    final split = value.split('*').where((s) => s.isNotEmpty).toList();
    return split.isNotEmpty ? split[0] : value;
  }

  int _parseInt(String val, int defaultValue) {
    val = val.replaceAll("*", "").trim();
    return int.tryParse(val) ?? defaultValue;
  }

  double _parseDecimal(String val) {
    val = val.replaceAll("*", "").trim();
    return double.tryParse(val) ?? 0.0;
  }

  Future<bool> acceptOrder(String orderNo, int minutes, PrintSettings settings) async {
    try {
      String sdesc = "${minutes}_ok";
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      String datetime = "${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:00";

      final String url = "${settings.apiUrl}/api/v1/confirmorder?a=${settings.storeId}&o=$orderNo&ak=Accepted&m=$sdesc&dt=$datetime&u=${settings.userName}&p=${settings.password}";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(Uri.parse(url));
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> acceptOrder() Error: $e");
      return false;
    }
  }

  Future<bool> rejectOrder(String orderNo, String reason, PrintSettings settings) async {
    try {
      final String url = "${settings.apiUrl}/api/v1/confirmorder?a=${settings.storeId}&o=$orderNo&ak=Rejected&m=$reason&dt=0&u=${settings.userName}&p=${settings.password}";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(Uri.parse(url));
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> rejectOrder() Error: $e");
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderNo, PrintSettings settings, String status, String desc) async {
    try {
      final String url = "${settings.apiUrl}/api/v1/confirmorder?a=${settings.storeId}&o=$orderNo&ak=$status&m=$desc&dt=0&u=${settings.userName}&p=${settings.password}";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(Uri.parse(url));
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> updateOrderStatus() Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password, String apiUrl) async {
    try {
      final loginObj = {'email': email, 'password': password};
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/restologin, Body: $loginObj");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/restologin"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginObj),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("ApiService -> login() Auth Error: Status Code: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("ApiService -> login() Exception: $e");
    }
    return null;
  }

  Future<List<dynamic>> getRestaurantOrderList({
    required String storeId,
    required String fromDate,
    required String toDate,
    required String apiUrl,
    String type = "0",
    String reason = "",
    String time = "",
    String orderType = "1",
    String paymentMode = "1",
    String status = "",
  }) async {
    try {
      final body = {
        "pkid": storeId,
        "type": type,
        "reason": reason,
        "time": time,
        "ordertype": orderType,
        "paymentmode": paymentMode,
        "status": status,
        "fromdate": fromDate,
        "todate": toDate
      };
      
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/getrestaurantorderlist, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/getrestaurantorderlist"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200 || response.statusCode == 206) {
        final apiText = response.body.trim();
        if (apiText.startsWith('{')) {
          final data = jsonDecode(apiText);
          if (data is List) return data;
          if (data is Map) {
            if (data.containsKey('orderlists')) return data['orderlists'] as List;
            if (data.containsKey('data')) return data['data'] as List;
            return [data];
          }
        } else if (apiText.startsWith('#')) {
          final List<String> rawOrders = apiText.split(RegExp(r'[\n\r]+'));
          final List<dynamic> results = [];
          for (String raw in rawOrders) {
            final order = _parseOrder(raw);
            if (order != null) results.add(order.toMap());
          }
          return results;
        }
      }
    } catch (e) {
      print("ApiService -> getRestaurantOrderList() Error: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getOrderDataById({
    required String orderId,
    required String apiUrl,
  }) async {
    try {
      final body = {
        "pkid": orderId,
        "type": ""
      };
      
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/getorderdatabyid, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/getorderdatabyid"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200 || response.statusCode == 206) {
        final apiText = response.body.trim();
        if (apiText.startsWith('{')) {
          final data = jsonDecode(apiText);
          if (data is Map && data.containsKey('orderlists') && (data['orderlists'] as List).isNotEmpty) {
            final orderInfo = Map<String, dynamic>.from(data['orderlists'][0]);
            if (data.containsKey('orderdetail')) {
              orderInfo['orderdetails'] = data['orderdetail'];
            }
            return orderInfo;
          }
          return data;
        } else if (apiText.startsWith('#')) {
          // Parse legacy string format
          final order = _parseOrder(apiText);
          return order?.toMap();
        }
      }
    } catch (e) {
      print("ApiService -> getOrderDataById() Error: $e");
    }
    return null;
  }

  // ===== NEWLY INTEGRATED APIS FROM SWAGGER =====

  Future<bool> changeOrderStatus({
    required String pkid,
    required String status,
    required String apiUrl,
  }) async {
    try {
      final body = {
        "pkid": pkid,
        "status": status,
        "type": "",
        "reason": "",
        "time": "",
        "ordertype": "",
        "paymentmode": "",
        "todate": "",
        "fromdate": ""
      };
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/changeorderstatus, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/changeorderstatus"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> changeOrderStatus() Error: $e");
      return false;
    }
  }

  Future<bool> refundOrder({
    required String orderId,
    required String refundAmt,
    required String apiUrl,
  }) async {
    try {
      final body = {
        "orderid": orderId,
        "status": "Refund",
        "cancelby": "Restaurant",
        "refundamt": refundAmt,
        "type": ""
      };
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/orderrefund, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/orderrefund"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> refundOrder() Error: $e");
      return false;
    }
  }

  Future<List<dynamic>> getRestaurantMenuList({
    required String storeId,
    required String apiUrl,
  }) async {
    try {
      final body = {"restid": storeId};
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/getrestaurantmenulist, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/getrestaurantmenulist"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('data')) return data['data'];
        return [data];
      }
    } catch (e) {
      print("ApiService -> getRestaurantMenuList() Error: $e");
    }
    return [];
  }

  Future<bool> updateItemAvailability({
    required String itemId,
    required bool isAvailable,
    required String apiUrl,
  }) async {
    try {
      final body = {
        "pkid": itemId,
        "status": isAvailable ? "1" : "0"
      };
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/updateisactive, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/updateisactive"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> updateItemAvailability() Error: $e");
      return false;
    }
  }

  Future<List<dynamic>> getCouponList({
    required String storeId,
    required String apiUrl,
  }) async {
    try {
      final body = {"restid": storeId};
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/getcouponlist, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/getcouponlist"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('data')) return data['data'];
        return [data];
      }
    } catch (e) {
      print("ApiService -> getCouponList() Error: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getRestaurantDashboard({
    required String storeId,
    required String apiUrl,
  }) async {
    try {
      final body = {"restid": storeId};
      LoggerService.to.log("API REQUEST: POST $apiUrl/api/restaurantmaster/getrestdashboard, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/restaurantmaster/getrestdashboard"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("ApiService -> getRestaurantDashboard() Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRestaurantOpenCloseTime({
    required String storeId,
    required String apiUrl,
  }) async {
    try {
      final String url = "$apiUrl/api/restaurantmaster/GetRestaurantOpenCloseTimeDetails?restid=$storeId";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(Uri.parse(url));
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("ApiService -> getRestaurantOpenCloseTime() Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> savePrintingSettings({
    required String storeId,
    required String printerType,
    required String paperSize,
    required bool autoPrint,
    required int timeout,
    required int totalPrint,
    required String selectedDeviceMac,
    required String selectedDeviceName,
    required String status,
    required String printerStatus,
    required String music,
    required bool isPageHeader,
    required String setHeadercontent,
    required bool isPagefooter,
    required String setDateFormate,
    required String setTimeFormate,
    required bool isPrintDateTime,
    required String apiUrl,
  }) async {
    try {
      final body = {
        "restaurantId": int.tryParse(storeId) ?? 0,
        "status": status,
        "printerStatus": printerStatus,
        "printerType": printerType,
        "paperSize": paperSize,
        "autoPrint": autoPrint,
        "totalPrint": totalPrint,
        "timeoutseconds": timeout,
        "music": music,
        "isPageHeader": isPageHeader,
        "setHeadercontent": setHeadercontent,
        "isPagefooter": isPagefooter,
        "setDateFormate": setDateFormate,
        "setTimeFormate": setTimeFormate,
        "isPrintDateTime": isPrintDateTime,
        "deviceMACAddress": selectedDeviceMac
      };

      LoggerService.to.log("API REQUEST: POST $apiUrl/api/PrintingSettings/SavePrintingSettings, Body: $body");

      final response = await _client.post(
        Uri.parse("$apiUrl/api/PrintingSettings/SavePrintingSettings"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("ApiService -> savePrintingSettings() Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPrintingSettings({
    required String storeId,
    required String apiUrl,
  }) async {
    try {
      final String url = "$apiUrl/api/PrintingSettings/GetPrintingSettings?restaurantId=$storeId";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(
        Uri.parse(url),
        headers: {'accept': '*/*'},
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0];
        } else if (data is Map) {
          return data as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("ApiService -> getPrintingSettings() Error: $e");
    }
    return null;
  }
  Future<bool> saveLog({
    required String storeId,
    required File logFile,
    required String apiUrl,
  }) async {
    try {
      final url = Uri.parse("$apiUrl/api/PrintingSettings/SaveLog");
      final request = http.MultipartRequest('POST', url);
      
      request.fields['RestaurantId'] = storeId;
      request.files.add(await http.MultipartFile.fromPath('logFile', logFile.path));
      
      LoggerService.to.log("API REQUEST: POST $url, RestaurantId: $storeId, File: ${logFile.path}");
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");
      
      return response.statusCode == 200;
    } catch (e) {
      print("ApiService -> saveLog() Error: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPrintingAppMusic({
    required String apiUrl,
  }) async {
    try {
      final String url = "$apiUrl/api/PrintingSettings/GetPrintingAppMusic";
      LoggerService.to.log("API REQUEST: GET $url");

      final response = await _client.get(
        Uri.parse(url),
        headers: {'accept': '*/*'},
      );
      LoggerService.to.log("API RESPONSE: Status ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      print("ApiService -> getPrintingAppMusic() Error: $e");
    }
    return [];
  }
}
