import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Asistencia.dart';
import 'package:tobaco/Screens/Admin/user_management_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Services/Asistencia_Service/asistencia_service.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/theme_provider.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  bool _isProcessingAction = false;

  TextTheme get _textTheme => Theme.of(context).textTheme;

  TextStyle get _sectionTitleStyle =>
      _textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w700);

  TextStyle get _cardTitleStyle =>
      _textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700) ??
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  TextStyle get _bodyTextStyle =>
      _textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

  TextStyle get _supportTextStyle =>
      _bodyTextStyle.copyWith(color: Colors.grey[600]);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: AppTheme.appBarTitleStyle,
        ),
        backgroundColor: null, // Usar el tema
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(authProvider),
              if (_isProcessingAction) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle('Preferencias'),
              const SizedBox(height: 12),
              _buildThemeCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Asistencia'),
              const SizedBox(height: 12),
              _buildAssistanceCard(),
              const SizedBox(height: 24),
              if (authProvider.currentUser?.isAdmin == true) ...[
                _buildSectionTitle('Administración'),
                const SizedBox(height: 12),
                _buildNavigationCard(
                  icon: Icons.manage_accounts,
                  iconColor: AppTheme.primaryColor,
                  title: 'Gestión de usuarios',
                  description: 'Administra permisos y cuentas del equipo.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              _buildSectionTitle('Sesión'),
              const SizedBox(height: 12),
              _buildNavigationCard(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: 'Cerrar sesión',
                description: 'Finaliza la sesión actual en este dispositivo.',
                onTap: _cerrarSesion,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final initials = (user?.userName.isNotEmpty ?? false)
        ? user!.userName.substring(0, 1).toUpperCase()
        : 'U';
    // Mostrar rol en español para el usuario actual
    final roleLabel =
        (user?.isAdmin ?? false) ? 'Administrador' : 'Empleado';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              child: Text(
                initials,
                style: _textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ) ??
                    const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.userName ?? 'Usuario',
                    style: _textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleLabel,
                    style: _supportTextStyle,
                  ),
                  if (user?.isAdmin == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Perfil Administrador',
                        style: _textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: _sectionTitleStyle,
    );
  }

  Widget _buildThemeCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, __) {
            // Reflejar el estado efectivo: oscuro si está en dark o si es system y el dispositivo está en oscuro
            final isDark = themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                'Modo oscuro',
                style: _cardTitleStyle,
              ),
              subtitle: Text(
                'Alterna entre el modo claro y oscuro de la aplicación.',
                style: _supportTextStyle,
              ),
              trailing: Switch(
                value: isDark,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssistanceCard() {
    return _buildActionCard(
      icon: Icons.schedule,
      iconColor: AppTheme.primaryColor,
      title: 'Gestión de asistencia',
      description:
          'Accede a las acciones rápidas de registro o consulta tu historial.',
      primaryLabel: 'Acciones rápidas',
      primaryTap: _openAsistenciaActionsSheet,
      secondaryLabel: 'Ver historial',
      secondaryTap: _openHistorialSheet,
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String primaryLabel,
    required VoidCallback primaryTap,
    String? secondaryLabel,
    VoidCallback? secondaryTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: _cardTitleStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: _supportTextStyle,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isProcessingAction ? null : primaryTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMainButtons),
                    ),
                  ),
                  child: Text(primaryLabel),
                ),
                if (secondaryLabel != null && secondaryTap != null)
                  OutlinedButton(
                    onPressed: _isProcessingAction ? null : secondaryTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMainButtons,
                        ),
                      ),
                    ),
                    child: Text(secondaryLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: _cardTitleStyle,
        ),
        subtitle: Text(
          description,
          style: _supportTextStyle,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _isProcessingAction ? null : onTap,
      ),
    );
  }

  Future<void> _openAsistenciaActionsSheet() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      await AppDialogs.showErrorDialog(
        context: context,
        title: 'Usuario no encontrado',
        message:
            'No pudimos identificar tu usuario. Intenta iniciar sesión nuevamente.',
      );
      return;
    }

    final selectedAction = await showModalBottomSheet<_AsistenciaQuickAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Acciones rápidas',
                  style: _sectionTitleStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona una acción para continuar con tu registro de asistencia.',
                  style: _supportTextStyle,
                ),
                const SizedBox(height: 20),
                _buildSheetOption(
                  icon: Icons.login,
                  color: Colors.green,
                  title: 'Registrar entrada',
                  subtitle: 'Comienza una nueva jornada laboral.',
                  value: _AsistenciaQuickAction.registrarEntrada,
                  context: context,
                ),
                const SizedBox(height: 12),
                _buildSheetOption(
                  icon: Icons.logout,
                  color: Colors.red,
                  title: 'Registrar salida',
                  subtitle: 'Finaliza tu jornada y calcula horas trabajadas.',
                  value: _AsistenciaQuickAction.registrarSalida,
                  context: context,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedAction == null) return;

    switch (selectedAction) {
      case _AsistenciaQuickAction.registrarEntrada:
        await _registrarEntrada(userId);
        break;
      case _AsistenciaQuickAction.registrarSalida:
        await _registrarSalida(userId);
        break;
    }
  }

  Widget _buildSheetOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required _AsistenciaQuickAction value,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
        onTap: () => Navigator.of(context).pop(value),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppTheme.borderRadiusMainButtons),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _cardTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: _supportTextStyle,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openHistorialSheet() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      await AppDialogs.showErrorDialog(
        context: context,
        title: 'Usuario no encontrado',
        message:
            'No pudimos identificar tu usuario. Intenta iniciar sesión nuevamente.',
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: FutureBuilder<List<Asistencia>>(
                future: AsistenciaService.getAsistenciasByUserId(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'No pudimos cargar tu historial. Inténtalo nuevamente.\n${_cleanErrorMessage(snapshot.error)}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final historial = snapshot.data ?? [];

                  if (historial.isEmpty) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppTheme.primaryColor.withOpacity(0.15)
                                : AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_outlined,
                            size: 64,
                            color: isDark 
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Sin registros de asistencia',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Aún no tienes registros de asistencia. Tus registros aparecerán aquí cuando los generes.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark 
                                  ? Colors.grey.shade400 
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial de asistencia',
                        style: _sectionTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mostrando los últimos ${historial.length.clamp(0, 10)} registros.',
                        style: _supportTextStyle,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: historial.take(10).length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final asistencia = historial[index];
                            final fecha = DateFormat('dd/MM/yyyy')
                                .format(asistencia.fechaHoraEntrada);
                            final horaEntrada = DateFormat('HH:mm')
                                .format(asistencia.fechaHoraEntrada);
                            final horaSalida =
                                asistencia.fechaHoraSalida != null
                                    ? DateFormat('HH:mm')
                                        .format(asistencia.fechaHoraSalida!)
                                    : '--';

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        fecha,
                                        style: _cardTitleStyle,
                                      ),
                                      Chip(
                                        label: Text(
                                          asistencia.estaActiva
                                              ? 'En progreso'
                                              : 'Completado',
                                        ),
                                        backgroundColor: asistencia.estaActiva
                                            ? Colors.orange[100]
                                            : Colors.green[100],
                                        labelStyle: TextStyle(
                                          color: asistencia.estaActiva
                                              ? Colors.orange[800]
                                              : Colors.green[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Entrada: $horaEntrada'),
                                  Text('Salida: $horaSalida'),
                                  if (!asistencia.estaActiva)
                                    Text(
                                      'Horas trabajadas: ${asistencia.horasTrabajadasFormateadas}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _registrarEntrada(dynamic userId) async {
    await _runAsyncAction(() async {
      final asistencia = await AsistenciaService.registrarEntrada(userId);
      if (!mounted) return;
      await AppDialogs.showSuccessDialog(
        context: context,
        title: 'Entrada registrada',
        message:
            'Tu entrada ha sido registrada exitosamente.\n\nUbicación: ${asistencia.ubicacionEntrada ?? "No disponible"}',
      );
    });
  }

  Future<void> _registrarSalida(dynamic userId) async {
    final asistenciaActiva =
        await AsistenciaService.getAsistenciaActiva(userId);
    if (asistenciaActiva == null) {
      if (!mounted) return;
      await AppDialogs.showErrorDialog(
        context: context,
        title: 'Sin registro activo',
        message: 'No encontramos una entrada activa para cerrar.',
      );
      return;
    }

    final confirmado = await AppDialogs.showConfirmationDialog(
      context: context,
      title: '¿Registrar salida?',
      message: '¿Deseas registrar la salida de tu jornada actual?',
    );

    if (!mounted || !confirmado) return;

    await _runAsyncAction(() async {
      final asistencia =
          await AsistenciaService.registrarSalida(asistenciaActiva.id);
      if (!mounted) return;
      await AppDialogs.showSuccessDialog(
        context: context,
        title: 'Salida registrada',
        message:
            'Tu salida ha sido registrada exitosamente.\n\nUbicación: ${asistencia.ubicacionSalida ?? "No disponible"}\nHoras trabajadas: ${asistencia.horasTrabajadasFormateadas}',
      );
    });
  }

  Future<void> _runAsyncAction(Future<void> Function() action) async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      await AppDialogs.showErrorDialog(
        context: context,
        title: 'Error',
        message: _cleanErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  String _cleanErrorMessage(Object? error) {
    final raw = error?.toString() ?? 'Ocurrió un error desconocido.';
    return raw.replaceFirst('Exception: ', '');
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await AppDialogs.showLogoutConfirmationDialog(
      context: context,
    );

    if (confirmado) {
      // Limpiar datos del usuario anterior para no mostrarlos al siguiente (incl. caché productos/tenant)
      context.read<ClienteProvider>().clearForNewUser();
      context.read<VentasProvider>().clearForNewUser();
      await context.read<ProductoProvider>().clearForNewUser();
      context.read<CategoriasProvider>().clearForNewUser();
      context.read<PermisosProvider>().clearPermisos();
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

enum _AsistenciaQuickAction {
  registrarEntrada,
  registrarSalida,
}
