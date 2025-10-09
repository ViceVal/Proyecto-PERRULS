import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../models/sucursal.dart';
import '../screens/detalle_mascota_screen.dart';

class MascotaCard extends StatelessWidget {
  final Mascota mascota;
  final Sucursal sucursal;

  const MascotaCard({required this.mascota, required this.sucursal});

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(mascota.imagenUrl, width: 60, height: 60, fit: BoxFit.cover),
        ),
        title: Text(mascota.nombre),
        subtitle: Text("${mascota.especie} • ${mascota.raza} • ${sucursal.nombre}"),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: _estadoColor(mascota.estado), borderRadius: BorderRadius.circular(6)),
          child: Text(mascota.estado, style: const TextStyle(color: Colors.white)),
        ),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetalleMascotaScreen(mascota: mascota, sucursal: sucursal))),
      ),
    );
  }
}