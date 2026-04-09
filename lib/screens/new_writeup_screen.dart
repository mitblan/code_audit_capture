import 'package:flutter/material.dart';
import '../models/audit_writeup.dart';

class NewWriteupScreen extends StatefulWidget {
  final String plantNumber;

  const NewWriteupScreen({super.key, required this.plantNumber});

  @override
  State<NewWriteupScreen> createState() => _NewWriteupScreenState();
}

class _NewWriteupScreenState extends State<NewWriteupScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveWriteup() {
    final text = _descriptionController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final writeup = AuditWriteup(
      plantNumber: widget.plantNumber,
      description: text,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, writeup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Write-up - Plant ${widget.plantNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Write-up description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveWriteup,
              child: const Text('Save Write-up'),
            ),
          ],
        ),
      ),
    );
  }
}
