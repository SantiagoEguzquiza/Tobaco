import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/RecorridoProgramado.dart';
import '../../Models/DiaSemana.dart';
import '../../Models/Cliente.dart';
import '../../Models/User.dart';
import '../../Services/RecorridosProgramados_Service/recorridos_programados_provider.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Services/User_Service/user_provider.dart';
import '../../Services/Auth_Service/auth_service.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';
import '../../Theme/dialogs.dart';
import '../../Theme/headers.dart';

class RecorridosProgramadosScreen extends StatefulWidget {
  const RecorridosProgramadosScreen({super.key});

  @override
  State<RecorridosProgramadosScreen> createState() => _RecorridosProgramadosScreenState();
}

class _RecorridosProgramadosScreenState extends State<RecorridosProgramadosScreen> {
  List<User> _vendedores = [];
  User? _vendedorSeleccionado;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener usuario actual
      final usuarioActual = await AuthService.getCurrentUser();
      
      if (usuarioActual == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AppTheme.showSnackBar(
            context,
            AppTheme.errorSnackBar('No se pudo obtener el usuario actual'),
          );
        }
        return;
      }
      
      // Si es Admin, cargar todos los usuarios para poder seleccionar
      if (usuarioActual.isAdmin) {
        final userProvider = context.read<UserProvider>();
        try {
          await userProvider.loadUsers();
          
          if (!mounted) return;
          
          setState(() {
            // Incluir empleados y administradores activos
            _vendedores = userProvider.users.where((u) => (u.isEmployee || u.isAdmin) && u.isActive).toList();
            _isLoading = false;
          });
          
          if (_vendedores.isNotEmpty) {
            setState(() {
              _vendedorSeleccionado = _vendedores.first;
            });
            await _cargarRecorridos();
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          if (Apihandler.isConnectionError(e)) {
            await Apihandler.handleConnectionError(context, e);
          } else {
            AppTheme.showSnackBar(
              context,
              AppTheme.errorSnackBar('Error al cargar empleados: $e'),
            );
          }
        }
      } else {
        // Si es Repartidor-Vendedor, solo mostrar sus propios recorridos
        setState(() {
          _vendedores = [usuarioActual];
          _vendedorSeleccionado = usuarioActual;
          _isLoading = false;
        });
        await _cargarRecorridos();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al cargar datos: $e'),
        );
      }
    }
  }

  Future<void> _cargarRecorridos() async {
    if (_vendedorSeleccionado == null) return;

    try {
      final provider = context.read<RecorridosProgramadosProvider>();
      await provider.obtenerRecorridosPorVendedor(_vendedorSeleccionado!.id);
    } catch (e) {
      if (!mounted) return;
      // Manejar errores de conexión con el diálogo
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al cargar recorridos: $e'),
        );
      }
    }
  }

  List<RecorridoProgramado> _recorridosPorDia(DiaSemana dia, RecorridosProgramadosProvider provider) {
    return provider.recorridosPorDia(dia, _vendedorSeleccionado?.id);
  }

  Future<void> _agregarRecorrido(DiaSemana dia) async {
    if (_vendedorSeleccionado == null || !mounted) return;

    final clienteProvider = context.read<ClienteProvider>();
    await clienteProvider.obtenerClientes();
    
    if (!mounted) return;
    
    final clientes = clienteProvider.clientes.cast<Cliente>();

    final provider = context.read<RecorridosProgramadosProvider>();
    final clientesEnEsteDia = _recorridosPorDia(dia, provider).map((r) => r.clienteId).toSet();
    final clientesDisponibles = clientes.where((c) => !clientesEnEsteDia.contains(c.id)).toList();

    if (clientesDisponibles.isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('Todos los clientes ya están asignados a este día'),
      );
      return;
    }

    final cliente = await showDialog<Cliente>(
      context: context,
      builder: (context) => _SeleccionarClienteDialog(clientes: clientesDisponibles),
    );

    if (cliente == null || cliente.id == null) return;

    final recorridosDelDia = _recorridosPorDia(dia, provider);
    final siguienteOrden = recorridosDelDia.isEmpty ? 1 : recorridosDelDia.last.orden + 1;

    try {
      await provider.crearRecorrido(
        vendedorId: _vendedorSeleccionado!.id,
        clienteId: cliente.id!,
        diaSemana: dia,
        orden: siguienteOrden,
      );
      await _cargarRecorridos();
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Cliente agregado al recorrido'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al agregar recorrido: $e'),
        );
      }
    }
  }

  Future<void> _eliminarRecorrido(RecorridoProgramado recorrido) async {
    final confirmar = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar del Recorrido',
      message: '¿Deseas eliminar "${recorrido.clienteNombre}" del recorrido de ${recorrido.diaSemana.nombre}?',
      itemName: recorrido.clienteNombre,
    );

    if (confirmar != true) return;

    try {
      final provider = context.read<RecorridosProgramadosProvider>();
      await provider.eliminarRecorrido(recorrido.id);
      await _cargarRecorridos();
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Cliente eliminado del recorrido'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al eliminar recorrido: $e'),
        );
      }
    }
  }

  Future<void> _cambiarDia(RecorridoProgramado recorrido) async {
    final nuevoDia = await showDialog<DiaSemana>(
      context: context,
      builder: (context) => _SeleccionarDiaDialog(),
    );

    if (nuevoDia == null || nuevoDia == recorrido.diaSemana) return;

    try {
      final provider = context.read<RecorridosProgramadosProvider>();
      final recorridosDelNuevoDia = _recorridosPorDia(nuevoDia, provider);
      final nuevoOrden = recorridosDelNuevoDia.isEmpty ? 1 : recorridosDelNuevoDia.last.orden + 1;

      await provider.actualizarRecorrido(
        id: recorrido.id,
        diaSemana: nuevoDia,
        orden: nuevoOrden,
      );
      await _cargarRecorridos();
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Día cambiado exitosamente'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al cambiar día: $e'),
        );
      }
    }
  }

  Future<void> _reordenar(RecorridoProgramado recorrido, bool subir) async {
    final provider = context.read<RecorridosProgramadosProvider>();
    final recorridosDelDia = _recorridosPorDia(recorrido.diaSemana, provider);
    final indiceActual = recorridosDelDia.indexWhere((r) => r.id == recorrido.id);
    
    if (indiceActual == -1) return;
    
    final nuevoIndice = subir ? indiceActual - 1 : indiceActual + 1;
    if (nuevoIndice < 0 || nuevoIndice >= recorridosDelDia.length) return;

    final otroRecorrido = recorridosDelDia[nuevoIndice];
    
    try {
      await provider.actualizarRecorrido(
        id: recorrido.id,
        orden: otroRecorrido.orden,
      );
      await provider.actualizarRecorrido(
        id: otroRecorrido.id,
        orden: recorrido.orden,
      );
      await _cargarRecorridos();
    } catch (e) {
      if (!mounted) return;
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al reordenar: $e'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecorridosProgramadosProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: null,
            title: const Text('Recorridos Programados', style: AppTheme.appBarTitleStyle),
            actions: [
              // Solo mostrar el selector si hay más de un vendedor (Admin puede ver todos)
              if (_vendedores.length > 1)
                PopupMenuButton<User>(
                  icon: const Icon(Icons.person),
                  onSelected: (vendedor) async {
                    setState(() {
                      _vendedorSeleccionado = vendedor;
                    });
                    await _cargarRecorridos();
                  },
                  itemBuilder: (context) => _vendedores.map((v) => PopupMenuItem(
                    value: v,
                    child: Text(v.userName),
                  )).toList(),
                ),
            ],
          ),
          body: _isLoading || provider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isLoading ? 'Cargando vendedores...' : 'Cargando recorridos...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : _vendedorSeleccionado == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay vendedores disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header principal
                          HeaderSimple(
                            leadingIcon: Icons.route,
                            title: 'Recorridos Programados',
                            subtitle: 'Vendedor: ${_vendedorSeleccionado?.userName ?? "No seleccionado"}',
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Cards de días de la semana
                          ...DiaSemana.values.map((dia) {
                            final recorridos = _recorridosPorDia(dia, provider);
                            return _DiaCard(
                              dia: dia,
                              recorridos: recorridos,
                              onAgregar: () => _agregarRecorrido(dia),
                              onEliminar: _eliminarRecorrido,
                              onCambiarDia: _cambiarDia,
                              onReordenar: _reordenar,
                            );
                          }),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

class _DiaCard extends StatelessWidget {
  final DiaSemana dia;
  final List<RecorridoProgramado> recorridos;
  final VoidCallback onAgregar;
  final Function(RecorridoProgramado) onEliminar;
  final Function(RecorridoProgramado) onCambiarDia;
  final Function(RecorridoProgramado, bool) onReordenar;

  const _DiaCard({
    required this.dia,
    required this.recorridos,
    required this.onAgregar,
    required this.onEliminar,
    required this.onCambiarDia,
    required this.onReordenar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del día
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dia.nombreCorto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dia.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '${recorridos.length} cliente${recorridos.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: onAgregar,
                  tooltip: 'Agregar cliente',
                ),
              ],
            ),
          ),
          
          // Lista de recorridos
          if (recorridos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No hay clientes asignados para este día',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: recorridos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final recorrido = entry.value;
                  return _RecorridoItem(
                    recorrido: recorrido,
                    index: index,
                    totalRecorridos: recorridos.length,
                    onEliminar: onEliminar,
                    onCambiarDia: onCambiarDia,
                    onReordenar: onReordenar,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecorridoItem extends StatelessWidget {
  final RecorridoProgramado recorrido;
  final int index;
  final int totalRecorridos;
  final Function(RecorridoProgramado) onEliminar;
  final Function(RecorridoProgramado) onCambiarDia;
  final Function(RecorridoProgramado, bool) onReordenar;

  const _RecorridoItem({
    required this.recorrido,
    required this.index,
    required this.totalRecorridos,
    required this.onEliminar,
    required this.onCambiarDia,
    required this.onReordenar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Número de orden
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${recorrido.orden}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Información del cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recorrido.clienteNombre ?? 'Sin nombre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recorrido.clienteDireccion ?? 'Sin dirección',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                color: index > 0 ? AppTheme.primaryColor : Colors.grey,
                onPressed: index > 0 ? () => onReordenar(recorrido, true) : null,
                tooltip: 'Subir orden',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                color: index < totalRecorridos - 1 ? AppTheme.primaryColor : Colors.grey,
                onPressed: index < totalRecorridos - 1 ? () => onReordenar(recorrido, false) : null,
                tooltip: 'Bajar orden',
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 8),
                        Text('Cambiar día'),
                      ],
                    ),
                    onTap: () => Future.delayed(Duration.zero, () => onCambiarDia(recorrido)),
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () => Future.delayed(Duration.zero, () => onEliminar(recorrido)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeleccionarClienteDialog extends StatelessWidget {
  final List<Cliente> clientes;

  const _SeleccionarClienteDialog({required this.clientes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Seleccionar Cliente',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: clientes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay clientes disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: clientes.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final cliente = clientes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(context).pop(cliente),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cliente.nombre,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  cliente.direccion ?? 'Sin dirección',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeleccionarDiaDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Seleccionar Día',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: DiaSemana.values.map((dia) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(dia),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    dia.nombreCorto,
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dia.nombre,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}