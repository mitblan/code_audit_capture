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
    setState(() {
      _isLoading = true;
    });

    try {
      final plants = await DatabaseService().getAllPlants();

      if (!mounted) return;

      setState(() {
        _plants = plants;

        if (_selectedPlant == null && _plants.isNotEmpty) {
          _selectedPlant = _plants.first.plantNumber;
        } else if (_selectedPlant != null &&
            !_plants.any((p) => p.plantNumber == _selectedPlant)) {
          _selectedPlant = _plants.isNotEmpty
              ? _plants.first.plantNumber
              : null;
        }
      });

      await _loadPrefixes();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _plants = [];
        _prefixes = [];
        _selectedPlant = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load plants: $e')));
    }
  }

  Future<void> _loadPrefixes() async {
    if (_selectedPlant == null) {
      setState(() {
        _prefixes = [];
        _isLoading = false;
      });
      return;
    }

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load prefixes: $e')));
    }
  }

  Future<void> _showPrefixDialog({PlantUnitPrefix? existingPrefix}) async {
    final result = await showDialog<_PrefixDialogResult>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(
          text: existingPrefix?.prefix ?? '',
        );
        bool isDefault = existingPrefix?.isDefault ?? false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                existingPrefix == null ? 'Add Prefix' : 'Edit Prefix',
              ),
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
                    contentPadding: EdgeInsets.zero,
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final prefixValue = controller.text.trim().toUpperCase();

                    if (prefixValue.isEmpty) return;

                    Navigator.of(dialogContext).pop(
                      _PrefixDialogResult(
                        prefix: prefixValue,
                        isDefault: isDefault,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || _selectedPlant == null) return;

    try {
      if (existingPrefix == null) {
        await DatabaseService().insertPlantUnitPrefix(
          PlantUnitPrefix(
            plantNumber: _selectedPlant!,
            prefix: result.prefix,
            isDefault: result.isDefault,
          ),
        );
      } else {
        await DatabaseService().updatePlantUnitPrefix(
          existingPrefix.copyWith(
            prefix: result.prefix,
            isDefault: result.isDefault,
          ),
        );
      }

      if (!mounted) return;

      await _loadPrefixes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingPrefix == null ? 'Prefix added.' : 'Prefix updated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prefix may already exist for this plant.'),
        ),
      );
    }
  }

  Future<void> _deletePrefix(PlantUnitPrefix prefix) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Prefix'),
          content: Text(
            'Delete "${prefix.prefix}" from Plant ${prefix.plantNumber}?',
          ),
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
      await DatabaseService().deletePlantUnitPrefix(prefix.id!);

      if (!mounted) return;

      await _loadPrefixes();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prefix deleted.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete prefix: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPlants = _plants.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Unit Prefixes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasPlants ? () => _showPrefixDialog() : null,
        icon: const Icon(Icons.add),
        label: const Text('Add Prefix'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedPlant,
              decoration: const InputDecoration(
                labelText: 'Plant',
                border: OutlineInputBorder(),
              ),
              items: _plants
                  .map(
                    (plant) => DropdownMenuItem<String>(
                      value: plant.plantNumber,
                      child: Text('Plant ${plant.plantNumber}'),
                    ),
                  )
                  .toList(),
              onChanged: !hasPlants
                  ? null
                  : (value) async {
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
                : !hasPlants
                ? const Center(
                    child: Text('No plants found. Add a plant first.'),
                  )
                : _prefixes.isEmpty
                ? const Center(child: Text('No prefixes found for this plant.'))
                : ListView.separated(
                    itemCount: _prefixes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
                              tooltip: 'Edit',
                              onPressed: () =>
                                  _showPrefixDialog(existingPrefix: prefix),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
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

class _PrefixDialogResult {
  final String prefix;
  final bool isDefault;

  const _PrefixDialogResult({required this.prefix, required this.isDefault});
}
