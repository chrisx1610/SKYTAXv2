import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../state/app_controller.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/kiosk_widgets.dart';

/// Listado de facturas con búsqueda; solo accesible desde el panel admin.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _search = TextEditingController();
  List<Invoice> _invoices = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AppController controller = context.read<AppController>();
    try {
      final List<Invoice> result =
          await controller.invoices.getAll(search: _search.text);
      if (!mounted) return;
      setState(() {
        _invoices = result;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.instance.error('No se pudo cargar el historial', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = context.watch<AppController>();
    final AppStrings s = controller.strings;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: s.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
          onChanged: (_) => _load(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _invoices.isEmpty
                  ? Center(
                      child: Text(
                        s.noInvoices,
                        style: TextStyle(
                            fontSize: 18, color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _invoices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final Invoice invoice = _invoices[index];
                        return AdminListCard(
                          icon: Icons.receipt_long_rounded,
                          title:
                              '${invoice.number} · ${invoice.registration}',
                          subtitle:
                              '${Formatters.dateTime(invoice.createdAt)} · '
                              '${s.paymentMethodName(invoice.paymentMethod)}',
                          onTap: () => showInvoiceDialog(context, invoice, s),
                          actions: [
                            Text(
                              Formatters.money(invoice.total),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
