import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final String currentPage;

  const AppSidebar({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
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
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) return const SizedBox();

          return Column(
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
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Shop Manager',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    SidebarItem(
                      icon: Icons.home_outlined,
                      label: 'Accueil',
                      selected: currentPage == '/home',
                      onTap: () => context.go('/home'),
                    ),
                    SidebarItem(
                      icon: Icons.point_of_sale,
                      label: 'Point de vente',
                      selected: currentPage == '/sales',
                      onTap: () => context.go('/sales'),
                    ),
                    SidebarItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Historique',
                      selected: currentPage == '/sale-history',
                      onTap: () => context.go('/sale-history'),
                    ),
                    const SizedBox(height: 8),
                    if (user.isAdmin) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'GESTION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                      SidebarItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Produits',
                        selected: currentPage == '/products',
                        onTap: () => context.go('/products'),
                      ),
                      SidebarItem(
                        icon: Icons.category_outlined,
                        label: 'Catégories',
                        selected: currentPage == '/categories',
                        onTap: () => context.go('/categories'),
                      ),
                      SidebarItem(
                        icon: Icons.people_outline,
                        label: 'Clients',
                        selected: currentPage == '/customers',
                        onTap: () => context.go('/customers'),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Déconnexion',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    auth.logout();
                    context.go('/login');
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
