import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await AppDb().getCustomers();
    setState(() {});
  }

  void _openForm([Customer? c]) async {
    final nameC = TextEditingController(text: c?.name ?? '');
    final phoneC = TextEditingController(text: c?.phone ?? '');
    final addrC = TextEditingController(text: c?.address ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c == null ? 'Thêm khách hàng' : 'Sửa khách hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Tên')), 
              TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Điện thoại')),
              TextField(controller: addrC, decoration: const InputDecoration(labelText: 'Địa chỉ')),
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
      final nc = Customer(
        id: c?.id,
        name: nameC.text.trim(),
        phone: phoneC.text.trim(),
        address: addrC.text.trim(),
        debt: c?.debt ?? 0,
      );
      await AppDb().upsertCustomer(nc);
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
            final c = items[i];
            return ListTile(
              title: Text(c.name),
              subtitle: Text('SĐT: ${c.phone} · Nợ: ${c.debt}'),
              onTap: () => _openForm(c),
            );
          },
        ),
      ),
    );
  }
}
