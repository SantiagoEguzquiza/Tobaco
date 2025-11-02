import 'dart:convert';
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
      // Load users
      await context.read<UserProvider>().loadUsers();
      final allUsers = context.read<UserProvider>().users;
      _employees = allUsers.where((u) => u.isActive && u.role == 'Employee').toList();

      // Load sales
      await context.read<VentasProvider>().obtenerVentas();
      final allSales = context.read<VentasProvider>().ventas;
      
      // Get only unassigned sales (no UsuarioIdAsignado) that are not delivered
      _unassignedSales = allSales.where((v) => 
          v.estadoEntrega != EstadoEntrega.entregada && // Not delivered
          v.usuarioIdAsignado == null // Not assigned to any employee yet
      ).toList();
      
      // Sort by date (most recent first)
      _unassignedSales.sort((a, b) => b.fecha.compareTo(a.fecha));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos';
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
        AppTheme.warningSnackBar('No hay empleados disponibles'),
      );
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
                  : SingleChildScrollView(
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
    );
  }
}
