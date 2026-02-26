import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/realtime_provider.dart';
import 'screens/realtime_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RealtimeProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        
        title: 'Monitor de Temperatura',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const Scaffold(body: RealtimeScreen()),
      ),
    );
  }
}