import 'package:flutter/material.dart';

void main() {
  runApp(PerrulsApp());
}

class PerrulsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perruls - Adopción',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: MascotasScreen(),
    );
  }
}

// ------------------ MODELOS ------------------ //

class Sucursal {
  final String idCampus;
  final String nombre;
  Sucursal({required this.idCampus, required this.nombre});
}

class Vacuna {
  final String nombre;
  final DateTime fechaAplicacion;
  final DateTime proximaFecha;

  Vacuna({
    required this.nombre,
    required this.fechaAplicacion,
    required this.proximaFecha,
  });
}

class Medicamento {
  final String nombre;
  final String dosis;
  Medicamento({required this.nombre, required this.dosis});
}

class Tratamiento {
  final String descripcion;
  final List<Medicamento> medicamentos;

  Tratamiento({required this.descripcion, required this.medicamentos});
}

class Derivacion {
  final String veterinaria;
  final String motivo;
  final String estado;
  Derivacion({required this.veterinaria, required this.motivo, required this.estado});
}

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

// ------------------ DATOS DE EJEMPLO ------------------ //

class DatosEjemplo {
  static final List<Sucursal> sucursales = [
    Sucursal(idCampus: "C1", nombre: "Campus Isabel Bongard"),
    Sucursal(idCampus: "C2", nombre: "Campus Santiago"),
  ];

  static final List<Mascota> mascotas = [
    Mascota(
      chipId: "001",
      nombre: "Charlie",
      imagenUrl: "https://static.wikia.nocookie.net/reinoanimalia/images/e/ed/Golden_retriver.png/revision/latest/thumbnail/width/360/height/360?cb=20130303080930&path-prefix=es",
      especie: ".",
      raza: "Labrador",
      edad: "5 años",
      peso: "25 kg",
      estado: "Disponible",
      idCampus: "C1",
      descripcion:
          "Observaciones: Necesita atención por artrosis y otitis crónica, requiere tratamientos regulares y revisiones médicas periódicas.",
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
      especie: ".",
      raza: "Mestizo",
      edad: "2 años",
      peso: "4 kg",
      estado: "Adoptado",
      idCampus: "C1",
      descripcion:
          "Pitufina es tranquila, disfruta del contacto humano y sigue las rutinas de vacunación establecidas por el personal Perruls.",
      vacunas: [
        Vacuna(
            nombre: "Triple Felina",
            fechaAplicacion: DateTime.parse("2023-03-10"),
            proximaFecha: DateTime.parse("2024-03-10")),
      ],
    ),
  ];
}

// ------------------ PANTALLA MASCOTAS ------------------ //

class MascotasScreen extends StatefulWidget {
  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Mascota> _mascotas = DatosEjemplo.mascotas;
  late List<Mascota> _mascotasFiltradas;

  @override
  void initState() {
    super.initState();
    _mascotasFiltradas = _mascotas;
  }

  void _filtrarMascotas(String query) {
    if (query.isEmpty) {
      setState(() => _mascotasFiltradas = _mascotas);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _mascotasFiltradas = _mascotas
          .where((m) =>
              m.nombre.toLowerCase().contains(q) ||
              m.raza.toLowerCase().contains(q) ||
              m.especie.toLowerCase().contains(q))
          .toList();
    });
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'adoptado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mascotas Perruls")),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              onChanged: _filtrarMascotas,
              decoration: InputDecoration(
                hintText: "Buscar mascota, raza o especie...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
          ..._mascotasFiltradas.map((m) {
            final sucursal = DatosEjemplo.sucursales.firstWhere(
                (s) => s.idCampus == m.idCampus,
                orElse: () => Sucursal(idCampus: "", nombre: "Desconocida"));
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(m.imagenUrl, width: 60, height: 60, fit: BoxFit.cover),
                ),
                title: Text(m.nombre),
                subtitle: Text("${m.especie} • ${m.raza} • ${sucursal.nombre}"),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: _estadoColor(m.estado), borderRadius: BorderRadius.circular(6)),
                  child: Text(m.estado, style: const TextStyle(color: Colors.white)),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetalleMascotaScreen(mascota: m, sucursal: sucursal))),
              ),
            );
          }).toList(),
          if (_mascotasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text("No se encontraron mascotas 😿")),
            ),
        ],
      ),
    );
  }
}

// ------------------ DETALLE ------------------ //

class DetalleMascotaScreen extends StatelessWidget {
  final Mascota mascota;
  final Sucursal sucursal;

  const DetalleMascotaScreen({required this.mascota, required this.sucursal});

  String _formatFecha(DateTime fecha) =>
      "${fecha.day}/${fecha.month}/${fecha.year}";

  Card _buildSectionCard(String title, List<Widget> content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mascota.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(mascota.imagenUrl, height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard("Información general", [
              Text("Chip ID: ${mascota.chipId}"),
              Text("Nombre: ${mascota.nombre}"),
              Text("Especie: ${mascota.especie}"),
              Text("Raza: ${mascota.raza}"),
              Text("Edad: ${mascota.edad}"),
              Text("Peso: ${mascota.peso}"),
              Text("Estado: ${mascota.estado}"),
              Text("Sucursal: ${sucursal.nombre}"),
              Text("Descripción: ${mascota.descripcion}"),
            ]),
            if (mascota.enfermedades.isNotEmpty)
              _buildSectionCard("Enfermedades / Alergias",
                  mascota.enfermedades.map((e) => Text("• $e")).toList()),
            if (mascota.vacunas.isNotEmpty)
              _buildSectionCard(
                  "Vacunas",
                  mascota.vacunas
                      .map((v) => Text(
                          "${v.nombre}: ${_formatFecha(v.fechaAplicacion)} → Próxima: ${_formatFecha(v.proximaFecha)}"))
                      .toList()),
            if (mascota.tratamientos.isNotEmpty)
              _buildSectionCard(
                  "Tratamientos",
                  mascota.tratamientos.map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.descripcion),
                            ...t.medicamentos
                                .map((m) => Text("• ${m.nombre}: ${m.dosis}"))
                                .toList()
                          ]),
                    );
                  }).toList()),
            if (mascota.derivaciones.isNotEmpty)
              _buildSectionCard(
                  "Derivaciones",
                  mascota.derivaciones
                      .map((d) => Text(
                          "${d.motivo} - Veterinaria: ${d.veterinaria} - Estado: ${d.estado}"))
                      .toList()),
          ],
        ),
      ),
    );
  }
}
