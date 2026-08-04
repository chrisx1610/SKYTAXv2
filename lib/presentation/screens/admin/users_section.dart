import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/models.dart';
import '../../state/app_controller.dart';
import '../../widgets/kiosk_widgets.dart';

/// Gestión del usuario administrador del sistema.
///
/// El sistema trabaja con un único usuario administrativo: no se crean ni
/// eliminan usuarios, solo se puede cambiar su nombre y su contraseña.
class UsersSection extends StatefulWidget {
  const UsersSection({super.key});

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  AppUser? _admin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppController controller = context.read<AppController>();
    try {
      final List<AppUser> users = await controller.users.getAll();
      if (!mounted) return;
      setState(() {
        _admin =
            users.where((user) => user.isAdmin).firstOrNull ?? users.firstOrNull;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.instance
          .error('No se pudo cargar el usuario administrador', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final AppUser? admin = _admin;
    if (admin == null) return;
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserDialog(existing: admin),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppUser? admin = _admin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: s.sectionUsers),
          const SizedBox(height: 8),
          Text(
            s.singleAdminNote,
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (admin == null)
            Text(
              s.noRecords,
              style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
            )
          else
            AdminListCard(
              icon: Icons.shield_rounded,
              iconBackground: scheme.tertiaryContainer,
              iconColor: scheme.onTertiaryContainer,
              title: '${admin.username} · ${admin.fullName}',
              subtitle: s.roleAdmin,
              onTap: _edit,
              actions: [
                IconButton(
                  tooltip: s.edit,
                  iconSize: 26,
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: _edit,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Diálogo de edición del administrador (nombre, usuario y contraseña).
class _UserDialog extends StatefulWidget {
  const _UserDialog({required this.existing});

  final AppUser existing;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _username =
      TextEditingController(text: widget.existing.username);
  late final TextEditingController _fullName =
      TextEditingController(text: widget.existing.fullName);
  final TextEditingController _password = TextEditingController();
  String? _usernameError;
  bool _saving = false;

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppController controller = context.read<AppController>();
    final AppStrings s = controller.strings;
    setState(() => _usernameError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final bool duplicated = await controller.users.usernameExists(
        _username.text,
        excludeId: widget.existing.id,
      );
      if (duplicated) {
        setState(() {
          _saving = false;
          _usernameError = s.usernameExists;
        });
        return;
      }
      final AppUser user = AppUser(
        id: widget.existing.id,
        username: _username.text.trim(),
        fullName: _fullName.text.trim(),
        role: widget.existing.role,
      );
      await controller.users.update(user, newPassword: _password.text);
      controller.refreshCurrentAdmin(user);
      await controller.audit('USUARIO_EDITADO', user.username);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      AppLogger.instance.error('No se pudo guardar el usuario', e, st);
      if (mounted) {
        setState(() {
          _saving = false;
          _usernameError = s.errorGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.watch<AppController>().strings;

    return AlertDialog(
      title: Text(s.editUser),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: s.usernameLabel,
                  errorText: _usernameError,
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? s.requiredField
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullName,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(labelText: s.fullNameField),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? s.requiredField
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: s.passwordLabel,
                  helperText: s.passwordKeepHint,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(s.save),
        ),
      ],
    );
  }
}
