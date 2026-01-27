import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_sidebar.dart';
import '../auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/home'),
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
                        _buildStats(context, isDesktop),
                        const SizedBox(height: 32),
                        _buildRecentSales(context, isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : const _MobileDrawer(),
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
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          const Spacer(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return IconButton(
                icon: Icon(auth.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: auth.toggleTheme,
                tooltip: 'Changer le thème',
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
        final user = auth.currentUser;
        if (user == null) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user.username} 👋',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isAdmin 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                    size: 16,
                    color: user.isAdmin 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isAdmin ? 'Administrateur' : 'Caissier',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: user.isAdmin 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final totalSales = auth.sales.length;
        final totalRevenue = auth.sales.fold(0.0, (sum, sale) => sum + sale.total);
        final todaySales = auth.sales.where((s) {
          final today = DateTime.now();
          return s.date.day == today.day && 
                 s.date.month == today.month && 
                 s.date.year == today.year;
        }).length;
        final todayRevenue = auth.sales.where((s) {
          final today = DateTime.now();
          return s.date.day == today.day && 
                 s.date.month == today.month && 
                 s.date.year == today.year;
        }).fold(0.0, (sum, sale) => sum + sale.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.3 : 1.1,
              children: [
                _StatCard(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Ventes aujourd\'hui',
                  value: '$todaySales',
                  color: Colors.blue,
                  onTap: () => context.go('/sales'),
                ),
                _StatCard(
                  icon: Icons.attach_money,
                  label: 'CA aujourd\'hui',
                  value: '${todayRevenue.toStringAsFixed(0)} F',
                  color: Colors.green,
                  subtitle: todaySales > 0 ? 'Moy: ${(todayRevenue / todaySales).toStringAsFixed(0)} F' : null,
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Produits',
                  value: '${auth.products.length}',
                  color: Colors.purple,
                  subtitle: '${auth.products.where((p) => p.stock < 10).length} stock bas',
                  onTap: () => context.go('/products'),
                ),
                _StatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Total ventes',
                  value: '$totalSales',
                  color: Colors.orange,
                  subtitle: '${totalRevenue.toStringAsFixed(0)} F',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSales(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.sales.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune vente enregistrée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.go('/sales'),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Nouvelle vente'),
                  ),
                ],
              ),
            ),
          );
        }

        final recentSales = auth.sales.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dernières ventes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/sale-history'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentSales.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                ),
                itemBuilder: (context, index) {
                  final sale = recentSales[index];
                  return _SaleListItem(sale: sale);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaleListItem extends StatelessWidget {
  final sale;

  const _SaleListItem({required this.sale});

  @override
  Widget build(BuildContext context) {
    final time = '${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.receipt_long_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        'Vente #${sale.id}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(time),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${sale.total.toStringAsFixed(0)} F',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sale.status == 'completed' ? 'Terminé' : sale.status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) return const SizedBox();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.store, size: 48),
                    const SizedBox(height: 12),
                    Text('Shop Manager', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(user.username, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Accueil'), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(Icons.point_of_sale), title: const Text('Point de vente'), onTap: () { Navigator.pop(context); context.go('/sales'); }),
              ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Historique'), onTap: () { Navigator.pop(context); context.go('/sale-history'); }),
              if (user.isAdmin) ...[
                const Divider(),
                ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Produits'), onTap: () { Navigator.pop(context); context.go('/products'); }),
                ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Catégories'), onTap: () { Navigator.pop(context); context.go('/categories'); }),
              ],
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Déconnexion', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  auth.logout();
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}