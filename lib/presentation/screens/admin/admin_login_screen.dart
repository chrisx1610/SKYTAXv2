import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';
import 'admin_home_screen.dart';

/// Autenticación para acceder al panel administrativo.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final AppController controller = context.read<AppController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final bool ok =
        await controller.adminLogin(_username.text, _password.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = controller.strings.invalidCredentials;
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AdminHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;

    return KioskScaffold(
      title: s.adminLoginTitle,
      maxWidth: 560,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _username,
                enabled: !_loading,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  labelText: s.usernameLabel,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                enabled: !_loading,
                obscureText: true,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  labelText: s.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_rounded),
                  errorText: _error,
                ),
                onSubmitted: (_) => _loading ? null : _login(),
              ),
              const SizedBox(height: 28),
              BigActionButton(
                label: s.login,
                icon: Icons.login_rounded,
                onPressed: _loading ? null : _login,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                  child: Text(s.back),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
