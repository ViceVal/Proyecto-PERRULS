import '../models/vacuna.dart';
import '../models/tratamiento.dart';
import '../models/derivacion.dart';
import '../models/sucursal.dart';
import '../models/medicamento.dart';


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

  Mascota copyWith({
    String? chipId,
    String? nombre,
    String? imagenUrl,
    String? especie,
    String? raza,
    String? edad,
    String? peso,
    String? estado,
    String? idCampus,
    String? descripcion,
    List<String>? enfermedades,
    List<Vacuna>? vacunas,
    List<Tratamiento>? tratamientos,
    List<Derivacion>? derivaciones,
  }) {
    return Mascota(
      chipId: chipId ?? this.chipId,
      nombre: nombre ?? this.nombre,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      especie: especie ?? this.especie,
      raza: raza ?? this.raza,
      edad: edad ?? this.edad,
      peso: peso ?? this.peso,
      estado: estado ?? this.estado,
      idCampus: idCampus ?? this.idCampus,
      descripcion: descripcion ?? this.descripcion,
      enfermedades: enfermedades ?? this.enfermedades,
      vacunas: vacunas ?? this.vacunas,
      tratamientos: tratamientos ?? this.tratamientos,
      derivaciones: derivaciones ?? this.derivaciones,
    );
  }
}

// ------------------ DATOS DE EJEMPLO ------------------ //

