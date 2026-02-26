import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemperatureService {
  
  // Función privada para obtener la IP y Puerto de SharedPreferences
  // Si no existen, usa los valores por defecto que tenías.
  Future<String> _getHost(String protocol) async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip') ?? '181.229.203.180';
    final port = prefs.getString('server_port') ?? '8888';
    return '$protocol://$ip:$port';
  }

  // Obtener historial (HTTP GET)
  Future<List<dynamic>> getHistory() async {
    final baseUrl = await _getHost('http');
    final response = await http.get(Uri.parse('$baseUrl/historial'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar el historial desde $baseUrl');
    }
  }
  // Dentro de la clase TemperatureService en temperature_service.dart

Future<List<dynamic>> getFilteredHistory(int hours) async {
  final baseUrl = await _getHost('http');
  // Dependiendo de tu API, podrías pasar un parámetro o usar rutas distintas
  final response = await http.get(Uri.parse('$baseUrl/historial?horas=$hours'));
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Error al cargar datos de $hours horas');
  }
}

  // Obtener datos de las últimas 6 horas (HTTP GET)
  Future<Map<String, dynamic>> getLast6Hours() async {
    final baseUrl = await _getHost('http');
    final response = await http.get(Uri.parse('$baseUrl/ultimas_horas'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar datos desde $baseUrl');
    }
  }

  // Conectar a WebSocket para datos en tiempo real
  // IMPORTANTE: Ahora devuelve un Future<WebSocketChannel> porque debe esperar a leer la IP
  Future<WebSocketChannel> createChannel() async {
    try {
      final wsUrl = await _getHost('ws');
      print("Intentando conectar al WebSocket en $wsUrl");
      return WebSocketChannel.connect(Uri.parse(wsUrl));
    } catch (e) {
      print("Error al conectar al WebSocket: $e");
      throw Exception("No se pudo conectar al WebSocket: $e");
    }
  }
}