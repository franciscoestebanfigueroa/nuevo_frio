import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../providers/realtime_provider.dart';

class TemperatureHistoryScreen extends StatefulWidget {
  const TemperatureHistoryScreen({super.key});

  @override
  State<TemperatureHistoryScreen> createState() => _TemperatureHistoryScreenState();
}

class _TemperatureHistoryScreenState extends State<TemperatureHistoryScreen> {
  int _selectedHours = 6;
  late Future<void> _fetchHistoryFuture;

  @override
  void initState() {
    super.initState();
    // Cargamos el historial una sola vez al iniciar la pantalla
    // para que los datos en tiempo real no reinicien la vista.
    _fetchHistoryFuture = Provider.of<RealtimeProvider>(context, listen: false).fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final realtimeProvider = Provider.of<RealtimeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Temperatura'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _fetchHistoryFuture = realtimeProvider.fetchHistory();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildFilterSelector(),
          Expanded(
            child: FutureBuilder(
              future: _fetchHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final history = realtimeProvider.historyCache;

                if (history.isEmpty) {
                  return const Center(
                    child: Text('No hay datos disponibles en el servidor'),
                  );
                }

                final processedData = _processData(history, _selectedHours);
                final List<TemperatureData> chartData = processedData['chartData'];

                if (chartData.isEmpty) {
                  return const Center(child: Text('No hay registros en este rango de horas'));
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStatsCards(processedData),
                      const SizedBox(height: 10),
                      _buildChart(chartData),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [1, 3, 6].map((hours) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: ChoiceChip(
            label: Text('$hours Horas'),
            selected: _selectedHours == hours,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedHours = hours);
              }
            },
            selectedColor: Colors.blue[200],
          ),
        );
      }).toList(),
    );
  }

Widget _buildChart(List<TemperatureData> data) {
  return Container(
    height: 350,
    padding: const EdgeInsets.all(10),
    child: SfCartesianChart(
      primaryXAxis: DateTimeAxis(dateFormat: DateFormat('HH:mm')),
      primaryYAxis: const NumericAxis(
        // LÍNEA DE REFERENCIA (SET POINT)
        plotBands: <PlotBand>[
          PlotBand(
            isVisible: true,
            start: 4, // Aquí pones la temperatura de corte ideal
            end: 4,
            borderColor: Colors.redAccent,
            borderWidth: 2,
            dashArray: <double>[5, 5],
            text: 'Set Point (4°C)',
            textStyle: TextStyle(color: Colors.redAccent),
          )
        ],
      ),
      series: <CartesianSeries<TemperatureData, DateTime>>[
        AreaSeries<TemperatureData, DateTime>(
          dataSource: data,
          xValueMapper: (TemperatureData d, _) => d.fecha,
          yValueMapper: (TemperatureData d, _) => d.temperatura,
          color: Colors.blue.withOpacity(0.2),
          borderColor: const Color.fromARGB(255, 25, 118, 210),
          borderWidth: 2,
        )
      ],
    ),
  );
}

  
Widget _buildStatsCards(Map<String, dynamic> stats) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Row(
          children: [
            _statCard('Máx', stats['maxTemp'], Colors.red),
            _statCard('Min', stats['minTemp'], Colors.blue),
            _statCard('Prom', stats['avgTemp'], Colors.green),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _statCard('Ciclos (${_selectedHours}h)', stats['motorCount'].toDouble(), Colors.orange, isInt: true),
            _statCard('Frecuencia', stats['minutesPerCycle'], Colors.deepOrange, isTime: true),
            _statCard('Rendimiento', stats['avgSlope'], Colors.purple, isSlope: true),
          ],
        ),
      ],
    ),
  );
}

Widget _statCard(String label, double value, Color color, {bool isInt = false, bool isSlope = false, bool isTime = false}) {
  String valorStr = "${value.toStringAsFixed(1)}°";
  if (isInt) valorStr = value.toInt().toString();
  if (isSlope) valorStr = "${value.toStringAsFixed(2)}°/m";
  if (isTime) valorStr = value > 0 ? "cada ${value.toStringAsFixed(1)} min" : "N/A";

  return Expanded(
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(valorStr, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}
Map<String, dynamic> _processData(List<dynamic> rawData, int hours) {
  final DateTime now = DateTime.now();
  final DateTime limit = now.subtract(Duration(hours: hours));
  
  List<TemperatureData> chartData = [];
  List<double> temps = [];
  int motorOnCount = 0;
  double totalNegativeSlope = 0;
  int slopeSamples = 0;
  bool isCurrentlyCooling = false;

  for (int i = 0; i < rawData.length; i++) {
    try {
      final DateTime date = DateTime.parse(rawData[i]['fecha']);
      if (date.isAfter(limit)) {
        final double temp = double.parse(rawData[i]['temperatura'].toString());
        chartData.add(TemperatureData(fecha: date, temperatura: temp));
        temps.add(temp);

        if (i > 0) {
          final double prevTemp = double.parse(rawData[i - 1]['temperatura'].toString());
          double diff = temp - prevTemp;

          if (diff < 0) {
            totalNegativeSlope += diff;
            slopeSamples++;
          }

          // Filtro de histéresis para conteo de arranques
          if (diff < -0.15 && !isCurrentlyCooling) { 
            motorOnCount++;
            isCurrentlyCooling = true;
          } 
          if (diff > 0.1) {
            isCurrentlyCooling = false;
          }
        }
      }
    } catch (e) { continue; }
  }

  // CÁLCULO DE FRECUENCIA TEMPORAL
  // Dividimos los minutos del filtro por la cantidad de arranques
  double minutesPerCycle = 0;
  if (motorOnCount > 0) {
    minutesPerCycle = (hours * 60) / motorOnCount;
  }

  if (temps.isEmpty) return {'chartData': <TemperatureData>[], 'motorCount': 0, 'minutesPerCycle': 0.0};

  return {
    'chartData': chartData,
    'maxTemp': temps.reduce((a, b) => a > b ? a : b),
    'minTemp': temps.reduce((a, b) => a < b ? a : b),
    'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
    'motorCount': motorOnCount,
    'minutesPerCycle': minutesPerCycle,
    'avgSlope': slopeSamples > 0 ? (totalNegativeSlope / slopeSamples) : 0.0,
  };
}
}

class TemperatureData {
  final DateTime fecha;
  final double temperatura;
  TemperatureData({required this.fecha, required this.temperatura});
}
