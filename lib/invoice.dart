import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'models.dart';
import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

String money(int v) => _vnd.format(v);

Future<Uint8List> buildInvoice(Order order, List<OrderItem> items, Map<String, Product> products, Customer? customer) async {
  final pdf = pw.Document();
  final created = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
  int subtotal = 0;
  for (final it in items) {
    subtotal += it.price * it.qty;
  }
  final total = subtotal - order.discount;
  final remain = total - order.paid;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('HÓA ĐƠN BÁN HÀNG', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Ngày: $created'),
            if (customer != null) pw.Text('Khách hàng: ${customer.name} - ${customer.phone}'),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Sản phẩm', 'SL', 'Đơn giá', 'Thành tiền'],
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              data: items.map((it) {
                final p = products[it.productId];
                final line = it.price * it.qty;
                return [p?.name ?? '', it.qty.toString(), money(it.price), money(line)];
              }).toList(),
              cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
            ),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Tạm tính: ${money(subtotal)}')]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Giảm giá: ${money(order.discount)}')]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Tổng: ${money(total)}')]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Đã thu: ${money(order.paid)}')]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Còn lại: ${money(remain)}')]),
            pw.SizedBox(height: 24),
            pw.Text('Cảm ơn Quý khách!'),
          ],
        );
      },
    ),
  );
  return pdf.save();
}
