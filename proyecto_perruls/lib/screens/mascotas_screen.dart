import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../models/sucursal.dart';
import '../data/datos_ejemplo.dart';
import '../widgets/mascota_card.dart';
import 'agregar_mascota_screen.dart';

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

  void _navegarAAgregarMascota() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgregarMascotaScreen()),
    ).then((_) {
      // Actualizar la lista cuando regrese de agregar mascota
      setState(() {
        _mascotasFiltradas = _mascotas;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mascotas Perruls"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navegarAAgregarMascota,
            tooltip: "Agregar mascota",
          ),
        ],
      ),
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
            return MascotaCard(mascota: m, sucursal: sucursal);
          }).toList(),
          if (_mascotasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text("No se encontraron mascotas 😿")),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAAgregarMascota,
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: "Agregar nueva mascota",
      ),
    );
  }
}