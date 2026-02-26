import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartDetailScreen extends StatelessWidget {
  final Map<String, dynamic> chartData;

  const ChartDetailScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Historial'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SfCartesianChart(
                zoomPanBehavior: ZoomPanBehavior(
                  enablePinching: true,
                  enablePanning: true,
                  enableMouseWheelZooming: true,
                ),
                primaryXAxis: const DateTimeAxis(
                  title: AxisTitle(text: 'Hora'),
                  intervalType: DateTimeIntervalType.hours,
                  labelFormat: '{value:Hm}',
                  labelRotation: 45,
                ),
                primaryYAxis: const NumericAxis(
                  title: AxisTitle(text: 'Temperatura (°C)'),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.y°C a las point.x:Hm',
                ),
                series: <CartesianSeries>[
                  LineSeries<dynamic, DateTime>(
                    dataSource: chartData['chartData'],
                    xValueMapper: (data, _) => data.fecha,
                    yValueMapper: (data, _) => data.temperatura,
                    name: 'Temperatura',
                    color: Colors.blue,
                    width: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: Colors.blue,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildStatsSummary(chartData),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Máxima', '${data['maxTemp'].toStringAsFixed(1)}°C'),
            _buildStatItem('Mínima', '${data['minTemp'].toStringAsFixed(1)}°C'),
            _buildStatItem('Promedio', '${data['avgTemp'].toStringAsFixed(1)}°C'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }
}