import 'package:flutter/material.dart';
import '../models/rvia_code.dart';
import '../services/rvia_service.dart';

class RviaSearchScreen extends StatefulWidget {
  const RviaSearchScreen({super.key});

  @override
  State<RviaSearchScreen> createState() => _RviaSearchScreenState();
}

class _RviaSearchScreenState extends State<RviaSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<RviaCode> _allCodes = [];
  List<RviaCode> _filteredCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCodes();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCodes() async {
    try {
      final codes = await RviaService.loadCodes();

      if (!mounted) return;

      setState(() {
        _allCodes = codes;
        _filteredCodes = codes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load RVIA data: $e')));
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCodes = _allCodes;
      } else {
        _filteredCodes = _allCodes.where((code) {
          return code.codeReference.toLowerCase().contains(query) ||
              code.discipline.toLowerCase().contains(query) ||
              code.description.toLowerCase().contains(query) ||
              code.type.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _selectCode(RviaCode code) {
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RVIA Search')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search code, discipline, or description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCodes.isEmpty
                  ? const Center(child: Text('No matching RVIA codes found.'))
                  : ListView.builder(
                      itemCount: _filteredCodes.length,
                      itemBuilder: (context, index) {
                        final code = _filteredCodes[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(code.codeReference),
                            subtitle: Text(
                              '${code.discipline}\n${code.description}',
                            ),
                            isThreeLine: true,
                            trailing: Text(code.type),
                            onTap: () => _selectCode(code),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
