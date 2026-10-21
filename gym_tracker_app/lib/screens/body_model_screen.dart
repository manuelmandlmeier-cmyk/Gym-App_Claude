import 'package:flutter/material.dart';
import '../models/body_model.dart';
import '../services/storage_service.dart';
import '../widgets/body_wireframe_3d.dart';

class BodyModelScreen extends StatefulWidget {
  const BodyModelScreen({super.key});

  @override
  State<BodyModelScreen> createState() => _BodyModelScreenState();
}

class _BodyModelScreenState extends State<BodyModelScreen> {
  final StorageService _storage = StorageService();
  BodyMeasurements _measurements = BodyMeasurements(date: DateTime.now());
  Map<MuscleGroup, double> _heatmap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final m = await _storage.getLatestMeasurements();
    final h = await _storage.getMuscleHeatmapLast7Days();
    if (!mounted) return;
    setState(() {
      _measurements = m;
      _heatmap = h;
      _isLoading = false;
    });
  }

  void _editMeasurements() {
    final chestController = TextEditingController(text: _measurements.chestCm.toString());
    final waistController = TextEditingController(text: _measurements.waistCm.toString());
    final shouldersController = TextEditingController(text: _measurements.shouldersCm.toString());
    final bicepsController = TextEditingController(text: _measurements.bicepsCm.toString());
    final thighsController = TextEditingController(text: _measurements.thighsCm.toString());

    double parse(TextEditingController c, double fallback) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? fallback;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Körpermaße anpassen (cm)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                    controller: shouldersController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Schulterumfang (cm)')),
                TextField(
                    controller: chestController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Brustumfang (cm)')),
                TextField(
                    controller: waistController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Taillenumfang (cm)')),
                TextField(
                    controller: bicepsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Oberarmumfang (cm)')),
                TextField(
                    controller: thighsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Oberschenkelumfang (cm)')),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    _measurements.shouldersCm = parse(shouldersController, _measurements.shouldersCm);
                    _measurements.chestCm = parse(chestController, _measurements.chestCm);
                    _measurements.waistCm = parse(waistController, _measurements.waistCm);
                    _measurements.bicepsCm = parse(bicepsController, _measurements.bicepsCm);
                    _measurements.thighsCm = parse(thighsController, _measurements.thighsCm);

                    await _storage.saveMeasurements(_measurements);
                    if (!mounted || !sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    _loadData();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Modell aktualisieren'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Körpermodell & Heatmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editMeasurements,
            tooltip: 'Maße anpassen',
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 380,
            width: double.infinity,
            color: Colors.black26,
            child: Stack(
              children: [
                BodyWireframe3D(measurements: _measurements, muscleHeatmap: _heatmap),
                const Positioned(
                  bottom: 12,
                  left: 12,
                  child: Text('💡 Drehen: Wischen auf dem Modell',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Muskel-Belastung (Letzte 7 Tage)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(color: Color(0xFF4A5568), label: 'Erholt'),
                    _LegendItem(color: Color(0xFF38A169), label: 'Leicht'),
                    _LegendItem(color: Color(0xFFDD6B20), label: 'Optimal'),
                    _LegendItem(color: Color(0xFFE53E3E), label: 'Hoch'),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.straighten, color: Colors.cyanAccent),
                    title: const Text('Aktuelle Proportionen'),
                    subtitle: Text(
                        'Schulter: ${_measurements.shouldersCm}cm • Brust: ${_measurements.chestCm}cm • Taille: ${_measurements.waistCm}cm • Arm: ${_measurements.bicepsCm}cm'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _editMeasurements,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
