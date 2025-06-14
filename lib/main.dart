import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'alarm_control_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://bqsybflgtewuguaapwap.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxc3liZmxndGV3dWd1YWFwd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NTIzMjEsImV4cCI6MjA2NDAyODMyMX0.F46vDD0l3LuGMbHLHXiIjPhzrDlQfJYq92b-fF_RJHY",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Alarma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AlarmControlScreen(),
    );
  }
}