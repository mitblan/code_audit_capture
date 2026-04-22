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
  List<String> _categories = ['All'];

  String _selectedCategory = 'All';
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

      final categories =
          codes
              .map((code) => code.discipline.trim())
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _allCodes = codes;
        _categories = ['All', ...categories];
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

    List<RviaCode> filtered = _allCodes;

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where(
            (code) =>
                code.discipline.trim().toLowerCase() ==
                _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((code) {
        final searchableText = [
          code.codeReference,
          code.standard,
          code.subCat,
          code.type,
          code.discipline,
          code.description,
        ].join(' ').toLowerCase();

        return searchableText.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final aCode = a.codeReference.toLowerCase();
      final bCode = b.codeReference.toLowerCase();

      final aStarts = aCode.startsWith(query);
      final bStarts = bCode.startsWith(query);

      if (query.isNotEmpty && aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }

      return aCode.compareTo(bCode);
    });

    setState(() {
      _filteredCodes = filtered;
    });
  }

  void _selectCode(RviaCode code) {
    Navigator.pop(context, code);
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RVIA Search')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : 'All',
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'All';
                });
                _applyFilter();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search code, type, category, or description',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                      ),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            title: Text(
                              '${code.codeReference}  •  ${code.type}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(code.discipline),
                                  const SizedBox(height: 2),
                                  Text(
                                    code.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
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
