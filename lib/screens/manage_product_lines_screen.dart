import 'package:flutter/material.dart';
import '../models/product_line.dart';
import '../services/database_service.dart';

class ManageProductLinesScreen extends StatefulWidget {
  const ManageProductLinesScreen({super.key});

  @override
  State<ManageProductLinesScreen> createState() =>
      _ManageProductLinesScreenState();
}

class _ManageProductLinesScreenState extends State<ManageProductLinesScreen> {
  List<ProductLine> _productLines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductLines();
  }

  Future<void> _loadProductLines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lines = await DatabaseService().getAllProductLines();

      if (!mounted) return;

      setState(() {
        _productLines = lines;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _productLines = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product lines: $e')),
      );
    }
  }

  Future<void> _showDialog({ProductLine? existing}) async {
    final controller = TextEditingController(text: existing?.code ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Add Product Line' : 'Edit Product Line',
          ),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Code (2 characters)',
              border: OutlineInputBorder(),
            ),
            maxLength: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim().toUpperCase();
                if (value.isEmpty) return;

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      if (existing == null) {
        await DatabaseService().insertProductLine(ProductLine(code: result));
      } else {
        await DatabaseService().updateProductLine(
          existing.copyWith(code: result),
        );
      }

      if (!mounted) return;

      await _loadProductLines();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Product line added.' : 'Product line updated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Code already exists.')));
    }
  }

  Future<void> _delete(ProductLine line) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product Line'),
          content: Text('Delete "${line.code}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DatabaseService().deleteProductLine(line.id!);

      if (!mounted) return;

      await _loadProductLines();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleted.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Product Lines')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _productLines.isEmpty
          ? const Center(child: Text('No product lines found.'))
          : ListView.separated(
              itemCount: _productLines.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final line = _productLines[index];

                return ListTile(
                  title: Text(line.code),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showDialog(existing: line),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(line),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
