import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          // Theme toggle
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              context.read<AuthProvider>().toggleTheme();
            },
            tooltip: 'Changer le thème',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const _AppDrawer(),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser!;
          
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.isAdmin 
                          ? Icons.admin_panel_settings 
                          : Icons.person,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Welcome message
                  Text(
                    'Bienvenue,',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.username,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: user.isAdmin 
                          ? Colors.orange.shade100 
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.isAdmin 
                            ? Colors.orange 
                            : Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isAdmin 
                              ? Icons.verified_user 
                              : Icons.badge,
                          color: user.isAdmin 
                              ? Colors.orange.shade700 
                              : Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isAdmin ? 'Administrateur' : 'Caissier',
                          style: TextStyle(
                            color: user.isAdmin 
                                ? Colors.orange.shade900 
                                : Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Info card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Authentification réussie !',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.isAdmin
                                ? 'Vous avez accès à toutes les fonctionnalités administratives.'
                                : 'Vous pouvez effectuer des ventes et gérer les produits.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Permissions list
                          _buildPermissionItem(
                            context,
                            Icons.dashboard,
                            'Tableau de bord',
                            true,
                          ),
                          _buildPermissionItem(
                            context,
                            Icons.shopping_cart,
                            'Gérer les ventes',
                            true,
                          ),
                          _buildPermissionItem(
                            context,
                            Icons.inventory,
                            'Gérer les produits',
                            user.isAdmin,
                          ),
                          _buildPermissionItem(
                            context,
                            Icons.people,
                            'Gérer les clients',
                            user.isAdmin,
                          ),
                          _buildPermissionItem(
                            context,
                            Icons.settings,
                            'Paramètres système',
                            user.isAdmin,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout button
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context,
    IconData icon,
    String label,
    bool hasAccess,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasAccess ? Icons.check_circle : Icons.cancel,
            color: hasAccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: hasAccess ? Colors.black87 : Colors.grey,
                decoration: hasAccess ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
              context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

// Drawer pour la navigation
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser!;
          
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.store,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shop Manager',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.username} • ${user.isAdmin ? "Admin" : "Caissier"}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Accueil'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Se déconnecter',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  authProvider.logout();
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