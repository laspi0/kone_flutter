part of '../sales_screen.dart';

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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(102),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(77),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun client trouvé',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(128),
                      ),
                    ),
                  ],
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
