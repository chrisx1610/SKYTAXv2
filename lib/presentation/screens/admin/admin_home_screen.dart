import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/app_strings.dart';
import '../../state/app_controller.dart';
import '../history_screen.dart';
import 'aircraft_section.dart';
import 'pending_section.dart';
import 'reports_section.dart';
import 'settings_section.dart';
import 'users_section.dart';

/// Ancho mínimo para mostrar la barra de navegación lateral fija.
/// Por debajo, el menú pasa a un panel desplegable para no robarle
/// ancho al contenido.
const double _kRailBreakpoint = 720;

/// Panel administrativo con navegación adaptable entre secciones.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  Future<void> _logout() async {
    final NavigatorState navigator = Navigator.of(context);
    await context.read<AppController>().adminLogout();
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;

    final List<(IconData, String, Widget)> sections = [
      (Icons.flight_rounded, s.sectionAircraft, const AircraftSection()),
      (Icons.group_rounded, s.sectionUsers, const UsersSection()),
      (Icons.schedule_rounded, s.sectionPending, const PendingSection()),
      (Icons.tune_rounded, s.sectionSettings, const SettingsSection()),
      (
        Icons.receipt_long_rounded,
        s.sectionHistory,
        const Padding(padding: EdgeInsets.all(16), child: HistoryView()),
      ),
      (Icons.insert_chart_rounded, s.sectionReports, const ReportsSection()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= _kRailBreakpoint;

        return Scaffold(
          appBar: AppBar(
            // En pantallas angostas el nombre del aeropuerto se omite para
            // que el título no se recorte con puntos suspensivos.
            title: Text(
              wide
                  ? '${s.adminTitle} · ${controller.config.airportDisplay}'
                  : s.adminTitle,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (wide && controller.currentAdmin != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      controller.currentAdmin!.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: s.logout,
                iconSize: 26,
                icon: const Icon(Icons.logout_rounded),
                onPressed: _logout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: wide
              ? null
              : _SectionsDrawer(
                  sections: sections,
                  selectedIndex: _index,
                  airport: controller.config.airportDisplay,
                  onSelected: (value) => setState(() => _index = value),
                ),
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: (value) =>
                            setState(() => _index = value),
                        labelType: NavigationRailLabelType.all,
                        minWidth: 96,
                        destinations: [
                          for (final (IconData icon, String label, _)
                              in sections)
                            NavigationRailDestination(
                              icon: Icon(icon, size: 28),
                              label: Text(label,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: sections[_index].$3),
                    ],
                  )
                : sections[_index].$3,
          ),
        );
      },
    );
  }
}

/// Menú lateral desplegable usado en pantallas angostas.
class _SectionsDrawer extends StatelessWidget {
  const _SectionsDrawer({
    required this.sections,
    required this.selectedIndex,
    required this.airport,
    required this.onSelected,
  });

  final List<(IconData, String, Widget)> sections;
  final int selectedIndex;
  final String airport;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(
                airport,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            for (int i = 0; i < sections.length; i++)
              ListTile(
                selected: i == selectedIndex,
                selectedTileColor: scheme.primaryContainer,
                leading: Icon(sections[i].$1, size: 26),
                title: Text(
                  sections[i].$2,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  onSelected(i);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
