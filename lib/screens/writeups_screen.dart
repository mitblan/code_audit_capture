import 'package:flutter/material.dart';
import 'new_writeup_screen.dart';
import '../models/audit_writeup.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';

class WriteupsScreen extends StatefulWidget {
  final String plantNumber;

  const WriteupsScreen({super.key, required this.plantNumber});

  @override
  State<WriteupsScreen> createState() => _WriteupsScreenState();
}

class _WriteupsScreenState extends State<WriteupsScreen> {
  List<AuditWriteup> _writeups = [];

  @override
  void initState() {
    super.initState();
    _loadWriteups();
  }

  Future<void> _loadWriteups() async {
    final data = await DatabaseService().getWriteupsByPlant(widget.plantNumber);

    setState(() {
      _writeups = data;
    });
  }

  Future<void> _goToNewWriteup() async {
    await Navigator.push<AuditWriteup>(
      context,
      MaterialPageRoute(
        builder: (_) => NewWriteupScreen(plantNumber: widget.plantNumber),
      ),
    );

    await _loadWriteups();
  }

  Future<void> _editWriteup(AuditWriteup writeup) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewWriteupScreen(
          plantNumber: widget.plantNumber,
          existingWriteup: writeup,
        ),
      ),
    );

    await _loadWriteups();
  }

  Future<void> _exportWriteups() async {
    try {
      final filePath = await ExportService().exportAllWriteupsToCsv();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported to: $filePath'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant ${widget.plantNumber} Write-ups'),
        actions: [
          IconButton(
            onPressed: _exportWriteups,
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: _writeups.isEmpty
          ? const Center(
              child: Text('No write-ups entered for this session yet.'),
            )
          : ListView.builder(
              itemCount: _writeups.length,
              itemBuilder: (context, index) {
                final writeup = _writeups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(writeup.newCodeReference),
                    subtitle: Text(
                      '${writeup.category}\n${writeup.nonConformanceNo}',
                    ),
                    isThreeLine: true,
                    onTap: () => _editWriteup(writeup),
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Write-up'),
                          content: const Text(
                            'Are you sure you want to delete this write-up?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && writeup.id != null) {
                        await DatabaseService().deleteWriteup(writeup.id!);
                        await _loadWriteups();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Write-up deleted')),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNewWriteup,
        child: const Icon(Icons.add),
      ),
    );
  }
}
