class ItemInventario {
  final String id;
  final String nombre;
  final String categoria;
  final int cantidad;
  final int cantidadMinima;
  final String unidad;
  final DateTime? fechaVencimiento;
  final String ubicacion;

  ItemInventario({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.cantidadMinima,
    required this.unidad,
    this.fechaVencimiento,
    required this.ubicacion,
  });
}