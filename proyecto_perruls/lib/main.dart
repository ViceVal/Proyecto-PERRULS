import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'services/storage_service.dart';
import 'models/usuario.dart';
import 'models/item_inventario.dart';
import 'models/mascota.dart';
import 'models/sucursal.dart';
import 'models/derivacion.dart';
import 'models/tratamiento.dart';
import 'models/vacuna.dart';
import 'models/medicamento.dart';
import 'data/datos_ejemplo.dart';


void main() {
  runApp(PerrulsApp());
}

class PerrulsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perruls',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: AuthWrapper(),
    );
  }
}

// ------------------ SERVICIO DE AUTENTICACIÓN ------------------ //

class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  List<Usuario> _usuarios = [];
  Usuario? _usuarioActual;
  bool _initialized = false;
  
  Usuario? get usuarioActual => _usuarioActual;
  bool get estaAutenticado => _usuarioActual != null;
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _usuarios = await StorageService().cargarUsuarios();
      if (_usuarios.isEmpty) {
        _usuarios = [
          Usuario(email: 'admin@perruls.com', password: 'admin123', nombre: 'Administrador'),
          Usuario(email: 'usuario@ejemplo.com', password: 'usuario123', nombre: 'Usuario Ejemplo'),
        ];
        await StorageService().guardarUsuarios(_usuarios);
      }
      _initialized = true;
    }
  }
  
  Future<bool> login(String email, String password) async {
    await _ensureInitialized();
    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email == email && u.password == password,
      );
      _usuarioActual = usuario;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> registrar(String email, String password, String nombre) async {
    await _ensureInitialized();
    if (_usuarios.any((u) => u.email == email)) {
      return false;
    }
    
    final nuevoUsuario = Usuario(
      email: email,
      password: password,
      nombre: nombre,
    );
    
    _usuarios.add(nuevoUsuario);
    await StorageService().guardarUsuarios(_usuarios);
    _usuarioActual = nuevoUsuario;
    return true;
  }
  
  void logout() {
    _usuarioActual = null;
  }
}



// ------------------ SERVICIO INVENTARIO ------------------ //

class InventarioService {
  static final InventarioService _instance = InventarioService._internal();
  
  factory InventarioService() {
    return _instance;
  }
  
  InventarioService._internal();
  
  List<ItemInventario> _items = [];
  bool _initialized = false;
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _items = await StorageService().cargarInventario();
      if (_items.isEmpty) {
        _items = [
          ItemInventario(
            id: "1",
            nombre: "Comida para perros adulto",
            categoria: "Alimentos",
            cantidad: 50,
            cantidadMinima: 10,
            unidad: "kg",
            ubicacion: "Almacén A",
          ),
          ItemInventario(
            id: "2",
            nombre: "Vacuna Rabia",
            categoria: "Medicamentos",
            cantidad: 25,
            cantidadMinima: 5,
            unidad: "dosis",
            fechaVencimiento: DateTime(2024, 12, 31),
            ubicacion: "Refrigerador 1",
          ),
          ItemInventario(
            id: "3",
            nombre: "Correas medianas",
            categoria: "Accesorios",
            cantidad: 15,
            cantidadMinima: 3,
            unidad: "unidades",
            ubicacion: "Estante 2",
          ),
        ];
        await StorageService().guardarInventario(_items);
      }
      _initialized = true;
    }
  }
  
  Future<List<ItemInventario>> obtenerItems() async {
    await _ensureInitialized();
    return _items;
  }
  
  Future<void> agregarItem(ItemInventario item) async {
    await _ensureInitialized();
    _items.add(item);
    await StorageService().guardarInventario(_items);
  }
  
  Future<void> actualizarItem(String id, ItemInventario itemActualizado) async {
    await _ensureInitialized();
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = itemActualizado;
      await StorageService().guardarInventario(_items);
    }
  }
  
  Future<void> eliminarItem(String id) async {
    await _ensureInitialized();
    _items.removeWhere((item) => item.id == id);
    await StorageService().guardarInventario(_items);
  }
  
  Future<List<ItemInventario>> obtenerItemsBajosStock() async {
    await _ensureInitialized();
    return _items.where((item) => item.cantidad <= item.cantidadMinima).toList();
  }
}

