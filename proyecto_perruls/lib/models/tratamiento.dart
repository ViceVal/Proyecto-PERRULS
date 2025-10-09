import 'medicamento.dart';

class Tratamiento {
  final String descripcion;
  final List<Medicamento> medicamentos;

  Tratamiento({required this.descripcion, required this.medicamentos});
}