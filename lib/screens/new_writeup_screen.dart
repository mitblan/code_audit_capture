import 'package:flutter/material.dart';
import '../models/audit_writeup.dart';
import '../services/database_service.dart';

class NewWriteupScreen extends StatefulWidget {
  final String plantNumber;
  final AuditWriteup? existingWriteup;

  const NewWriteupScreen({
    super.key,
    required this.plantNumber,
    this.existingWriteup,
  });

  @override
  State<NewWriteupScreen> createState() => _NewWriteupScreenState();
}

class _NewWriteupScreenState extends State<NewWriteupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeReferenceController =
      TextEditingController();
  final TextEditingController _disciplineController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.existingWriteup != null) {
      _codeReferenceController.text = widget.existingWriteup!.codeReference;
      _disciplineController.text = widget.existingWriteup!.discipline;
      _descriptionController.text = widget.existingWriteup!.description;
    }
  }

  @override
  void dispose() {
    _codeReferenceController.dispose();
    _disciplineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveWriteup() async {
    try {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
        return;
      }

      final writeup = AuditWriteup(
        id: widget.existingWriteup?.id,
        plantNumber: widget.plantNumber,
        codeReference: _codeReferenceController.text.trim(),
        discipline: _disciplineController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.existingWriteup?.createdAt ?? DateTime.now(),
      );

      if (widget.existingWriteup == null) {
        await DatabaseService().insertWriteup(writeup);
      } else {
        await DatabaseService().updateWriteup(writeup);
      }

      if (mounted) {
        Navigator.pop(context, writeup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingWriteup == null
              ? 'New Write-up - Plant ${widget.plantNumber}'
              : 'Edit Write-up - Plant ${widget.plantNumber}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeReferenceController,
                decoration: const InputDecoration(
                  labelText: 'Code Reference',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a code reference';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _disciplineController,
                decoration: const InputDecoration(
                  labelText: 'Discipline',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a discipline';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveWriteup,
                  child: const Text('Save Write-up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
