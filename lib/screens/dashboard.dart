import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(); // root reference

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("⚡ BMS Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded, color: Colors.blueAccent),
            tooltip: 'View Charts',
            onPressed: () {
              Navigator.pushNamed(context, '/charts');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade400,
        onPressed: () {
          Navigator.pushNamed(context, '/charts');
        },
        icon: const Icon(Icons.bar_chart_rounded),
        label: const Text('View Charts'),
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No BMS logs found"));
          }

          Map<dynamic, dynamic> data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Handle root node structure
          Map<dynamic, dynamic> logs = {};
          if (data.containsKey("bms_logs")) {
            logs = Map<dynamic, dynamic>.from(data["bms_logs"]);
          } else {
            logs = data;
          }

          List<MapEntry<dynamic, dynamic>> logList = logs.entries.toList();
          logList.sort((a, b) => b.key.toString().compareTo(a.key.toString())); // latest first

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logList.length,
            itemBuilder: (context, index) {
              final logKey = logList[index].key;
              final logData = Map<String, dynamic>.from(logList[index].value);

              final current = logData['current'] ?? 'N/A';
              final soc = logData['soc'] ?? 'N/A';
              final voltage = logData['voltage'] ?? 'N/A';
              final tempMax = logData['tempMax'] ?? logData['tempmax'] ?? 'N/A';
              final tempMin = logData['tempMin'] ?? logData['tempmin'] ?? 'N/A';
              final timestamp = logData['timestamp'] ?? 'N/A';

              final cellVoltages = logData['cellVoltages'] != null
                  ? Map<String, dynamic>.from(logData['cellVoltages'])
                  : {};

              // ✅ Sort cell voltages by ascending cell number
              final sortedCells = cellVoltages.entries.toList()
                ..sort((a, b) {
                  final cellA = int.tryParse(a.key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  final cellB = int.tryParse(b.key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  return cellA.compareTo(cellB);
                });

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      "📘 Log: $logKey",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Timestamp: $timestamp",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    children: [
                      _buildDataRow("Current", "$current A"),
                      _buildDataRow("SOC", "$soc %"),
                      _buildDataRow("Voltage", "$voltage V"),
                      _buildDataRow("Temp Max", "$tempMax °C"),
                      _buildDataRow("Temp Min", "$tempMin °C"),
                      const SizedBox(height: 10),
                      if (sortedCells.isNotEmpty) ...[
                        const Text(
                          "Cell Voltages:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: sortedCells
                              .map((entry) => Chip(
                                    label: Text(
                                        "${entry.key}: ${entry.value.toString()} V"),
                                    backgroundColor: Colors.blue.shade50,
                                  ))
                              .toList(),
                        ),
                      ] else
                        const Text(
                          "No cell voltages available",
                          style: TextStyle(color: Colors.redAccent),
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

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
