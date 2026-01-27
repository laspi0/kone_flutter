import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  DateTimeRange? _selectedRange;
  int? _selectedUserId;
  int? _selectedCustomerId;

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
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return IconButton(
                icon: Icon(
                  auth.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
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
        final hasActiveFilters = _selectedRange != null ||
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
                        _selectedRange = null;
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
                // Date Range Filter
                _FilterChip(
                  label: _selectedRange == null
                      ? 'Période'
                      : '${_selectedRange!.start.day}/${_selectedRange!.start.month} - ${_selectedRange!.end.day}/${_selectedRange!.end.month}',
                  icon: Icons.calendar_today_outlined,
                  isSelected: _selectedRange != null,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedRange,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme:
                                Theme.of(context).colorScheme.copyWith(
                                      primary:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() => _selectedRange = range);
                    }
                  },
                  onClear: _selectedRange != null
                      ? () => setState(() => _selectedRange = null)
                      : null,
                ),

                // User Filter
                _FilterChip(
                  label: _selectedUserId == null
                      ? 'Caissier'
                      : auth.users
                          .firstWhere((u) => u.id == _selectedUserId)
                          .username,
                  icon: Icons.person_outline,
                  isSelected: _selectedUserId != null,
                  onTap: () => _showUserFilterDialog(context, auth),
                  onClear: _selectedUserId != null
                      ? () => setState(() => _selectedUserId = null)
                      : null,
                ),

                // Customer Filter
                _FilterChip(
                  label: _selectedCustomerId == null
                      ? 'Client'
                      : auth.customers
                          .firstWhere((c) => c.id == _selectedCustomerId)
                          .name,
                  icon: Icons.shopping_bag_outlined,
                  isSelected: _selectedCustomerId != null,
                  onTap: () => _showCustomerFilterDialog(context, auth),
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

  void _showUserFilterDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par caissier'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...auth.users.map(
                (user) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(user.username),
                  trailing: _selectedUserId == user.id
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: _selectedUserId == user.id,
                  onTap: () {
                    setState(() => _selectedUserId = user.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showCustomerFilterDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par client'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...auth.customers.map(
                (customer) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle:
                      (customer.phone?.isNotEmpty == true) ? Text(customer.phone!) : null,
                  trailing: _selectedCustomerId == customer.id
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: _selectedCustomerId == customer.id,
                  onTap: () {
                    setState(() => _selectedCustomerId = customer.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
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

          if (_selectedRange != null) {
            if (sale.date.isBefore(_selectedRange!.start) ||
                sale.date.isAfter(_selectedRange!.end)) return false;
          }

          if (_selectedUserId != null && sale.userId != _selectedUserId)
            return false;
          if (_selectedCustomerId != null &&
              sale.customerId != _selectedCustomerId) return false;

          return true;
        }).toList();

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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({
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

class _SaleCard extends StatefulWidget {
  final Sale sale;

  const _SaleCard({required this.sale});

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _isExpanded = false;
  List<SaleItem>? _saleItems;

  @override
  Widget build(BuildContext context) {
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
                final auth = context.read<AuthProvider>();
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