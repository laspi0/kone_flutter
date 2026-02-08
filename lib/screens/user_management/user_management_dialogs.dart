part of '../user_management_screen.dart';

class _UserDialog extends StatefulWidget {
  final User? user;
  final bool restrictToCashier;
  const _UserDialog({this.user, this.restrictToCashier = false});

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
    _usernameController =
        TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.restrictToCashier ? 'cashier' : widget.user?.role;
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
    final restrictToCashier = widget.restrictToCashier;

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
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom d\'utilisateur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEditing
                      ? 'Nouveau mot de passe (optionnel)'
                      : 'Mot de passe *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return '6 caractères minimum';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle *',
                  border: OutlineInputBorder(),
                ),
                items: (restrictToCashier
                        ? <String>['cashier']
                        : <String>['superuser', 'admin', 'cashier'])
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: restrictToCashier
                    ? null
                    : (String? newValue) {
                        setState(() => _selectedRole = newValue);
                      },
                validator: (value) {
                  return value == null ? 'Veuillez sélectionner un rôle' : null;
                },
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final isEditing = widget.user != null;
    final selectedRole = widget.restrictToCashier ? 'cashier' : _selectedRole;

    if (isEditing) {
      final updatedUser = widget.user!.copyWith(
        username: _usernameController.text,
        passwordHash: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : widget.user!.passwordHash,
        role: selectedRole,
        isActive: _isActive,
      );
      await auth.updateUser(updatedUser);
    } else {
      final newUser = User(
        username: _usernameController.text,
        passwordHash: _passwordController.text,
        role: selectedRole!,
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
