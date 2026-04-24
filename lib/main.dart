import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final IconData icon;

  Zone({required this.name, required this.crowdLevel, required this.icon});

  int get waitTime => (crowdLevel / 10).round();

  Color get color {
    if (crowdLevel <= 30) return Colors.greenAccent;
    if (crowdLevel <= 70) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Zone> zones;
  Timer? dataTimer;
  final Random random = Random();

  // Real-time Weather Data Variables
  String temperature = "--";
  String weatherCondition = "Loading...";
  bool isRaining = false;

  @override
  void initState() {
    super.initState();
    zones = [
      Zone(name: "Gate A", crowdLevel: 20, icon: Icons.door_front_door),
      Zone(name: "Gate B", crowdLevel: 45, icon: Icons.sensor_door),
      Zone(name: "Food Court", crowdLevel: 60, icon: Icons.fastfood),
      Zone(name: "Washroom", crowdLevel: 15, icon: Icons.wc),
      Zone(name: "Exit Gate", crowdLevel: 10, icon: Icons.logout),
      Zone(name: "Parking", crowdLevel: 30, icon: Icons.local_parking),
    ];

    // Fetch real weather data immediately
    fetchLiveWeather();

    // Update crowd and weather every 5 seconds
    dataTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      simulateCrowdLogic();
      fetchLiveWeather();
    });
  }

  // AGENTIC DATA FETCH: Calling Open-Meteo API (Ahmedabad Coordinates)
  Future<void> fetchLiveWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=23.0225&longitude=72.5714&current_weather=true'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = "${data['current_weather']['temperature']}°C";
          double code = data['current_weather']['weathercode'].toDouble();
          // Weather codes > 50 usually mean rain/drizzle
          isRaining = code > 50;
          weatherCondition = isRaining ? "Raining" : "Clear Sky";
        });
      }
    } catch (e) {
      debugPrint("Weather API Error: $e");
    }
  }

  void simulateCrowdLogic() {
    setState(() {
      for (var zone in zones) {
        double adjustment = (random.nextDouble() * 15 - 7);

        // AGENT REASONING: Influence crowd based on real-time weather
        if (isRaining && (zone.name == "Food Court" || zone.name == "Washroom")) {
          adjustment += 10; // People rush indoors if raining
        }
        if (!isRaining && zone.name.contains("Gate")) {
          adjustment += 5; // People move to gates if weather is clear
        }

        zone.crowdLevel = (zone.crowdLevel + adjustment).clamp(0, 100);
      }
    });
  }

  Zone get bestZone => zones.reduce((a, b) => a.crowdLevel < b.crowdLevel ? a : b);
  Zone? get alertZone => zones.any((z) => z.crowdLevel > 85)
      ? zones.firstWhere((z) => z.crowdLevel > 85) : null;

  @override
  void dispose() {
    dataTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = alertZone;
    final suggest = bestZone;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Column(
        children: [
          // 1. LIVE AGENT STATUS HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRaining ? [Colors.blueGrey.shade900, Colors.blue.shade900] : [Colors.blue.shade900, Colors.indigo.shade900],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("StadiumOS • Narendra Modi Stadium", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text("AI COMMAND CENTER", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(isRaining ? Icons.umbrella : Icons.wb_sunny, color: Colors.orangeAccent),
                      const SizedBox(width: 10),
                      Text("$temperature | $weatherCondition", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 2. EMERGENCY ALERT (Animated)
          if (alert != null || isRaining)
            Container(
              width: double.infinity,
              color: isRaining ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  isRaining
                      ? "🌧️ WEATHER ALERT: Rain detected. Directing fans to Indoor Food Court."
                      : "🚨 CROWD ALERT: ${alert?.name} is at capacity. Redirecting to ${suggest.name}.",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

          // 3. THE GRID MAP
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.1
                ),
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  final zone = zones[index];
                  return AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: zone.color.withOpacity(0.5), width: 2),
                      boxShadow: [BoxShadow(color: zone.color.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(zone.icon, color: zone.color, size: 30),
                        const SizedBox(height: 10),
                        Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${zone.waitTime}m wait", style: TextStyle(color: zone.color, fontSize: 12)),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: LinearProgressIndicator(
                            value: zone.crowdLevel / 100,
                            backgroundColor: Colors.white10,
                            color: zone.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. AGENTIC REASONING FOOTER
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0F172A),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.psychology, color: Colors.white)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("AGENT REASONING", style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        Text(
                          isRaining
                              ? "Atmospheric sensors detected precipitation. Optimizing indoor zone capacity."
                              : "Flow Analysis: ${suggest.name} is currently the most efficient zone for fan movement.",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}