class Category {
  const Category({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono = 'category',
    this.color = '#9E9E9E',
    this.activa = true,
    this.orden = 0,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String icono;
  final String color;
  final bool activa;
  final int orden;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String? ?? 'category',
      color: json['color'] as String? ?? '#9E9E9E',
      activa: json['activa'] as bool? ?? true,
      orden: json['orden'] as int? ?? 0,
    );
  }
}
