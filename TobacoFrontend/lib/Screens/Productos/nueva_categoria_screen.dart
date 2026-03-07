import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/Categoria.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';
import '../../Helpers/color_picker.dart';

class NuevaCategoriaScreen extends StatefulWidget {
  const NuevaCategoriaScreen({super.key});

  @override
  State<NuevaCategoriaScreen> createState() => _NuevaCategoriaScreenState();
}

class _NuevaCategoriaScreenState extends State<NuevaCategoriaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String _selectedColor = '#9E9E9E';
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _crearCategoria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<CategoriasProvider>();
    final sortOrder = provider.categorias.length;

    try {
      final nueva = Categoria(
        nombre: _nombreController.text.trim(),
        colorHex: _selectedColor,
        sortOrder: sortOrder,
      );
      await provider.agregarCategoria(nueva);

      if (!mounted) return;
      setState(() => _isLoading = false);
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Categoría agregada exitosamente'),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        final msg = e.toString().replaceFirst('Exception: ', '');
        AppTheme.showSnackBar(context, AppTheme.errorSnackBar('Error al agregar categoría: $msg'));
      }
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
          title: const Text('Nueva categoría', style: AppTheme.appBarTitleStyle),
          backgroundColor: null,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Información',
                  icon: Icons.category_outlined,
                  children: [
                    _buildTextFormField(
                      controller: _nombreController,
                      label: 'Nombre de la categoría *',
                      hint: 'Ingresa el nombre',
                      icon: Icons.label_outline,
                      isDark: isDark,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ColorPicker(
                      selectedColor: _selectedColor,
                      onColorSelected: (color) => setState(() => _selectedColor = color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _crearCategoria,
                          icon: const Icon(Icons.add_circle_outline, size: 22),
                          label: const Text('Crear categoría', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
