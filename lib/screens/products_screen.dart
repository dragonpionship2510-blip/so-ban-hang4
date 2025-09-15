import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await AppDb().getProducts();
    setState(() {});
  }

  void _openForm([Product? p]) async {
    final nameC = TextEditingController(text: p?.name ?? '');
    final skuC = TextEditingController(text: p?.sku ?? '');
    final retailC = TextEditingController(text: (p?.priceRetail ?? 0).toString());
    final wholesaleC = TextEditingController(text: (p?.priceWholesale ?? 0).toString());
    final costC = TextEditingController(text: (p?.cost ?? 0).toString());
    final stockC = TextEditingController(text: (p?.stock ?? 0).toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Tên')), 
              TextField(controller: skuC, decoration: const InputDecoration(labelText: 'SKU')),
              TextField(controller: retailC, decoration: const InputDecoration(labelText: 'Giá lẻ'), keyboardType: TextInputType.number),
              TextField(controller: wholesaleC, decoration: const InputDecoration(labelText: 'Giá sỉ'), keyboardType: TextInputType.number),
              TextField(controller: costC, decoration: const InputDecoration(labelText: 'Giá vốn'), keyboardType: TextInputType.number),
              TextField(controller: stockC, decoration: const InputDecoration(labelText: 'Tồn kho'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );

    if (ok == true) {
      final np = Product(
        id: p?.id,
        name: nameC.text.trim(),
        sku: skuC.text.trim(),
        priceRetail: int.tryParse(retailC.text) ?? 0,
        priceWholesale: int.tryParse(wholesaleC.text) ?? 0,
        cost: int.tryParse(costC.text) ?? 0,
        stock: int.tryParse(stockC.text) ?? 0,
      );
      await AppDb().upsertProduct(np);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = items[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text('SKU: ${p.sku} · Lẻ: ${p.priceRetail} · Sỉ: ${p.priceWholesale} · Vốn: ${p.cost} · Tồn: ${p.stock}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(p)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await AppDb().deleteProduct(p.id); _load(); }),
              ]),
            );
          },
        ),
      ),
    );
  }
}
