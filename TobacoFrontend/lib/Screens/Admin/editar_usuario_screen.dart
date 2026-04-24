import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Models/User.dart';
import '../../Models/TipoVendedor.dart';
import '../../Services/User_Service/user_provider.dart';
import '../../Services/Auth_Service/auth_provider.dart';
import '../../Services/Auth_Service/auth_service.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Services/Ventas_Service/ventas_provider.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Services/Permisos_Service/permisos_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';

bool _hasUpperCase(String password) => password.contains(RegExp(r'[A-Z]'));
bool _hasLowerCase(String password) => password.contains(RegExp(r'[a-z]'));
bool _hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
bool _hasMinLength(String password) => password.length >= 6;

bool _isLastAdmin(User user, UserProvider userProvider) {
  if (!user.isAdmin || !user.isActive) return false;
  final activeAdmins = userProvider.users.where((u) => u.isAdmin && u.isActive && u.id != user.id).length;
  return activeAdmins == 0;
}

Future<void> _showLastAdminRoleChangeWarningDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('No se puede cambiar el rol', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
      content: const Text(
        'No puedes cambiar el rol del último administrador a empleado.\n\n'
        'Para realizar esta acción, primero crea otro usuario administrador.',
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ),
      ],
    ),
  );
}

Future<void> _showLastAdminDeactivationWarningDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('No se puede desactivar', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
      content: const Text(
        'No puedes desactivar tu cuenta porque eres el último administrador activo.\n\n'
        'Para realizar esta acción, primero crea otro usuario administrador.',
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ),
      ],
    ),
  );
}

class EditarUsuarioScreen extends StatefulWidget {
  final User user;

  const EditarUsuarioScreen({super.key, required this.user});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _zonaController;
  late String _selectedRole;
  late TipoVendedor _selectedTipoVendedor;
  late bool _isActive;

