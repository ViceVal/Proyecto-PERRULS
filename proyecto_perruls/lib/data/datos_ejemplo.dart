import '../models/sucursal.dart';
import '../models/mascota.dart';
import '../models/vacuna.dart';
import '../models/medicamento.dart';
import '../models/tratamiento.dart';
import '../models/derivacion.dart';

class DatosEjemplo {
  static List<Sucursal> sucursales = [
    Sucursal(idCampus: "C1", nombre: "Campus Isabel Bongard"),
    Sucursal(idCampus: "C2", nombre: "Campus Santiago"),
  ];

  static List<Mascota> mascotas = [
    Mascota(
      chipId: "001",
      nombre: "Charlie",
      imagenUrl: "https://static.wikia.nocookie.net/reinoanimalia/images/e/ed/Golden_retriver.png/revision/latest/thumbnail/width/360/height/360?cb=20130303080930&path-prefix=es",
      especie: "Perro",
      raza: "Labrador",
      edad: "5 años",
      peso: "25 kg",
      estado: "Disponible",
      idCampus: "C1",
      descripcion: "Observaciones: Necesita atención por artrosis y otitis crónica, requiere tratamientos regulares y revisiones médicas periódicas.",
      enfermedades: ["Artrosis", "Otitis crónica"],
      vacunas: [
        Vacuna(
            nombre: "Rabia",
            fechaAplicacion: DateTime.parse("2023-01-15"),
            proximaFecha: DateTime.parse("2024-01-15")),
      ],
      tratamientos: [
        Tratamiento(
            descripcion: "Tratamiento para artrosis",
            medicamentos: [
              Medicamento(nombre: "ArtriTabs", dosis: "1 tableta cada 12 horas")
            ])
      ],
      derivaciones: [
        Derivacion(
            veterinaria: "Clínica Veterinaria Central",
            motivo: "Consulta por artrosis avanzada",
            estado: "Completada")
      ],
    ),
    Mascota(
      chipId: "002",
      nombre: "Pitufina",
      imagenUrl: "https://picsum.photos/seed/2/200/200",
      especie: "Gato",
      raza: "Mestizo",
      edad: "2 años",
      peso: "4 kg",
      estado: "Adoptado",
      idCampus: "C1",
      descripcion: "Pitufina es tranquila, disfruta del contacto humano y sigue las rutinas de vacunación establecidas por el personal Perruls.",
      vacunas: [
        Vacuna(
            nombre: "Triple Felina",
            fechaAplicacion: DateTime.parse("2023-03-10"),
            proximaFecha: DateTime.parse("2024-03-10")),
      ],
    ),
  ];
}