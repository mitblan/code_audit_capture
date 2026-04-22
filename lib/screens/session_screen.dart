import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../models/plant_session_summary.dart';
import '../services/code_comp_export_service.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/session_pdf_export_service.dart';
import 'settings_screen.dart';
import 'writeups_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<Plant> _plants = [];
  String? _selectedPlant;
  List<PlantSessionSummary> _sessionSummaries = [];
  List<PlantSessionSummary> _fullyExportedSessionSummaries = [];
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

    try {
      final summaries = await DatabaseService().getPlantSessionSummaries();
      final fullyExportedSummaries = await DatabaseService()
          .getFullyExportedPlantSessionSummaries();
      final plants = await DatabaseService().getAllPlants();

      if (!mounted) return;

      setState(() {
        _sessionSummaries = summaries;
        _fullyExportedSessionSummaries = fullyExportedSummaries;
        _plants = plants;

        final validPlantNumbers = _plants.map((p) => p.plantNumber).toSet();

        if (_selectedPlant != null &&
            !validPlantNumbers.contains(_selectedPlant)) {
          _selectedPlant = null;
        }

        if (_selectedPlant == null && _plants.isNotEmpty) {
          _selectedPlant = _plants.first.plantNumber;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sessionSummaries = [];
        _fullyExportedSessionSummaries = [];
        _plants = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load sessions: $e')));
    }
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

  Future<void> _exportAllCsvs() async {
    try {
      setState(() {
        _isExportingCsv = true;
      });

      final folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose folder for exported CSV files',
      );

      if (!mounted) return;

      if (folderPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export cancelled.')));
        return;
      }

      final dbImportPath = await ExportService().exportAllWriteupsToFolder(
        folderPath,
      );

      final ccImportPath = await CodeCompExportService()
          .exportAllWriteupsToFolder(folderPath);

      if (!mounted) return;

      await _loadSessionSummaries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported:\n$dbImportPath\n$ccImportPath'),
          duration: const Duration(seconds: 6),
        ),
      );
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

  Future<void> _purgeExportedWriteups() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Purge Fully Exported Write-ups'),
          content: const Text(
            'This will permanently delete only write-ups that have been exported to all three destinations:\n\n'
            '• Plant PDF\n'
            '• DBImport CSV\n'
            '• CCImport CSV\n\n'
            'Any write-up missing even one export will be kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Purge'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final deletedCount = await DatabaseService().purgeFullyExportedWriteups();

      if (!mounted) return;

      await _loadSessionSummaries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedCount == 0
                ? 'No fully exported write-ups were eligible to purge.'
                : 'Purged $deletedCount fully exported write-ups.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Purge failed: $e')));
    }
  }

  Future<void> _exportPlantPdf(String plantNumber) async {
    try {
      final result = await SessionPdfExportService().exportPlantSessionPdf(
        plantNumber,
      );

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF export cancelled.')));
      } else {
        await _loadSessionSummaries();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved successfully.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  Future<void> _showResetExportFlagsDialog(String plantNumber) async {
    bool resetPdf = false;
    bool resetCsv = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Reset Export Flags - Plant $plantNumber'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: resetPdf,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('PDF export'),
                    onChanged: (value) {
                      setDialogState(() {
                        resetPdf = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: resetCsv,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('CSV exports'),
                    subtitle: const Text('Resets both DBImport and CCImport'),
                    onChanged: (value) {
                      setDialogState(() {
                        resetCsv = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: (resetPdf || resetCsv)
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text('Reset Selected'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      final updatedCount = await DatabaseService().resetExportFlagsForPlant(
        plantNumber,
        resetPdf: resetPdf,
        resetDb: resetCsv,
        resetCc: resetCsv,
        onlyFullyExported: true,
      );

      if (!mounted) return;

      await _loadSessionSummaries();

      final parts = <String>[];
      if (resetPdf) parts.add('PDF');
      if (resetCsv) parts.add('CSV');
      final resetSummary = parts.join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedCount == 0
                ? 'No fully exported write-ups were updated for Plant $plantNumber.'
                : 'Reset $resetSummary flags for $updatedCount write-ups in Plant $plantNumber.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset export flags failed: $e')));
    }
  }

  List<Widget> _buildPendingExportChips(PlantSessionSummary summary) {
    final chips = <Widget>[];

    if (summary.pendingPdfCount > 0) {
      chips.add(_buildStatusChip('PDF ${summary.pendingPdfCount}'));
    }

    final pendingCsvCount = summary.pendingDbCount > summary.pendingCcCount
        ? summary.pendingDbCount
        : summary.pendingCcCount;

    if (pendingCsvCount > 0) {
      chips.add(_buildStatusChip('CSV $pendingCsvCount'));
    }

    return chips;
  }

  Widget _buildStatusChip(String label) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  List<Widget> _buildCompletedExportChips() {
    return const [
      Chip(
        label: Text('PDF ✓'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      Chip(
        label: Text('CSV ✓'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ];
  }

  Widget _buildSummarySubtitle(
    PlantSessionSummary summary, {
    required bool fullyExported,
  }) {
    final chips = fullyExported
        ? _buildCompletedExportChips()
        : _buildPendingExportChips(summary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${summary.writeupCount} writeups'),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnexportedWriteups = _sessionSummaries.isNotEmpty;
    final hasFullyExportedWriteups = _fullyExportedSessionSummaries.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Audit Capture'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );

              await _loadSessionSummaries();
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
                    value: _selectedPlant,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select plant',
                      isDense: true,
                    ),
                    items: _plants
                        .map(
                          (plant) => DropdownMenuItem<String>(
                            value: plant.plantNumber,
                            child: Text('Plant ${plant.plantNumber}'),
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
                  ? _exportAllCsvs
                  : null,
              icon: _isExportingCsv
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download),
              label: const Text('Export CSV Files'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: hasFullyExportedWriteups && !_isExportingCsv
                  ? _purgeExportedWriteups
                  : null,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Purge Fully Exported Write-ups'),
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
                    subtitle: _buildSummarySubtitle(
                      summary,
                      fullyExported: false,
                    ),
                    isThreeLine: true,
                    onTap: () => _openPlantSession(summary.plantNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Export plant PDF',
                          icon: const Icon(Icons.picture_as_pdf),
                          onPressed: () => _exportPlantPdf(summary.plantNumber),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Fully Exported Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const SizedBox.shrink()
            else if (_fullyExportedSessionSummaries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No fully exported writeups found.'),
                ),
              )
            else
              ..._fullyExportedSessionSummaries.map(
                (summary) => Card(
                  child: ListTile(
                    title: Text('Plant ${summary.plantNumber}'),
                    subtitle: _buildSummarySubtitle(
                      summary,
                      fullyExported: true,
                    ),
                    isThreeLine: true,
                    onTap: () => _openPlantSession(summary.plantNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Reset export flags',
                          icon: const Icon(Icons.restart_alt),
                          onPressed: () =>
                              _showResetExportFlagsDialog(summary.plantNumber),
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
