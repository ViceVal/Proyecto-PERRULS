import 'package:postgres/postgres.dart';
import '../config/database_config.dart';

class DatabaseService {
  static Future<PostgreSQLConnection> getConnection() async {
    final connection = PostgreSQLConnection(
      DatabaseConfig.host,
      DatabaseConfig.port,
      DatabaseConfig.database,
      username: DatabaseConfig.username,
      password: DatabaseConfig.password,
    );
    await connection.open();
    return connection;
  }
  
  // Método helper para cerrar conexión de forma segura
  static Future<void> closeConnection(PostgreSQLConnection? conn) async {
    try {
      await conn?.close();
    } catch (e) {
      print('Error cerrando conexión: $e');
    }
  }
}