import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../services/battery_service.dart';
import '../../services/permission_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final meshEngine = context.read<MeshEngine>();
    final batteryService = context.read<BatteryService>();
    final permService = context.read<PermissionService>();

    await Future.wait([
      meshEngine.initialize(),
      batteryService.initialize(),
      permService.checkPermissions(),
    ]);

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    if (!permService.isMeshReady) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A192F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Icon(
              Icons.hub_rounded,
              size: 80,
              color: Color(0xFF38BDF8),
            ),
            SizedBox(height: 20),
            Text(
              'MESHCONNECT',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Decentralized Offline Mesh Communication',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ],
        ),
      ),
    );
  }
}
