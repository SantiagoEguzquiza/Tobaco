import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Widget de header con botón de acción
/// Muestra un ícono a la izquierda, título/subtítulo alineados, y un botón de acción a la derecha
class HeaderConBoton extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final VoidCallback onAction;
  final IconData actionIcon;
  final String actionTooltip;
  final HeaderButtonType buttonType;
  final Color? customBackgroundColor;
  final Color? customBorderColor;

  const HeaderConBoton({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.onAction,
    required this.actionIcon,
    required this.actionTooltip,
    this.buttonType = HeaderButtonType.primary,
    this.customBackgroundColor,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ] : [
            (customBackgroundColor ?? AppTheme.primaryColor).withOpacity(0.1),
            (customBackgroundColor ?? AppTheme.secondaryColor).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
            ? const Color(0xFF404040)
            : (customBorderColor ?? AppTheme.primaryColor).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          // Ícono principal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: customBackgroundColor ?? AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              leadingIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Botón de acción
          _buildActionButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isDark) {
    Color buttonColor;
    Color iconColor;
    
    switch (buttonType) {
      case HeaderButtonType.primary:
        buttonColor = AppTheme.primaryColor;
        iconColor = Colors.white;
        break;
      case HeaderButtonType.destructive:
        buttonColor = Colors.red;
        iconColor = Colors.white;
        break;
      case HeaderButtonType.secondary:
        buttonColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
        iconColor = isDark ? Colors.white : Colors.grey[700]!;
        break;
    }

    return Tooltip(
      message: actionTooltip,
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                actionIcon,
                color: iconColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de header con buscador
/// Muestra un ícono, título/subtítulo y debajo un TextField con funcionalidad de búsqueda
class HeaderConBuscador extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;
  final Color? customBackgroundColor;
  final Color? customBorderColor;
  /// Icono o botón a la derecha del buscador (ej. Icons.tune para filtros avanzados).
  final Widget? trailing;

  const HeaderConBuscador({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.onSubmitted,
    this.customBackgroundColor,
    this.customBorderColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 680;
    final topPad = isCompact ? 12.0 : 20.0;
    final horizontalPad = isCompact ? 14.0 : 20.0;
    final bottomTitlePad = isCompact ? 16.0 : 24.0;
    final searchPad = isCompact ? 12.0 : 16.0;
    final titleSize = isCompact ? 18.0 : 24.0;
    final subtitleSize = isCompact ? 12.0 : 14.0;
    final iconPadding = isCompact ? 8.0 : 12.0;
    final iconSize = isCompact ? 20.0 : 24.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ] : [
            (customBackgroundColor ?? AppTheme.primaryColor).withOpacity(0.1),
            (customBackgroundColor ?? AppTheme.primaryColor).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark 
            ? const Color(0xFF404040)
            : (customBorderColor ?? AppTheme.primaryColor).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Sección superior con ícono, título y subtítulo
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, topPad, horizontalPad, bottomTitlePad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: customBackgroundColor ?? AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                  ),
                  child: Icon(
                    leadingIcon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: isCompact ? 4 : 6),
                        Padding(
                          padding: EdgeInsets.only(bottom: isCompact ? 2 : 4),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              height: 1.35,
                              color: isDark ? Colors.grey[300] : Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isCompact ? 2 : 4),
          
          // Sección de búsqueda
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, searchPad),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: AppTheme.primaryColor,
                    selectionColor: AppTheme.primaryColor.withOpacity(0.3),
                    selectionHandleColor: AppTheme.primaryColor,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    size: 20,
                  ),
                  suffixIcon: (controller.text.isNotEmpty || trailing != null)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trailing != null) trailing!,
                            if (controller.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                                  size: 20,
                                ),
                                onPressed: onClear,
                                tooltip: 'Limpiar búsqueda',
                              ),
                          ],
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enum para tipos de botones en el header
enum HeaderButtonType {
  primary,
  destructive,
  secondary,
}

/// Widget de header simple (solo título y subtítulo)
/// Para casos donde no se necesita botón ni buscador
class HeaderSimple extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final Color? customBackgroundColor;
  final Color? customBorderColor;
  final Widget? actions; // Widget adicional en la derecha

  const HeaderSimple({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.customBackgroundColor,
    this.customBorderColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.height < 680;
    final pad = isCompact ? 14.0 : 20.0;
    final iconPad = isCompact ? 8.0 : 12.0;
    final iconSize = isCompact ? 20.0 : 24.0;
    final titleSize = isCompact ? 18.0 : 24.0;
    final subtitleSize = isCompact ? 12.0 : 14.0;
    final spacing = isCompact ? 8.0 : 16.0;
    final subtitleTop = isCompact ? 2.0 : 4.0;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ] : [
            (customBackgroundColor ?? AppTheme.primaryColor).withOpacity(0.1),
            (customBackgroundColor ?? AppTheme.secondaryColor).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
        border: Border.all(
          color: isDark 
            ? const Color(0xFF404040)
            : (customBorderColor ?? AppTheme.primaryColor).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              color: customBackgroundColor ?? AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            ),
            child: Icon(
              leadingIcon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryColor,
                    ),
                    maxLines: 1,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: subtitleTop),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: isDark ? Colors.grey[300] : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          // Widget de acciones adicionales (ej: badge de sincronización)
          if (actions != null) ...[
            SizedBox(width: isCompact ? 8 : 12),
            actions!,
          ],
        ],
      ),
    );
  }
}
