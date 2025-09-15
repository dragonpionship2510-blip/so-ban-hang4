import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class AppDb {
  static final AppDb _i = AppDb._();
  AppDb._();
  factory AppDb() => _i;

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<bool> _hasColumn(Database d, String table, String column) async {
    final info = await d.rawQuery("PRAGMA table_info($table)");
    return info.any((row) => row['name'] == column);
  }

  Future<Database> _open() async {
    final p = join(await getDatabasesPath(), 'so_ban_hang.db');
    return openDatabase(p, version: 2, onCreate: (d, v) async {
      await d.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT,
        priceRetail INTEGER,
        priceWholesale INTEGER,
        cost INTEGER,
        stock INTEGER
      );
      ''');
      await d.execute('''
      CREATE TABLE customers(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        debt INTEGER
      );
      ''');
      await d.execute('''
      CREATE TABLE orders(
        id TEXT PRIMARY KEY,
        createdAt INTEGER,
        customerId TEXT,
        discount INTEGER,
        paid INTEGER
      );
      ''');
      await d.execute('''
      CREATE TABLE order_items(
        id TEXT PRIMARY KEY,
        orderId TEXT,
        productId TEXT,
        qty INTEGER,
        price INTEGER
      );
      ''');
    }, onUpgrade: (d, oldV, newV) async {
      if (oldV < 2) {
        // migrate products to have new columns
        if (!await _hasColumn(d, 'products', 'priceRetail')) {
          await d.execute("ALTER TABLE products ADD COLUMN priceRetail INTEGER DEFAULT 0");
        }
        if (!await _hasColumn(d, 'products', 'priceWholesale')) {
          await d.execute("ALTER TABLE products ADD COLUMN priceWholesale INTEGER DEFAULT 0");
        }
        if (!await _hasColumn(d, 'products', 'cost')) {
          await d.execute("ALTER TABLE products ADD COLUMN cost INTEGER DEFAULT 0");
        }
        if (!await _hasColumn(d, 'products', 'stock')) {
          await d.execute("ALTER TABLE products ADD COLUMN stock INTEGER DEFAULT 0");
        }
      }
    });
  }

  // Products
  Future<List<Product>> getProducts() async {
    final d = await db;
    final rows = await d.query('products', orderBy: 'name');
    return rows.map((e) => Product.fromMap(e)).toList();
  }

  Future<Map<String, Product>> getProductMap() async {
    final list = await getProducts();
    return { for (final p in list) p.id : p };
  }

  Future<void> upsertProduct(Product p) async {
    final d = await db;
    await d.insert('products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProduct(String id) async {
    final d = await db;
    await d.delete('products', where: 'id=?', whereArgs: [id]);
  }

  // Customers
  Future<List<Customer>> getCustomers() async {
    final d = await db;
    final rows = await d.query('customers', orderBy: 'name');
    return rows.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final d = await db;
    final rows = await d.query('customers', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<void> upsertCustomer(Customer c) async {
    final d = await db;
    await d.insert('customers', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCustomer(String id) async {
    final d = await db;
    await d.delete('customers', where: 'id=?', whereArgs: [id]);
  }

  // Orders
  Future<void> createOrder(Order o, List<OrderItem> items) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.insert('orders', o.toMap());
      for (final it in items) {
        await txn.insert('order_items', it.toMap());
        // giảm tồn kho
        await txn.rawUpdate('UPDATE products SET stock = stock - ? WHERE id=?', [it.qty, it.productId]);
      }
      final total = await _calcOrderSubtotal(items) - o.discount;
      final remain = total - o.paid;
      if (o.customerId != null && remain != 0) {
        // cập nhật công nợ KH
        await txn.rawUpdate('UPDATE customers SET debt = debt + ? WHERE id=?', [remain, o.customerId]);
      }
    });
  }

  Future<int> _calcOrderSubtotal(List<OrderItem> items) async {
    int s = 0;
    for (final it in items) {
      s += it.price * it.qty;
    }
    return s;
  }

  Future<Map<String, Object>> dailyReport(DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    final ordersRows = await d.rawQuery('SELECT id, discount, paid FROM orders WHERE createdAt BETWEEN ? AND ?', [start, end]);
    int orders = ordersRows.length;
    int revenue = 0;
    int collected = 0;
    int profit = 0;

    for (final r in ordersRows) {
      final orderId = r['id'] as String;
      final itRows = await d.query('order_items', where: 'orderId=?', whereArgs: [orderId]);
      int subtotal = 0;
      int orderProfit = 0;
      for (final it in itRows) {
        final price = it['price'] as int;
        final qty = it['qty'] as int;
        subtotal += price * qty;
        // get cost for product
        final p = await d.query('products', columns: ['cost'], where: 'id=?', whereArgs: [it['productId']]);
        final cost = p.isEmpty ? 0 : (p.first['cost'] as int);
        orderProfit += (price - cost) * qty;
      }
      revenue += subtotal - (r['discount'] as int);
      orderProfit -= (r['discount'] as int); // discount giảm lợi nhuận
      profit += orderProfit;
      collected += (r['paid'] as int);
    }
    return {
      'orders': orders,
      'revenue': revenue,
      'collected': collected,
      'profit': profit,
    };
  }
}