// ------------------ WRAPPER DE AUTENTICACIÓN ------------------ //

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    // Forzar la inicialización de los servicios
    await MascotaService().obtenerMascotas(); // Esto activa _cargarMascotas()
    await InventarioService().obtenerItems(); // Esto activa _cargarItems()
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando datos...'),
            ],
          ),
        ),
      );
    }
    
    return StreamBuilder<bool>(
      stream: Stream.value(AuthService().estaAutenticado),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data! ? MascotasScreen() : LoginScreen();
        }
        return LoginScreen();
      },
    );
  }
}

// ------------------ PANTALLA DE LOGIN ------------------ //

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simular delay de red
      await Future.delayed(Duration(milliseconds: 1500));
      
      final bool success = await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MascotasScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email o contraseña incorrectos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegarARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo y título
                SizedBox(height: 40),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Perruls',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal[600],
                  ),
                ),
                SizedBox(height: 40),

                // Formulario de login
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[700],
                            ),
                          ),
                          SizedBox(height: 24),

                          // Campo email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Ingresa un email válido';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Campo contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 8),

                          // Recordar contraseña
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implementar recuperación de contraseña
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Funcionalidad en desarrollo'),
                                  ),
                                );
                              },
                              child: Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Botón de login
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _isLoading
                                ? ElevatedButton(
                                    onPressed: null,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _iniciarSesion,
                                    child: Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('O'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Botón de registro
                          OutlinedButton(
                            onPressed: _navegarARegistro,
                            child: Text('Crear Cuenta Nueva'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: BorderSide(color: Colors.teal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Información adicional
                SizedBox(height: 40),
                Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contacta a soporte: soporte@perruls.com'),
                      ),
                    );
                  },
                  child: Text(
                    'Contactar Soporte',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ PANTALLA DE REGISTRO ------------------ //

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simular delay de red
      await Future.delayed(Duration(milliseconds: 1500));
      
      final bool success = await AuthService().registrar(
        _emailController.text.trim(),
        _passwordController.text,
        _nombreController.text.trim(),
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Cuenta creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MascotasScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El email ya está registrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegarALogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text('Crear Cuenta'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _navegarALogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                // Ilustración
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Únete a Perruls',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 40),

                // Formulario de registro
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Campo nombre
                          TextFormField(
                            controller: _nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre Completo',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              if (value.length < 2) {
                                return 'El nombre debe tener al menos 2 caracteres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Campo email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Ingresa un email válido';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Campo contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Campo confirmar contraseña
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor confirma tu contraseña';
                              }
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Botón de registro
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _isLoading
                                ? ElevatedButton(
                                    onPressed: null,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _registrar,
                                    child: Text(
                                      'Crear Cuenta',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(height: 16),

                          // Enlace a login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿Ya tienes una cuenta?'),
                              TextButton(
                                onPressed: _navegarALogin,
                                child: Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Términos y condiciones
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Al crear una cuenta, aceptas nuestros Términos de Servicio y Política de Privacidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// ------------------ SERVICIO MASCOTAS ------------------ //

class MascotaService {
  static final MascotaService _instance = MascotaService._internal();
  
  factory MascotaService() {
    return _instance;
  }
  
  MascotaService._internal();
  
  List<Mascota> _mascotas = [];
  bool _initialized = false;
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _mascotas = await StorageService().cargarMascotas();
      if (_mascotas.isEmpty) {
        _mascotas = DatosEjemplo.mascotas;
        await StorageService().guardarMascotas(_mascotas);
      }
      _initialized = true;
    }
  }
  
  Future<List<Mascota>> obtenerMascotas() async {
    await _ensureInitialized();
    return _mascotas;
  }
  
  Future<void> agregarMascota(Mascota mascota) async {
    await _ensureInitialized();
    _mascotas.add(mascota);
    await StorageService().guardarMascotas(_mascotas);
  }
  
  Future<void> actualizarMascota(String chipId, Mascota mascotaActualizada) async {
    await _ensureInitialized();
    final index = _mascotas.indexWhere((m) => m.chipId == chipId);
    if (index != -1) {
      _mascotas[index] = mascotaActualizada;
      await StorageService().guardarMascotas(_mascotas);
    }
  }
  
  Future<void> eliminarMascota(String chipId) async {
    await _ensureInitialized();
    _mascotas.removeWhere((m) => m.chipId == chipId);
    await StorageService().guardarMascotas(_mascotas);
  }
  
  Future<Mascota?> obtenerMascotaPorChip(String chipId) async {
    await _ensureInitialized();
    try {
      return _mascotas.firstWhere((m) => m.chipId == chipId);
    } catch (e) {
      return null;
    }
  }
}

// ------------------ PANTALLA MASCOTAS ------------------ //

class MascotasScreen extends StatefulWidget {
  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Mascota> _mascotas = [];
  late List<Mascota> _mascotasFiltradas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  void _cargarMascotas() async {
    final mascotas = await MascotaService().obtenerMascotas();
    setState(() {
      _mascotas = mascotas;
      _mascotasFiltradas = mascotas;
      _isLoading = false;
    });
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
      _cargarMascotas(); // Recargar la lista después de agregar
    });
  }

  void _editarMascota(Mascota mascota) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarMascotaScreen(mascota: mascota)),
    ).then((resultado) {
      if (resultado == true) {
        _cargarMascotas();
      }
      
    });
  }

  void _mostrarOpcionesMascota(Mascota mascota) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Editar mascota'),
                onTap: () {
                  Navigator.pop(context);
                  _editarMascota(mascota);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar mascota'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoEliminar(mascota);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoEliminar(Mascota mascota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar mascota'),
        content: Text('¿Estás seguro de que quieres eliminar a ${mascota.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await MascotaService().eliminarMascota(mascota.chipId);
              _cargarMascotas(); // Recargar la lista después de eliminar
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${mascota.nombre} ha sido eliminado')),
              );
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navegarAInventario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InventarioScreen()),
    );
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              AuthService().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService().usuarioActual;
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando mascotas...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mascotas Perruls"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navegarAAgregarMascota,
            tooltip: "Agregar mascota",
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Inventario'),
                  ],
                ),
                onTap: _navegarAInventario,
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
                onTap: _cerrarSesion,
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header con información del usuario (SIN email)
          if (usuario != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.teal[50],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      usuario.nombre[0].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${usuario.nombre}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Barra de búsqueda
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

          // Lista de mascotas (SIN estado)
          ..._mascotasFiltradas.map((m) {
            final sucursal = DatosEjemplo.sucursales.firstWhere(
                (s) => s.idCampus == m.idCampus,
                orElse: () => Sucursal(idCampus: "", nombre: "Desconocida"));
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    m.imagenUrl, 
                    width: 60, 
                    height: 60, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.pets, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                title: Text(
                  m.nombre,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${m.especie} • ${m.raza}"),
                    Text(
                      sucursal.nombre,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetalleMascotaScreen(mascota: m, sucursal: sucursal))),
                onLongPress: () => _mostrarOpcionesMascota(m),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAAgregarMascota,
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: "Agregar nueva mascota",
      ),
    );
  }
}

