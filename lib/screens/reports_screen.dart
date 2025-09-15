import 'package:flutter/material.dart';
import '../db.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime day = DateTime.now();
  Map<String, Object>? data;

  Future<void> _load() async {
    data = await AppDb().dailyReport(day);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(df.format(day)),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: day);
                  if (d != null) { setState(() => day = d); _load(); }
                },
                child: const Text('Chọn ngày'),
              ),
            ],
          ),
        ),
        if (data == null) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()) else
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _tile('Số đơn', '${data!['orders']}'),
              _tile('Doanh thu', NumberFormat.decimalPattern('vi_VN').format(data!['revenue'] as int)),
              _tile('Đã thu', NumberFormat.decimalPattern('vi_VN').format(data!['collected'] as int)),
              _tile('Lợi nhuận (ước tính)', NumberFormat.decimalPattern('vi_VN').format(data!['profit'] as int)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(String a, String b) => ListTile(title: Text(a), trailing: Text(b, style: const TextStyle(fontWeight: FontWeight.bold)));
}
