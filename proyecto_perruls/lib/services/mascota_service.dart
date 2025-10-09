import '../models/mascota.dart';
import '../data/datos_ejemplo.dart';

class MascotaService {
  static final MascotaService _instance = MascotaService._internal();
  
  factory MascotaService() {
    return _instance;
  }
  
  MascotaService._internal();
  
  List<Mascota> obtenerMascotas() {
    return DatosEjemplo.mascotas;
  }
  
  void agregarMascota(Mascota mascota) {
    DatosEjemplo.mascotas.add(mascota);
  }
  
  Mascota? obtenerMascotaPorChip(String chipId) {
    try {
      return DatosEjemplo.mascotas.firstWhere((m) => m.chipId == chipId);
    } catch (e) {
      return null;
    }
  }
}