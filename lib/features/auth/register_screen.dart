import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/wplus_api.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _asCreator = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(wplusApiProvider);
      await api.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim().isEmpty
            ? _usernameController.text.trim()
            : _displayNameController.text.trim(),
        asCreator: _asCreator,
      );
      await ref.read(walletBalanceProvider.notifier).refresh();
      ref.invalidate(currentUserProvider);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _error = 'Registration failed. Email or username may be taken.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(labelText: 'Display Name (optional)', prefixIcon: Icon(Icons.badge_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (min 6 chars)', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Register as Creator'),
            value: _asCreator,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _asCreator = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: _loading ? 'CREATING...' : 'CREATE ACCOUNT',
            icon: Icons.person_add,
            expanded: true,
            onPressed: _loading ? () {} : _register,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}
