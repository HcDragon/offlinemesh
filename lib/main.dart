import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/splash/splash_screen.dart';
import 'mesh/mesh_engine.dart';
import 'services/battery_service.dart';
import 'services/discovery_service.dart';
import 'services/permission_service.dart';
import 'services/sos_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final meshEngine = MeshEngine();
  final batteryService = BatteryService();
  final permissionService = PermissionService();
  final sosService = SosService(meshEngine);
  final discoveryService = DiscoveryService(meshEngine);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshEngine>.value(value: meshEngine),
        ChangeNotifierProvider<BatteryService>.value(value: batteryService),
        ChangeNotifierProvider<PermissionService>.value(value: permissionService),
        ChangeNotifierProvider<SosService>.value(value: sosService),
        ChangeNotifierProvider<DiscoveryService>.value(value: discoveryService),
      ],
      child: const MeshConnectApp(),
    ),
  );
}

class MeshConnectApp extends StatelessWidget {
  const MeshConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          primary: const Color(0xFF1E40AF),
          secondary: const Color(0xFF10B981),
          error: const Color(0xFFDC2626),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
