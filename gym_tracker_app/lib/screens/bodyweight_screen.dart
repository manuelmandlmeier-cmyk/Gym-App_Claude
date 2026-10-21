import 'package:flutter/material.dart';
import '../models/workout_set.dart';
import '../services/storage_service.dart';
import 'body_model_screen.dart';

class BodyweightScreen extends StatefulWidget {
  const BodyweightScreen({super.key});

  @override
  State<BodyweightScreen> createState() => _BodyweightScreenState();
}

class _BodyweightScreenState extends State<BodyweightScreen> {
  final StorageService _storage = StorageService();
  List<BodyweightEntry> _entries = [];
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _storage.getBodyweightEntries();
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      _showMessage('Laden fehlgeschlagen: $e');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 8)));
  }

  Future<void> _addWeight() async {
    final val = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (val == null || val <= 0) {
      _showMessage('Bitte ein gültiges Gewicht eingeben, z. B. 85,5');
      return;
    }
    try {
      await _storage.saveBodyweightEntry(BodyweightEntry(date: DateTime.now(), weightKg: val));
      _weightController.clear();
      await _loadEntries();
    } catch (e) {
      _showMessage('Speichern fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Körpergewichts-Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            tooltip: '3D-Körpermodell & Heatmap',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyModelScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Aktuelles Gewicht (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addWeight,
                  icon: const Icon(Icons.add),
                  label: const Text('Eintragen'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Verlauf', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text('Noch keine Einträge vorhanden.'))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.monitor_weight, color: Colors.blue),
                            title: Text('${entry.weightKg} kg',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${entry.date.day}.${entry.date.month}.${entry.date.year}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
