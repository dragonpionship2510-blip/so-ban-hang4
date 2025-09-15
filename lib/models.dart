import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Product {
  final String id;
  String name;
  String sku;
  int priceRetail;
  int priceWholesale;
  int cost; // giá vốn
  int stock; // tồn kho

  Product({
    String? id,
    required this.name,
    this.sku = '',
    this.priceRetail = 0,
    this.priceWholesale = 0,
    this.cost = 0,
    this.stock = 0,
  }) : id = id ?? _uuid.v4();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'sku': sku,
        'priceRetail': priceRetail,
        'priceWholesale': priceWholesale,
        'cost': cost,
        'stock': stock,
      };

  static Product fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        sku: (m['sku'] ?? '') as String,
        priceRetail: (m['priceRetail'] ?? 0) as int,
        priceWholesale: (m['priceWholesale'] ?? 0) as int,
        cost: (m['cost'] ?? 0) as int,
        stock: (m['stock'] ?? 0) as int,
      );
}

class Customer {
  final String id;
  String name;
  String phone;
  String address;
  int debt; // nợ dương = KH còn nợ shop

  Customer({
    String? id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.debt = 0,
  }) : id = id ?? _uuid.v4();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'debt': debt,
      };

  static Customer fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        phone: (m['phone'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        debt: (m['debt'] ?? 0) as int,
      );
}

class OrderItem {
  final String id;
  String orderId;
  String productId;
  int qty;
  int price;

  OrderItem({
    String? id,
    required this.orderId,
    required this.productId,
    required this.qty,
    required this.price,
  }) : id = id ?? _uuid.v4();

  Map<String, Object?> toMap() => {
        'id': id,
        'orderId': orderId,
        'productId': productId,
        'qty': qty,
        'price': price,
      };
}

class Order {
  final String id;
  DateTime createdAt;
  String? customerId; // có thể null – bán lẻ
  int discount; // VND
  int paid; // đã thu

  Order({
    String? id,
    DateTime? createdAt,
    this.customerId,
    this.discount = 0,
    this.paid = 0,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'customerId': customerId,
        'discount': discount,
        'paid': paid,
      };

  static Order fromMap(Map<String, Object?> m) => Order(
        id: m['id'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        customerId: m['customerId'] as String?,
        discount: (m['discount'] ?? 0) as int,
        paid: (m['paid'] ?? 0) as int,
      );
}
