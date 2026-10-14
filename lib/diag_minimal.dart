import 'package:flutter/material.dart';

/// MINIMAL diagnostic entrypoint: pure Flutter, ZERO plugins.
/// If this UI appears, the engine + Dart isolate are fine and the crash
/// is caused by one of the plugins (google_mobile_ads / in_app_purchase).
/// If this ALSO crashes, the problem is the engine/build itself.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MinimalDiagApp());
}

class MinimalDiagApp extends StatelessWidget {
  const MinimalDiagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 80),
                SizedBox(height: 16),
                Text(
                  'MINIMAL DIAG OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Engine + Dart chal rahe hain.\nScreenshot bhejo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
