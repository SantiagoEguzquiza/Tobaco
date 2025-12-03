/// Interfaz base para todos los servicios de caché
/// Define los métodos comunes que deben implementar todos los servicios
abstract class ICacheService<T> {
  /// Obtiene todos los elementos del caché
  Future<List<T>> getAll();

  /// Guarda un elemento en el caché
  Future<void> save(T item);

  /// Guarda múltiples elementos en el caché
  Future<void> saveAll(List<T> items);

  /// Obtiene un elemento por su ID
  Future<T?> getById(dynamic id);

  /// Elimina un elemento del caché por su ID
  Future<bool> deleteById(dynamic id);

  /// Limpia todo el caché de esta entidad
  Future<void> clear();

  /// Verifica si hay datos en el caché
  Future<bool> hasData();

  /// Obtiene el número de elementos en el caché
  Future<int> count();

  /// Marca que no hay datos disponibles (para evitar cargas infinitas en offline)
  Future<void> markAsEmpty();

  /// Verifica si está marcado como vacío
  Future<bool> isEmptyMarked();

  /// Limpia el marcador de vacío
  Future<void> clearEmptyMark();
}
