import 'vacuna.dart';
import 'tratamiento.dart';
import 'derivacion.dart';

class Mascota {
  final String chipId;
  final String nombre;
  final String imagenUrl;
  final String especie;
  final String raza;
  final String edad;
  final String peso;
  final String estado;
  final String idCampus;
  final String descripcion;
  final List<String> enfermedades;
  final List<Vacuna> vacunas;
  final List<Tratamiento> tratamientos;
  final List<Derivacion> derivaciones;

  Mascota({
    required this.chipId,
    required this.nombre,
    required this.imagenUrl,
    required this.especie,
    required this.raza,
    required this.edad,
    required this.peso,
    required this.estado,
    required this.idCampus,
    required this.descripcion,
    this.enfermedades = const [],
    this.vacunas = const [],
    this.tratamientos = const [],
    this.derivaciones = const [],
  });
}