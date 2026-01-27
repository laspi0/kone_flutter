import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models.dart'; // Assuming models.dart contains Sale, SaleItem, Product, Category, Client

class PdfService {
  Future<Uint8List> generateInvoicePdf(
      Sale sale, List<SaleItem> saleItems, Customer? customer, ShopInfo shopInfo) async {
    final pdf = pw.Document();

    final formatCurrency = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 3000 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('FACTURE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Divider(),
                pw.SizedBox(height: 5),

                // Shop Info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(shopInfo.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(shopInfo.address, style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Tel: ${shopInfo.phone}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Email: ${shopInfo.email}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Invoice & Client Details
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Facture N°: ${sale.id}', style: const pw.TextStyle(fontSize: 10)),
                    if (customer != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text('Client:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.name, style: const pw.TextStyle(fontSize: 10)),
                      if (customer.phone != null && customer.phone!.isNotEmpty)
                        pw.Text('Tél: ${customer.phone!}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Items List
                ...saleItems.map((item) {
                  return pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(item.productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Text(formatCurrency.format(item.subtotal), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${item.quantity} x ${formatCurrency.format(item.unitPrice)}', style: const pw.TextStyle(fontSize: 8)),
                          // pw.Text(formatCurrency.format(item.subtotal), style: const pw.TextStyle(fontSize: 8)), // Already above
                        ],
                      ),
                      pw.SizedBox(height: 5),
                    ],
                  );
                }),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Total
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total HT:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(formatCurrency.format(sale.total), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TVA (0%):', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(formatCurrency.format(0), style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL À PAYER:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(formatCurrency.format(sale.total), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Footer
                pw.Center(
                  child: pw.Text('Merci pour votre achat !', style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text('Powered by Shop Manager', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