// ------------------ PANTALLA AGREGAR MASCOTA ------------------ //

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
  
  // Controladores para información médica
  final TextEditingController _enfermedadController = TextEditingController();
  final TextEditingController _vacunaNombreController = TextEditingController();
  final TextEditingController _tratamientoDescController = TextEditingController();
  final TextEditingController _medicamentoNombreController = TextEditingController();
  final TextEditingController _medicamentoDosisController = TextEditingController();
  final TextEditingController _derivacionVeterinariaController = TextEditingController();
  final TextEditingController _derivacionMotivoController = TextEditingController();
  
  String _imagenUrl = "https://images.unsplash.com/photo-1552053831-71594a27632d?w=400";
  String _sucursalSeleccionada = "C1";
  XFile? _imagenSeleccionada;
  
  // Listas para información médica
  List<String> _enfermedades = [];
  List<Vacuna> _vacunas = [];
  List<Tratamiento> _tratamientos = [];
  List<Derivacion> _derivaciones = [];
  
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
              child: Text("📁 Galería"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'camara'),
              child: Text("📷 Cámara"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'defecto'),
              child: Text("🖼️ Imagen por defecto"),
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = imagen;
          _imagenUrl = imagen.path;
        });
      }
    } else if (option == 'camara') {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = imagen;
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imagenesPorDefecto.map((url) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _imagenUrl = url;
                      _imagenSeleccionada = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _imagenUrl == url ? Colors.teal : Colors.grey,
                        width: _imagenUrl == url ? 3 : 1,
                      ),
                    ),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  // Métodos para agregar información médica
  void _agregarEnfermedad() {
    if (_enfermedadController.text.isNotEmpty) {
      setState(() {
        _enfermedades.add(_enfermedadController.text);
        _enfermedadController.clear();
      });
    }
  }

  void _eliminarEnfermedad(int index) {
    setState(() {
      _enfermedades.removeAt(index);
    });
  }

  void _agregarVacuna() {
    if (_vacunaNombreController.text.isNotEmpty) {
      setState(() {
        _vacunas.add(Vacuna(
          nombre: _vacunaNombreController.text,
          fechaAplicacion: DateTime.now(),
          proximaFecha: DateTime.now().add(Duration(days: 365)),
        ));
        _vacunaNombreController.clear();
      });
    }
  }

  void _eliminarVacuna(int index) {
    setState(() {
      _vacunas.removeAt(index);
    });
  }

  void _agregarMedicamento() {
    if (_medicamentoNombreController.text.isNotEmpty && _medicamentoDosisController.text.isNotEmpty) {
      setState(() {
        if (_tratamientos.isEmpty) {
          _tratamientos.add(Tratamiento(
            descripcion: _tratamientoDescController.text.isNotEmpty 
                ? _tratamientoDescController.text 
                : "Tratamiento general",
            medicamentos: [
              Medicamento(
                nombre: _medicamentoNombreController.text,
                dosis: _medicamentoDosisController.text,
              )
            ],
          ));
        } else {
          _tratamientos.last.medicamentos.add(Medicamento(
            nombre: _medicamentoNombreController.text,
            dosis: _medicamentoDosisController.text,
          ));
        }
        _medicamentoNombreController.clear();
        _medicamentoDosisController.clear();
      });
    }
  }

  void _agregarTratamiento() {
    if (_tratamientoDescController.text.isNotEmpty) {
      setState(() {
        _tratamientos.add(Tratamiento(
          descripcion: _tratamientoDescController.text,
          medicamentos: [],
        ));
        _tratamientoDescController.clear();
      });
    }
  }

  void _eliminarTratamiento(int index) {
    setState(() {
      _tratamientos.removeAt(index);
    });
  }

  void _agregarDerivacion() {
    if (_derivacionVeterinariaController.text.isNotEmpty && _derivacionMotivoController.text.isNotEmpty) {
      setState(() {
        _derivaciones.add(Derivacion(
          veterinaria: _derivacionVeterinariaController.text,
          motivo: _derivacionMotivoController.text,
          estado: "Pendiente",
        ));
        _derivacionVeterinariaController.clear();
        _derivacionMotivoController.clear();
      });
    }
  }

  void _eliminarDerivacion(int index) {
    setState(() {
      _derivaciones.removeAt(index);
    });
  }

  void _guardarMascota() {
    if (_formKey.currentState!.validate()) {

      // Determinar la URL final de la imagen
      String imagenFinal = _imagenUrl;
      if (_imagenSeleccionada != null) {
        imagenFinal = _imagenSeleccionada!.path;
      }

      // Crear nueva mascota
      final nuevaMascota = Mascota(
        chipId: _chipIdController.text,
        nombre: _nombreController.text,
        imagenUrl: imagenFinal,
        especie: _especieController.text,
        raza: _razaController.text,
        edad: _edadController.text,
        peso: _pesoController.text,
        estado: "Disponible", // Estado por defecto
        idCampus: _sucursalSeleccionada,
        descripcion: _descripcionController.text,
        enfermedades: [],
        vacunas: [],
        tratamientos: [],
        derivaciones: [],
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

  Widget _buildImagePreview() {
    if (_imagenSeleccionada != null) {
      return Image.file(
        File(_imagenSeleccionada!.path),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (_imagenUrl.startsWith('http')) {
      return Image.network(
        _imagenUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[300],
            child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
          );
        },
      );
    } else {
      return Image.asset(
        _imagenUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[300],
            child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
          );
        },
      );
    }
  }

  Widget _buildSeccionMedica(String titulo, Widget contenido) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 8),
            contenido,
          ],
        ),
      ),
    );
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImagePreview(),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Toca para cambiar imagen",
                      style: TextStyle(color: Colors.teal, fontSize: 12),
                    ),
                    if (_imagenSeleccionada != null)
                      Text(
                        "Imagen local seleccionada",
                        style: TextStyle(color: Colors.green, fontSize: 10),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Información básica
              Text(
                "Información Básica",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              SizedBox(height: 16),

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

              // Sección de Enfermedades y Alergias
              _buildSeccionMedica(
                "Enfermedades y Alergias",
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _enfermedadController,
                            decoration: InputDecoration(
                              labelText: "Enfermedad o Alergia",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _agregarEnfermedad,
                          child: Icon(Icons.add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ..._enfermedades.asMap().entries.map((entry) {
                      return ListTile(
                        leading: Icon(Icons.medical_services, color: Colors.red),
                        title: Text(entry.value),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarEnfermedad(entry.key),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Sección de Vacunas
              _buildSeccionMedica(
                "Vacunas",
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vacunaNombreController,
                            decoration: InputDecoration(
                              labelText: "Nombre de Vacuna",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _agregarVacuna,
                          child: Icon(Icons.add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ..._vacunas.asMap().entries.map((entry) {
                      return ListTile(
                        leading: Icon(Icons.vaccines, color: Colors.green),
                        title: Text(entry.value.nombre),
                        subtitle: Text("Aplicada: ${entry.value.fechaAplicacion.day}/${entry.value.fechaAplicacion.month}/${entry.value.fechaAplicacion.year}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarVacuna(entry.key),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Sección de Tratamientos y Medicamentos
              _buildSeccionMedica(
                "Tratamientos y Medicamentos",
                Column(
                  children: [
                    TextFormField(
                      controller: _tratamientoDescController,
                      decoration: InputDecoration(
                        labelText: "Descripción del Tratamiento",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _agregarTratamiento,
                      child: Text("Agregar Tratamiento"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _medicamentoNombreController,
                            decoration: InputDecoration(
                              labelText: "Nombre del Medicamento",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _medicamentoDosisController,
                            decoration: InputDecoration(
                              labelText: "Dosis",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _agregarMedicamento,
                          child: Icon(Icons.add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ..._tratamientos.asMap().entries.map((entry) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.value.descripcion,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarTratamiento(entry.key),
                                  ),
                                ],
                              ),
                              ...entry.value.medicamentos.map((med) => 
                                Text("• ${med.nombre}: ${med.dosis}")
                              ).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Sección de Derivaciones
              _buildSeccionMedica(
                "Derivaciones Veterinarias",
                Column(
                  children: [
                    TextFormField(
                      controller: _derivacionVeterinariaController,
                      decoration: InputDecoration(
                        labelText: "Veterinaria",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _derivacionMotivoController,
                      decoration: InputDecoration(
                        labelText: "Motivo de Derivación",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _agregarDerivacion,
                      child: Text("Agregar Derivación"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._derivaciones.asMap().entries.map((entry) {
                      return ListTile(
                        leading: Icon(Icons.local_hospital, color: Colors.blue),
                        title: Text(entry.value.veterinaria),
                        subtitle: Text(entry.value.motivo),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarDerivacion(entry.key),
                        ),
                      );
                    }).toList(),
                  ],
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
                      child: Text("Guardar Mascota"),
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

// ------------------ PANTALLA EDITAR MASCOTA CORREGIDA ------------------ //

class EditarMascotaScreen extends StatefulWidget {
  final Mascota mascota;

  const EditarMascotaScreen({required this.mascota});

  @override
  _EditarMascotaScreenState createState() => _EditarMascotaScreenState();
}

class _EditarMascotaScreenState extends State<EditarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos del formulario
  late TextEditingController _chipIdController;
  late TextEditingController _nombreController;
  late TextEditingController _especieController;
  late TextEditingController _razaController;
  late TextEditingController _edadController;
  late TextEditingController _pesoController;
  late TextEditingController _descripcionController;
  
  late String _sucursalSeleccionada;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos actuales de la mascota
    _chipIdController = TextEditingController(text: widget.mascota.chipId);
    _nombreController = TextEditingController(text: widget.mascota.nombre);
    _especieController = TextEditingController(text: widget.mascota.especie);
    _razaController = TextEditingController(text: widget.mascota.raza);
    _edadController = TextEditingController(text: widget.mascota.edad);
    _pesoController = TextEditingController(text: widget.mascota.peso);
    _descripcionController = TextEditingController(text: widget.mascota.descripcion);
    
    _sucursalSeleccionada = widget.mascota.idCampus;
  }

  @override
  void dispose() {
    _chipIdController.dispose();
    _nombreController.dispose();
    _especieController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      try {
        print("🔄 Iniciando actualización de mascota: ${widget.mascota.chipId}");
        
        // Crear mascota actualizada - USAR LOS DATOS ORIGINALES COMO BASE
        final mascotaActualizada = Mascota(
          chipId: widget.mascota.chipId, // Usar el chipId original
          nombre: _nombreController.text,
          imagenUrl: widget.mascota.imagenUrl, // Mantener imagen original
          especie: _especieController.text,
          raza: _razaController.text,
          edad: _edadController.text,
          peso: _pesoController.text,
          estado: widget.mascota.estado, // Mantener estado original
          idCampus: _sucursalSeleccionada,
          descripcion: _descripcionController.text,
          // Mantener toda la información médica original
          enfermedades: widget.mascota.enfermedades ?? [],
          vacunas: widget.mascota.vacunas ?? [],
          tratamientos: widget.mascota.tratamientos ?? [],
          derivaciones: widget.mascota.derivaciones ?? [],
        );

        print("📝 Datos a guardar:");
        print("Nombre: ${_nombreController.text}");
        print("Especie: ${_especieController.text}");
        print("Raza: ${_razaController.text}");
        
        // Actualizar en la lista
        await MascotaService().actualizarMascota(widget.mascota.chipId, mascotaActualizada);
        
        print("✅ Mascota actualizada en el servicio");

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Mascota actualizada exitosamente"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Esperar un poco para que se vea el mensaje
        await Future.delayed(Duration(milliseconds: 1500));

        // Regresar a la pantalla anterior
        Navigator.pop(context, true); // Pasar 'true' para indicar que se actualizó
        
      } catch (e) {
        print("❌ Error al actualizar: $e");
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al actualizar la mascota: $e"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar ${widget.mascota.nombre}"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _guardarCambios,
            tooltip: "Guardar cambios",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Información de la mascota
              Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Información Actual",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Chip ID: ${widget.mascota.chipId}"),
                      Text("Imagen: ${widget.mascota.imagenUrl}"),
                    ],
                  ),
                ),
              ),

              // Chip ID (solo lectura)
              TextFormField(
                controller: _chipIdController,
                decoration: InputDecoration(
                  labelText: "Chip ID",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                readOnly: true,
                enabled: false,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor selecciona una sucursal";
                  }
                  return null;
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
                      onPressed: _guardarCambios,
                      child: Text("Guardar Cambios"),
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

// ------------------ DETALLE MASCOTA ------------------ //

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
      appBar: AppBar(
        title: Text(mascota.nombre),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarMascotaScreen(mascota: mascota),
                ),
              );
            },
            tooltip: "Editar mascota",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mascota.imagenUrl, 
                  height: 200, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.pets, size: 80, color: Colors.grey[600]),
                    );
                  },
                ),
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
// ------------------ PANTALLA DE INVENTARIO ------------------ //

class InventarioScreen extends StatefulWidget {
  @override
  _InventarioScreenState createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemInventario> _items = [];
  late List<ItemInventario> _itemsFiltrados;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarItems();
  }

  void _cargarItems() async {
    final items = await InventarioService().obtenerItems();
    setState(() {
      _items = items;
      _itemsFiltrados = items;
      _isLoading = false;
    });
  }

  void _filtrarItems(String query) {
    if (query.isEmpty) {
      setState(() => _itemsFiltrados = _items);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _itemsFiltrados = _items
          .where((item) =>
              item.nombre.toLowerCase().contains(q) ||
              item.categoria.toLowerCase().contains(q) ||
              item.ubicacion.toLowerCase().contains(q))
          .toList();
    });
  }

  void _navegarAAgregarItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgregarItemScreen()),
    ).then((_) {
      _cargarItems(); // Recargar después de agregar
    });
  }

  void _restarCantidad(ItemInventario item, int cantidad) async {
    final nuevoItem = ItemInventario(
      id: item.id,
      nombre: item.nombre,
      categoria: item.categoria,
      cantidad: item.cantidad - cantidad,
      cantidadMinima: item.cantidadMinima,
      unidad: item.unidad,
      fechaVencimiento: item.fechaVencimiento,
      ubicacion: item.ubicacion,
    );
    
    await InventarioService().actualizarItem(item.id, nuevoItem);
    _cargarItems(); // Recargar la lista
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Se restaron $cantidad ${item.unidad} de ${item.nombre}")),
    );
  }

  void _mostrarDialogoRestar(ItemInventario item) {
    final cantidadController = TextEditingController(text: "1");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Restar cantidad"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("¿Cuánto quieres restar de ${item.nombre}?"),
            SizedBox(height: 16),
            TextFormField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Cantidad a restar",
                border: OutlineInputBorder(),
                suffixText: item.unidad,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 1;
              if (cantidad > 0) {
                _restarCantidad(item, cantidad);
                Navigator.pop(context);
              }
            },
            child: Text('Restar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesItem(ItemInventario item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.remove, color: Colors.orange),
                title: Text('Restar cantidad'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoRestar(item);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Editar item'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar edición
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edición de items en desarrollo')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar item'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoEliminar(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoEliminar(ItemInventario item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar item'),
        content: Text('¿Estás seguro de que quieres eliminar ${item.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await InventarioService().eliminarItem(item.id);
              _cargarItems(); // Recargar después de eliminar
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.nombre} ha sido eliminado')),
              );
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStockColor(ItemInventario item) {
    if (item.cantidad <= item.cantidadMinima) {
      return Colors.red;
    } else if (item.cantidad <= item.cantidadMinima * 2) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando inventario...'),
            ],
          ),
        ),
      );
    }

    final itemsBajosStock = _items.where((item) => item.cantidad <= item.cantidadMinima).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario Perruls"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navegarAAgregarItem,
            tooltip: "Agregar item",
          ),
        ],
      ),
      body: Column(
        children: [
          // Alert de stock bajo
          if (itemsBajosStock.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${itemsBajosStock.length} items con stock bajo',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarItems,
              decoration: InputDecoration(
                hintText: "Buscar por nombre, categoría o ubicación...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),

          // Lista de items
          Expanded(
            child: ListView(
              children: [
                ..._itemsFiltrados.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getStockColor(item).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForCategory(item.categoria),
                          color: _getStockColor(item),
                        ),
                      ),
                      title: Text(
                        item.nombre,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item.categoria} • ${item.ubicacion}"),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Stock: ${item.cantidad} ${item.unidad}",
                                style: TextStyle(
                                  color: _getStockColor(item),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item.cantidad <= item.cantidadMinima)
                                Text(
                                  " (BAJO)",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          if (item.fechaVencimiento != null)
                            Text(
                              "Vence: ${item.fechaVencimiento!.day}/${item.fechaVencimiento!.month}/${item.fechaVencimiento!.year}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón para restar rápidamente 1 unidad
                          if (item.cantidad > 0)
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.orange),
                              onPressed: () => _restarCantidad(item, 1),
                              tooltip: "Restar 1 unidad",
                            ),
                          Text(
                            "Mín: ${item.cantidadMinima}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _mostrarDialogoRestar(item),
                      onLongPress: () => _mostrarOpcionesItem(item),
                    ),
                  );
                }).toList(),
                if (_itemsFiltrados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("No se encontraron items")),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAAgregarItem,
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: "Agregar nuevo item",
      ),
    );
  }

  IconData _getIconForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'alimentos':
        return Icons.fastfood;
      case 'medicamentos':
        return Icons.medical_services;
      case 'accesorios':
        return Icons.pets;
      case 'limpieza':
        return Icons.clean_hands;
      default:
        return Icons.inventory;
    }
  }
}

// ------------------ PANTALLA AGREGAR ITEM INVENTARIO ------------------ //

class AgregarItemScreen extends StatefulWidget {
  @override
  _AgregarItemScreenState createState() => _AgregarItemScreenState();
}

class _AgregarItemScreenState extends State<AgregarItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _cantidadMinimaController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  
  DateTime? _fechaVencimiento;
  final List<String> _categorias = ['Alimentos', 'Medicamentos', 'Accesorios', 'Limpieza', 'Otros'];

  void _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _fechaVencimiento = picked;
      });
    }
  }

  void _guardarItem() {
    if (_formKey.currentState!.validate()) {
      final nuevoItem = ItemInventario(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreController.text,
        categoria: _categoriaController.text,
        cantidad: int.parse(_cantidadController.text),
        cantidadMinima: int.parse(_cantidadMinimaController.text),
        unidad: _unidadController.text,
        fechaVencimiento: _fechaVencimiento,
        ubicacion: _ubicacionController.text,
      );

      InventarioService().agregarItem(nuevoItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Item agregado exitosamente")),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar Item al Inventario"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Nuevo Item",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: "Nombre del Item *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa el nombre";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categoriaController.text.isEmpty ? null : _categoriaController.text,
                decoration: InputDecoration(
                  labelText: "Categoría *",
                  border: OutlineInputBorder(),
                ),
                items: _categorias
                    .map((categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaController.text = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor selecciona una categoría";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadController,
                      decoration: InputDecoration(
                        labelText: "Cantidad *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingresa la cantidad";
                        }
                        if (int.tryParse(value) == null) {
                          return "Ingresa un número válido";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unidadController,
                      decoration: InputDecoration(
                        labelText: "Unidad *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.square_foot),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingresa la unidad";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _cantidadMinimaController,
                decoration: InputDecoration(
                  labelText: "Cantidad Mínima *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                  helperText: "Alerta cuando el stock llegue a esta cantidad",
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa la cantidad mínima";
                  }
                  if (int.tryParse(value) == null) {
                    return "Ingresa un número válido";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: "Ubicación *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  helperText: "Ej: Almacén A, Refrigerador 1, Estante 2",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Por favor ingresa la ubicación";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Selector de fecha de vencimiento
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text(
                  _fechaVencimiento == null
                      ? "Seleccionar fecha de vencimiento (opcional)"
                      : "Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}",
                ),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: _seleccionarFecha,
              ),
              SizedBox(height: 24),

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
                      onPressed: _guardarItem,
                      child: Text("Guardar Item"),
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