import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as exc;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../auth_provider.dart';
import '../models.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';

part 'sale_history/sale_history_widgets.dart';

class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedUserId;
  int? _selectedCustomerId;

  // Method to show password confirmation for bulk actions
  void _showPasswordConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final auth = context.read<AuthProvider>();
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('⚠️ $title'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cette action est IRREVERSIBLE.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(content),
                    const SizedBox(height: 16),
                    Text(
                      'Pour confirmer, veuillez entrer votre mot de passe.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (value != auth.currentUser!.passwordHash) {
                          return 'Mot de passe incorrect';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Supprimer'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$title en cours...')),
                    );
                    await onConfirm();
                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opération terminée avec succès.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to show month/year picker
  Future<void> _showMonthYearPicker() async {
    final auth = context.read<AuthProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SÉLECTIONNER UN MOIS',
    );

    if (picked != null && mounted) {
      final startDate = DateTime(picked.year, picked.month, 1);
      final endDate = DateTime(picked.year, picked.month + 1, 0, 23, 59, 59);
      final monthName = DateFormat.yMMMM('fr_FR').format(picked);

      _showPasswordConfirmationDialog(
        context: context,
        title: 'Supprimer les ventes de $monthName',
        content: 'Toutes les ventes du mois de $monthName seront supprimées.',
        onConfirm: () => auth.deleteSalesInDateRange(startDate, endDate),
      );
    }
  }

  // Method to show year picker
  Future<void> _showYearPicker() async {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une année'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              selectedDate: DateTime.now(),
              onChanged: (DateTime dateTime) {
                final startDate = DateTime(dateTime.year, 1, 1);
                final endDate = DateTime(dateTime.year, 12, 31, 23, 59, 59);
                Navigator.of(context).pop();
                _showPasswordConfirmationDialog(
                  context: context,
                  title: 'Supprimer les ventes de ${dateTime.year}',
                  content: 'Toutes les ventes de l\'année ${dateTime.year} seront supprimées.',
                  onConfirm: () => auth.deleteSalesInDateRange(startDate, endDate),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/sale-history'),
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
                        const SizedBox(height: 24),
                        _buildSearchBar(context),
                        const SizedBox(height: 24),
                        _buildFilters(context),
                        const SizedBox(height: 24),
                        _buildSalesList(context, isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
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
          IconButton(
            icon: Icon(
              auth.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: auth.toggleTheme,
          ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportSalesToExcel(context),
              tooltip: 'Exporter vers Excel',
            ),
          if (auth.isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'by_month':
                    _showMonthYearPicker();
                    break;
                  case 'by_year':
                    _showYearPicker();
                    break;
                  case 'all':
                    _showPasswordConfirmationDialog(
                      context: context,
                      title: 'Supprimer tout l\'historique',
                      content: 'Absolument toutes les ventes seront supprimées.',
                      onConfirm: auth.deleteAllSales,
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'by_month',
                  child: Text('Supprimer par mois...'),
                ),
                const PopupMenuItem<String>(
                  value: 'by_year',
                  child: Text('Supprimer par année...'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'all',
                  child: Text('Tout supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final totalRevenue = auth.sales.fold(
          0.0,
          (sum, sale) => sum + sale.total,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des ventes',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${auth.sales.length} vente${auth.sales.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
                Text(
                  ' • ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
                Text(
                  '${totalRevenue.toStringAsFixed(0)} FCFA total',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher par n° de vente...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final hasActiveFilters = _startDate != null ||
            _endDate != null ||
            _selectedUserId != null ||
            _selectedCustomerId != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filtres',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 12),
                if (hasActiveFilters)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Réinitialiser'),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedUserId = null;
                        _selectedCustomerId = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Date de début
                _DatePickerChip(
                  label: _startDate == null
                      ? 'Date début'
                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                  icon: Icons.calendar_today_outlined,
                  isSelected: _startDate != null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  onClear: _startDate != null
                      ? () => setState(() => _startDate = null)
                      : null,
                ),

                // Date de fin
                _DatePickerChip(
                  label: _endDate == null
                      ? 'Date fin'
                      : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  icon: Icons.event_outlined,
                  isSelected: _endDate != null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  onClear: _endDate != null
                      ? () => setState(() => _endDate = null)
                      : null,
                ),

                // Filtres rapides de période
                _QuickDateFilterChip(
                  label: 'Aujourd\'hui',
                  icon: Icons.today_outlined,
                  isSelected: _isToday(),
                  onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = DateTime(now.year, now.month, now.day);
                      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    });
                  },
                ),

                _QuickDateFilterChip(
                  label: '7 derniers jours',
                  icon: Icons.date_range_outlined,
                  isSelected: _isLast7Days(),
                  onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 7));
                      _endDate = now;
                    });
                  },
                ),

                _QuickDateFilterChip(
                  label: '30 derniers jours',
                  icon: Icons.calendar_month_outlined,
                  isSelected: _isLast30Days(),
                  onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 30));
                      _endDate = now;
                    });
                  },
                ),

                // User Filter avec recherche
                _SearchableFilterChip<User>(
                  label: _selectedUserId == null
                      ? 'Caissier'
                      : auth.users
                          .firstWhere((u) => u.id == _selectedUserId)
                          .username,
                  icon: Icons.person_outline,
                  isSelected: _selectedUserId != null,
                  items: auth.users,
                  itemBuilder: (user) => _UserListItem(user: user),
                  searchFilter: (user, query) =>
                      user.username.toLowerCase().contains(query.toLowerCase()),
                  onSelected: (user) {
                    setState(() => _selectedUserId = user.id);
                  },
                  selectedItemId: _selectedUserId,
                  onClear: _selectedUserId != null
                      ? () => setState(() => _selectedUserId = null)
                      : null,
                ),

                // Customer Filter avec recherche
                _SearchableFilterChip<Customer>(
                  label: _selectedCustomerId == null
                      ? 'Client'
                      : auth.customers
                          .firstWhere((c) => c.id == _selectedCustomerId)
                          .name,
                  icon: Icons.shopping_bag_outlined,
                  isSelected: _selectedCustomerId != null,
                  items: auth.customers,
                  itemBuilder: (customer) => _CustomerListItem(customer: customer),
                  searchFilter: (customer, query) =>
                      customer.name.toLowerCase().contains(query.toLowerCase()) ||
                      (customer.phone?.toLowerCase().contains(query.toLowerCase()) ?? false),
                  onSelected: (customer) {
                    setState(() => _selectedCustomerId = customer.id);
                  },
                  selectedItemId: _selectedCustomerId,
                  onClear: _selectedCustomerId != null
                      ? () => setState(() => _selectedCustomerId = null)
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isToday() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _startDate!.year == today.year &&
        _startDate!.month == today.month &&
        _startDate!.day == today.day;
  }

  bool _isLast7Days() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return (_startDate!.difference(sevenDaysAgo).inDays.abs() <= 1) &&
        (_endDate!.difference(now).inDays.abs() <= 1);
  }

  bool _isLast30Days() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return (_startDate!.difference(thirtyDaysAgo).inDays.abs() <= 1) &&
        (_endDate!.difference(now).inDays.abs() <= 1);
  }

  Widget _buildSalesList(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.sales.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aucune vente enregistrée',
          );
        }

        var filteredSales = auth.sales.where((sale) {
          if (_searchQuery.isNotEmpty &&
              !sale.id.toString().contains(_searchQuery)) return false;

          if (_startDate != null) {
            if (sale.date.isBefore(_startDate!)) return false;
          }

          if (_endDate != null) {
            if (sale.date.isAfter(_endDate!)) return false;
          }

          if (_selectedUserId != null && sale.userId != _selectedUserId)
            return false;
          if (_selectedCustomerId != null &&
              sale.customerId != _selectedCustomerId) return false;

          return true;
        }).toList();

        if (filteredSales.isEmpty) {
          return const EmptyState(
            icon: Icons.filter_list_off,
            title: 'Aucune vente trouvée',
            subtitle: 'Essayez de modifier vos filtres',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredSales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sale = filteredSales[index];
            return _SaleCard(sale: sale);
          },
        );
      },
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final _startDateController = TextEditingController();
    final _endDateController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sélectionner une période'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de début',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      startDate = pickedDate;
                      _startDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date de début.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de fin',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      endDate = pickedDate;
                      _endDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date de fin.';
                    }
                    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
                      return 'La date de fin ne peut pas être antérieure à la date de début.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, DateTimeRange(start: startDate!, end: endDate!));
                }
              },
              child: const Text('Exporter'),
            ),
          ],
        );
      },
    ).then((dateRange) async {
      if (dateRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exportation annulée.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final adjustedEndDate = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
      final List<SaleWithItems> salesData = await auth.getSalesWithItemsInDateRange(dateRange.start, adjustedEndDate);

      if (salesData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune vente à exporter pour cette période.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final excel = exc.Excel.createExcel();
      final exc.Sheet sheet = excel['Ventes'];
      excel.setDefaultSheet('Ventes');
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final headers = [
        'ID Vente', 'Date', 'Heure', 'Caissier', 'Client',
        'Nom Produit', 'Quantité', 'Prix Unitaire', 'Sous-total'
      ];
      sheet.appendRow(headers.map((h) => exc.TextCellValue(h)).toList());

      for (final saleWithItems in salesData) {
        final sale = saleWithItems.sale;
        final cashier = auth.users.firstWhere((u) => u.id == sale.userId, orElse: () => User(id: -1, username: 'Inconnu', passwordHash: '', role: '')).username;
        final customer = sale.customerId != null
            ? auth.customers.firstWhere((c) => c.id == sale.customerId, orElse: () => Customer(id: -1, name: 'Inconnu')).name
            : 'Client au comptoir';
        
        final date = DateFormat('dd/MM/yyyy').format(sale.date);
        final time = DateFormat('HH:mm:ss').format(sale.date);

        for (final item in saleWithItems.items) {
          final row = [
            exc.IntCellValue(sale.id!),
            exc.TextCellValue(date),
            exc.TextCellValue(time),
            exc.TextCellValue(cashier),
            exc.TextCellValue(customer),
            exc.TextCellValue(item.productName),
            exc.IntCellValue(item.quantity),
            exc.DoubleCellValue(item.unitPrice),
            exc.DoubleCellValue(item.subtotal),
          ];
          sheet.appendRow(row);
        }
      }

      final bytes = excel.encode();
      if (bytes != null) {
        final formattedStartDate = DateFormat('yyyy-MM-dd').format(dateRange.start);
        final formattedEndDate = DateFormat('yyyy-MM-dd').format(dateRange.end);
        final String? outputFile = await FilePicker.platform.saveFile(
          fileName: 'export_ventes_${formattedStartDate}_au_${formattedEndDate}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ventes exportées avec succès vers : $outputFile'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'exportation des ventes.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _exportSalesToExcel(BuildContext context) async {
    await _showCustomDateRangePicker(context);
  }
}
