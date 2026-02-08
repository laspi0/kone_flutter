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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune vente enregistrée',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune vente trouvée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez de modifier vos filtres',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
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

// Widget pour les filtres de date simple
class _DatePickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            if (isSelected && onClear != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget pour les filtres de date rapides
class _QuickDateFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les filtres avec recherche (caissier, client)
class _SearchableFilterChip<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final bool Function(T, String) searchFilter;
  final Function(T) onSelected;
  final int? selectedItemId;
  final VoidCallback? onClear;

  const _SearchableFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.items,
    required this.itemBuilder,
    required this.searchFilter,
    required this.onSelected,
    required this.selectedItemId,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSearchDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected && onClear != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SearchableDialog<T>(
        title: label,
        items: items,
        itemBuilder: itemBuilder,
        searchFilter: searchFilter,
        onSelected: onSelected,
        selectedItemId: selectedItemId,
      ),
    );
  }
}

// Dialog avec recherche
class _SearchableDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final bool Function(T, String) searchFilter;
  final Function(T) onSelected;
  final int? selectedItemId;

  const _SearchableDialog({
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.searchFilter,
    required this.onSelected,
    required this.selectedItemId,
  });

  @override
  State<_SearchableDialog<T>> createState() => _SearchableDialogState<T>();
}

class _SearchableDialogState<T> extends State<_SearchableDialog<T>> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return widget.searchFilter(item, _searchQuery);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            const SizedBox(height: 16),

            // List
            Flexible(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun résultat',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return InkWell(
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
                          child: widget.itemBuilder(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher un utilisateur dans la liste
class _UserListItem extends StatelessWidget {
  final User user;

  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              user.username[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.username,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher un client dans la liste
class _CustomerListItem extends StatelessWidget {
  final Customer customer;

  const _CustomerListItem({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (customer.phone?.isNotEmpty == true)
                  Text(
                    customer.phone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatefulWidget {
  final Sale sale;

  const _SaleCard({required this.sale});

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _isExpanded = false;
  List<SaleItem>? _saleItems;

  void _showDeleteConfirmationDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la vente #${widget.sale.id} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.deleteSale(widget.sale.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vente supprimée avec succès.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final date =
        '${widget.sale.date.day}/${widget.sale.date.month}/${widget.sale.date.year}';
    final time =
        '${widget.sale.date.hour.toString().padLeft(2, '0')}:${widget.sale.date.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              if (!_isExpanded && _saleItems == null) {
                _saleItems = await auth.getSaleItems(widget.sale.id!);
              }
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vente #${widget.sale.id}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.sale.total.toStringAsFixed(0)} F',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Terminé',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  if (auth.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _showDeleteConfirmationDialog(context, auth),
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && _saleItems != null) ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Articles',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._saleItems!.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} F',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.subtotal.toStringAsFixed(0)} F',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.08),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.sale.total.toStringAsFixed(0)} FCFA',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}