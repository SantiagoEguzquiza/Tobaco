import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Services/User_Service/user_provider.dart';
import '../../Services/Auth_Service/auth_service.dart';
import '../../Services/Ventas_Service/ventas_provider.dart';
import '../../Models/User.dart';
import '../../Models/Ventas.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/dialogs.dart';
import '../../Theme/headers.dart';
import '../../Helpers/api_handler.dart';

class AsignarVentasScreen extends StatefulWidget {
  const AsignarVentasScreen({super.key});

  @override
  State<AsignarVentasScreen> createState() => _AsignarVentasScreenState();
}

class _AsignarVentasScreenState extends State<AsignarVentasScreen> {
  List<User> _employees = [];
  List<Ventas> _unassignedSales = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load users - puede fallar si no hay permisos
      try {
        await context.read<UserProvider>().loadUsers();
        final allUsers = context.read<UserProvider>().users;
        // Filtrar solo empleados que pueden ser repartidores (Repartidor o Repartidor-Vendedor)
        _employees = allUsers.where((u) => 
          u.isActive && 
          u.role == 'Employee' &&
          (u.esRepartidor == true || u.esRepartidorVendedor == true)
        ).toList();
        
        debugPrint('✅ Cargados ${_employees.length} empleados para asignar ventas');
      } catch (e) {
        // Si falla cargar usuarios, puede ser un problema de permisos o del servidor
        debugPrint('Error al cargar usuarios: $e');
        _employees = [];
        
        // Si es un error de conexión, mostrar el diálogo
        if (Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
          setState(() {
            _isLoading = false;
            _errorMessage = 'No se pudieron cargar los empleados. Verifica tu conexión.';
          });
          return;
        }
        
        // Si es un error 500 o 403, probablemente es un problema de permisos del backend
        // Continuar con las ventas pero mostrar advertencia
        final errorString = e.toString();
        if (errorString.contains('500') || errorString.contains('403')) {
          debugPrint('⚠️ Error de permisos del servidor al cargar usuarios. Continuando sin empleados.');
          // No mostrar error fatal, solo continuar
        }
      }

      // Load sales
      try {
        await context.read<VentasProvider>().obtenerVentas();
        final allSales = context.read<VentasProvider>().ventas;
        
        // Get only unassigned sales (no UsuarioIdAsignado) that are not delivered
        _unassignedSales = allSales.where((v) => 
            v.estadoEntrega != EstadoEntrega.entregada && // Not delivered
            v.usuarioIdAsignado == null // Not assigned to any employee yet
        ).toList();
        
        // Sort by date (most recent first)
        _unassignedSales.sort((a, b) => b.fecha.compareTo(a.fecha));
      } catch (e) {
        debugPrint('Error al cargar ventas: $e');
        if (Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
          setState(() {
            _isLoading = false;
            _errorMessage = 'No se pudieron cargar las ventas. Verifica tu conexión.';
          });
          return;
        }
        throw e;
      }

      setState(() {
        _isLoading = false;
        // Si no hay empleados pero hay ventas, mostrar advertencia pero permitir ver las ventas
        if (_employees.isEmpty && _unassignedSales.isNotEmpty) {
          // No establecer errorMessage fatal, solo mostrar advertencia en la UI
          // El usuario podrá ver las ventas pero no podrá asignarlas
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
      });
      
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      }
    }
  }

  Future<void> _assignSale(Ventas venta, User employee) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.post(
        Uri.parse('${Apihandler.baseUrl}/Ventas/asignar'),
        headers: headers,
        body: jsonEncode({
          'ventaId': venta.id,
          'usuarioId': employee.id,
        }),
      );

      if (response.statusCode == 200) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Venta asignada exitosamente'),
        );
        _loadData(); // Reload data
      } else {
        throw Exception('Error al asignar la venta');
      }
    } catch (e) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al asignar la venta'),
      );
    }
  }

  Future<void> _showAssignDialog(Ventas venta) async {
    if (_employees.isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('No hay empleados disponibles. No se pudieron cargar los repartidores. Intenta recargar la página.'),
      );
      // Intentar recargar los usuarios
      try {
        await context.read<UserProvider>().loadUsers();
        final allUsers = context.read<UserProvider>().users;
        _employees = allUsers.where((u) => 
          u.isActive && 
          u.role == 'Employee' &&
          (u.esRepartidor == true || u.esRepartidorVendedor == true)
        ).toList();
        
        if (_employees.isNotEmpty) {
          // Si ahora hay empleados, mostrar el diálogo
          _showAssignDialog(venta);
          return;
        }
      } catch (e) {
        debugPrint('Error al recargar usuarios: $e');
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Asignar Venta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la venta
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              venta.cliente.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${venta.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona el empleado:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Lista de empleados con altura máxima
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(employee.userName),
                        subtitle: employee.email != null && employee.email!.isNotEmpty
                            ? Text(
                                employee.email!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              )
                            : null,
                        onTap: () async {
                          Navigator.pop(context);
                          await _assignSale(venta, employee);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade900.withOpacity(0.5)
                            : Colors.grey.shade100.withOpacity(0.5),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Builder(
            builder: (context) => SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : AppTheme.primaryColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null,
        title: const Text('Asignar Ventas', style: AppTheme.appBarTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _unassignedSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_turned_in,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay ventas pendientes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Todas las ventas ya están asignadas o entregadas',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Mostrar advertencia si no hay empleados disponibles
                        if (_employees.isEmpty && _unassignedSales.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No se pudieron cargar los empleados',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Puedes ver las ventas pero no asignarlas. Verifica tu conexión o contacta al administrador.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HeaderSimple(
                                  leadingIcon: Icons.assignment_ind,
                                  title: 'Asignar Ventas',
                                  subtitle: '${_unassignedSales.length} ventas pendientes de asignar',
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _unassignedSales.length,
                                  itemBuilder: (context, index) {
                                    final venta = _unassignedSales[index];
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
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () => _showAssignDialog(venta),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                // Indicador de estado
                                                Container(
                                                  width: 4,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // Información de la venta
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        venta.cliente.nombre,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).brightness == Brightness.dark
                                                              ? Colors.white
                                                              : AppTheme.textColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.attach_money,
                                                            size: 16,
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey.shade400
                                                                : Colors.grey.shade600,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Total: \$${venta.total.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey.shade400
                                                                  : Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.calendar_today,
                                                            size: 16,
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey.shade400
                                                                : Colors.grey.shade600,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${venta.fecha.day}/${venta.fecha.month}/${venta.fecha.year}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey.shade400
                                                                  : Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.location_on,
                                                            size: 16,
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey.shade400
                                                                : Colors.grey.shade600,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              venta.cliente.direccion ?? 'Sin dirección',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Theme.of(context).brightness == Brightness.dark
                                                                    ? Colors.grey.shade400
                                                                    : Colors.grey.shade600,
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
                                                
                                                // Botón de asignar
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.person_add,
                                                      color: AppTheme.primaryColor,
                                                      size: 24,
                                                    ),
                                                    onPressed: () => _showAssignDialog(venta),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
