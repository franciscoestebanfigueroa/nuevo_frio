import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/temperature_service.dart';

class RealtimeProvider with ChangeNotifier {
  final TemperatureService _temperatureService = TemperatureService();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  String _receivedData = "Esperando datos...";
  bool _isConnected = false;
  bool _isReconnecting = false;

  // Getters
  String get receivedData => _receivedData;
  bool get isConnected => _isConnected;
// Dentro de la clase RealtimeProvider

int _selectedHours = 6; // Por defecto 6 horas
int get selectedHours => _selectedHours;
// En realtime_provider.dart agregamos una variable para el cache
List<dynamic> _historyCache = [];
List<dynamic> get historyCache => _historyCache;

// Nuevo método para cargar el historial una sola vez
Future<void> fetchHistory() async {
  try {
    _historyCache = await _temperatureService.getHistory();
    notifyListeners();
  } catch (e) {
    print("Error cargando historial: $e");
  }
}

void setFilter(int hours) {
  _selectedHours = hours;
  notifyListeners(); // Esto hará que el FutureBuilder en la UI se dispare de nuevo
}

// Modificamos este método para que acepte el filtro
Future<List<dynamic>> getTemperatureHistoryFiltered() async {
  return await _temperatureService.getFilteredHistory(_selectedHours);
}
  RealtimeProvider() {
    connectWebSocket();
  }

  /// Establece la conexión con el monitor de la heladera
  Future<void> connectWebSocket() async {
    // Si ya estamos intentando conectar, no duplicamos esfuerzos
    if (_isReconnecting) return;

    try {
      print("Iniciando conexión WebSocket...");
      
      // Cerramos cualquier suscripción o canal previo
      await _disposeOldConnection();

      // Obtenemos el canal (el servicio ahora es asíncrono por las SharedPreferences)
      _channel = await _temperatureService.createChannel();
      
      _isConnected = true;
      _isReconnecting = false;
      notifyListeners();

      _subscription = _channel!.stream.listen(
        (data) {
          _processIncomingData(data);
        },
        onError: (error) {
          print("Error en stream: $error");
          _handleDisconnect();
        },
        onDone: () {
          print("Servidor cerró la conexión.");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("No se pudo conectar: $e");
      _handleDisconnect();
    }
  }

  /// Procesa los datos crudos que llegan del ESP32/Servidor
  void _processIncomingData(dynamic data) {
    print("Datos recibidos: $data");
    try {
      final decodedData = jsonDecode(data);
      // Ajusta la clave 'temperatura' según lo que envíe tu hardware
      if (decodedData.containsKey('temperatura')) {
        _receivedData = "${decodedData['temperatura']}°C";
      } else {
        _receivedData = data.toString();
      }
    } catch (e) {
      // Si no es JSON, mostramos el texto plano
      _receivedData = data.toString();
    }
    _isConnected = true;
    notifyListeners();
  }

  /// Maneja la desconexión y dispara la reconexión automática
  void _handleDisconnect() {
    _isConnected = false;
    _receivedData = "Reconectando...";
    notifyListeners();
    reconnect();
  }

  /// Intenta reconectar cada 5 segundos
  void reconnect() {
    if (_isReconnecting) return;
    
    _isReconnecting = true;
    Timer(const Duration(seconds: 5), () {
      _isReconnecting = false;
      connectWebSocket();
    });
  }

  /// Limpieza de recursos antes de una nueva conexión
  Future<void> _disposeOldConnection() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  /// Para usar desde la pantalla de historial
  Future<List<dynamic>> getTemperatureHistory() async {
    return await _temperatureService.getHistory();
  }

  @override
  void dispose() {
    _disposeOldConnection();
    super.dispose();
  }
}