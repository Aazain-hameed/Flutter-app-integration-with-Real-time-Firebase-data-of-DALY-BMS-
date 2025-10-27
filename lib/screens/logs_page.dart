import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  // Reference to "logs" node
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("logs");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ESP32 Realtime Logs"),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("❌ Error loading logs"));
          }
          if (!snapshot.hasData ||
              (snapshot.data! as DatabaseEvent).snapshot.value == null) {
            return const Center(child: Text("No logs available"));
          }

          // Convert snapshot to Map
          Map data =
              (snapshot.data! as DatabaseEvent).snapshot.value as Map;

          // Convert Map to List for ListView
          List logEntries = data.entries.toList();

          // Sort logs by timestamp (latest first)
          logEntries.sort((a, b) {
            var logA = a.value as Map;
            var logB = b.value as Map;
            return logB["timestamp"].compareTo(logA["timestamp"]);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logEntries.length,
            itemBuilder: (context, index) {
              var log = logEntries[index].value as Map;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.orange, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            "Log #${index + 1}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            log["timestamp"] ?? "",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoTile("Voltage", "${log["voltage"]} V",
                              Icons.battery_full, Colors.blue),
                          _buildInfoTile("Current", "${log["current"]} A",
                              Icons.electric_bolt, Colors.green),
                          _buildInfoTile("Temp", "${log["temperature"]} °C",
                              Icons.thermostat, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ Helper widget to style Voltage, Current, Temperature
  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
