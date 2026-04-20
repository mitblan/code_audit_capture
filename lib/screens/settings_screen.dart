import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/rvia_import_service.dart';
import 'manage_plants_screen.dart';
import 'manage_departments.screen.dart';
import 'manage_unit_prefixes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _rviaCount = 0;
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadRviaCount();
  }

  Future<void> _loadRviaCount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await DatabaseService().getRviaCodeCount();

      if (!mounted) return;

      setState(() {
        _rviaCount = count;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _rviaCount = 0;
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load RVIA count: $e')));
    }
  }

  Future<void> _importRviaCsv() async {
    try {
      setState(() {
        _isImporting = true;
      });

      final importedCount = await RviaImportService().importFromCsvFile();

      if (!mounted) return;

      if (importedCount == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('RVIA import cancelled.')));
      } else {
        await _loadRviaCount();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $importedCount RVIA records successfully.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RVIA import failed: $e'),
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rviaStatusText = _isLoading
        ? 'Loading...'
        : _rviaCount > 0
        ? '$_rviaCount RVIA records loaded'
        : 'Using bundled sample RVIA data';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RVIA Database',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(rviaStatusText),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importRviaCsv,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: const Text('Import RVIA CSV'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Manage Plants'),
              subtitle: const Text('Add, edit, or delete plant numbers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagePlantsScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('Manage Unit Prefixes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageUnitPrefixesScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Manage Departments'),
              subtitle: const Text('Add, edit, or delete department options'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageDepartmentsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
