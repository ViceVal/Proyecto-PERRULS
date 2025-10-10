// lib/services/storage_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
// Importar los modelos desde su ubicación
import '../models/mascota.dart';
import '../models/vacuna.dart';
import '../models/tratamiento.dart';
import '../models/medicamento.dart';
import '../models/derivacion.dart';
import '../models/item_inventario.dart';
import '../models/usuario.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() {
    return _instance;
  }
  
  StorageService._internal();
  
  // Obtener el directorio de documentos de la aplicación
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Archivo para guardar mascotas
  Future<File> get _mascotasFile async {
    final path = await _localPath;
    return File('$path/mascotas.bin');
  }

  // Archivo para guardar inventario
  Future<File> get _inventarioFile async {
    final path = await _localPath;
    return File('$path/inventario.bin');
  }

  // Archivo para guardar usuarios
  Future<File> get _usuariosFile async {
    final path = await _localPath;
    return File('$path/usuarios.bin');
  }

  // ==================== MASCOTAS ==================== //
  
  Future<void> guardarMascotas(List<Mascota> mascotas) async {
    try {
      final file = await _mascotasFile;
      final mascotasJson = mascotas.map((m) => _mascotaToJson(m)).toList();
      final jsonString = json.encode(mascotasJson);
      await file.writeAsBytes(utf8.encode(jsonString));
      print('✅ ${mascotas.length} mascotas guardadas en archivo binario');
    } catch (e) {
      print('❌ Error al guardar mascotas: $e');
      rethrow;
    }
  }
  
  Future<List<Mascota>> cargarMascotas() async {
    try {
      final file = await _mascotasFile;
      if (!await file.exists()) {
        print('ℹ️ Archivo de mascotas no existe, retornando lista vacía');
        return [];
      }
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);
      final lista = json.decode(jsonString) as List;
      final mascotas = lista.map((m) => _mascotaFromJson(m as Map<String, dynamic>)).toList();
      print('✅ ${mascotas.length} mascotas cargadas desde archivo binario');
      return mascotas;
    } catch (e) {
      print('❌ Error al cargar mascotas: $e');
      return [];
    }
  }

  Future<void> eliminarArchivoMascotas() async {
    try {
      final file = await _mascotasFile;
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Archivo de mascotas eliminado');
      }
    } catch (e) {
      print('❌ Error al eliminar archivo de mascotas: $e');
    }
  }

  // ==================== INVENTARIO ==================== //
  
  Future<void> guardarInventario(List<ItemInventario> items) async {
    try {
      final file = await _inventarioFile;
      final itemsJson = items.map((i) => _itemToJson(i)).toList();
      final jsonString = json.encode(itemsJson);
      await file.writeAsBytes(utf8.encode(jsonString));
      print('✅ ${items.length} items de inventario guardados en archivo binario');
    } catch (e) {
      print('❌ Error al guardar inventario: $e');
      rethrow;
    }
  }
  
  Future<List<ItemInventario>> cargarInventario() async {
    try {
      final file = await _inventarioFile;
      if (!await file.exists()) {
        print('ℹ️ Archivo de inventario no existe, retornando lista vacía');
        return [];
      }
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);
      final lista = json.decode(jsonString) as List;
      final items = lista.map((i) => _itemFromJson(i as Map<String, dynamic>)).toList();
      print('✅ ${items.length} items de inventario cargados desde archivo binario');
      return items;
    } catch (e) {
      print('❌ Error al cargar inventario: $e');
      return [];
    }
  }

  // ==================== USUARIOS ==================== //
  
  Future<void> guardarUsuarios(List<Usuario> usuarios) async {
    try {
      final file = await _usuariosFile;
      final usuariosJson = usuarios.map((u) => _usuarioToJson(u)).toList();
      final jsonString = json.encode(usuariosJson);
      await file.writeAsBytes(utf8.encode(jsonString));
      print('✅ ${usuarios.length} usuarios guardados en archivo binario');
    } catch (e) {
      print('❌ Error al guardar usuarios: $e');
      rethrow;
    }
  }
  
  Future<List<Usuario>> cargarUsuarios() async {
    try {
      final file = await _usuariosFile;
      if (!await file.exists()) {
        print('ℹ️ Archivo de usuarios no existe, retornando lista vacía');
        return [];
      }
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);
      final lista = json.decode(jsonString) as List;
      final usuarios = lista.map((u) => _usuarioFromJson(u as Map<String, dynamic>)).toList();
      print('✅ ${usuarios.length} usuarios cargados desde archivo binario');
      return usuarios;
    } catch (e) {
      print('❌ Error al cargar usuarios: $e');
      return [];
    }
  }

  // ==================== UTILIDADES ==================== //

  Future<Map<String, dynamic>> obtenerInfoArchivos() async {
    final mascotasFile = await _mascotasFile;
    final inventarioFile = await _inventarioFile;
    final usuariosFile = await _usuariosFile;
    
    return {
      'mascotas': {
        'existe': await mascotasFile.exists(),
        'tamano': await mascotasFile.exists() ? await mascotasFile.length() : 0,
        'ruta': mascotasFile.path,
      },
      'inventario': {
        'existe': await inventarioFile.exists(),
        'tamano': await inventarioFile.exists() ? await inventarioFile.length() : 0,
        'ruta': inventarioFile.path,
      },
      'usuarios': {
        'existe': await usuariosFile.exists(),
        'tamano': await usuariosFile.exists() ? await usuariosFile.length() : 0,
        'ruta': usuariosFile.path,
      },
    };
  }

  Future<void> resetearTodosLosArchivos() async {
    await eliminarArchivoMascotas();
    final inventarioFile = await _inventarioFile;
    if (await inventarioFile.exists()) await inventarioFile.delete();
    final usuariosFile = await _usuariosFile;
    if (await usuariosFile.exists()) await usuariosFile.delete();
    print('🗑️ Todos los archivos han sido eliminados');
  }
  
  // ==================== CONVERSIÓN JSON ==================== //
  
  Map<String, dynamic> _mascotaToJson(Mascota mascota) {
    return {
      'chipId': mascota.chipId,
      'nombre': mascota.nombre,
      'imagenUrl': mascota.imagenUrl,
      'especie': mascota.especie,
      'raza': mascota.raza,
      'edad': mascota.edad,
      'peso': mascota.peso,
      'estado': mascota.estado,
      'idCampus': mascota.idCampus,
      'descripcion': mascota.descripcion,
      'enfermedades': mascota.enfermedades,
      'vacunas': mascota.vacunas.map((v) => _vacunaToJson(v)).toList(),
      'tratamientos': mascota.tratamientos.map((t) => _tratamientoToJson(t)).toList(),
      'derivaciones': mascota.derivaciones.map((d) => _derivacionToJson(d)).toList(),
    };
  }
  
  Mascota _mascotaFromJson(Map<String, dynamic> json) {
    return Mascota(
      chipId: json['chipId'] as String,
      nombre: json['nombre'] as String,
      imagenUrl: json['imagenUrl'] as String,
      especie: json['especie'] as String,
      raza: json['raza'] as String,
      edad: json['edad'] as String,
      peso: json['peso'] as String,
      estado: json['estado'] as String,
      idCampus: json['idCampus'] as String,
      descripcion: json['descripcion'] as String,
      enfermedades: List<String>.from(json['enfermedades'] as List),
      vacunas: (json['vacunas'] as List).map((v) => _vacunaFromJson(v as Map<String, dynamic>)).toList(),
      tratamientos: (json['tratamientos'] as List).map((t) => _tratamientoFromJson(t as Map<String, dynamic>)).toList(),
      derivaciones: (json['derivaciones'] as List).map((d) => _derivacionFromJson(d as Map<String, dynamic>)).toList(),
    );
  }
  
  Map<String, dynamic> _itemToJson(ItemInventario item) {
    return {
      'id': item.id,
      'nombre': item.nombre,
      'categoria': item.categoria,
      'cantidad': item.cantidad,
      'cantidadMinima': item.cantidadMinima,
      'unidad': item.unidad,
      'fechaVencimiento': item.fechaVencimiento?.millisecondsSinceEpoch,
      'ubicacion': item.ubicacion,
    };
  }
  
  ItemInventario _itemFromJson(Map<String, dynamic> json) {
    return ItemInventario(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String,
      cantidad: json['cantidad'] as int,
      cantidadMinima: json['cantidadMinima'] as int,
      unidad: json['unidad'] as String,
      fechaVencimiento: json['fechaVencimiento'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['fechaVencimiento'] as int)
          : null,
      ubicacion: json['ubicacion'] as String,
    );
  }
  
  Map<String, dynamic> _usuarioToJson(Usuario usuario) {
    return {
      'email': usuario.email,
      'password': usuario.password,
      'nombre': usuario.nombre,
    };
  }
  
  Usuario _usuarioFromJson(Map<String, dynamic> json) {
    return Usuario(
      email: json['email'] as String,
      password: json['password'] as String,
      nombre: json['nombre'] as String,
    );
  }
  
  Map<String, dynamic> _vacunaToJson(Vacuna vacuna) {
    return {
      'nombre': vacuna.nombre,
      'fechaAplicacion': vacuna.fechaAplicacion.millisecondsSinceEpoch,
      'proximaFecha': vacuna.proximaFecha.millisecondsSinceEpoch,
    };
  }
  
  Vacuna _vacunaFromJson(Map<String, dynamic> json) {
    return Vacuna(
      nombre: json['nombre'] as String,
      fechaAplicacion: DateTime.fromMillisecondsSinceEpoch(json['fechaAplicacion'] as int),
      proximaFecha: DateTime.fromMillisecondsSinceEpoch(json['proximaFecha'] as int),
    );
  }
  
  Map<String, dynamic> _tratamientoToJson(Tratamiento tratamiento) {
    return {
      'descripcion': tratamiento.descripcion,
      'medicamentos': tratamiento.medicamentos.map((m) => _medicamentoToJson(m)).toList(),
    };
  }
  
  Tratamiento _tratamientoFromJson(Map<String, dynamic> json) {
    return Tratamiento(
      descripcion: json['descripcion'] as String,
      medicamentos: (json['medicamentos'] as List).map((m) => _medicamentoFromJson(m as Map<String, dynamic>)).toList(),
    );
  }
  
  Map<String, dynamic> _medicamentoToJson(Medicamento medicamento) {
    return {
      'nombre': medicamento.nombre,
      'dosis': medicamento.dosis,
    };
  }
  
  Medicamento _medicamentoFromJson(Map<String, dynamic> json) {
    return Medicamento(
      nombre: json['nombre'] as String,
      dosis: json['dosis'] as String,
    );
  }
  
  Map<String, dynamic> _derivacionToJson(Derivacion derivacion) {
    return {
      'veterinaria': derivacion.veterinaria,
      'motivo': derivacion.motivo,
      'estado': derivacion.estado,
    };
  }
  
  Derivacion _derivacionFromJson(Map<String, dynamic> json) {
    return Derivacion(
      veterinaria: json['veterinaria'] as String,
      motivo: json['motivo'] as String,
      estado: json['estado'] as String,
    );
  }
}