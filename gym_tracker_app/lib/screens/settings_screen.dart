import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _msg(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export(BuildContext context) async {
    final json = await StorageService().exportAll();
    await Clipboard.setData(ClipboardData(text: json));
    _msg(context, 'Backup in die Zwischenablage kopiert. Füge es z. B. in eine Notiz ein.');
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daten wiederherstellen'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Backup-Text hier einfügen',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Wiederherstellen')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await StorageService().importAll(controller.text);
      _msg(context, 'Backup wiederhergestellt. Wechsle den Tab, um die Daten neu zu laden.');
    } catch (_) {
      _msg(context, 'Das Backup konnte nicht gelesen werden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen & Backup')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Daten exportieren'),
            subtitle: const Text('Kopiert deine Trainingshistorie als Text in die Zwischenablage'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Daten wiederherstellen'),
            subtitle: const Text('Backup-Text einfügen und einlesen'),
            onTap: () => _import(context),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Über die App'),
            subtitle: Text('Kraftsport App v1.1.0 (Offline First)'),
          ),
        ],
      ),
    );
  }
}
