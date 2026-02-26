import 'package:control_temp/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/realtime_provider.dart';
import 'temperature_history_screen.dart';

class RealtimeScreen extends StatelessWidget {
  const RealtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final realtimeProvider = Provider.of<RealtimeProvider>(context);
    final theme = Theme.of(context);

    String? extractTemperature() {
      try {
        final regex = RegExp(r'([-+]?\d*\.?\d+)');
        final match = regex.firstMatch(realtimeProvider.receivedData);
        return match?.group(1);
      } catch (e) {
        return null;
      }
    }

    final temperature = extractTemperature();
    final double? tempValue = temperature != null ? double.tryParse(temperature) : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Monitoreo en Tiempo Real'),
        centerTitle: true,
        elevation: 0,
      actions: [
  IconButton(
    icon: const Icon(Icons.settings),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ),
  ),
  IconButton(
    icon: const Icon(Icons.history),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TemperatureHistoryScreen()),
    ),
  ),
],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildConnectionStatus(realtimeProvider, theme),
            const SizedBox(height: 40),
            _buildTemperatureDisplay(tempValue, theme),
            const SizedBox(height: 20),
            _buildAdditionalData(realtimeProvider.receivedData, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(RealtimeProvider provider, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: provider.isConnected 
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.isConnected ? Icons.wifi : Icons.wifi_off,
            size: 18,
            color: provider.isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            provider.isConnected ? 'Conectado' : 'Desconectado',
            style: TextStyle(
              color: provider.isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureDisplay(double? temperature, ThemeData theme) {
    Color getTempColor(double? temp) {
      if (temp == null) return theme.colorScheme.onSurface;
      if (temp > 30) return Colors.red;
      if (temp < 10) return Colors.blue;
      return Colors.green;
    }

    return Column(
      children: [
        Text(
          'Temperatura Actual',
          style: TextStyle(
            fontSize: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: temperature != null
              ? Container(
                  key: ValueKey<double>(temperature),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        getTempColor(temperature).withOpacity(0.2),
                        getTempColor(temperature).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getTempColor(temperature).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        temperature.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: getTempColor(temperature),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 24,
                          color: getTempColor(temperature).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  '--.- °C',
                  style: TextStyle(
                    fontSize: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAdditionalData(String rawData, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos completos:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rawData.isNotEmpty ? rawData : 'Esperando datos...',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última actualización: ${_formatTime(DateTime.now())}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal(); // Convertir a hora local
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
  }
}