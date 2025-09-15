import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'customers_screen.dart';
import 'sales_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = const [SalesScreen(), ProductsScreen(), CustomersScreen(), ReportsScreen()];
    final titles = ['Bán hàng', 'Sản phẩm', 'Khách hàng', 'Báo cáo'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_idx])),
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Bán hàng'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Sản phẩm'),
          NavigationDestination(icon: Icon(Icons.people_alt), label: 'Khách hàng'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
        ],
        onDestinationSelected: (i) => setState(() => _idx = i),
      ),
    );
  }
}
