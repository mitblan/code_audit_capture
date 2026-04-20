import 'package:flutter/material.dart';
import '../models/departments.dart';
import '../services/database_service.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  const ManageDepartmentsScreen({super.key});

  @override
  State<ManageDepartmentsScreen> createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  List<Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final departments = await DatabaseService().getAllDepartments();

      if (!mounted) return;

      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _departments = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load departments: $e')));
    }
  }

  Future<void> _showDepartmentDialog({Department? department}) async {
    final controller = TextEditingController(text: department?.name ?? '');

    final isEditing = department != null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Department' : 'Add Department'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Department Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department name cannot be empty.'),
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await DatabaseService().updateDepartment(
                      department.copyWith(name: name),
                    );
                  } else {
                    await DatabaseService().insertDepartment(
                      Department(name: name),
                    );
                  }

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  await _loadDepartments();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing ? 'Department updated.' : 'Department added.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not save department. It may already exist.',
                      ),
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _deleteDepartment(Department department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content: Text(
            'Delete "${department.name}" from the department list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DatabaseService().deleteDepartment(department.id!);

      if (!mounted) return;

      await _loadDepartments();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Department deleted.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete department: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Departments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDepartmentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Department'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
          ? const Center(
              child: Text('No departments found. Add one to get started.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _departments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final department = _departments[index];

                return Card(
                  child: ListTile(
                    title: Text(department.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showDepartmentDialog(department: department),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                          onPressed: () => _deleteDepartment(department),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
