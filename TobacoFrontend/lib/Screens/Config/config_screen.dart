import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tobaco/Models/Asistencia.dart';
import 'package:tobaco/Services/Asistencia_Service/asistencia_service.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  Asistencia? _asistenciaActiva;
  List<Asistencia> _historialAsistencias = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _isLoadingHistory = true;
    });

    try {
      // Cargar asistencia activa
      final asistenciaActiva = await AsistenciaService.getAsistenciaActiva(userId);
      
      // Cargar historial (últimas 10 asistencias)
      final historial = await AsistenciaService.getAsistenciasByUserId(userId);

      if (!mounted) return;

      setState(() {
        _asistenciaActiva = asistenciaActiva;
        _historialAsistencias = historial.take(10).toList();
        _isLoading = false;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingHistory = false;
      });

      if (mounted) {
        AppDialogs.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al cargar datos: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _registrarEntrada() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Error',
        message: 'Usuario no encontrado',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final asistencia = await AsistenciaService.registrarEntrada(userId);
      
      if (!mounted) return;

      setState(() {
        _asistenciaActiva = asistencia;
        _isLoading = false;
      });

      AppDialogs.showSuccessDialog(
        context: context,
        title: 'Entrada Registrada',
        message: 'Tu entrada ha sido registrada exitosamente.\n\nUbicación: ${asistencia.ubicacionEntrada ?? "No disponible"}',
      );

      // Recargar historial
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      AppDialogs.showErrorDialog(
        context: context,
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _registrarSalida() async {
    if (_asistenciaActiva == null) return;

    final confirmado = await AppDialogs.showConfirmationDialog(
      context: context,
      title: '¿Registrar Salida?',
      message: '¿Estás seguro de que deseas registrar tu salida?',
    );

    if (!mounted) return;

    if (!confirmado) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final asistencia = await AsistenciaService.registrarSalida(_asistenciaActiva!.id);
      
      if (!mounted) return;

      setState(() {
        _asistenciaActiva = null;
        _isLoading = false;
      });

      AppDialogs.showSuccessDialog(
        context: context,
        title: 'Salida Registrada',
        message: 'Tu salida ha sido registrada exitosamente.\n\nUbicación: ${asistencia.ubicacionSalida ?? "No disponible"}\n\nHoras trabajadas: ${asistencia.horasTrabajadasFormateadas}',
      );

      // Recargar historial
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      AppDialogs.showErrorDialog(
        context: context,
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Configuración',
          style: AppTheme.appBarTitleStyle,
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del usuario
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          authProvider.currentUser?.userName.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.currentUser?.userName ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.currentUser?.role ?? 'Empleado',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección de Registro de Asistencia
              Text(
                'Registro de Asistencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),

              // Estado actual
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 3,
                  ),
                )
              else
                _buildEstadoAsistencia(),

              const SizedBox(height: 32),

              // Historial de Asistencias
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (_isLoadingHistory)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _buildHistorial(),

              const SizedBox(height: 32),

              // Botón de Cerrar Sesión
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await AppDialogs.showLogoutConfirmationDialog(
      context: context,
    );

    if (confirmado) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildEstadoAsistencia() {
    if (_asistenciaActiva != null) {
      // Usuario tiene entrada registrada
      return Card(
        elevation: 2,
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.login, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Entrada Registrada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Hora de entrada:',
                value: DateFormat('dd/MM/yyyy HH:mm').format(_asistenciaActiva!.fechaHoraEntrada),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Ubicación:',
                value: _asistenciaActiva!.ubicacionEntrada ?? 'No disponible',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registrarSalida,
                  icon: const Icon(Icons.logout),
                  label: const Text('Registrar Salida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Usuario no tiene entrada registrada
      return Card(
        elevation: 2,
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_off, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Sin Registro Activo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No tienes un registro de entrada activo. Marca tu entrada para comenzar tu jornada laboral.',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registrarEntrada,
                  icon: const Icon(Icons.login),
                  label: const Text('Registrar Entrada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800]),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorial() {
    if (_historialAsistencias.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay registros de asistencia',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historialAsistencias.length,
      itemBuilder: (context, index) {
        final asistencia = _historialAsistencias[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: asistencia.estaActiva ? Colors.green : Colors.grey,
              child: Icon(
                asistencia.estaActiva ? Icons.access_time : Icons.check,
                color: Colors.white,
              ),
            ),
            title: Text(
              DateFormat('dd/MM/yyyy').format(asistencia.fechaHoraEntrada),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrada: ${DateFormat('HH:mm').format(asistencia.fechaHoraEntrada)}',
                ),
                if (asistencia.fechaHoraSalida != null)
                  Text(
                    'Salida: ${DateFormat('HH:mm').format(asistencia.fechaHoraSalida!)}',
                  ),
                if (!asistencia.estaActiva)
                  Text(
                    'Horas: ${asistencia.horasTrabajadasFormateadas}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              asistencia.estaActiva ? Icons.pending : Icons.done_all,
              color: asistencia.estaActiva ? Colors.orange : Colors.green,
            ),
          ),
        );
      },
    );
  }
}

