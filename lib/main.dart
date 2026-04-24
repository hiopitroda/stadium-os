import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const StadiumOS());
}

class StadiumOS extends StatelessWidget {
  const StadiumOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StadiumOS Live Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class Zone {
  final String name;
  double crowdLevel;

  Zone({required this.name, required this.crowdLevel});

  int get waitTime => (crowdLevel / 10).round();

  Color get color {
    if (crowdLevel <= 30) return Colors.greenAccent.withOpacity(0.8);
    if (crowdLevel <= 70) return Colors.orangeAccent.withOpacity(0.8);
    return Colors.redAccent.withOpacity(0.8);
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Zone> zones;
  Timer? timer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    zones = [
      Zone(name: "Gate A", crowdLevel: 20),
      Zone(name: "Gate B", crowdLevel: 45),
      Zone(name: "Food Court", crowdLevel: 60),
      Zone(name: "Washroom", crowdLevel: 15),
      Zone(name: "Exit Gate", crowdLevel: 10),
      Zone(name: "Parking", crowdLevel: 30),
    ];

    timer = Timer.periodic(const Duration(seconds: 2), (t) => simulateCrowd());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void simulateCrowd() {
    setState(() {
      for (var zone in zones) {
        double fluctuation = zone.name == "Food Court"
            ? (random.nextDouble() * 30 - 10) // Higher fluctuation
            : (random.nextDouble() * 10 - 5);

        zone.crowdLevel = (zone.crowdLevel + fluctuation).clamp(0, 100);
      }
    });
  }

  Zone get bestZone => zones.reduce((a, b) => a.crowdLevel < b.crowdLevel ? a : b);

  Zone? get alertZone {
    List<Zone> crowded = zones.where((z) => z.crowdLevel > 80).toList();
    if (crowded.isEmpty) return null;
    return crowded.reduce((a, b) => a.crowdLevel > b.crowdLevel ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final activeAlert = alertZone;
    final suggestion = bestZone;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "StadiumOS Live Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            Text(
              "Powered by AI (simulated)",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Alert Banner
          AnimatedOpacity(
            opacity: activeAlert != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activeAlert != null
                          ? "🚨 ${activeAlert.name} is crowded! Go to ${suggestion.name} instead (${suggestion.waitTime} min wait)"
                          : "",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Grid-based Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  final zone = zones[index];
                  bool isHighRisk = zone.crowdLevel > 80;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: zone.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHighRisk ? Colors.white : zone.color,
                        width: isHighRisk ? 4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: zone.color.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Icon(Icons.sensors, size: 16, color: zone.color),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                zone.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${zone.waitTime} min wait",
                                style: TextStyle(fontSize: 14, color: zone.color),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Crowd: ${zone.crowdLevel.toStringAsFixed(0)}%",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Smart Suggestion Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Text(
                    "Smart Suggestion: Go to ${suggestion.name} – shortest wait",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}