import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models.dart'; // Assuming models.dart contains Sale, SaleItem, Product, Category, Client

class PdfService {
  Future<Uint8List> generateInvoicePdf(
      Sale sale, List<SaleItem> saleItems, Customer? customer) async {
    final pdf = pw.Document();

    final formatCurrency = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FACTURE',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Shop Manager',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Adresse du magasin, Ville, Pays'), // Placeholder
                        pw.Text('Téléphone: +123 456 7890'), // Placeholder
                        pw.Text('Email: contact@shopmanager.com'), // Placeholder
                      ],
                    ),
                                          // pw.Image(
                                          //   pw.MemoryImage(
                                          //     // Replace with your logo image if available
                                          //     Uint8List.fromList([]),
                                          //   ),
                                          //   height: 50,
                                          // ),
                                          pw.SizedBox(height: 50, width: 50), // Placeholder to maintain layout
                                        ],
                                      ),                pw.Divider(),
                pw.SizedBox(height: 20),

                // Invoice Details & Client Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Facture N°: ${sale.id}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}'),
                      ],
                    ),
                    if (customer != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Client:',
                              style: pw.TextStyle(
                                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text(customer.name),
                          if (customer.address != null && customer.address!.isNotEmpty)
                            pw.Text(customer.address!),
                          if (customer.phone != null && customer.phone!.isNotEmpty)
                            pw.Text(customer.phone!),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Items Table
                pw.Table.fromTextArray(
                  headers: [
                    'Produit',
                    'Quantité',
                    'Prix Unitaire',
                    'Total'
                  ],
                  data: saleItems.map((item) {
                    return [
                      item.productName,
                      item.quantity.toString(),
                      formatCurrency.format(item.unitPrice),
                      formatCurrency.format(item.subtotal),
                    ];
                  }).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
                pw.SizedBox(height: 20),

                // Total
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total HT: ${formatCurrency.format(sale.total)}', // Assuming total is already net
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'TVA (0%): ${formatCurrency.format(0)}', // Placeholder for VAT
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'TOTAL À PAYER: ${formatCurrency.format(sale.total)}',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Center(
                  child: pw.Text('Merci pour votre achat !',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
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
