import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Services/Auth_Service/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 197, 197, 197),
              Color.fromARGB(255, 16, 58, 18),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                            MediaQuery.of(context).padding.top - 
                            MediaQuery.of(context).padding.bottom - 40,
                ),
                child: IntrinsicHeight(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Header Section
                          _buildHeader(),
                          
                          // Login Form
                          _buildLoginForm(),
                          
                          // Footer
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Container with gradient
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.business_center,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        // App Title
        const Text(
          'PROVIDER',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 48, 48, 48),
            fontFamily: 'Raleway',
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sistema de Gestión Comercial',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 49, 49, 49),
            fontFamily: 'Raleway',
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
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

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inicia sesión para acceder al sistema',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 24),

            // Username Field
            _buildTextField(
              controller: _userNameController,
              label: 'Usuario',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su usuario';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Error Message
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.errorMessage != null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
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

            // Login Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Container(
                  width: double.infinity,
                  height: 48,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.login,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Raleway',
                                  letterSpacing: 1.0,
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(
        fontSize: 16,
        color: Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'Raleway',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF333333),
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF333333),
          size: 24,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF333333),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF333333),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          '© 2025 Provider',
          style: TextStyle(
            color: Color.fromARGB(255, 223, 223, 223),
            fontSize: 14,
            fontFamily: 'Raleway',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sistema de Gestión Comercial',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 12,
            fontFamily: 'Raleway',
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      authProvider.clearError();
      
      final success = await authProvider.login(
        _userNameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to main menu
        Navigator.of(context).pushReplacementNamed('/menu');
      }
    }
  }
}