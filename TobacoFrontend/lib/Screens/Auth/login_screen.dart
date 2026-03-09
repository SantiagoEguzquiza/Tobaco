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

enum _LoginLayoutSize { compact, medium, regular }

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
                final layoutSize = height < 700 || width < 360
                    ? _LoginLayoutSize.compact
                    : (height < 840 || width < 430)
                        ? _LoginLayoutSize.medium
                        : _LoginLayoutSize.regular;
                final isCompactLayout = layoutSize == _LoginLayoutSize.compact;
                final isMediumLayout = layoutSize == _LoginLayoutSize.medium;
                final padding = switch (layoutSize) {
                  _LoginLayoutSize.compact => 20.0,
                  _LoginLayoutSize.medium => 22.0,
                  _LoginLayoutSize.regular => 24.0,
                };
                final sectionSpacing = switch (layoutSize) {
                  _LoginLayoutSize.compact => 24.0,
                  _LoginLayoutSize.medium => 18.0,
                  _LoginLayoutSize.regular => 32.0,
                };
                final minHeight = isCompactLayout
                    ? null
                    : (height -
                          MediaQuery.paddingOf(context).top -
                          MediaQuery.paddingOf(context).bottom -
                          (isMediumLayout ? 24 : 40));
                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minHeight ?? 0,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: isCompactLayout
                            ? MainAxisAlignment.start
                            : (isMediumLayout
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.spaceEvenly),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompactLayout) SizedBox(height: sectionSpacing),
                          _buildHeader(layoutSize),
                          SizedBox(
                            height: layoutSize == _LoginLayoutSize.regular
                                ? 0
                                : sectionSpacing,
                          ),
                          _buildLoginForm(layoutSize),
                          SizedBox(
                            height: layoutSize == _LoginLayoutSize.regular
                                ? 0
                                : sectionSpacing,
                          ),
                          _buildFooter(layoutSize),
                          if (isCompactLayout) SizedBox(height: sectionSpacing),
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

  Widget _buildHeader(_LoginLayoutSize layoutSize) {
    final isCompactLayout = layoutSize == _LoginLayoutSize.compact;
    final logoSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 64.0,
      _LoginLayoutSize.medium => 78.0,
      _LoginLayoutSize.regular => 100.0,
    };
    final iconSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 32.0,
      _LoginLayoutSize.medium => 38.0,
      _LoginLayoutSize.regular => 50.0,
    };
    final titleSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 24.0,
      _LoginLayoutSize.medium => 27.0,
      _LoginLayoutSize.regular => 32.0,
    };
    final subtitleSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 13.0,
      _LoginLayoutSize.medium => 14.5,
      _LoginLayoutSize.regular => 16.0,
    };
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
                blurRadius: isCompactLayout ? 12 : (layoutSize == _LoginLayoutSize.medium ? 16 : 20),
                offset: Offset(0, isCompactLayout ? 6 : (layoutSize == _LoginLayoutSize.medium ? 8 : 10)),
              ),
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: isCompactLayout ? 8 : (layoutSize == _LoginLayoutSize.medium ? 11 : 15),
                offset: Offset(0, isCompactLayout ? 3 : (layoutSize == _LoginLayoutSize.medium ? 4 : 5)),
              ),
            ],
          ),
          child: Icon(
            Icons.business_center,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(
          height: switch (layoutSize) {
            _LoginLayoutSize.compact => 20.0,
            _LoginLayoutSize.medium => 18.0,
            _LoginLayoutSize.regular => 24.0,
          },
        ),
        Text(
          'PROVIDER',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color.fromARGB(255, 48, 48, 48),
            fontFamily: 'Raleway',
            letterSpacing: switch (layoutSize) {
              _LoginLayoutSize.compact => 1.2,
              _LoginLayoutSize.medium => 1.5,
              _LoginLayoutSize.regular => 2.0,
            },
          ),
        ),
        SizedBox(
          height: switch (layoutSize) {
            _LoginLayoutSize.compact => 10.0,
            _LoginLayoutSize.medium => 9.0,
            _LoginLayoutSize.regular => 12.0,
          },
        ),
        Text(
          'Sistema de Gestión Comercial',
          style: TextStyle(
            fontSize: subtitleSize,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : const Color.fromARGB(255, 49, 49, 49),
            fontFamily: 'Raleway',
            letterSpacing: switch (layoutSize) {
              _LoginLayoutSize.compact => 0.5,
              _LoginLayoutSize.medium => 0.7,
              _LoginLayoutSize.regular => 1.0,
            },
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          width: switch (layoutSize) {
            _LoginLayoutSize.compact => 56.0,
            _LoginLayoutSize.medium => 66.0,
            _LoginLayoutSize.regular => 80.0,
          },
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

  Widget _buildLoginForm(_LoginLayoutSize layoutSize) {
    final isCompactLayout = layoutSize == _LoginLayoutSize.compact;
    final formPadding = switch (layoutSize) {
      _LoginLayoutSize.compact => 24.0,
      _LoginLayoutSize.medium => 24.0,
      _LoginLayoutSize.regular => 28.0,
    };
    final titleSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 20.0,
      _LoginLayoutSize.medium => 22.0,
      _LoginLayoutSize.regular => 24.0,
    };
    final subtitleSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 13.0,
      _LoginLayoutSize.medium => 13.5,
      _LoginLayoutSize.regular => 14.0,
    };
    final afterSubtitle = switch (layoutSize) {
      _LoginLayoutSize.compact => 24.0,
      _LoginLayoutSize.medium => 20.0,
      _LoginLayoutSize.regular => 28.0,
    };
    final fieldSpacing = switch (layoutSize) {
      _LoginLayoutSize.compact => 22.0,
      _LoginLayoutSize.medium => 18.0,
      _LoginLayoutSize.regular => 22.0,
    };
    final afterPassword = switch (layoutSize) {
      _LoginLayoutSize.compact => 18.0,
      _LoginLayoutSize.medium => 14.0,
      _LoginLayoutSize.regular => 18.0,
    };
    final beforeButton = switch (layoutSize) {
      _LoginLayoutSize.compact => 22.0,
      _LoginLayoutSize.medium => 18.0,
      _LoginLayoutSize.regular => 24.0,
    };
    final buttonHeight = switch (layoutSize) {
      _LoginLayoutSize.compact => 48.0,
      _LoginLayoutSize.medium => 50.0,
      _LoginLayoutSize.regular => 52.0,
    };
    return Container(
      padding: EdgeInsets.all(formPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(
          switch (layoutSize) {
            _LoginLayoutSize.compact => 18.0,
            _LoginLayoutSize.medium => 19.0,
            _LoginLayoutSize.regular => 20.0,
          },
        ),
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
            SizedBox(
              height: switch (layoutSize) {
                _LoginLayoutSize.compact => 14.0,
                _LoginLayoutSize.medium => 13.0,
                _LoginLayoutSize.regular => 12.0,
              },
            ),
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

            _buildTextField(
              controller: _userNameController,
              label: 'Usuario',
              icon: Icons.person_outline,
              layoutSize: layoutSize,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su usuario';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
              layoutSize: layoutSize,
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
                  padding: EdgeInsets.symmetric(
                    vertical: isCompactLayout ? 12 : 8,
                    horizontal: 16,
                  ),
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: switch (layoutSize) {
                      _LoginLayoutSize.compact => 13.0,
                      _LoginLayoutSize.medium => 13.5,
                      _LoginLayoutSize.regular => 14.0,
                    },
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
                    padding: EdgeInsets.all(isCompactLayout ? 14 : 16),
                    margin: EdgeInsets.only(
                      bottom: layoutSize == _LoginLayoutSize.medium ? 16 : 20,
                    ),
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
                          height: isCompactLayout ? 22 : 24,
                          width: isCompactLayout ? 22 : 24,
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
                                size: isCompactLayout ? 22 : 24,
                              ),
                              SizedBox(
                                width: layoutSize == _LoginLayoutSize.medium ? 10 : 12,
                              ),
                              Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  fontSize: switch (layoutSize) {
                                    _LoginLayoutSize.compact => 16.0,
                                    _LoginLayoutSize.medium => 17.0,
                                    _LoginLayoutSize.regular => 18.0,
                                  },
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Raleway',
                                  letterSpacing: isCompactLayout ? 0.8 : 1.0,
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
    required _LoginLayoutSize layoutSize,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 15.0,
      _LoginLayoutSize.medium => 16.0,
      _LoginLayoutSize.regular => 16.0,
    };
    final iconSize = switch (layoutSize) {
      _LoginLayoutSize.compact => 20.0,
      _LoginLayoutSize.medium => 22.0,
      _LoginLayoutSize.regular => 24.0,
    };
    final verticalPadding = switch (layoutSize) {
      _LoginLayoutSize.compact => 12.0,
      _LoginLayoutSize.medium => 14.0,
      _LoginLayoutSize.regular => 16.0,
    };
    final borderRadius = switch (layoutSize) {
      _LoginLayoutSize.compact => 12.0,
      _LoginLayoutSize.medium => 14.0,
      _LoginLayoutSize.regular => 16.0,
    };

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
          fontSize: switch (layoutSize) {
            _LoginLayoutSize.compact => 14.0,
            _LoginLayoutSize.medium => 15.0,
            _LoginLayoutSize.regular => 15.0,
          },
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
          horizontal: switch (layoutSize) {
            _LoginLayoutSize.compact => 12.0,
            _LoginLayoutSize.medium => 14.0,
            _LoginLayoutSize.regular => 16.0,
          },
          vertical: verticalPadding,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFooter(_LoginLayoutSize layoutSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '© 2025 Provider',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : const Color.fromARGB(255, 223, 223, 223),
            fontSize: switch (layoutSize) {
              _LoginLayoutSize.compact => 12.0,
              _LoginLayoutSize.medium => 13.0,
              _LoginLayoutSize.regular => 14.0,
            },
            fontFamily: 'Raleway',
          ),
        ),
        SizedBox(
          height: switch (layoutSize) {
            _LoginLayoutSize.compact => 6.0,
            _LoginLayoutSize.medium => 5.0,
            _LoginLayoutSize.regular => 4.0,
          },
        ),
        Text(
          'Sistema de Gestión Comercial',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade500
                : const Color.fromARGB(255, 255, 255, 255),
            fontSize: switch (layoutSize) {
              _LoginLayoutSize.compact => 11.0,
              _LoginLayoutSize.medium => 11.5,
              _LoginLayoutSize.regular => 12.0,
            },
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