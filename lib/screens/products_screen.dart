import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:excel/excel.dart' as exc;
import 'package:file_picker/file_picker.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';
import '../utils/import_utils.dart';

part 'products/products_dialogs.dart';
part 'products/products_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  int? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/products'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDesktop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 40 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 32),
                        _buildFilters(context),
                        const SizedBox(height: 32),
                        _buildProductsList(context, isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !authProvider.isAdmin
          ? null
          : FloatingActionButton(
              onPressed: () => _showProductDialog(context, null),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
          const Spacer(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return IconButton(
                icon: Icon(auth.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: auth.toggleTheme,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, categoryProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produits',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${productProvider.products.length} produit${productProvider.products.length > 1 ? 's' : ''} • ${categoryProvider.categories.length} catégorie${categoryProvider.categories.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un produit...',
            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Tous les produits',
                count: productProvider.products.length,
                selected: _selectedCategoryFilter == null,
                onTap: () => setState(() => _selectedCategoryFilter = null),
              ),
              const SizedBox(width: 12),
              ...categoryProvider.categories.map((cat) {
                final count = productProvider.products.where((p) => p.categoryId == cat.id).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _FilterChip(
                    label: cat.name,
                    count: count,
                    selected: _selectedCategoryFilter == cat.id,
                    onTap: () => setState(() => _selectedCategoryFilter = cat.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (authProvider.isAdmin)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _importProductsFromExcel(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importer depuis Excel'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _generateExcelTemplate(context),
                  icon: const Icon(Icons.description),
                  label: const Text('Générer modèle Excel'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _exportProductsToExcel(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter vers Excel'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProductsList(BuildContext context, bool isDesktop) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    var filteredProducts = productProvider.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == null || p.categoryId == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    if (productProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProducts.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Aucun produit trouvé',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _ProductCard(
          product: product,
          categoryName: categoryProvider.getCategoryName(product.categoryId),
          onTap: authProvider.isAdmin ? () => _showProductDialog(context, product) : null,
          onDelete: authProvider.isAdmin ? () => _confirmDelete(context, product) : null,
        );
      },
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    showDialog(context: context, builder: (context) => _ProductDialog(product: product));
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit supprimé')));
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportProductsToExcel(BuildContext context) async {
    final productProvider = context.read<ProductProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final products = productProvider.products;

    final excel = exc.Excel.createExcel();
    final exc.Sheet sheet = excel['Products'];
    excel.setDefaultSheet('Products');
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final headers = [
      'ID',
      'Nom',
      'Description',
      'Prix',
      'Stock',
      'Catégorie',
      'Code-barres'
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = exc.TextCellValue(headers[i]);
    }

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final categoryName = categoryProvider.getCategoryName(product.categoryId);
      final rowIndex = i + 1;

      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = exc.IntCellValue(product.id ?? -1);
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = exc.TextCellValue(product.name);
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = exc.TextCellValue(product.description ?? '');
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = exc.DoubleCellValue(product.price);
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = exc.IntCellValue(product.stock);
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = exc.TextCellValue(categoryName);
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = exc.TextCellValue(product.barcode ?? '');
    }

    final bytes = excel.encode();

    if (bytes != null) {
      final String? outputFile = await FilePicker.platform.saveFile(
        fileName: 'export_produits.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produits exportés avec succès vers : $outputFile'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exportation annulée.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'exportation des produits.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateExcelTemplate(BuildContext context) async {
    final excel = exc.Excel.createExcel();
    final exc.Sheet sheet = excel['Products'];
    excel.setDefaultSheet('Products');
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final headers = [
      'Nom',
      'Description',
      'Prix',
      'Stock',
      'Catégorie',
      'Code-barres'
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = exc.TextCellValue(headers[i]);
    }

    final bytes = excel.encode();

    if (bytes != null) {
      final String? outputFile = await FilePicker.platform.saveFile(
        fileName: 'modele_produits.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modèle Excel généré et sauvegardé à : $outputFile'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Génération de modèle annulée.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la génération du modèle Excel.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importProductsFromExcel(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Importation annulée.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final filePath = result.files.single.path!;
      final bytes = File(filePath).readAsBytesSync();
      final excel = exc.Excel.decodeBytes(bytes);

      final exc.Sheet? sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fichier Excel vide ou format invalide.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final headers = sheet
          .row(0)
          .map((cell) => cell?.value.toString() ?? '')
          .toList();
      final headerIndex = <String, int>{};
      for (var i = 0; i < headers.length; i++) {
        final normalized = normalizeHeader(headers[i]);
        if (normalized.isNotEmpty) {
          headerIndex[normalized] = i;
        }
      }

      final requiredHeaders = <String, String>{
        'nom': 'Nom',
        'description': 'Description',
        'prix': 'Prix',
        'stock': 'Stock',
        'categorie': 'Catégorie',
        'codebarres': 'Code-barres',
      };

      final missing = requiredHeaders.keys
          .where((key) => !headerIndex.containsKey(key))
          .toList();

      if (missing.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'En-têtes manquants ou invalides: ${missing.map((m) => requiredHeaders[m]).join(', ')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final productProvider = context.read<ProductProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      int importedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;
      final List<String> errors = [];
      final List<String> warnings = [];

      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.every((cell) => cell?.value == null)) continue;

        try {
          final rowNumber = i + 1;
          String name = cellValue(row, headerIndex['nom']!);
          String description = cellValue(row, headerIndex['description']!);
          String categoryName = cellValue(row, headerIndex['categorie']!);
          String barcode = cellValue(row, headerIndex['codebarres']!);
          double? price = parseDouble(cellValue(row, headerIndex['prix']!));
          int? stock = parseInt(cellValue(row, headerIndex['stock']!));

          final rowErrors = <String>[];
          if (name.isEmpty) rowErrors.add('Nom manquant');
          if (categoryName.isEmpty) rowErrors.add('Catégorie manquante');
          if (price == null) {
            rowErrors.add('Prix invalide');
          } else if (price <= 0) {
            rowErrors.add('Prix doit être > 0');
          }
          if (stock == null) {
            rowErrors.add('Stock invalide');
          } else if (stock < 0) {
            rowErrors.add('Stock doit être >= 0');
          }

          if (rowErrors.isNotEmpty) {
            errors.add('Ligne $rowNumber: ${rowErrors.join(', ')}.');
            skippedCount++;
            continue;
          }

          final validPrice = price!;
          final validStock = stock!;

          final normalizedCategory = normalizeText(categoryName);
          Category category = categoryProvider.categories.firstWhere(
            (cat) => normalizeText(cat.name) == normalizedCategory,
            orElse: () => Category(id: null, name: categoryName),
          );

          if (category.id == null) {
            await categoryProvider.addCategory(category);
            await categoryProvider.loadCategories();
            category = categoryProvider.categories.firstWhere(
              (cat) => normalizeText(cat.name) == normalizedCategory,
            );
          }

          Product? existingProduct;
          if (barcode.isNotEmpty) {
            existingProduct = productProvider.products.firstWhere(
              (p) => p.barcode == barcode,
              orElse: () => Product(
                id: null,
                name: '',
                description: '',
                price: 0,
                stock: 0,
                categoryId: 0,
                barcode: '',
              ),
            );
            if (existingProduct.id == null) existingProduct = null;
          }
          final normalizedName = normalizeText(name);
          if (existingProduct == null) {
            existingProduct = productProvider.products.firstWhere(
              (p) => normalizeText(p.name) == normalizedName,
              orElse: () => Product(
                id: null,
                name: '',
                description: '',
                price: 0,
                stock: 0,
                categoryId: 0,
                barcode: '',
              ),
            );
            if (existingProduct.id == null) existingProduct = null;
          }

          if (existingProduct == null) {
            final nearMatches = findNearNameMatches(
              normalizedName,
              productProvider.products,
            );
            if (nearMatches.isNotEmpty) {
              warnings.add(
                'Ligne $rowNumber: nom proche de ${nearMatches.join(', ')}',
              );
            }
          }

          if (barcode.isNotEmpty && existingProduct != null) {
            if (existingProduct.barcode != null &&
                existingProduct.barcode != barcode) {
              warnings.add(
                'Ligne $rowNumber: code-barres conflictuel (produit existant).',
              );
            }
          }

          Product newProduct = Product(
            id: existingProduct?.id,
            name: name,
            description: description.isEmpty ? null : description,
            price: validPrice,
            stock: validStock,
            categoryId: category.id!,
            barcode: barcode.isEmpty ? null : barcode,
          );

          if (existingProduct != null) {
            await productProvider.updateProduct(newProduct);
            updatedCount++;
          } else {
            await productProvider.addProduct(newProduct);
            importedCount++;
          }
        } catch (e) {
          errors.add('Ligne ${i + 1}: erreur inattendue (${e.toString()}).');
          skippedCount++;
        }
      }

      if (context.mounted) {
        await _showImportResultDialog(
          context,
          importedCount,
          updatedCount,
          skippedCount,
          errors,
          warnings,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'importation du fichier Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

Future<void> _showImportResultDialog(
  BuildContext context,
  int importedCount,
  int updatedCount,
  int skippedCount,
  List<String> errors,
  List<String> warnings,
) async {
  final hasErrors = errors.isNotEmpty;
  final hasWarnings = warnings.isNotEmpty;
  final preview = errors.take(10).toList();
  final warningPreview = warnings.take(10).toList();
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Importation terminée'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouveaux produits: $importedCount\n'
              'Produits mis à jour: $updatedCount\n'
              'Lignes ignorées: $skippedCount',
            ),
            if (hasWarnings) ...[
              const SizedBox(height: 16),
              Text(
                'Avertissements (${warnings.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...warningPreview.map((e) => Text('- $e')),
              if (warnings.length > warningPreview.length)
                Text('... +${warnings.length - warningPreview.length} autres'),
            ],
            if (hasErrors) ...[
              const SizedBox(height: 16),
              Text(
                'Erreurs (${errors.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...preview.map((e) => Text('- $e')),
              if (errors.length > preview.length)
                Text('... +${errors.length - preview.length} autres'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
