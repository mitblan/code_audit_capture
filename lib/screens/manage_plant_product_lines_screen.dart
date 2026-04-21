import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../models/product_line.dart';
import '../models/plant_product_line.dart';
import '../models/plant_product_line_option.dart';
import '../services/database_service.dart';

class ManagePlantProductLinesScreen extends StatefulWidget {
  const ManagePlantProductLinesScreen({super.key});

  @override
  State<ManagePlantProductLinesScreen> createState() =>
      _ManagePlantProductLinesScreenState();
}

class _ManagePlantProductLinesScreenState
    extends State<ManagePlantProductLinesScreen> {
  List<Plant> _plants = [];
  List<ProductLine> _allProductLines = [];
  List<PlantProductLineOption> _assignedLines = [];

  String? _selectedPlant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final plants = await DatabaseService().getAllPlants();
      final productLines = await DatabaseService().getAllProductLines();

      if (!mounted) return;

      setState(() {
        _plants = plants;
        _allProductLines = productLines;

        if (_selectedPlant == null && _plants.isNotEmpty) {
          _selectedPlant = _plants.first.plantNumber;
        } else if (_selectedPlant != null &&
            !_plants.any((p) => p.plantNumber == _selectedPlant)) {
          _selectedPlant = _plants.isNotEmpty
              ? _plants.first.plantNumber
              : null;
        }
      });

      await _loadAssignedLines();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _plants = [];
        _allProductLines = [];
        _assignedLines = [];
        _selectedPlant = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<void> _loadAssignedLines() async {
    if (_selectedPlant == null) {
      setState(() {
        _assignedLines = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assigned = await DatabaseService().getProductLinesForPlant(
        _selectedPlant!,
      );

      if (!mounted) return;

      setState(() {
        _assignedLines = assigned;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _assignedLines = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load assigned product lines: $e')),
      );
    }
  }

  Future<void> _showAddAssignmentDialog() async {
    if (_selectedPlant == null) return;

    final assignedIds = _assignedLines.map((e) => e.productLineId).toSet();

    final availableLines = _allProductLines
        .where((line) => !assignedIds.contains(line.id))
        .toList();

    if (availableLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All product lines are already assigned to this plant.',
          ),
        ),
      );
      return;
    }

    ProductLine? selectedLine = availableLines.first;
    bool isDefault = _assignedLines.isEmpty;

    final result = await showDialog<_AddPlantProductLineResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Product Line'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProductLine>(
                    value: selectedLine,
                    decoration: const InputDecoration(
                      labelText: 'Product Line',
                      border: OutlineInputBorder(),
                    ),
                    items: availableLines
                        .map(
                          (line) => DropdownMenuItem<ProductLine>(
                            value: line,
                            child: Text(line.code),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLine = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Default for this plant'),
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
                    if (selectedLine == null) return;

                    Navigator.of(dialogContext).pop(
                      _AddPlantProductLineResult(
                        productLineId: selectedLine!.id!,
                        isDefault: isDefault,
                      ),
                    );
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || _selectedPlant == null) return;

    try {
      await DatabaseService().assignProductLineToPlant(
        _selectedPlant!,
        result.productLineId,
        isDefault: result.isDefault,
      );

      if (!mounted) return;

      await _loadAssignedLines();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product line assigned.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment already exists.')),
      );
    }
  }

  Future<void> _setDefault(PlantProductLineOption option) async {
    try {
      await DatabaseService().updatePlantProductLine(
        PlantProductLine(
          id: option.assignmentId,
          plantNumber: option.plantNumber,
          productLineId: option.productLineId,
          isDefault: true,
        ),
      );

      if (!mounted) return;

      await _loadAssignedLines();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Default updated.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update default: $e')));
    }
  }

  Future<void> _removeAssignment(PlantProductLineOption option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Product Line'),
          content: Text(
            'Remove "${option.code}" from Plant ${option.plantNumber}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DatabaseService().removeProductLineFromPlant(option.assignmentId);

      if (!mounted) return;

      await _loadAssignedLines();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assignment removed.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove assignment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPlants = _plants.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Product Lines to Plants')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasPlants ? _showAddAssignmentDialog : null,
        icon: const Icon(Icons.add),
        label: const Text('Assign'),
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
                      await _loadAssignedLines();
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
                : _assignedLines.isEmpty
                ? const Center(
                    child: Text('No product lines assigned to this plant.'),
                  )
                : ListView.separated(
                    itemCount: _assignedLines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = _assignedLines[index];

                      return ListTile(
                        title: Text(option.code),
                        subtitle: option.isDefault
                            ? const Text('Default')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!option.isDefault)
                              IconButton(
                                icon: const Icon(Icons.star_outline),
                                tooltip: 'Set Default',
                                onPressed: () => _setDefault(option),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Remove',
                              onPressed: () => _removeAssignment(option),
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

class _AddPlantProductLineResult {
  final int productLineId;
  final bool isDefault;

  const _AddPlantProductLineResult({
    required this.productLineId,
    required this.isDefault,
  });
}
