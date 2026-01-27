import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../widgets/app_sidebar.dart'; // New import

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/categories'), // Replaced sidebar
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
                        _buildCategoriesList(context, isDesktop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAdmin) return const SizedBox();
          return FloatingActionButton(
            onPressed: () => _showCategoryDialog(context, null),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
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
          const Spacer(),
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

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégories',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${auth.categories.length} catégorie${auth.categories.length > 1 ? 's' : ''} • ${auth.products.length} produit${auth.products.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesList(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Aucune catégorie', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: auth.categories.length,
          itemBuilder: (context, index) {
            final category = auth.categories[index];
            final productCount = auth.products.where((p) => p.categoryId == category.id).length;
            return _CategoryCard(
              category: category,
              productCount: productCount,
              onTap: auth.isAdmin ? () => _showCategoryDialog(context, category) : null,
              onDelete: auth.isAdmin ? () => _confirmDelete(context, category) : null,
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, Category? category) {
    showDialog(context: context, builder: (context) => _CategoryDialog(category: category));
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer "${category.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              context.read<AuthProvider>().deleteCategory(category.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catégorie supprimée')));
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}



class _CategoryCard extends StatelessWidget {
  final Category category;
  final int productCount;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _CategoryCard({required this.category, required this.productCount, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.category, size: 24, color: Theme.of(context).colorScheme.primary),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$productCount produit${productCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(text: widget.category?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nouvelle catégorie' : 'Modifier la catégorie'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optionnelle)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final category = Category(
      id: widget.category?.id,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    final auth = context.read<AuthProvider>();
    if (widget.category == null) {
      auth.addCategory(category);
    } else {
      auth.updateCategory(category);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.category == null ? 'Catégorie ajoutée' : 'Catégorie modifiée')));
  }
}