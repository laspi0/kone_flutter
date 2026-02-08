import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_sidebar.dart';
import '../auth_provider.dart';
import '../providers/product_provider.dart';

part 'home/home_widgets.dart';

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
                icon: Icon(
                  auth.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
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
                    user.isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline,
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
    return Consumer2<AuthProvider, ProductProvider>(
      builder: (context, auth, productProvider, _) {
        final totalSales = auth.sales.length;
        final totalRevenue = auth.sales.fold(
          0.0,
          (sum, sale) => sum + sale.total,
        );
        final todaySales = auth.sales.where((s) {
          final today = DateTime.now();
          return s.date.day == today.day &&
              s.date.month == today.month &&
              s.date.year == today.year;
        }).length;
        final todayRevenue = auth.sales
            .where((s) {
              final today = DateTime.now();
              return s.date.day == today.day &&
                  s.date.month == today.month &&
                  s.date.year == today.year;
            })
            .fold(0.0, (sum, sale) => sum + sale.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                  subtitle: todaySales > 0
                      ? 'Moy: ${(todayRevenue / todaySales).toStringAsFixed(0)} F'
                      : null,
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Produits',
                  value: '${productProvider.products.length}',
                  color: Colors.purple,
                  subtitle:
                      '${productProvider.products.where((p) => p.stock < 10).length} stock bas',
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune vente enregistrée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentSales.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
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