  bool _isLoading = false;
  bool _hasUserNameError = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: widget.user.userName);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _passwordController = TextEditingController();
    _zonaController = TextEditingController(text: widget.user.zona ?? '');
    _selectedRole = widget.user.role;
    _selectedTipoVendedor = widget.user.tipoVendedor;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _zonaController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    setState(() {
      _hasUserNameError = false;
      _hasEmailError = false;
      _hasPasswordError = false;
    });
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    if (widget.user.isAdmin && widget.user.role == 'Admin' && _selectedRole == 'Employee' && _isLastAdmin(widget.user, userProvider)) {
      await _showLastAdminRoleChangeWarningDialog(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _clearFieldErrors();
    });

    Map<String, dynamic> result;
    try {
      result = await userProvider.updateUser(
        userId: widget.user.id,
        userName: _userNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        role: _selectedRole,
        isActive: _isActive,
        tipoVendedor: _selectedRole == 'Employee' ? _selectedTipoVendedor : null,
        zona: _zonaController.text.trim().isEmpty ? null : _zonaController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(context, AppTheme.errorSnackBar('No se pudo actualizar el usuario.'));
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final navigator = Navigator.of(context);

    if (result['success'] == true) {
      if (result['currentUserAffected'] == true) {
        await context.read<ClienteProvider>().clearForNewUser();
        await context.read<VentasProvider>().clearForNewUser();
        await context.read<ProductoProvider>().clearForNewUser();
        await context.read<CategoriasProvider>().clearForNewUser();
        context.read<PermisosProvider>().clearPermisos();
        await AuthService.logout();
        AppTheme.showSnackBar(
          context,
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(result['message'] ?? 'Tu cuenta ha sido desactivada', style: const TextStyle(fontSize: 14))),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (widget.user.id == authProvider.currentUser?.id && widget.user.role == 'Admin' && _selectedRole == 'Employee') {
        navigator.pop(true);
        AppTheme.showSnackBar(context, AppTheme.successSnackBar('Usuario actualizado. Serás redirigido al menú.'));
        if (mounted) navigator.pushNamedAndRemoveUntil('/menu', (route) => false);
        return;
      }

      AppTheme.showSnackBar(context, AppTheme.successSnackBar('Usuario "${_userNameController.text.trim()}" actualizado exitosamente'));
      navigator.pop(true);
    } else {
      String errorMessage = userProvider.errorMessage ?? 'Error al actualizar usuario';
      if (errorMessage.toLowerCase().contains('duplicate') ||
          errorMessage.toLowerCase().contains('username') ||
          errorMessage.toLowerCase().contains('ya existe') ||
          errorMessage.toLowerCase().contains('duplicado') ||
          errorMessage.toLowerCase().contains('ya está en uso')) {
        errorMessage = 'El nombre de usuario no está disponible. Elige otro.';
        setState(() => _hasUserNameError = true);
      } else if (errorMessage.toLowerCase().contains('email') || errorMessage.toLowerCase().contains('correo')) {
        errorMessage = 'El email no es válido o ya está en uso.';
        setState(() => _hasEmailError = true);
      } else if (errorMessage.toLowerCase().contains('password') || errorMessage.toLowerCase().contains('contraseña')) {
        errorMessage = 'La contraseña no cumple los requisitos.';
        setState(() => _hasPasswordError = true);
      }
      AppTheme.showSnackBar(context, AppTheme.errorSnackBar(errorMessage));
      userProvider.clearError();
    }
  }

  static double _bottomNavHeight(BuildContext context) {
    return 56.0 + MediaQuery.of(context).padding.bottom;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE0E0E0) : Colors.black87;
    final userProvider = context.watch<UserProvider>();
    final isLastAdmin = _isLastAdmin(widget.user, userProvider);
    final bottomNavHeight = _bottomNavHeight(context);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppTheme.primaryColor,
          selectionColor: AppTheme.primaryColor.withOpacity(0.3),
          selectionHandleColor: AppTheme.primaryColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Editar Usuario', style: AppTheme.appBarTitleStyle),
          backgroundColor: null,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      isDark: isDark,
                      title: 'Información básica',
                      icon: Icons.person_outline,
                      children: [
                        _buildTextFormField(
                          controller: _userNameController,
                          label: 'Nombre de usuario *',
                          hint: 'Sin espacios',
                          icon: Icons.person_outlined,
                          isDark: isDark,
                          hasError: _hasUserNameError,
                          onChanged: (_) => _clearFieldErrors(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.contains(' ')) return 'No puede contener espacios';
                            return null;
                          },
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _emailController,
                          label: 'Email (opcional)',
                          hint: 'ejemplo@correo.com',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          hasError: _hasEmailError,
                          onChanged: (_) => _clearFieldErrors(),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v.trim())) return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _passwordController,
                          label: 'Nueva contraseña (opcional)',
                          hint: 'Dejar vacío para mantener la actual',
                          icon: Icons.lock_outline,
                          isDark: isDark,
                          hasError: _hasPasswordError,
                          obscureText: true,
                          onChanged: (_) {
                            setState(() {});
                            _clearFieldErrors();
                          },
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              if (!_hasMinLength(v)) return 'Mínimo 6 caracteres';
                              if (!_hasUpperCase(v)) return 'Al menos una mayúscula';
                              if (!_hasLowerCase(v)) return 'Al menos una minúscula';
                              if (!_hasNumber(v)) return 'Al menos un número';
                            }
                            return null;
                          },
                        ),
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildPasswordRules(context, isDark),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      isDark: isDark,
                      title: 'Rol y tipo',
                      icon: Icons.badge_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: _dropdownDecoration(isDark),
                          dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          style: TextStyle(color: textColor, fontSize: 16),
                          items: [
                            DropdownMenuItem(
                              value: 'Employee',
                              enabled: !isLastAdmin,
                              child: Row(
                                children: [
                                  const Text('Empleado'),
                                  if (isLastAdmin) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
                                  ],
                                ],
                              ),
                            ),
                            const DropdownMenuItem(value: 'Admin', child: Text('Administrador')),
                          ],
                          onChanged: (value) {
                            if (value == 'Employee' && isLastAdmin) {
                              _showLastAdminRoleChangeWarningDialog(context);
                              return;
                            }
                            setState(() => _selectedRole = value!);
                          },
                        ),
                        if (_selectedRole == 'Employee') ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<TipoVendedor>(
                            initialValue: _selectedTipoVendedor,
                            decoration: _dropdownDecoration(isDark),
                            dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            style: TextStyle(color: textColor, fontSize: 16),
                            items: TipoVendedor.values
                                .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedTipoVendedor = value!),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTipoVendedor.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _zonaController,
                          label: 'Zona (opcional)',
                          hint: 'Ej: Zona Norte, Centro',
                          icon: Icons.location_on_outlined,
                          isDark: isDark,
                          hasError: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      isDark: isDark,
                      title: 'Estado',
                      icon: Icons.toggle_on_outlined,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: SwitchListTile.adaptive(
                            value: _isActive,
                            onChanged: (value) {
                              if (!value && isLastAdmin) {
                                _showLastAdminDeactivationWarningDialog(context);
                                return;
                              }
                              setState(() => _isActive = value);
                            },
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Usuario activo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            subtitle: isLastAdmin && _isActive
                                ? const Text(
                                    'No puedes desactivarte (eres el último administrador)',
                                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                  )
                                : null,
                            activeColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                            ),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoading
                            ? Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _guardarUsuario,
                                icon: const Icon(Icons.save_outlined, size: 22),
                                label: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool hasError = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: hasError ? Colors.red : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            prefixIcon: Icon(icon, color: hasError ? Colors.red : AppTheme.primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.red : (isDark ? const Color(0xFF404040) : Colors.grey.shade300)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.red : (isDark ? const Color(0xFF404040) : Colors.grey.shade300)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.red : AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRules(BuildContext context, bool isDark) {
    final p = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          _rule(Icons.check_circle, _hasMinLength(p), '6+ caracteres', isDark),
          _rule(Icons.check_circle, _hasUpperCase(p), 'Una mayúscula', isDark),
          _rule(Icons.check_circle, _hasLowerCase(p), 'Una minúscula', isDark),
          _rule(Icons.check_circle, _hasNumber(p), 'Un número', isDark),
        ],
      ),
    );
  }

  Widget _rule(IconData icon, bool ok, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.circle_outlined, size: 16, color: ok ? Colors.green : (isDark ? Colors.grey.shade600 : Colors.grey)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: ok ? Colors.green.shade700 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
        ],
      ),
    );
  }
}
