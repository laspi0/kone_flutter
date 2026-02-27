part of '../sales_screen.dart';

class _AddCustomItemDialog extends StatefulWidget {
  final AuthProvider auth;

  const _AddCustomItemDialog({required this.auth});

  @override
  State<_AddCustomItemDialog> createState() => _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends State<_AddCustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addCustomItem() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final quantity = int.parse(_quantityController.text.trim());

      widget.auth.addCustomItemToCart(
        name: name,
        price: price,
        quantity: quantity,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name ajouté au panier.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un article personnalisé'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'article',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Prix (FCFA)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un prix';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Prix invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer une quantité';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Quantité invalide';
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
          onPressed: _addCustomItem,
          child: const Text('Ajouter'),
        ),
      ],
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
  final _formKey = GlobalKey<FormState>();
  final _amountPaidController = TextEditingController();
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_calculateChange);
    _amountPaidController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final amountPaid = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;
    setState(() {
      _change = amountPaid - widget.total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finaliser la vente'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total à payer: ${widget.total.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Montant reçu (FCFA)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed < widget.total) {
                  return 'Le montant doit être supérieur ou égal au total';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Monnaie à rendre: ${_change.toStringAsFixed(0)} FCFA'),
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
              Navigator.pop(context, double.parse(_amountPaidController.text.trim()));
            }
          },
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

class _CustomerSelectorContent extends StatefulWidget {
  final AuthProvider auth;

  const _CustomerSelectorContent({required this.auth});

  @override
  State<_CustomerSelectorContent> createState() => _CustomerSelectorContentState();
}

class _CustomerSelectorContentState extends State<_CustomerSelectorContent> {
  late Future<List<Customer>> _customersFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _customersFuture = widget.auth.databaseHelper.getCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Customer>>(
            future: _customersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucun client trouvé.'));
              } else {
                final customers = snapshot.data!
                    .where((customer) => customer.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: customers.length + 1, // +1 for "Client au comptoir"
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Client au comptoir" option
                      return _CustomerTile(
                        customer: Customer(
                          id: null,
                          name: 'Client au comptoir',
                          isWalkin: true,
                        ),
                        selected: widget.auth.selectedCustomer == null,
                        onTap: () {
                          widget.auth.selectCustomer(null);
                          Navigator.pop(context);
                        },
                      );
                    }
                    final customer = customers[index - 1];
                    return _CustomerTile(
                      customer: customer,
                      selected: widget.auth.selectedCustomer?.id == customer.id,
                      onTap: () {
                        widget.auth.selectCustomer(customer);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}