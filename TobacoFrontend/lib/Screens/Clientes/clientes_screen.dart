import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Screens/Clientes/nuevoCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/editarCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Cargar clientes después del primer frame
    Future.microtask(() => context.read<ClienteProvider>().cargarClientes());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ClienteProvider>().cargarMasClientes();
    }
  }

  void _onSearchChanged(String value) {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();
    
    // Crear un nuevo timer para hacer debounce
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ClienteProvider>().buscarClientes(value);
      }
    });
  }

  /// Verifica si un cliente es "Consumidor Final"
  bool _esConsumidorFinal(Cliente cliente) {
    return cliente.nombre.trim().toLowerCase() == 'consumidor final';
  }

  Future<void> _actualizarClienteEnLista(Cliente clienteOriginal) async {
    if (clienteOriginal.id == null) return;
    
    try {
      await context.read<ClienteProvider>().actualizarClienteEnLista(clienteOriginal.id!);
    } catch (e) {
      log('Error al actualizar cliente en lista: $e', level: 1000);
      
      if (mounted && Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      }
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmacion = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Cliente',
      itemName: cliente.nombre,
    );

    if (confirmacion == true && cliente.id != null) {
      final provider = context.read<ClienteProvider>();
      
      try {
        await provider.eliminarCliente(cliente.id!);
        
        if (mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Cliente eliminado exitosamente'),
          );
        }
      } catch (e) {
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else if (mounted) {
          final backendMsg =
              e.toString().replaceFirst('Exception: ', '').trim();
          await AppDialogs.showErrorDialog(
            context: context,
            // Mostrar solo el mensaje que viene del backend
            message: backendMsg.isNotEmpty
                ? backendMsg
                : 'Ocurrió un error al eliminar el cliente.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: null, // Usar el tema
            title: const Text(
              'Clientes',
              style: AppTheme.appBarTitleStyle,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header con buscador - SIEMPRE VISIBLE
                  _buildHeaderSection(provider),
                  const SizedBox(height: 20),
                  // Lista con estados dentro
                  Expanded(child: _buildClientesList(provider)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(ClienteProvider provider) {
    // Contar clientes excluyendo "Consumidor Final"
    final clientesVisibles = provider.clientes.where((c) => !_esConsumidorFinal(c)).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderConBuscador(
          leadingIcon: Icons.people,
          title: 'Gestión de Clientes',
          subtitle: '$clientesVisibles clientes registrados',
          controller: _searchController,
          hintText: 'Buscar clientes...',
          onChanged: _onSearchChanged,
          onClear: () {
            _searchController.clear();
            provider.buscarClientes('');
          },
        ),
        const SizedBox(height: 16),
        // Botón de crear cliente - Solo mostrar si tiene permiso
        Consumer<PermisosProvider>(
          builder: (context, permisosProvider, child) {
            if (permisosProvider.canCreateClientes || permisosProvider.isAdmin) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NuevoClienteScreen(),
                      ),
                    );
                    // Si se retorna un Cliente, significa que se creó exitosamente
                    if (result is Cliente && mounted) {
                      await context.read<ClienteProvider>().cargarClientes();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text(
                    'Nuevo Cliente',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildClientesList(ClienteProvider provider) {
    final clientes = provider.clientes;
    final isLoading = provider.isLoading;
    final hasMoreData = provider.hasMoreData;
    final searchQuery = provider.searchQuery;

    // Filtrar "Consumidor Final" de la lista
    final clientesFiltrados = clientes.where((cliente) => !_esConsumidorFinal(cliente)).toList();
    clientesFiltrados.sort((a, b) => a.nombre.compareTo(b.nombre));

    if (isLoading && clientesFiltrados.isEmpty) {
      return _buildLoadingState();
    }

    if (clientesFiltrados.isEmpty) {
      return _buildEmptyState(searchQuery);
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        await context.read<ClienteProvider>().cargarClientes();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: clientesFiltrados.length + (hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == clientesFiltrados.length) {
            // Indicador de carga al final
            return isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final cliente = clientesFiltrados[index];
          return _buildClienteCard(cliente);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando clientes...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
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
                searchQuery.isNotEmpty
                    ? 'No se encontraron clientes'
                    : 'No hay clientes registrados',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'Intenta con otros términos de búsqueda'
                    : 'Crea tu primer cliente para comenzar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildClienteCard(Cliente cliente) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleClienteScreen(cliente: cliente),
              ),
            );
            // Si se retorna true o un Cliente, significa que hubo cambios
            if (result == true) {
              // Si es true (desde detalle), actualizar el cliente desde el servidor
              if (mounted && cliente.id != null) {
                await context.read<ClienteProvider>().actualizarClienteEnLista(cliente.id!);
              }
            } else if (result is Cliente) {
              // Si es un Cliente actualizado, actualizar directamente en la lista sin cambiar posición
              if (mounted) {
                context.read<ClienteProvider>().actualizarClienteDirecto(result);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de estado del cliente
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.direccion!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
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
                    Consumer<PermisosProvider>(
                      builder: (context, permisosProvider, child) {
                        // No mostrar botones de editar/eliminar para "Consumidor Final"
                        if (_esConsumidorFinal(cliente)) {
                          return const SizedBox.shrink();
                        }

                        final canEdit = permisosProvider.canEditClientes || permisosProvider.isAdmin;
                        final canDelete = permisosProvider.canDeleteClientes || permisosProvider.isAdmin;
                        
                        // Si no tiene ningún permiso de acción, no mostrar nada
                        if (!canEdit && !canDelete) {
                          return const SizedBox.shrink();
                        }
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón Editar
                            if (canEdit)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarClienteScreen(cliente: cliente),
                                      ),
                                    );
                                    // Si se retorna un Cliente, significa que se guardó exitosamente
                                    if (result is Cliente) {
                                      // Actualizar directamente el cliente en la lista sin cambiar su posición
                                      if (mounted) {
                                        context.read<ClienteProvider>().actualizarClienteDirecto(result);
                                        // Mostrar snackbar de éxito (el snackbar de editarCliente_screen ya se mostró, pero este es adicional en la pantalla principal)
                                        AppTheme.showSnackBar(
                                          context,
                                          AppTheme.successSnackBar('Cliente actualizado exitosamente'),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            if (canEdit && canDelete)
                              const SizedBox(width: 8),
                            // Botón Eliminar
                            if (canDelete)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _eliminarCliente(cliente),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}