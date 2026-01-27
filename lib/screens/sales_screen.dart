import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../auth_provider.dart';
import '../models.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDesktop),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildProductsList(context, isDesktop),
                      ),
                      if (isDesktop)
                        Container(
                          width: 400,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: _buildCart(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? _buildMobileCart(context) : null,
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Shop Manager',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _SidebarItem(icon: Icons.home_outlined, label: 'Accueil', onTap: () => context.go('/home')),
                _SidebarItem(icon: Icons.inventory_2_outlined, label: 'Produits', onTap: () => context.go('/products')),
                _SidebarItem(icon: Icons.category_outlined, label: 'Catégories', onTap: () => context.go('/categories')),
                _SidebarItem(icon: Icons.shopping_cart, label: 'Ventes', selected: true, onTap: () {}),
              ],
            ),
          ),
        ],
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
          Expanded(
            child: Text(
              'Nouvelle Vente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
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

  Widget _buildProductsList(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        var filteredProducts = auth.products.where((p) {
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) && p.stock > 0;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isDesktop ? 40 : 20),
              child: TextField(
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
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('Aucun produit disponible', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _ProductCard(
                          product: product,
                          categoryName: auth.getCategoryName(product.categoryId),
                          onAdd: () => auth.addToCart(product),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCart(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Panier',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (auth.cart.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmClearCart(context, auth),
                      tooltip: 'Vider le panier',
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
            Expanded(
              child: auth.cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('Panier vide', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: auth.cart.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = auth.cart[index];
                        return _CartItemCard(item: item);
                      },
                    ),
            ),
            if (auth.cart.isNotEmpty) ...[
              Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${auth.cartTotal.toStringAsFixed(0)} FCFA',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _completeSale(context, auth),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('Finaliser la vente', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMobileCart(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.cart.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${auth.cartItemCount} article(s)', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '${auth.cartTotal.toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => _showMobileCart(context),
                child: const Text('Voir le panier'),
              ),
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildCart(context),
        ),
      ),
    );
  }

  void _completeSale(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la vente'),
        content: Text('Total: ${auth.cartTotal.toStringAsFixed(0)} FCFA\n\nVoulez-vous finaliser cette vente ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await auth.completeSale();
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vente enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Erreur lors de la vente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          FilledButton(
            onPressed: () {
              auth.clearCart();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w500 : FontWeight.normal, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback onAdd;

  const _ProductCard({required this.product, required this.categoryName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  categoryName,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${product.price.toStringAsFixed(0)} F',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(fontSize: 11, color: product.stock < 10 ? Colors.red : Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.product.price.toStringAsFixed(0)} FCFA',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => auth.removeFromCart(item.product),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => auth.updateCartQuantity(item.product, item.quantity - 1),
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.quantity}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => auth.updateCartQuantity(item.product, item.quantity + 1),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  Text(
                    '${item.subtotal.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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