import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Titre
                        Text(
                          'Shop Manager',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour continuer',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre nom d\'utilisateur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 8),
                        
                        // Error message
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            if (authProvider.errorMessage != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Login button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Comptes de test
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comptes de test :',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTestAccount('Admin', 'admin', 'admin123'),
                              const SizedBox(height: 4),
                              _buildTestAccount('Caissier', 'caissier', 'caissier123'),
                              const SizedBox(height: 4),
                              _buildTestAccount('Caissier', 'marie', 'marie123'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestAccount(String role, String username, String password) {
    return Row(
      children: [
        Icon(
          role == 'Admin' ? Icons.admin_panel_settings : Icons.person,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$role: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '$username / $password',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}