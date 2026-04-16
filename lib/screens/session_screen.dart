import 'package:flutter/material.dart';

import '../models/plant_session_summary.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'settings_screen.dart';
import 'writeups_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final List<String> _plants = ['320', '340', '501', '810', '815'];

  String? _selectedPlant;
  List<PlantSessionSummary> _sessionSummaries = [];
  bool _isLoading = true;
  bool _isExportingCsv = false;

  @override
  void initState() {
    super.initState();
    _loadSessionSummaries();
  }

  Future<void> _loadSessionSummaries() async {
    setState(() {
      _isLoading = true;
    });

    final summaries = await DatabaseService().getPlantSessionSummaries();

    if (!mounted) return;

    setState(() {
      _sessionSummaries = summaries;
      _isLoading = false;
    });
  }

  Future<void> _startSession() async {
    if (_selectedPlant == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteupsScreen(plantNumber: _selectedPlant!),
      ),
    );

    await _loadSessionSummaries();
  }

  Future<void> _openPlantSession(String plantNumber) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteupsScreen(plantNumber: plantNumber),
      ),
    );

    await _loadSessionSummaries();
  }

  Future<void> _exportAccessCsv() async {
    try {
      setState(() {
        _isExportingCsv = true;
      });

      final String? result = await ExportService().exportAllWriteupsToCsv();

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export cancelled.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access CSV exported successfully.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (!mounted) return;

      setState(() {
        _isExportingCsv = false;
      });
    }
  }

  Future<void> _exportPlantPdf(String plantNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plant $plantNumber PDF export is next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnexportedWriteups = _sessionSummaries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Audit Capture'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessionSummaries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Start Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPlant,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select plant',
                      isDense: true,
                    ),
                    items: _plants
                        .map(
                          (plant) => DropdownMenuItem<String>(
                            value: plant,
                            child: Text('Plant $plant'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlant = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedPlant == null ? null : _startSession,
                    child: const Text('Start'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: hasUnexportedWriteups && !_isExportingCsv
                  ? _exportAccessCsv
                  : null,
              icon: _isExportingCsv
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download),
              label: const Text('Export All to Access CSV'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Unexported Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sessionSummaries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No unexported writeups found.'),
                ),
              )
            else
              ..._sessionSummaries.map(
                (summary) => Card(
                  child: ListTile(
                    title: Text('Plant ${summary.plantNumber}'),
                    subtitle: Text('${summary.writeupCount} writeups'),
                    onTap: () => _openPlantSession(summary.plantNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf),
                          onPressed: () => _exportPlantPdf(summary.plantNumber),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
