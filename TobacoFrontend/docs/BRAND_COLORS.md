# Identidad Visual — Colores de Marca

> **Actualización oficial**: a partir de esta fecha, el **gradiente de marca** definido por el equipo de marketing pasa a ser el color principal de todos los detalles visuales de la aplicación (botones primarios, acentos, íconos destacados, barras activas, headers, badges de acción, etc.).

---

## 1. Gradiente oficial de marca

| Propiedad | Valor |
|---|---|
| **Dirección** | Izquierda → Derecha (`bg-gradient-to-r` en Tailwind, `Alignment.centerLeft → Alignment.centerRight` en Flutter) |
| **Color inicio (from)** | `#154D6C` — Azul profundo (marca) |
| **Color fin (to)** | `#1CB5AC` — Teal de acción |

### Vista previa

```
┌──────────────────────────────────────────────────┐
│  #154D6C ──────────────────────────▶ #1CB5AC     │
│  Azul profundo                      Teal acción  │
└──────────────────────────────────────────────────┘
```

---

## 2. Tokens sugeridos

### Flutter (Dart)

```dart
class BrandColors {
  static const Color brandDeepBlue = Color(0xFF154D6C);
  static const Color brandTeal     = Color(0xFF1CB5AC);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandDeepBlue, brandTeal],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
```

### Tailwind / CSS

```css
:root {
  --brand-deep-blue: #154D6C;
  --brand-teal: #1CB5AC;
}

.bg-brand-gradient {
  background-image: linear-gradient(to right, #154D6C, #1CB5AC);
}
```

```html
<button class="bg-gradient-to-r from-[#154D6C] to-[#1CB5AC]">
  Acción principal
</button>
```

---

## 3. Dónde se aplica

El gradiente debe usarse como **color protagónico** en todo elemento que represente una acción o un detalle destacado de la marca, incluyendo:

- Botones principales (CTA: "Crear nueva venta", "Guardar", "Confirmar", etc.).
- Headers con énfasis de marca.
- Íconos de marca y logotipos.
- Badges, chips o etiquetas que señalen un estado importante.
- Barras de progreso y separadores de sección destacados.
- Indicadores de navegación activos (por ej. ítems seleccionados en menús).
- Sombras y resplandores (glow) de elementos destacados — usar `#1CB5AC` al 25–35% de opacidad.

---

## 4. Usos secundarios (colores planos)

Cuando el gradiente no sea viable (íconos pequeños, bordes finos, texto), usar **uno de los dos colores sólidos**:

- **`#154D6C`** — preferido para texto destacado, íconos sobre fondo claro y bordes.
- **`#1CB5AC`** — preferido para acentos de acción, chips activos, estados positivos/interactivos.

---

## 5. Accesibilidad y contraste

- Sobre el gradiente, **el texto debe ser siempre blanco (`#FFFFFF`)** con peso `w600` o superior.
- Evitar colocar texto oscuro sobre el gradiente.
- Para estados `disabled`, reducir la opacidad del gradiente al 50% y mantener el texto en blanco al 70%.
- Verificar contraste mínimo WCAG AA (4.5:1) para textos de cuerpo sobre versiones planas de los colores.

---

## 6. Qué **no** hacer

- ❌ No invertir el sentido del gradiente (siempre **izquierda → derecha**).
- ❌ No reemplazar los hex por aproximaciones (usar exactamente `#154D6C` y `#1CB5AC`).
- ❌ No combinar el gradiente con fondos saturados que compitan visualmente.
- ❌ No agregar un tercer color al degradado.
- ❌ No usar el gradiente en bloques de texto extensos ni como fondo completo de pantalla.

---

## 7. Control de cambios

- **Vigencia**: desde la fecha de publicación de este documento.
- **Alcance**: toda la aplicación (móvil, tablet, web) y materiales derivados (splash screens, íconos de tienda, emails transaccionales).
- **Responsable de la identidad**: equipo de marketing.

Cualquier excepción debe ser aprobada por el equipo de marketing antes de pasar a producción.
