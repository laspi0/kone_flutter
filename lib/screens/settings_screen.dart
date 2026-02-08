import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../auth_provider.dart';
import '../widgets/app_sidebar.dart';

part 'settings/settings_dialogs.dart';
part 'settings/settings_widgets.dart';

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
            color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
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
                    .withAlpha(153),
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

        // Section 4: Gestion des Utilisateurs (SUPERUSER / ADMIN)
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.currentUser!.isSuperuser && !auth.currentUser!.isAdmin) {
              return const SizedBox();
            }
            
            return Column(
              children: [
                _SettingsSection(
                  title: auth.currentUser!.isSuperuser
                      ? 'Gestion des Utilisateurs'
                      : 'Gestion des Caissiers',
                  icon: Icons.people_outline,
                  children: [
                    _SettingsTile(
                      icon: Icons.manage_accounts_outlined,
                      title: auth.currentUser!.isSuperuser
                          ? 'Gérer les comptes utilisateurs'
                          : 'Gérer les comptes caissiers',
                      subtitle: auth.currentUser!.isSuperuser
                          ? 'Créer, modifier ou supprimer des utilisateurs'
                          : 'Créer, modifier ou supprimer des caissiers',
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        context.go('/users-management');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // Section 5: À propos
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
              color: Theme.of(context).colorScheme.error.withAlpha(77),
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
                            .withAlpha(179),
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
}
