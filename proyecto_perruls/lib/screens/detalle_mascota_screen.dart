import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../models/sucursal.dart';

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