import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:shop_manager/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:intl/intl.dart' as intl;
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../widgets/app_sidebar.dart';
import '../services/pdf_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _searchQuery = '';
  int? _selectedCategoryFilter;

  // Controllers for barcode scanning
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (isDesktop) {
      // Set initial focus on the barcode field on desktop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _barcodeFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeMobile() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Annuler', true, ScanMode.BARCODE);

      if (!mounted) return;

      if (barcodeScanRes != '-1') {
        _onBarcodeSubmitted(barcodeScanRes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur du scanner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onBarcodeSubmitted(String barcode) async {
    if (barcode.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final db = DatabaseHelper.instance;

    final product = await db.getProductByBarcode(barcode.trim());

    if (mounted) {
      if (product != null) {
        if (product.stock > 0) {
          auth.addToCart(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} ajouté au panier.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('\'${product.name}\' est en rupture de stock.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit non trouvé pour le code-barres: $barcode'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        );
      }
    }

    // Clear and re-focus for the next scan on desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/sales'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDesktop),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: isDesktop ? 6 : 1,
                        child: _buildProductsSection(context, isDesktop),
                      ),
                      if (isDesktop)
                        SizedBox(width: 420, child: _buildCartSection(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !isDesktop
          ? Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.cart.isEmpty) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(context),
                  icon: Badge(
                    label: Text('${auth.cartItemCount}'),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: Text('${auth.cartTotal.toStringAsFixed(0)} F'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              },
            )
          : null,
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 40 : 20,
        24,
        isDesktop ? 40 : 20,
        24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          if (!isDesktop) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Point de Vente',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                auth.currentUser?.username ?? "",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return IconButton(
                icon: Icon(
                  auth.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: auth.toggleTheme,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context, bool isDesktop) {
    final isMobile = !isDesktop && (Platform.isAndroid || Platform.isIOS);

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Column(
          children: [
            // Search & Filters
            Container(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: Column(
                children: [
                  // Desktop Barcode Scanner
                  if (!isMobile) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withAlpha(77),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(128),
                        ),
                      ),
                      child: TextField(
                        controller: _barcodeController,
                        focusNode: _barcodeFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Scanner un code-barres...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(179),
                          ),
                          prefixIcon: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: _onBarcodeSubmitted,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(20),
                      ),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit par nom...',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(102),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(128),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              ),
                            if (isMobile)
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                onPressed: _scanBarcodeMobile,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category filters
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'Tout',
                          count: auth.products.where((p) => p.stock > 0).length,
                          selected: _selectedCategoryFilter == null,
                          onTap: () =>
                              setState(() => _selectedCategoryFilter = null),
                        ),
                        const SizedBox(width: 8),
                        ...auth.categories.map((cat) {
                          final count = auth.products
                              .where(
                                (p) => p.categoryId == cat.id && p.stock > 0,
                              )
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              label: cat.name,
                              count: count,
                              selected: _selectedCategoryFilter == cat.id,
                              onTap: () => setState(
                                () => _selectedCategoryFilter = cat.id,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Products List
            Expanded(child: _buildProductsList(context, auth, isDesktop)),
          ],
        );
      },
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    AuthProvider auth,
    bool isDesktop,
  ) {
    var filteredProducts = auth.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategoryFilter == null ||
          p.categoryId == _selectedCategoryFilter;
      final inStock = p.stock > 0;
      return matchesSearch && matchesCategory && inStock;
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isEmpty
                  ? 'Tous les produits sont en rupture'
                  : 'Essayez une autre recherche',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 20,
        16,
        isDesktop ? 32 : 20,
        100,
      ),
      itemCount: filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _ProductListItem(
          product: product,
          categoryName: auth.getCategoryName(product.categoryId),
          onAdd: () => auth.addToCart(product),
        );
      },
    );
  }

  Widget _buildCartSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              left: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(13),
              ),
            ),
          ),
          child: Column(
            children: [
              // Cart Header with customer selection
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panier',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${auth.cartItemCount} article${auth.cartItemCount > 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(128),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (auth.cart.isNotEmpty)
                          IconButton(
                            onPressed: () => _confirmClearCart(context, auth),
                            icon: const Icon(
                              Icons.delete_sweep_outlined,
                              size: 20,
                            ),
                            tooltip: 'Vider',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Customer selector
                    InkWell(
                      onTap: () => _showCustomerSelector(context, auth),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Client',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(128),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    auth.selectedCustomer?.name ??
                                        'Client au comptoir',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(128),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(20),
              ),
              // Cart Items
              Expanded(
                child: auth.cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(51),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Panier vide',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(102),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ajoutez des produits',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(77),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: auth.cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = auth.cart[index];
                          return _CartItem(item: item);
                        },
                      ),
              ),
              // Cart Footer
              if (auth.cart.isNotEmpty) ...[
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha(20),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(153),
                                ),
                          ),
                          Text(
                            '${auth.cartTotal.toStringAsFixed(0)} FCFA',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () => _completeSale(context, auth),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Finaliser',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: _buildCartSection(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _completeSale(BuildContext context, AuthProvider auth) async {
    final amountPaid = await _showPaymentDialog(context, auth);
    if (amountPaid == null) return;

    final result = await auth.completeSale(amountPaid: amountPaid);

    if (!mounted) return;

    if (result != null) {
      final Sale sale = result['sale'];
      final List<SaleItem> saleItems = result['saleItems'];
      final Customer? customer = result['customer'];

      // Generate PDF
      final pdfBytes = await PdfService().generateInvoicePdf(
        sale,
        saleItems,
        customer,
        auth.shopInfo!,
        auth.currentUser!.username,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Vente enregistrée'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

      // Show dialog for print/save option
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Facture Générée'),
          content: const Text(
            'Voulez-vous imprimer ou enregistrer la facture ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) async => pdfBytes,
                );
              },
              child: const Text('Imprimer Facture'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog

                if (!mounted) return;

                final fileName =
                    'facture-${intl.DateFormat('yyyyMMdd-HHmmss').format(sale.date)}-${sale.id}.pdf';
                final savePath = await FilePicker.platform.saveFile(
                  dialogTitle: 'Enregistrer la facture',
                  fileName: fileName,
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                if (savePath != null) {
                  final file = File(savePath);
                  await file.writeAsBytes(pdfBytes);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Facture enregistrée à: $savePath'),
                        backgroundColor: Colors.blue,
                        behavior: SnackBarBehavior.floating,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enregistrement de la facture annulé.'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Enregistrer Facture'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(auth.errorMessage ?? 'Erreur')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }
  }

  Future<double?> _showPaymentDialog(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _PaymentDialog(
        total: auth.cartTotal,
        itemCount: auth.cartItemCount,
      ),
    );
    return result;
  }


  void _showCustomerSelector(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Text(
                    'Sélectionner un client',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(child: _CustomerSelectorContent(auth: auth)),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Voulez-vous vraiment vider le panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              auth.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final double total;
  final int itemCount;

  const _PaymentDialog({
    required this.total,
    required this.itemCount,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.total.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final amountPaid = _parseAmount(_controller.text);
    final change = amountPaid != null ? amountPaid - widget.total : 0;
    final isValid = amountPaid != null && amountPaid >= widget.total;
    final errorText = amountPaid == null
        ? 'Entrez un montant'
        : amountPaid < widget.total
            ? 'Montant insuffisant'
            : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Paiement'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.itemCount} article${widget.itemCount > 1 ? 's' : ''}',
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${widget.total.toStringAsFixed(0)} FCFA',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Montant reçu',
              suffixText: 'FCFA',
              errorText: errorText,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monnaie à rendre:'),
              Text(
                '${change > 0 ? change.toStringAsFixed(0) : '0'} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: isValid ? () => Navigator.pop(context, amountPaid) : null,
          icon: const Icon(Icons.check),
          label: const Text('Encaisser'),
        ),
      ],
    );
  }
}

class _CustomerSelectorContent extends StatefulWidget {
  final AuthProvider auth;

  const _CustomerSelectorContent({required this.auth});

  @override
  State<_CustomerSelectorContent> createState() =>
      _CustomerSelectorContentState();
}

class _CustomerSelectorContentState extends State<_CustomerSelectorContent> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) {
      // Client au comptoir + tous les clients
      return [Customer.walkin, ...widget.auth.customers];
    }

    // Filtrer par recherche
    final filtered = widget.auth.customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.phone?.contains(_searchQuery) ?? false);
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou téléphone...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha(102),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              autofocus: true,
            ),
          ),
        ),
        if (customers.isEmpty && _searchQuery.isNotEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(77),
                    ),
                    const SizedBox(height: 12),
                                          Text(
                                            'Aucun client trouvé',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface.withAlpha(128),
                                            ),
                                          ),                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == customers.length - 1 ? 0 : 12,
                  ),
                  child: _CustomerTile(
                    customer: customer,
                    selected: widget.auth.selectedCustomer?.id == customer.id,
                    onTap: () {
                      widget.auth.selectCustomer(customer);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// WIDGETS

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withAlpha(64)
                    : Theme.of(context).colorScheme.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback onAdd;

  const _ProductListItem({
    required this.product,
    required this.categoryName,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock < 10;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? Colors.orange.withAlpha(38)
                                  : Colors.green.withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_outlined,
                                  size: 11,
                                  color: isLowStock
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.stock}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isLowStock
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Price & Add Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'FCFA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(179),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add, size: 20),
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary.withAlpha(77)
                        : Theme.of(context).colorScheme.onSurface.withAlpha(13),
                  ),      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary.withAlpha(51)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  customer.isWalkin ? Icons.store : Icons.person_outline,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(128),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (customer.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.phone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final CartItem item;

  const _CartItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.product.price.toStringAsFixed(0)} F',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(128),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => auth.removeFromCart(item.product),
                    icon: const Icon(Icons.close, size: 18),
                    color: Theme.of(context).colorScheme.error,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withAlpha(128),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => auth.updateCartQuantity(
                            item.product,
                            item.quantity - 1,
                          ),
                          icon: const Icon(Icons.remove, size: 16),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 28),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.quantity}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => auth.updateCartQuantity(
                            item.product,
                            item.quantity + 1,
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.subtotal.toStringAsFixed(0)} F',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
