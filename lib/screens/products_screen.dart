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
import '../widgets/app_sidebar.dart'; // New import

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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/products'), // Replaced sidebar
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
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAdmin) return const SizedBox();
          return FloatingActionButton(
            onPressed: () => _showProductDialog(context, null),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
              '${auth.products.length} produit${auth.products.length > 1 ? 's' : ''} • ${auth.categories.length} catégorie${auth.categories.length > 1 ? 's' : ''}',
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
                    count: auth.products.length,
                    selected: _selectedCategoryFilter == null,
                    onTap: () => setState(() => _selectedCategoryFilter = null),
                  ),
                  const SizedBox(width: 12),
                  ...auth.categories.map((cat) {
                    final count = auth.products.where((p) => p.categoryId == cat.id).length;
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
            const SizedBox(height: 16), // Add some spacing for the new buttons
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isAdmin) return const SizedBox.shrink();
                return Column(
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
                        icon: const Icon(Icons.download),
                        label: const Text('Générer modèle Excel'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsList(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        var filteredProducts = auth.products.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategoryFilter == null || p.categoryId == _selectedCategoryFilter;
          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Aucun produit trouvé', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
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
              categoryName: auth.getCategoryName(product.categoryId),
              onTap: auth.isAdmin ? () => _showProductDialog(context, product) : null,
              onDelete: auth.isAdmin ? () => _confirmDelete(context, product) : null,
            );
          },
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
              context.read<AuthProvider>().deleteProduct(product.id!);
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

  Future<void> _generateExcelTemplate(BuildContext context) async {
    final excel = exc.Excel.createExcel();
    final exc.Sheet sheet = excel['Products'];
    // Make sure "Products" is the default visible sheet
    excel.setDefaultSheet('Products');
    // Remove the default empty sheet if it exists
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

    // Write headers
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
        final normalized = _normalizeHeader(headers[i]);
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

      final auth = context.read<AuthProvider>();
      int importedCount = 0;
      int updatedCount = 0;
      final List<String> errors = [];
      final List<String> warnings = [];

      for (var i = 1; i < sheet.maxRows; i++) { // Skip header row
        final row = sheet.row(i);
        if (row.every((cell) => cell?.value == null)) continue; // Skip empty rows

        String name = _cellValue(row, headerIndex['nom']!);
        String description = _cellValue(row, headerIndex['description']!);
        double? price = _parseDouble(_cellValue(row, headerIndex['prix']!));
        int? stock = _parseInt(_cellValue(row, headerIndex['stock']!));
        String categoryName = _cellValue(row, headerIndex['categorie']!);
        String barcode = _cellValue(row, headerIndex['codebarres']!);

        if (name.isEmpty || price == null || price <= 0 || stock == null || stock < 0 || categoryName.isEmpty) {
          errors.add('Ligne ${i + 1}: données invalides (Nom/Prix/Stock/Catégorie).');
          continue;
        }

        // Handle category: find or create
        final normalizedCategory = _normalizeText(categoryName);
        Category? category = auth.categories.firstWhere(
          (cat) => _normalizeText(cat.name) == normalizedCategory,
          orElse: () => Category(id: null, name: categoryName), // Temporary local Category object
        );

        if (category.id == null) {
          // Category does not exist, create it
          await auth.addCategory(category);
          // Reload categories to get the new category with its ID
          await auth.loadCategories();
          category = auth.categories.firstWhere(
            (cat) => _normalizeText(cat.name) == normalizedCategory,
          );
        }

        // Check for existing product by name or barcode
        Product? existingProduct;
        if (barcode.isNotEmpty) {
          existingProduct = auth.products.firstWhere(
            (p) => p.barcode == barcode,
            orElse: () => Product(id: null, name: '', description: '', price: 0, stock: 0, categoryId: 0, barcode: ''),
          );
          if (existingProduct.id == null) existingProduct = null;
        }
        final normalizedName = _normalizeText(name);
        if (existingProduct == null) {
          existingProduct = auth.products.firstWhere(
            (p) => _normalizeText(p.name) == normalizedName,
            orElse: () => Product(id: null, name: '', description: '', price: 0, stock: 0, categoryId: 0, barcode: ''),
          );
          if (existingProduct.id == null) existingProduct = null;
        }

        if (existingProduct == null) {
          final nearMatches = _findNearNameMatches(normalizedName, auth.products);
          if (nearMatches.isNotEmpty) {
            warnings.add(
              'Ligne ${i + 1}: nom proche de ${nearMatches.join(', ')}',
            );
          }
        }


        Product newProduct = Product(
          id: existingProduct?.id, // Use existing ID if found
          name: name,
          description: description.isEmpty ? null : description,
          price: price,
          stock: stock,
          categoryId: category.id!,
          barcode: barcode.isEmpty ? null : barcode,
        );

        if (existingProduct != null) {
          await auth.updateProduct(newProduct);
          updatedCount++;
        } else {
          await auth.addProduct(newProduct);
          importedCount++;
        }
      }

        if (context.mounted) {
        await _showImportResultDialog(
          context,
          importedCount,
          updatedCount,
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

String _normalizeHeader(String value) {
  return _normalizeText(value);
}

String _normalizeText(String value) {
  final trimmed = value.trim().toLowerCase();
  final withoutAccents = trimmed
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c');
  return withoutAccents.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _cellValue(List<exc.Data?> row, int index) {
  if (index >= row.length) return '';
  final value = row[index]?.value;
  return value == null ? '' : value.toString().trim();
}

double? _parseDouble(String raw) {
  if (raw.isEmpty) return null;
  var cleaned = raw.replaceAll('\u00A0', ' ').trim();
  cleaned = cleaned.replaceAll(RegExp(r'[^\d,.\-]'), '');
  if (cleaned.isEmpty) return null;
  if (cleaned.contains(',') && !cleaned.contains('.')) {
    cleaned = cleaned.replaceAll(',', '.');
  } else {
    cleaned = cleaned.replaceAll(',', '');
  }
  return double.tryParse(cleaned);
}

int? _parseInt(String raw) {
  if (raw.isEmpty) return null;
  var cleaned = raw.replaceAll('\u00A0', ' ').trim();
  cleaned = cleaned.replaceAll(RegExp(r'[^\d\-]'), '');
  if (cleaned.isEmpty) return null;
  return int.tryParse(cleaned);
}

Future<void> _showImportResultDialog(
  BuildContext context,
  int importedCount,
  int updatedCount,
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
              'Produits mis à jour: $updatedCount',
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

List<String> _findNearNameMatches(
  String normalizedName,
  List<Product> products,
) {
  if (normalizedName.isEmpty) return [];
  final results = <String>[];
  for (final product in products) {
    final normalizedExisting = _normalizeText(product.name);
    if (normalizedExisting.isEmpty || normalizedExisting == normalizedName) {
      continue;
    }
    final contains = normalizedExisting.contains(normalizedName) ||
        normalizedName.contains(normalizedExisting);
    final prefixRatio = _commonPrefixRatio(normalizedExisting, normalizedName);
    final lengthDiff =
        (normalizedExisting.length - normalizedName.length).abs();
    final isNear = contains || (prefixRatio >= 0.85 && lengthDiff <= 3);
    if (isNear) {
      results.add('"${product.name}"');
      if (results.length >= 3) break;
    }
  }
  return results;
}

double _commonPrefixRatio(String a, String b) {
  final minLen = a.length < b.length ? a.length : b.length;
  int i = 0;
  while (i < minLen && a[i] == b[i]) {
    i++;
  }
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 0;
  return i / maxLen;
}



class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ProductCard({required this.product, required this.categoryName, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock < 10;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_outlined, size: 32, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isLowStock ? Colors.red : Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _barcodeController; // New controller
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? ''); // Initialize barcode controller
    _selectedCategoryId = widget.product?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose(); // Dispose barcode controller
    super.dispose();
  }

  Future<void> _scanBarcodeAndPopulate() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Annuler', true, ScanMode.BARCODE);
    if (!mounted) return;

    if (barcodeScanRes != '-1') { // '-1' means user canceled
      setState(() {
        _barcodeController.text = barcodeScanRes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Nouveau produit' : 'Modifier le produit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom du produit', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                    items: auth.categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _barcodeController, // Barcode controller
                    decoration: InputDecoration(
                      labelText: 'Code-barres',
                      border: const OutlineInputBorder(),
                      suffixIcon: (Platform.isAndroid || Platform.isIOS)
                        ? IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcodeAndPopulate,
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Prix (FCFA)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      price: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      categoryId: _selectedCategoryId!,
      barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text, // Add barcode
    );

    final auth = context.read<AuthProvider>();
    if (widget.product == null) {
      auth.addProduct(product);
    } else {
      auth.updateProduct(product);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.product == null ? 'Produit ajouté' : 'Produit modifié')));
  }
}
