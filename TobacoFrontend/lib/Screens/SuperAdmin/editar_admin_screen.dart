import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Models/Tenant.dart';
import '../../Models/User.dart';
import '../../Services/Admin_Service/admin_service.dart';
import '../../Theme/app_theme.dart';

bool _hasUpperCase(String password) => password.contains(RegExp(r'[A-Z]'));
bool _hasLowerCase(String password) => password.contains(RegExp(r'[a-z]'));
bool _hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
bool _hasMinLength(String password) => password.length >= 8;

class EditarAdminScreen extends StatefulWidget {
  final Tenant tenant;
  final User admin;

  const EditarAdminScreen({super.key, required this.tenant, required this.admin});

  @override
  State<EditarAdminScreen> createState() => _EditarAdminScreenState();
}

class _EditarAdminScreenState extends State<EditarAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userNameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  bool _hasUserNameError = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: widget.admin.userName);
    _emailController = TextEditingController(text: widget.admin.email ?? '');
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    setState(() {
      _hasUserNameError = false;
      _hasEmailError = false;
      _hasPasswordError = false;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _clearFieldErrors();
    });

    try {
      await _adminService.actualizarAdmin(
        widget.tenant.id,
        widget.admin.id,
        userName: _userNameController.text.trim(),
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      FocusScope.of(context).unfocus();
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Administrador "${_userNameController.text.trim()}" actualizado exitosamente'),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          title: const Text('Editar Administrador', style: AppTheme.appBarTitleStyle),
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
                          hint: 'Dejar vacío para no cambiar',
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
                              if (!_hasMinLength(v)) return 'Mínimo 8 caracteres';
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
                      title: 'Tenant',
                      icon: Icons.business_outlined,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.store, color: AppTheme.primaryColor, size: 24),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.tenant.nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 3,
                              ),
                            ),
                          ],
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
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: _isLoading
                              ? Container(
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
                                  onPressed: _guardarCambios,
                                  icon: const Icon(Icons.save_outlined, size: 18),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text(
                                      'Guardar cambios',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                    ),
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
          _rule(Icons.check_circle, _hasMinLength(p), '8+ caracteres', isDark),
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
