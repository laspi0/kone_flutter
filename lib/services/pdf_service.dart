import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models.dart';

class PdfService {
  Future<Uint8List> generateInvoicePdf(
    Sale sale,
    List<SaleItem> saleItems,
    Customer? customer,
    ShopInfo shopInfo,
    String cashierName,
  ) async {
    final pdf = pw.Document();

    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );

    // Charger le logo de manière asynchrone
    pw.Widget? logoWidget;
    if (shopInfo.logo != null && shopInfo.logo!.isNotEmpty) {
      try {
        final logoFile = File(shopInfo.logo!);
        if (await logoFile.exists()) {
          final imageBytes = await logoFile.readAsBytes();
          final logoImage = pw.MemoryImage(imageBytes);
          logoWidget = pw.Image(logoImage, height: 40); // Hauteur du logo
        }
      } catch (e) {
        print("Could not load logo for PDF: $e");
      }
    }


    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          3000 * PdfPageFormat.mm,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ================================
                // En-tête avec séparateur
                // ================================
                _buildSeparator(),
                pw.SizedBox(height: 5),

                // Informations boutique (centré)
                pw.Center(
                  child: pw.Column(
                    children: [
                      // Afficher le logo s'il existe
                      if (logoWidget != null) ...[
                        logoWidget,
                        pw.SizedBox(height: 5),
                      ],
                      pw.Text(
                        shopInfo.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        shopInfo.address,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'Tel: ${shopInfo.phone}',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 5),
                _buildSeparator(),
                pw.SizedBox(height: 8),

                // ================================
                // Informations vente
                // ================================
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(sale.date)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      DateFormat('HH:mm').format(sale.date),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Caissier: $cashierName',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Vente #${sale.id}',
                  style: const pw.TextStyle(fontSize: 9),
                ),

                // Informations client (si existe)
                if (customer != null && !customer.isWalkin) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Client: ${customer.name}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  if (customer.phone?.isNotEmpty == true)
                    pw.Text(
                      'Tél: ${customer.phone}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                ],

                pw.SizedBox(height: 5),
                _buildDashedSeparator(),
                pw.SizedBox(height: 5),

                // ================================
                // En-tête tableau produits
                // ================================
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'Produit',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      width: 30,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Qté',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      width: 50,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Prix',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                _buildDashedSeparator(),
                pw.SizedBox(height: 3),

                // ================================
                // Liste des produits
                // ================================
                ...saleItems.map((item) {
                  return pw.Column(
                    children: [
                      // Ligne 1: Nom du produit et prix total
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              item.productName,
                              style: const pw.TextStyle(fontSize: 9),
                              maxLines: 2,
                            ),
                          ),
                          pw.Container(
                            width: 30,
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              '${item.quantity}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Container(
                            width: 50,
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              formatCurrency.format(item.subtotal),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      // Ligne 2: Détail (quantité × prix unitaire)
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.quantity} × ${formatCurrency.format(item.unitPrice)}',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ],
                  );
                }),

                pw.SizedBox(height: 2),
                _buildDashedSeparator(),
                pw.SizedBox(height: 5),

                // ================================
                // Total
                // ================================
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TOTAL: ',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${formatCurrency.format(sale.total)} FCFA',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Montant reçu et rendu (si applicable)
                if (sale.amountPaid != null && sale.amountPaid! > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Reçu: ',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '${formatCurrency.format(sale.amountPaid!)} FCFA',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Rendu: ',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '${formatCurrency.format(sale.amountPaid! - sale.total)} FCFA',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],

                pw.SizedBox(height: 5),
                _buildSeparator(),
                pw.SizedBox(height: 8),

                // ================================
                // Message de remerciement
                // ================================
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Merci pour votre visite !',
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'À bientôt !',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 5),
                _buildSeparator(),
                pw.SizedBox(height: 10),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Séparateur plein (=)
  pw.Widget _buildSeparator() {
    return pw.Container(
      width: double.infinity,
      height: 1,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.black,
            width: 1,
          ),
        ),
      ),
    );
  }

  // Séparateur pointillé (-)
  pw.Widget _buildDashedSeparator() {
    return pw.Row(
      children: List.generate(
        32,
        (index) => pw.Expanded(
          child: pw.Container(
            height: 1,
            margin: const pw.EdgeInsets.symmetric(horizontal: 1),
            color: index % 2 == 0 ? PdfColors.black : PdfColors.white,
          ),
        ),
      ),
    );
  }
}