import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../models/plant_unit_prefix.dart';
import '../services/database_service.dart';

class ManageUnitPrefixesScreen extends StatefulWidget {
  const ManageUnitPrefixesScreen({super.key});

  @override
  State<ManageUnitPrefixesScreen> createState() =>
      _ManageUnitPrefixesScreenState();
}

class _ManageUnitPrefixesScreenState extends State<ManageUnitPrefixesScreen> {
  List<Plant> _plants = [];
  List<PlantUnitPrefix> _prefixes = [];

  String? _selectedPlant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await DatabaseService().getAllPlants();

      if (!mounted) return;

      setState(() {
        _plants = plants;

        if (_selectedPlant == null && plants.isNotEmpty) {
          _selectedPlant = plants.first.plantNumber;
        }
      });

      if (_selectedPlant != null) {
        await _loadPrefixes();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load plants: $e')));
    }
  }

  Future<void> _loadPrefixes() async {
    if (_selectedPlant == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefixes = await DatabaseService().getPrefixesForPlant(
        _selectedPlant!,
      );

      if (!mounted) return;

      setState(() {
        _prefixes = prefixes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _prefixes = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _showPrefixDialog({PlantUnitPrefix? prefix}) async {
    final controller = TextEditingController(text: prefix?.prefix ?? '');

    bool isDefault = prefix?.isDefault ?? false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(prefix == null ? 'Add Prefix' : 'Edit Prefix'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Prefix',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Default'),
                    value: isDefault,
                    onChanged: (value) {
                      setDialogState(() {
                        isDefault = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final value = controller.text.trim().toUpperCase();

                    if (value.isEmpty) return;

                    try {
                      if (prefix == null) {
                        await DatabaseService().insertPlantUnitPrefix(
                          PlantUnitPrefix(
                            plantNumber: _selectedPlant!,
                            prefix: value,
                            isDefault: isDefault,
                          ),
                        );
                      } else {
                        await DatabaseService().updatePlantUnitPrefix(
                          prefix.copyWith(prefix: value, isDefault: isDefault),
                        );
                      }

                      if (!mounted) return;

                      Navigator.pop(context);
                      await _loadPrefixes();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prefix may already exist.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _deletePrefix(PlantUnitPrefix prefix) async {
    await DatabaseService().deletePlantUnitPrefix(prefix.id!);
    await _loadPrefixes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Unit Prefixes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPrefixDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedPlant,
              decoration: const InputDecoration(
                labelText: 'Plant',
                border: OutlineInputBorder(),
              ),
              items: _plants
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.plantNumber,
                      child: Text('Plant ${p.plantNumber}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedPlant = value;
                });
                await _loadPrefixes();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prefixes.isEmpty
                ? const Center(child: Text('No prefixes found.'))
                : ListView.builder(
                    itemCount: _prefixes.length,
                    itemBuilder: (context, index) {
                      final prefix = _prefixes[index];

                      return ListTile(
                        title: Text(prefix.prefix),
                        subtitle: prefix.isDefault
                            ? const Text('Default')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showPrefixDialog(prefix: prefix),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deletePrefix(prefix),
                            ),
                          ],
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
