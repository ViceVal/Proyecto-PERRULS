import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../models/sucursal.dart';
import '../data/datos_ejemplo.dart';
import 'detalle_mascota_screen.dart';

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});

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
          }),
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