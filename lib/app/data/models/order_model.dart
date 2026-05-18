class OrderModel {
  String? storeName;
  String? orderDate;
  String? orderType;
  String? orderNo;
  List<OrderItem> items;
  double serviceCharge;
  double deliveryCharge;
  double discount;
  double total;
  String? customerName;
  String? address;
  String? phone;
  String? paymentMode;
  String? requestedFor;
  String? previousOrder;
  String? comments;

  OrderModel({
    this.storeName,
    this.orderDate,
    this.orderType,
    this.orderNo,
    List<OrderItem>? items,
    this.serviceCharge = 0,
    this.deliveryCharge = 0,
    this.discount = 0,
    this.total = 0,
    this.customerName,
    this.address,
    this.phone,
    this.paymentMode,
    this.requestedFor,
    this.previousOrder,
    this.comments,
  }) : items = items ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': orderNo ?? "0000",
      'orderid': orderNo ?? "0000",
      'storeName': storeName ?? "",
      'date': orderDate ?? "",
      'time': orderDate ?? "", // Satisfy OrderCard time requirement
      'type': orderType ?? 'Order',
      'customer': customerName ?? "Walk-In",
      'address': address ?? "",
      'phone': phone ?? "",
      'total': '£${total.toStringAsFixed(2)}',
      'service_charge': '£${serviceCharge.toStringAsFixed(2)}',
      'delivery_charge': '£${deliveryCharge.toStringAsFixed(2)}',
      'discount': '£${discount.toStringAsFixed(2)}',
      'payment_mode': paymentMode ?? 'Cash',
      'requested_for': requestedFor ?? 'As soon as possible',
      'previous_order': previousOrder ?? '0',
      'comments': comments ?? "",
      'items': items.map((i) => {
        'name': i.name ?? "Item", 
        'qty': i.qty, 
        'price': '£${i.price.toStringAsFixed(2)}',
        'modifiers': i.modifiers,
      }).toList(),
    };
  }
}

class OrderItem {
  int qty;
  String? name;
  double price;
  List<String> modifiers;

  OrderItem({
    this.qty = 1,
    this.name,
    this.price = 0,
    List<String>? modifiers,
  }) : modifiers = modifiers ?? [];
}
