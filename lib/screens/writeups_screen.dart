import 'package:flutter/material.dart';
import 'new_writeup_screen.dart';
import '../models/audit_writeup.dart';

class WriteupsScreen extends StatefulWidget {
  final String plantNumber;

  const WriteupsScreen({super.key, required this.plantNumber});

  @override
  State<WriteupsScreen> createState() => _WriteupsScreenState();
}

class _WriteupsScreenState extends State<WriteupsScreen> {
  final List<AuditWriteup> _writeups = [];

  Future<void> _goToNewWriteup() async {
    final result = await Navigator.push<AuditWriteup>(
      context,
      MaterialPageRoute(
        builder: (_) => NewWriteupScreen(plantNumber: widget.plantNumber),
      ),
    );

    if (result != null) {
      setState(() {
        _writeups.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plant ${widget.plantNumber} Write-ups')),
      body: _writeups.isEmpty
          ? const Center(child: Text('No write-ups yet'))
          : ListView.builder(
              itemCount: _writeups.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text('${index + 1}'),
                  title: Text('Plant ${_writeups[index].plantNumber}'),
                  subtitle: Text(_writeups[index].description),
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
