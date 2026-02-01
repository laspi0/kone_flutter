import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../auth_provider.dart';
import '../widgets/app_sidebar.dart';
import '../models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/settings'),
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
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return _buildSettingsSections(context, isDesktop, auth);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gérez vos préférences et paramètres de l\'application',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Future<void> _pickAndSaveLogo(AuthProvider auth) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final documentsDir = await getApplicationDocumentsDirectory();
      
      // Use a consistent filename for the logo
      final fileExtension = p.extension(sourceFile.path);
      final targetFile = File(p.join(documentsDir.path, 'shop_logo$fileExtension'));

      // Copy the file to the app's documents directory
      await sourceFile.copy(targetFile.path);

      // Update the shop info with the new logo path
      final updatedShopInfo = auth.shopInfo!.copyWith(logo: targetFile.path);
      await auth.updateShopInfo(updatedShopInfo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildSettingsSections(
      BuildContext context, bool isDesktop, AuthProvider auth) {
    return Column(
      children: [
        // Section 1: Profil Utilisateur
        _SettingsSection(
          title: 'Profil Utilisateur',
          icon: Icons.person_outline,
          children: [
            _SettingsTile(
              icon: Icons.edit_outlined,
              title: 'Modifier le nom d\'utilisateur',
              subtitle: 'Changer votre nom d\'utilisateur',
              onTap: () => _showEditUsernameDialog(context),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              subtitle: 'Mettre à jour votre mot de passe',
              onTap: () => _showChangePasswordDialog(context),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Section 2: Informations Boutique (ADMIN uniquement)
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.currentUser!.isAdmin) return const SizedBox();
            
            return Column(
              children: [
                _SettingsSection(
                  title: 'Informations Boutique',
                  icon: Icons.store_outlined,
                  customHeader: auth.shopInfo?.logo != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          width: 150,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.file(
                            File(auth.shopInfo!.logo!),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.store_mall_directory_outlined, size: 64),
                          ),
                        ),
                      ),
                    )
                  : null,
                  children: [
                    _SettingsTile(
                      icon: Icons.business_outlined,
                      title: 'Nom de la boutique',
                      subtitle: auth.shopInfo!.name,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        _showEditShopInfoDialog(
                          context,
                          auth,
                          'Modifier le nom de la boutique',
                          auth.shopInfo!.name,
                          'Nom de la boutique',
                          Icons.business_outlined,
                          (newValue) {
                            final updatedShopInfo =
                                auth.shopInfo!.copyWith(name: newValue);
                            auth.updateShopInfo(updatedShopInfo);
                          },
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      title: 'Adresse',
                      subtitle: auth.shopInfo!.address,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        _showEditShopInfoDialog(
                          context,
                          auth,
                          'Modifier l\'adresse',
                          auth.shopInfo!.address,
                          'Adresse',
                          Icons.location_on_outlined,
                          (newValue) {
                            final updatedShopInfo =
                                auth.shopInfo!.copyWith(address: newValue);
                            auth.updateShopInfo(updatedShopInfo);
                          },
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.phone_outlined,
                      title: 'Téléphone',
                      subtitle: auth.shopInfo!.phone,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        _showEditShopInfoDialog(
                          context,
                          auth,
                          'Modifier le numéro de téléphone',
                          auth.shopInfo!.phone,
                          'Téléphone',
                          Icons.phone_outlined,
                          (newValue) {
                            final updatedShopInfo =
                                auth.shopInfo!.copyWith(phone: newValue);
                            auth.updateShopInfo(updatedShopInfo);
                          },
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: auth.shopInfo!.email,
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        _showEditShopInfoDialog(
                          context,
                          auth,
                          'Modifier l\'email',
                          auth.shopInfo!.email,
                          'Email',
                          Icons.email_outlined,
                          (newValue) {
                            final updatedShopInfo =
                                auth.shopInfo!.copyWith(email: newValue);
                            auth.updateShopInfo(updatedShopInfo);
                          },
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.image_outlined,
                      title: 'Logo de la boutique',
                      subtitle: auth.shopInfo?.logo != null ? 'Changer le logo' : 'Ajouter un logo',
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _pickAndSaveLogo(auth),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // Section 3: Alertes
        _SettingsSection(
          title: 'Alertes',
          icon: Icons.notifications_outlined,
          children: [
            _SettingsTile(
              icon: Icons.warning_amber_outlined,
              title: 'Seuil de stock faible',
              subtitle: 'Actuel: ${auth.shopInfo!.lowStockThreshold}',
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                _showEditLowStockThresholdDialog(context, auth);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Section 4: À propos
        _SettingsSection(
          title: 'À propos',
          icon: Icons.info_outline,
          children: [
            _SettingsTile(
              icon: Icons.code_outlined,
              title: 'Version de l\'application',
              subtitle: '1.0.0',
              trailing: null,
            ),
            _SettingsTile(
              icon: Icons.support_agent_outlined,
              title: 'Contact Support',
              subtitle: 'pro4307191@gmail.com',
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () {
                // TODO: Ouvrir email ou page de contact
              },
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Bouton de déconnexion
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Text(
                      'Se déconnecter de votre compte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _showLogoutDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== DIALOGUES POUR PROFIL UTILISATEUR ==========

  void _showEditUsernameDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentUsername = auth.currentUser!.username;
    final controller = TextEditingController(text: currentUsername);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom d\'utilisateur'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nouveau nom d\'utilisateur',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom d\'utilisateur ne peut pas être vide';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
                autofocus: true,
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newUsername = controller.text.trim();
                
                await auth.updateUsername(newUsername);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nom d\'utilisateur mis à jour avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => obscureCurrent = !obscureCurrent);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez votre mot de passe actuel';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => obscureNew = !obscureNew);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez un nouveau mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Les mots de passe ne correspondent pas';
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final auth = context.read<AuthProvider>();
                  
                  bool success = await auth.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                                    
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Mot de passe changé avec succès'
                              : 'Mot de passe actuel incorrect',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
              final auth = context.read<AuthProvider>();
              auth.logout();
              Navigator.pop(context);
              context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGUES POUR INFORMATIONS BOUTIQUE ==========

  void _showEditShopInfoDialog(
      BuildContext context,
      AuthProvider auth,
      String title,
      String currentValue,
      String labelText,
      IconData icon,
      Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(icon),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ ne peut pas être vide';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await onSave(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$labelText mis à jour avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGUES POUR ALERTES ==========

  void _showEditLowStockThresholdDialog(
      BuildContext context, AuthProvider auth) {
    final currentThreshold = auth.shopInfo!.lowStockThreshold;
    final controller =
        TextEditingController(text: currentThreshold.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le seuil de stock faible'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Seuil de stock faible',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.warning_amber_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le seuil ne peut pas être vide';
              }
              final int? threshold = int.tryParse(value.trim());
              if (threshold == null || threshold < 0) {
                return 'Veuillez entrer un nombre valide (>= 0)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newThreshold = int.parse(controller.text.trim());
                final updatedShopInfo =
                    auth.shopInfo!.copyWith(lowStockThreshold: newThreshold);
                await auth.updateShopInfo(updatedShopInfo);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seuil de stock faible mis à jour'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

// ========== WIDGETS RÉUTILISABLES ==========

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? customHeader;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    this.customHeader,
    required this.children,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (customHeader != null)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: customHeader,
            ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          indent: 20,
          endIndent: 20,
        ),
        InkWell(
          onTap: onTap,
          borderRadius: (title == 'Logo de la boutique' || title == 'Contact Support') 
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}