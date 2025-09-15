import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';

class PruebaBcuPage extends StatelessWidget {
  const PruebaBcuPage({super.key});

  Future<void> _run(BuildContext context) async {
    final hoy = DateTime.now();
    final desde = hoy.subtract(const Duration(days: 7));
    await context.read<BcuProvider>().loadCotizaciones(
      monedas: [2222], // USD (o [0] para todas, puede venir pesado)
      desde: desde,
      hasta: hoy,
      grupo: 2,        // Locales
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BcuProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('BCU SOAP (Provider)')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => _run(context), child: const Text('Consultar')),
          if (vm.isLoading) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          if (vm.error != null) Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${vm.error}')),
          Expanded(
            child: ListView.separated(
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = vm.items[i];
                return ListTile(
                  title: Text('${c.nombre ?? c.moneda} — ${c.codigoIso ?? ''}'),
                  subtitle: Text('Fecha: ${c.fecha ?? '-'}'),
                  trailing: Text('TCV: ${c.tcv ?? '-'}\nTCC: ${c.tcc ?? '-'}'),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
