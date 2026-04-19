import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/database_service.dart';

class ManagePlantsScreen extends StatefulWidget {
  const ManagePlantsScreen({super.key});

  @override
  State<ManagePlantsScreen> createState() => _ManagePlantsScreenState();
}

class _ManagePlantsScreenState extends State<ManagePlantsScreen> {
  List<Plant> _plants = [];
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
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _plants = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load plants: $e')));
    }
  }

  Future<void> _showPlantDialog({Plant? plant}) async {
    final controller = TextEditingController(text: plant?.plantNumber ?? '');

    final isEditing = plant != null;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Plant' : 'Add Plant'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Plant Number',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final plantNumber = controller.text.trim();

                if (plantNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plant number is required.')),
                  );
                  return;
                }

                final db = DatabaseService();
                final existingPlants = await db.getAllPlants();

                final duplicateExists = existingPlants.any(
                  (p) =>
                      p.plantNumber.toLowerCase() ==
                          plantNumber.toLowerCase() &&
                      p.id != plant?.id,
                );

                if (duplicateExists) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plant already exists.')),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await db.updatePlant(
                      Plant(id: plant.id, plantNumber: plantNumber),
                    );
                  } else {
                    await db.insertPlant(Plant(plantNumber: plantNumber));
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  await _loadPlants();
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save plant: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlant(Plant plant) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Plant'),
            content: Text(
              'Are you sure you want to delete Plant ${plant.plantNumber}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await DatabaseService().deletePlant(plant.id!);

      if (!mounted) return;

      await _loadPlants();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plant ${plant.plantNumber} deleted.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete plant: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Plants')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlantDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plants.isEmpty
          ? const Center(child: Text('No plants configured.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plants.length,
              itemBuilder: (context, index) {
                final plant = _plants[index];

                return Card(
                  child: ListTile(
                    title: Text(
                      'Plant ${plant.plantNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _showPlantDialog(plant: plant),
                    onLongPress: () => _deletePlant(plant),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Plant',
                      onPressed: () => _showPlantDialog(plant: plant),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
