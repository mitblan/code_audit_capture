import 'package:flutter/material.dart';
import '../models/audit_writeup.dart';
import '../models/departments.dart';
import '../models/rvia_code.dart';
import '../services/database_service.dart';
import 'rvia_search_screen.dart';

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

  // Row 2
  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  String? _selectedDepartment;
  List<Department> _departments = [];
  bool _isLoadingDepartments = true;

  bool _repeatViolation = false;
  final TextEditingController _timesRepeatController = TextEditingController();

  // Row 3
  final TextEditingController _violationDescriptionController =
      TextEditingController();

  bool _grounding = false;
  bool _solar = false;
  bool _panelBoard = false;
  bool _applianceInstall = false;

  // RVIA section
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _codeReferenceController =
      TextEditingController();
  final TextEditingController _codeClassController = TextEditingController();
  final TextEditingController _codeDescriptionController =
      TextEditingController();

  RviaCode? _selectedRviaCode;

  @override
  void initState() {
    super.initState();
    _loadDepartments();

    final existing = widget.existingWriteup;
    if (existing != null) {
      _unitNumberController.text = existing.unitNumber;
      _modelNumberController.text = existing.modelNumber;
      _selectedDepartment = existing.department.isNotEmpty
          ? existing.department
          : null;

      _repeatViolation = existing.repeatViolation;
      _timesRepeatController.text = existing.timesRepeat.toString();

      _violationDescriptionController.text = existing.nonConformanceNo;

      _grounding = existing.grounding;
      _solar = existing.solar;
      _panelBoard = existing.panelBoard;
      _applianceInstall = existing.applianceInstall;

      _categoryController.text = existing.category;
      _codeReferenceController.text = existing.newCodeReference;
      _codeClassController.text = existing.codeClass;
      _codeDescriptionController.text = existing.codeDescription;

      if (existing.rviaId != null) {
        _selectedRviaCode = RviaCode(
          rviaId: existing.rviaId!,
          standard: '',
          subCat: '',
          type: existing.rviaType ?? existing.codeClass,
          discipline: existing.category,
          description: existing.rviaDescription ?? existing.codeDescription,
        );
      }
    } else {
      _timesRepeatController.text = '0';
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _modelNumberController.dispose();
    _timesRepeatController.dispose();
    _violationDescriptionController.dispose();

    _categoryController.dispose();
    _codeReferenceController.dispose();
    _codeClassController.dispose();
    _codeDescriptionController.dispose();

    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await DatabaseService().getAllDepartments();

      if (!mounted) return;

      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _departments = [];
        _isLoadingDepartments = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load departments: $e')));
    }
  }

  List<String> _departmentOptions() {
    final names = _departments.map((d) => d.name).toList();

    final currentValue = _selectedDepartment?.trim();

    if (currentValue != null &&
        currentValue.isNotEmpty &&
        !names.contains(currentValue)) {
      names.add(currentValue);
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    return names;
  }

  Future<void> _searchRviaCode() async {
    final selectedCode = await Navigator.push<RviaCode>(
      context,
      MaterialPageRoute(builder: (_) => const RviaSearchScreen()),
    );

    if (selectedCode != null) {
      setState(() {
        _selectedRviaCode = selectedCode;

        // Current RVIA mapping
        _codeReferenceController.text = selectedCode.codeReference;
        _categoryController.text = selectedCode.discipline;
        _codeClassController.text = selectedCode.type;
        _codeDescriptionController.text = selectedCode.description;
      });
    }
  }

  void _saveWriteup() async {
    try {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
        return;
      }

      final int timesRepeat =
          int.tryParse(_timesRepeatController.text.trim()) ?? 0;

      final writeup = AuditWriteup(
        id: widget.existingWriteup?.id,
        plantNumber: widget.plantNumber,
        dateDetected: widget.existingWriteup?.dateDetected ?? DateTime.now(),
        detectedBy: widget.existingWriteup?.detectedBy ?? 'Audit',
        unitNumber: _unitNumberController.text.trim(),
        modelNumber: _modelNumberController.text.trim(),
        department: _selectedDepartment ?? '',
        nonConformanceNo: _violationDescriptionController.text.trim(),
        category: _categoryController.text.trim(),
        newCodeReference: _codeReferenceController.text.trim(),
        codeClass: _codeClassController.text.trim(),
        codeDescription: _codeDescriptionController.text.trim(),
        repeatViolation: _repeatViolation,
        timesRepeat: _repeatViolation ? timesRepeat : 0,
        grounding: _grounding,
        solar: _solar,
        panelBoard: _panelBoard,
        applianceInstall: _applianceInstall,
        rviaId: _selectedRviaCode?.rviaId ?? widget.existingWriteup?.rviaId,
        rviaType: _selectedRviaCode?.type ?? widget.existingWriteup?.rviaType,
        rviaDescription:
            _selectedRviaCode?.description ??
            widget.existingWriteup?.rviaDescription,
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

  Widget _buildMutedRviaCard() {
    final bool hasRvia =
        _codeReferenceController.text.trim().isNotEmpty ||
        _categoryController.text.trim().isNotEmpty ||
        _codeClassController.text.trim().isNotEmpty ||
        _codeDescriptionController.text.trim().isNotEmpty;

    if (!hasRvia) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No RVIA code selected.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black87),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Code Reference: ${_codeReferenceController.text}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Category: ${_categoryController.text}'),
            const SizedBox(height: 4),
            Text('Code Class: ${_codeClassController.text}'),
            const SizedBox(height: 6),
            Text('Code Description: ${_codeDescriptionController.text}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRowTwo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: TextFormField(
            controller: _unitNumberController,
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: TextFormField(
            controller: _modelNumberController,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: _departmentOptions().contains(_selectedDepartment)
                ? _selectedDepartment
                : null,
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),
            items: _departmentOptions()
                .map(
                  (dept) =>
                      DropdownMenuItem<String>(value: dept, child: Text(dept)),
                )
                .toList(),
            onChanged: _isLoadingDepartments
                ? null
                : (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Repeat', style: TextStyle(fontSize: 16)),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Transform.scale(
                        scale: 0.68,
                        child: Switch(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: _repeatViolation,
                          onChanged: (value) {
                            setState(() {
                              _repeatViolation = value;
                              if (!value) {
                                _timesRepeatController.text = '0';
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: TextFormField(
            controller: _timesRepeatController,
            enabled: _repeatViolation,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Repeat #',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_repeatViolation) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed < 1) {
                  return 'Required';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlagsPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Grounding'),
            value: _grounding,
            onChanged: (value) {
              setState(() {
                _grounding = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Solar'),
            value: _solar,
            onChanged: (value) {
              setState(() {
                _solar = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Panel Board'),
            value: _panelBoard,
            onChanged: (value) {
              setState(() {
                _panelBoard = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Appliance Install'),
            value: _applianceInstall,
            onChanged: (value) {
              setState(() {
                _applianceInstall = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRowThree() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _violationDescriptionController,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Violation Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: _buildFlagsPanel()),
        ],
      ),
    );
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _searchRviaCode,
                    icon: const Icon(Icons.search),
                    label: const Text('Search RVIA'),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMutedRviaCard(),
                const SizedBox(height: 16),
                _buildRowTwo(),
                const SizedBox(height: 16),
                SizedBox(height: 220, child: _buildRowThree()),
                const SizedBox(height: 20),
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
      ),
    );
  }
}
