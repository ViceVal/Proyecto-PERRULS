import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mascota.dart';
import '../data/datos_ejemplo.dart';
import '../services/mascota_service.dart';

class AgregarMascotaScreen extends StatefulWidget {
  @override
  _AgregarMascotaScreenState createState() => _AgregarMascotaScreenState();
}

class _AgregarMascotaScreenState extends State<AgregarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Controladores para los campos del formulario
  final TextEditingController _chipIdController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especieController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  
  String _imagenUrl = "https://picsum.photos/seed/mascota/200/200";
  String _estadoSeleccionado = "Disponible";
  String _sucursalSeleccionada = "C1";
  
  // Lista de URLs de imágenes por defecto
  final List<String> _imagenesPorDefecto = [
    "https://images.unsplash.com/photo-1552053831-71594a27632d?w=400",
    "https://images.unsplash.com/photo-1560809459-56a7f5f8fce1?w=400",
    "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=400",
    "https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400",
    "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400",
  ];

  Future<void> _seleccionarImagen() async {
    final option = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Seleccionar imagen"),
          content: Text("¿Cómo deseas agregar la imagen?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'galeria'),
              child: Text("Galería"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'camara'),
              child: Text("Cámara"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'defecto'),
              child: Text("Imagen por defecto"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancelar'),
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );

    if (option == 'galeria') {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (imagen != null) {
        setState(() {
          _imagenUrl = imagen.path;
        });
      }
    } else if (option == 'camara') {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (imagen != null) {
        setState(() {
          _imagenUrl = imagen.path;
        });
      }
    } else if (option == 'defecto') {
      _mostrarSelectorImagenes();
    }
  }

  void _mostrarSelectorImagenes() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Seleccionar imagen por defecto"),
          content: SingleChildScrollView(
            child: Column(
              children: _imagenesPorDefecto.map((url) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _imagenUrl = url;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Image.network(url, height: 80, fit: BoxFit.cover),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _guardarMascota() {
    if (_formKey.currentState!.validate()) {
      // Verificar si el chip ID ya existe
      final mascotaExistente = MascotaService().obtenerMascotaPorChip(_chipIdController.text);
      if (mascotaExistente != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ya existe una mascota con este Chip ID")),
        );
        return;
      }

      // Crear nueva mascota
      final nuevaMascota = Mascota(
        chipId: _chipIdController.text,
        nombre: _nombreController.text,
        imagenUrl: _imagenUrl,
        especie: _especieController.text,
        raza: _razaController.text,
        edad: _edadController.text,
        peso: _pesoController.text,
        estado: _estadoSeleccionado,
        idCampus: _sucursalSeleccionada,
        descripcion: _descripcionController.text,
      );

      // Agregar a la lista
      MascotaService().agregarMascota(nuevaMascota);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mascota agregada exitosamente")),
      );

      // Regresar a la pantalla anterior
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar Nueva Mascota"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selector de imagen
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal, width: 2),
                      ),
                      child: _imagenUrl.startsWith('http') || _imagenUrl.startsWith('https')
                          ? Image.network(_imagenUrl, fit: BoxFit.cover)
                          : Image.asset(_imagenUrl, fit: BoxFit.cover),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Toca para cambiar imagen",
                      style: TextStyle(color: Colors.teal, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Chip ID
              TextFormField(
                controller: _chipIdController,
                decoration: InputDecoration(
                  labelText: "Chip ID *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa el Chip ID";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: "Nombre *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa el nombre";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Especie y Raza en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _especieController,
                      decoration: InputDecoration(
                        labelText: "Especie *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Requerido";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _razaController,
                      decoration: InputDecoration(
                        labelText: "Raza *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Requerido";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Edad y Peso en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _edadController,
                      decoration: InputDecoration(
                        labelText: "Edad *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Requerido";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pesoController,
                      decoration: InputDecoration(
                        labelText: "Peso *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Requerido";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Estado
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: InputDecoration(
                  labelText: "Estado *",
                  border: OutlineInputBorder(),
                ),
                items: ["Disponible", "Adoptado", "En tratamiento", "Reservado"]
                    .map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado = value!;
                  });
                },
              ),
              SizedBox(height: 16),

              // Sucursal
              DropdownButtonFormField<String>(
                value: _sucursalSeleccionada,
                decoration: InputDecoration(
                  labelText: "Sucursal *",
                  border: OutlineInputBorder(),
                ),
                items: DatosEjemplo.sucursales
                    .map((sucursal) => DropdownMenuItem(
                          value: sucursal.idCampus,
                          child: Text(sucursal.nombre),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _sucursalSeleccionada = value!;
                  });
                },
              ),
              SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Descripción y Observaciones",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancelar"),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardarMascota,
                      child: Text("Guardar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}