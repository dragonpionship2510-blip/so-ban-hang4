import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../invoice.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

enum PriceMode { retail, wholesale }

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final items = <OrderItem>[];
  Customer? selectedCustomer;
  int discount = 0;
  int paid = 0;
  PriceMode mode = PriceMode.retail;

  Future<List<Product>> _products() => AppDb().getProducts();
  Future<List<Customer>> _customers() => AppDb().getCustomers();

  int get subtotal => items.fold(0, (s, it) => s + it.price * it.qty);
  int get total => subtotal - discount;
  int get remain => total - paid;

  void _addItem(Product p) {
    final price = mode == PriceMode.retail ? p.priceRetail : p.priceWholesale;
    setState(() {
      items.add(OrderItem(orderId: 'tmp', productId: p.id, qty: 1, price: price));
    });
  }

  void _saveOrderAndPrint() async {
    if (items.isEmpty) return;
    final order = Order(customerId: selectedCustomer?.id, discount: discount, paid: paid);
    final realItems = items.map((it) => OrderItem(orderId: order.id, productId: it.productId, qty: it.qty, price: it.price)).toList();
    await AppDb().createOrder(order, realItems);

    final products = await AppDb().getProductMap();
    final customer = order.customerId == null ? null : await AppDb().getCustomer(order.customerId!);
    final pdfBytes = await buildInvoice(order, realItems, products, customer);
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);

    setState(() {
      items.clear();
      selectedCustomer = null;
      discount = 0;
      paid = 0;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu đơn & in hóa đơn')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chọn khách hàng + chế độ giá
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              FutureBuilder(
                future: _customers(),
                builder: (_, snap) {
                  final cs = snap.data ?? <Customer>[];
                  return DropdownButtonFormField<Customer?>(
                    value: selectedCustomer,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Khách lẻ')),
                      ...cs.map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    ],
                    onChanged: (v) => setState(() => selectedCustomer = v),
                    decoration: const InputDecoration(labelText: 'Khách hàng'),
                  );
                },
              ),
              const SizedBox(height: 8),
              SegmentedButton<PriceMode>(
                segments: const [
                  ButtonSegment(value: PriceMode.retail, label: Text('Giá lẻ'), icon: Icon(Icons.sell_outlined)),
                  ButtonSegment(value: PriceMode.wholesale, label: Text('Giá sỉ'), icon: Icon(Icons.local_offer_outlined)),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setState(() => mode = s.first),
              ),
            ],
          ),
        ),

        // danh sách mặt hàng trong đơn
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = items[i];
              return ListTile(
                title: FutureBuilder(
                  future: AppDb().db.then((d) => d.query('products', where: 'id=?', whereArgs: [it.productId])).then((r) => r.first),
                  builder: (_, snap) => Text((snap.data?['name'] as String?) ?? '...'),
                ),
                subtitle: Text('SL: ${it.qty} · Giá: ${NumberFormat.decimalPattern('vi_VN').format(it.price)}'),
                trailing: SizedBox(
                  width: 180,
                  child: Row(children: [
                    IconButton(onPressed: () => setState(() => it.qty = (it.qty > 1 ? it.qty - 1 : 1)), icon: const Icon(Icons.remove_circle_outline)),
                    Text('${it.qty}'),
                    IconButton(onPressed: () => setState(() => it.qty++), icon: const Icon(Icons.add_circle_outline)),
                    IconButton(onPressed: () => setState(() => items.removeAt(i)), icon: const Icon(Icons.delete_outline)),
                  ]),
                ),
              );
            },
          ),
        ),

        // chọn sản phẩm để thêm
        Padding(
          padding: const EdgeInsets.all(8),
          child: FutureBuilder(
            future: _products(),
            builder: (_, snap) {
              final ps = snap.data ?? <Product>[];
              return Autocomplete<Product>(
                displayStringForOption: (p) => '${p.name} (${mode == PriceMode.retail ? p.priceRetail : p.priceWholesale})',
                optionsBuilder: (t) => ps.where((p) => p.name.toLowerCase().contains(t.text.toLowerCase())),
                onSelected: _addItem,
                fieldViewBuilder: (ctx, c, f, s) => TextField(controller: c, focusNode: f, decoration: const InputDecoration(labelText: 'Thêm sản phẩm...')),
              );
            },
          ),
        ),

        // tổng kết + thanh toán + in
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tạm tính: ${NumberFormat.decimalPattern('vi_VN').format(subtotal)}  ·  Giảm: ${discount}  ·  Tổng: ${NumberFormat.decimalPattern('vi_VN').format(total)}  ·  Còn lại: ${NumberFormat.decimalPattern('vi_VN').format(remain)}'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Giảm giá (VND)'), keyboardType: TextInputType.number, onChanged: (v) => setState(() => discount = int.tryParse(v) ?? 0))),
                const SizedBox(width: 8),
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Đã thu (VND)'), keyboardType: TextInputType.number, onChanged: (v) => setState(() => paid = int.tryParse(v) ?? 0))),
              ]),
              const SizedBox(height: 8),
              FilledButton.icon(onPressed: _saveOrderAndPrint, icon: const Icon(Icons.print), label: const Text('Lưu & In hóa đơn')),
            ],
          ),
        ),
      ],
    );
  }
}
