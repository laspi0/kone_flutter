import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../widgets/app_sidebar.dart';

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
        onPressed: () => _showCreateEditUserDialog(context),
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
          Text(
            'Gestion des Utilisateurs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -1,
            ),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilisateurs',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${auth.users.length} utilisateur${auth.users.length > 1 ? 's' : ''} trouvé${auth.users.length > 1 ? 's' : ''}',
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

        var filteredUsers = auth.users.where((user) {
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
              onTap: () => _showCreateEditUserDialog(context, user: user),
              onDelete: () => _confirmDeleteUser(context, user),
            );
          },
        );
      },
    );
  }

  void _showCreateEditUserDialog(BuildContext context, {User? user}) {
    showDialog(context: context, builder: (context) => _UserDialog(user: user));
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

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isSuperuser
        ? Colors.purple.shade300
        : user.isAdmin
            ? Colors.blue.shade300
            : Colors.green.shade300;
            
    final roleIcon = user.isSuperuser
        ? Icons.verified_user_outlined
        : user.isAdmin
            ? Icons.shield_outlined
            : Icons.person_outline;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(13)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: roleColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(roleIcon, color: roleColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.check_circle_outline : Icons.highlight_off_outlined,
                          size: 14,
                          color: user.isActive ? Colors.green : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 13,
                            color: user.isActive ? Colors.green : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer.withAlpha(77),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final User? user;
  const _UserDialog({this.user});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String? _selectedRole;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'utilisateur' : 'Créer un utilisateur'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nom d\'utilisateur *', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Veuillez entrer un nom d\'utilisateur';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEditing ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe *',
                  border: const OutlineInputBorder()
                ),
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) return 'Veuillez entrer un mot de passe';
                  if (value != null && value.isNotEmpty && value.length < 6) return '6 caractères minimum';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle *', border: OutlineInputBorder()),
                items: <String>['superuser', 'admin', 'cashier']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedRole = newValue);
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un rôle' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Compte actif'),
                value: _isActive,
                onChanged: (bool value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final isEditing = widget.user != null;

    if (isEditing) {
      final updatedUser = widget.user!.copyWith(
        username: _usernameController.text,
        passwordHash: _passwordController.text.isNotEmpty ? _passwordController.text : widget.user!.passwordHash,
        role: _selectedRole,
        isActive: _isActive,
      );
      await auth.updateUser(updatedUser);
    } else {
      final newUser = User(
        username: _usernameController.text,
        passwordHash: _passwordController.text,
        role: _selectedRole!,
        isActive: _isActive,
      );
      await auth.createUser(newUser);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Utilisateur mis à jour' : 'Utilisateur créé'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

