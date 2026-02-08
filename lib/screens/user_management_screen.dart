import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/access_denied.dart';

part 'user_management/user_management_dialogs.dart';
part 'user_management/user_management_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final auth = context.watch<AuthProvider>();
    final canManageAll = auth.currentUser?.isSuperuser ?? false;
    final canManageCashier = auth.currentUser?.isAdmin ?? false;

    if (!canManageAll && !canManageCashier) {
      return const AccessDenied(
        title: 'Accès refusé',
        message: 'Cette section est réservée aux administrateurs.',
        actionLabel: 'Retour à l\'accueil',
        actionRoute: '/home',
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/users-management'),
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
                        _buildUserList(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditUserDialog(
          context,
          restrictToCashier: !canManageAll,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(13))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/settings'),
            ),
          if (isDesktop) const SizedBox(width: 16),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final canManageAll = auth.currentUser?.isSuperuser ?? false;
              return Text(
                canManageAll ? 'Gestion des Utilisateurs' : 'Gestion des Caissiers',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).loadUsers(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final canManageAll = auth.currentUser?.isSuperuser ?? false;
        final total = canManageAll
            ? auth.users.length
            : auth.users.where((user) => user.role == 'cashier').length;
        final title = canManageAll ? 'Utilisateurs' : 'Caissiers';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$total utilisateur${total > 1 ? 's' : ''} trouvé${total > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
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
          hintText: 'Rechercher un utilisateur...',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withAlpha(102)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.users.isEmpty && auth.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (auth.users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.onSurface.withAlpha(51)),
                  const SizedBox(height: 16),
                  Text('Aucun utilisateur', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(128))),
                ],
              ),
            ),
          );
        }

        final canManageAll = auth.currentUser?.isSuperuser ?? false;
        var filteredUsers = auth.users.where((user) {
          if (!canManageAll && user.role != 'cashier') return false;
          return user.username.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
        
        if (filteredUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Text('Aucun résultat', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(128))),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredUsers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _UserCard(
              user: user,
              onTap: () => _showCreateEditUserDialog(
                context,
                user: user,
                restrictToCashier: !canManageAll,
              ),
              onDelete: () => _confirmDeleteUser(context, user),
            );
          },
        );
      },
    );
  }

  void _showCreateEditUserDialog(
    BuildContext context, {
    User? user,
    bool restrictToCashier = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: user,
        restrictToCashier: restrictToCashier,
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, User user) {
    final auth = context.read<AuthProvider>();
    if (user.id == auth.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas supprimer votre propre compte.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur ${user.username} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await auth.deleteUser(user.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Utilisateur ${user.username} supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
