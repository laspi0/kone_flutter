import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
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
import 'package:shop_manager/providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../services/pdf_service.dart';

part 'sales/sales_dialogs.dart';
part 'sales/sales_widgets.dart';

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
    final productProvider = context.read<ProductProvider>();
    final product = await productProvider.getProductByBarcode(barcode.trim());

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

    return Consumer3<AuthProvider, ProductProvider, CategoryProvider>(
      builder: (context, auth, productProvider, categoryProvider, _) {
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
                          count: productProvider.products.where((p) => p.stock > 0).length,
                          selected: _selectedCategoryFilter == null,
                          onTap: () =>
                              setState(() => _selectedCategoryFilter = null),
                        ),
                        const SizedBox(width: 8),
                        ...categoryProvider.categories.map((cat) {
                          final count = productProvider.products
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
            Expanded(
              child: _buildProductsList(
                context,
                auth,
                productProvider,
                categoryProvider,
                isDesktop,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    AuthProvider auth,
    ProductProvider productProvider,
    CategoryProvider categoryProvider,
    bool isDesktop,
  ) {
    var filteredProducts = productProvider.products.where((p) {
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
            categoryName: categoryProvider.getCategoryName(product.categoryId),
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

    if (mounted) {
      // Reload products to reflect new stock
      await context.read<ProductProvider>().loadProducts();
    }

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
