import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Services/Auth_Service/auth_provider.dart';
import '../../Services/Permisos_Service/permisos_provider.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Services/Ventas_Service/ventas_provider.dart';
import '../../Helpers/api_handler.dart';
import '../menu_screen.dart';
import 'recuperar_contrasena_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // No necesitamos verificar autenticación aquí porque AuthWrapper ya lo hace
    // Esto evita doble inicialización y bucles
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFF333333),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF333333),
              width: 2,
            ),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF4CAF50),
          selectionColor: Color(0xFF4CAF50),
          selectionHandleColor: Color(0xFF4CAF50),
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark ? [
              const Color(0xFF0F0F0F),
              const Color(0xFF1A1A1A),
              const Color(0xFF2A2A2A),
            ] : [
              const Color.fromARGB(255, 255, 255, 255),
              const Color.fromARGB(255, 197, 197, 197),
              const Color.fromARGB(255, 16, 58, 18),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = MediaQuery.sizeOf(context).height;
                final width = MediaQuery.sizeOf(context).width;
                // Incluir más celulares como "small": altura < 700 o ancho < 400
                final isSmallPhone = height < 700 || width < 400;
                final padding = isSmallPhone ? 20.0 : 24.0;
                final sectionSpacing = isSmallPhone ? 28.0 : 32.0;
                final minHeight = isSmallPhone
                    ? null
                    : (height - MediaQuery.paddingOf(context).top - MediaQuery.paddingOf(context).bottom - 40);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight ?? 0,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: isSmallPhone ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSmallPhone) SizedBox(height: sectionSpacing),
                          _buildHeader(isSmallPhone),
                          SizedBox(height: isSmallPhone ? sectionSpacing : 0),
                          _buildLoginForm(isSmallPhone),
                          SizedBox(height: isSmallPhone ? sectionSpacing : 0),
                          _buildFooter(isSmallPhone),
                          if (isSmallPhone) SizedBox(height: sectionSpacing),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallPhone) {
    final logoSize = isSmallPhone ? 64.0 : 100.0;
    final iconSize = isSmallPhone ? 32.0 : 50.0;
    final titleSize = isSmallPhone ? 24.0 : 32.0;
    final subtitleSize = isSmallPhone ? 13.0 : 16.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(logoSize / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: isSmallPhone ? 12 : 20,
                offset: Offset(0, isSmallPhone ? 6 : 10),
              ),
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: isSmallPhone ? 8 : 15,
                offset: Offset(0, isSmallPhone ? 3 : 5),
              ),
            ],
          ),
          child: Icon(
            Icons.business_center,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallPhone ? 20 : 24),
        Text(
          'PROVIDER',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color.fromARGB(255, 48, 48, 48),
            fontFamily: 'Raleway',
            letterSpacing: isSmallPhone ? 1.2 : 2.0,
          ),
        ),
        SizedBox(height: isSmallPhone ? 10 : 12),
        Text(
          'Sistema de Gestión Comercial',
          style: TextStyle(
            fontSize: subtitleSize,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : const Color.fromARGB(255, 49, 49, 49),
            fontFamily: 'Raleway',
            letterSpacing: isSmallPhone ? 0.5 : 1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          width: isSmallPhone ? 56 : 80,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isSmallPhone) {
    // En small phone más padding y espaciado para que no quede todo pegado
    final formPadding = isSmallPhone ? 24.0 : 28.0;
    final titleSize = isSmallPhone ? 20.0 : 24.0;
    final subtitleSize = isSmallPhone ? 13.0 : 14.0;
    final afterSubtitle = isSmallPhone ? 28.0 : 28.0;
    final fieldSpacing = isSmallPhone ? 26.0 : 22.0;
    final afterPassword = isSmallPhone ? 22.0 : 18.0;
    final beforeButton = isSmallPhone ? 28.0 : 24.0;
    final buttonHeight = isSmallPhone ? 48.0 : 48.0;
    return Container(
      padding: EdgeInsets.all(formPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(isSmallPhone ? 18 : 20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
                fontFamily: 'Raleway',
              ),
            ),
            SizedBox(height: isSmallPhone ? 14 : 12),
            Text(
              'Inicia sesión para acceder al sistema',
              style: TextStyle(
                fontSize: subtitleSize,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : const Color(0xFF666666),
                fontFamily: 'Raleway',
              ),
            ),
            SizedBox(height: afterSubtitle),

            // Username Field
            _buildTextField(
              controller: _userNameController,
              label: 'Usuario',
              icon: Icons.person_outline,
              isCompact: isSmallPhone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su usuario';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
              isCompact: isSmallPhone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su contraseña';
                }
                return null;
              },
            ),
            SizedBox(height: afterPassword),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecuperarContrasenaScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 12 : 8, horizontal: 16),
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: isSmallPhone ? 13 : 14,
                    fontFamily: 'Raleway',
                  ),
                ),
              ),
            ),
            SizedBox(height: beforeButton),

            // Error Message
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.errorMessage != null) {
                  return Container(
                    padding: EdgeInsets.all(isSmallPhone ? 14 : 16),
                    margin: EdgeInsets.only(bottom: isSmallPhone ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Login Button / Loading
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Container(
                  width: double.infinity,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading 
                        ? null 
                        : () => _handleLogin(context, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: authProvider.isLoading
                        ? SizedBox(
                            height: isSmallPhone ? 22 : 24,
                            width: isSmallPhone ? 22 : 24,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.login,
                                color: Colors.white,
                                size: isSmallPhone ? 22 : 24,
                              ),
                              SizedBox(width: isSmallPhone ? 10 : 12),
                              Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  fontSize: isSmallPhone ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Raleway',
                                  letterSpacing: isSmallPhone ? 0.8 : 1.0,
                                ),
                              ),
                            ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isCompact = false,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = isCompact ? 15.0 : 16.0;
    final iconSize = isCompact ? 20.0 : 24.0;
    final verticalPadding = isCompact ? 12.0 : 16.0;
    final borderRadius = isCompact ? 12.0 : 16.0;

    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(
        fontSize: fontSize,
        color: isDark ? Colors.white : const Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'Raleway',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : const Color(0xFF333333),
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey.shade400 : const Color(0xFF333333),
          size: iconSize,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF333333),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : const Color(0xFFE0E0E0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : const Color(0xFFE0E0E0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade400 : const Color(0xFF333333),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: verticalPadding,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFooter(bool isSmallPhone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '© 2025 Provider',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : const Color.fromARGB(255, 223, 223, 223),
            fontSize: isSmallPhone ? 12 : 14,
            fontFamily: 'Raleway',
          ),
        ),
        SizedBox(height: isSmallPhone ? 6 : 4),
        Text(
          'Sistema de Gestión Comercial',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade500
                : const Color.fromARGB(255, 255, 255, 255),
            fontSize: isSmallPhone ? 11 : 12,
            fontFamily: 'Raleway',
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      authProvider.clearError();
      
      // Limpiar permisos antes de iniciar login para asegurar estado limpio
      final permisosProvider = context.read<PermisosProvider>();
      permisosProvider.clearPermisos();
      
      try {
        final success = await authProvider.login(
          _userNameController.text.trim(),
          _passwordController.text,
        );

        if (success && mounted) {
          // Limpiar caché y estado de otro usuario para no mostrar sus datos al abrir pantallas
          await context.read<ClienteProvider>().clearForNewUser();
          await context.read<CategoriasProvider>().clearForNewUser();
          await context.read<ProductoProvider>().clearForNewUser();
          await context.read<VentasProvider>().clearForNewUser();
          if (!mounted) return;
          // Dar un momento al almacenamiento para que el token esté disponible (evita fallos al reingresar con el mismo usuario)
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) return;

          // Cargar permisos después del login; timeout 12s para no quedar colgado.
          bool permisosLoaded = false;
          for (int attempt = 0; attempt < 2 && mounted && !permisosLoaded; attempt++) {
            try {
              await permisosProvider
                  .loadPermisos(authProvider, forceReload: true)
                  .timeout(const Duration(seconds: 12));
              permisosLoaded = true;
            } on TimeoutException {
              permisosProvider.marcarTimeoutPermisos();
              break;
            } catch (e) {
              final isConnectionError = Apihandler.isConnectionError(e);
              if (isConnectionError && attempt == 0) {
                await Future.delayed(const Duration(milliseconds: 1500));
                if (!mounted) return;
              } else {
                break;
              }
            }
          }
          if (!permisosLoaded && mounted && permisosProvider.isLoading) {
            permisosProvider.marcarTimeoutPermisos();
          }

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MenuScreen()),
            );
          }
        }
      } catch (e) {
        // Mostrar diálogo de error de servidor si corresponde
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        }
        // Los demás errores ya se muestran en la UI del AuthProvider
      }
    }
  }

}