import 'package:flutter/material.dart';
import 'writeups_screen.dart';
import 'settings_screen.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plants = ['320', '340', '501', '810', '815'];

    String? selectedPlant;

    return Scaffold(
      appBar: AppBar(title: const Text('Start Session')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose Plant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlant,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select plant',
                  ),
                  items: plants
                      .map(
                        (plant) =>
                            DropdownMenuItem(value: plant, child: Text(plant)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlant = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selectedPlant == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WriteupsScreen(plantNumber: selectedPlant!),
                            ),
                          );
                        },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Start Session'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Settings'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
