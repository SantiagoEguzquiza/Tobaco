import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Models/User.dart';
import '../../Models/TipoVendedor.dart';
import '../../Services/User_Service/user_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';

bool _hasUpperCase(String password) => password.contains(RegExp(r'[A-Z]'));
bool _hasLowerCase(String password) => password.contains(RegExp(r'[a-z]'));
bool _hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
bool _hasMinLength(String password) => password.length >= 6;

class NuevoUsuarioScreen extends StatefulWidget {
  const NuevoUsuarioScreen({super.key});

  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _zonaController = TextEditingController();
  String _selectedRole = 'Employee';
  TipoVendedor _selectedTipoVendedor = TipoVendedor.repartidor;

  bool _isLoading = false;
  bool _hasUserNameError = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;

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

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _clearFieldErrors();
    });

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.createUser(
      userName: _userNameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      tipoVendedor: _selectedRole == 'Employee' ? _selectedTipoVendedor : null,
      zona: _zonaController.text.trim().isEmpty ? null : _zonaController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Usuario "${_userNameController.text.trim()}" creado exitosamente'),
      );
      Navigator.pop(context, true);
    } else {
      String errorMessage = userProvider.errorMessage ?? 'Error al crear usuario';
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
          title: const Text('Nuevo Usuario', style: AppTheme.appBarTitleStyle),
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
                          label: 'Contraseña *',
                          hint: 'Mayúscula, minúscula, número, 6+ caracteres',
                          icon: Icons.lock_outline,
                          isDark: isDark,
                          hasError: _hasPasswordError,
                          obscureText: true,
                          onChanged: (_) {
                            setState(() {});
                            _clearFieldErrors();
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'La contraseña es requerida';
                            if (!_hasMinLength(v)) return 'Mínimo 6 caracteres';
                            if (!_hasUpperCase(v)) return 'Al menos una mayúscula';
                            if (!_hasLowerCase(v)) return 'Al menos una minúscula';
                            if (!_hasNumber(v)) return 'Al menos un número';
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
                          value: _selectedRole,
                          decoration: _dropdownDecoration(isDark),
                          dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          style: TextStyle(color: textColor, fontSize: 16),
                          items: const [
                            DropdownMenuItem(value: 'Employee', child: Text('Empleado')),
                            DropdownMenuItem(value: 'Admin', child: Text('Administrador')),
                          ],
                          onChanged: (value) => setState(() => _selectedRole = value!),
                        ),
                        if (_selectedRole == 'Employee') ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<TipoVendedor>(
                            value: _selectedTipoVendedor,
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
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomNavHeight),
                child: Container(
                  padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
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
                                onPressed: _crearUsuario,
                                icon: const Icon(Icons.person_add_outlined, size: 22),
                                label: const Text('Crear Usuario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
