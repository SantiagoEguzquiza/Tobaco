class CategoriaReorderDTO {
  final int id;
  final int sortOrder;

  CategoriaReorderDTO({
    required this.id,
    required this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sortOrder': sortOrder,
      };
}
