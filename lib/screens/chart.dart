import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() {
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        Map<dynamic, dynamic> logsData =
            data.containsKey("bms_logs") ? data["bms_logs"] : data;

        List<Map<String, dynamic>> temp = [];
        logsData.forEach((key, value) {
          final log = Map<String, dynamic>.from(value);
          temp.add({
            "key": key,
            "voltage": (log["voltage"] ?? 0).toDouble(),
            "current": (log["current"] ?? 0).toDouble(),
            "soc": (log["soc"] ?? 0).toDouble(),
            "tempMax": (log["tempMax"] ?? log["tempmax"] ?? 0).toDouble(),
            "tempMin": (log["tempMin"] ?? log["tempmin"] ?? 0).toDouble(),
            // ensure a timestamp field exists (fallback to key string)
            "timestamp": log["timestamp"] ?? key.toString(),
          });
        });

        temp.sort((a, b) => a["key"].compareTo(b["key"])); // oldest first
        setState(() => logs = temp);
      }
    });
  }

  // Format timestamp to HH:mm:ss safely (supports int ms, double ms, ISO string, or fallback)
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      if (ts is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        return _twoDigits(dt.hour) + ':' + _twoDigits(dt.minute) + ':' + _twoDigits(dt.second);
      }
      if (ts is double) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
        return _twoDigits(dt.hour) + ':' + _twoDigits(dt.minute) + ':' + _twoDigits(dt.second);
      }
      final s = ts.toString();
      if (RegExp(r'^\d+$').hasMatch(s)) {
        final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(s));
        return _twoDigits(dt.hour) + ':' + _twoDigits(dt.minute) + ':' + _twoDigits(dt.second);
      }
      final dt = DateTime.tryParse(s);
      if (dt != null) {
        return _twoDigits(dt.hour) + ':' + _twoDigits(dt.minute) + ':' + _twoDigits(dt.second);
      }
      // fallback: show last part of string (push key or short id)
      return s.length > 8 ? s.substring(s.length - 8) : s;
    } catch (e) {
      return ts.toString();
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 BMS Charts"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildChartSection("Voltage (V)", Colors.orange, "voltage", 0, 60),
                  const SizedBox(height: 25),
                  _buildChartSection("Current (A)", Colors.green, "current", 0, 50),
                  const SizedBox(height: 25),
                  _buildChartSection("SOC (%)", Colors.blue, "soc", 0, 100),
                  const SizedBox(height: 25),
                  _buildChartSection("Temperature (°C)", Colors.red, "tempMax", 0, 100,
                      secondKey: "tempMin"),
                ],
              ),
            ),
    );
  }

  Widget _buildChartSection(String title, Color color, String key, double minY, double maxY,
      {String? secondKey}) {
    final xInterval = (logs.length / 5).clamp(1.0, 10.0).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY - minY) / 5,
                    verticalInterval: xInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.black, width: 1),
                        left: BorderSide(color: Colors.black, width: 1),
                        right: BorderSide(color: Colors.transparent),
                        top: BorderSide(color: Colors.transparent),
                      )),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: xInterval,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= logs.length) return const SizedBox.shrink();
                          final label = _formatTimestamp(logs[index]["timestamp"]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: logs.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), (entry.value[key] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    if (secondKey != null)
                      LineChartBarData(
                        spots: logs.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), (entry.value[secondKey] ?? 0).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Colors.orangeAccent,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
