import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/audit_writeup.dart';
import '../models/department.dart';
import '../models/plant_product_line_option.dart';
import '../models/plant_unit_prefix.dart';
import '../models/rvia_code.dart';
import '../services/database_service.dart';
import 'rvia_search_screen.dart';

class NewWriteupScreen extends StatefulWidget {
  final String plantNumber;
  final AuditWriteup? existingWriteup;
  final AuditWriteup? carryForwardFrom;

  const NewWriteupScreen({
    super.key,
    required this.plantNumber,
    this.existingWriteup,
    this.carryForwardFrom,
  });

  @override
  State<NewWriteupScreen> createState() => _NewWriteupScreenState();
}

class _NewWriteupScreenState extends State<NewWriteupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Unit
  final TextEditingController _unitSuffixController = TextEditingController();
  String? _selectedUnitPrefix;
  List<PlantUnitPrefix> _unitPrefixes = [];
  bool _isLoadingUnitPrefixes = true;

  // Model
  final TextEditingController _modelSuffixController = TextEditingController();
  String? _selectedProductLineCode;
  List<PlantProductLineOption> _productLines = [];
  bool _isLoadingProductLines = true;

  // Department
  String? _selectedDepartment;
  List<Department> _departments = [];
  bool _isLoadingDepartments = true;

  // Repeat
  bool _repeatViolation = false;
  final TextEditingController _timesRepeatController = TextEditingController();

  // Violation description
  final TextEditingController _violationDescriptionController =
      TextEditingController();

  // Flags
  bool _grounding = false;
  bool _solar = false;
  bool _panelBoard = false;
  bool _applianceInstall = false;

  // RVIA
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _codeReferenceController =
      TextEditingController();
  final TextEditingController _codeClassController = TextEditingController();
  final TextEditingController _codeDescriptionController =
      TextEditingController();

  RviaCode? _selectedRviaCode;

  // Pending combined values for async split after options load
  String? _pendingInitialUnitNumber;
  String? _pendingInitialModelNumber;
  bool _unitInitialized = false;
  bool _modelInitialized = false;

  @override
  void initState() {
    super.initState();

    _loadDepartments();
    _loadUnitPrefixes();
    _loadProductLines();

    final existing = widget.existingWriteup;

    if (existing != null) {
      // Edit mode
      _pendingInitialUnitNumber = existing.unitNumber;
      _pendingInitialModelNumber = existing.modelNumber;

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
      // New write-up
      _timesRepeatController.text = '0';

      final carryForward = widget.carryForwardFrom;
      if (carryForward != null) {
        _pendingInitialUnitNumber = carryForward.unitNumber;
        _pendingInitialModelNumber = carryForward.modelNumber;
      }
    }
  }

  @override
  void dispose() {
    _unitSuffixController.dispose();
    _modelSuffixController.dispose();
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

        if (_selectedDepartment == null && _departments.isNotEmpty) {
          _selectedDepartment = _departments.first.name;
        }
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

  Future<void> _loadUnitPrefixes() async {
    try {
      final prefixes = await DatabaseService().getPrefixesForPlant(
        widget.plantNumber,
      );

      if (!mounted) return;

      setState(() {
        _unitPrefixes = prefixes;
        _isLoadingUnitPrefixes = false;
      });

      _initializeUnitSelection();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _unitPrefixes = [];
        _isLoadingUnitPrefixes = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load unit prefixes: $e')),
      );
    }
  }

  Future<void> _loadProductLines() async {
    try {
      final productLines = await DatabaseService().getProductLinesForPlant(
        widget.plantNumber,
      );

      if (!mounted) return;

      setState(() {
        _productLines = productLines;
        _isLoadingProductLines = false;
      });

      _initializeModelSelection();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _productLines = [];
        _isLoadingProductLines = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product lines: $e')),
      );
    }
  }

  void _initializeUnitSelection() {
    if (_unitInitialized) return;

    if (_pendingInitialUnitNumber != null &&
        _pendingInitialUnitNumber!.trim().isNotEmpty) {
      _splitInitialUnitNumber(_pendingInitialUnitNumber!);
      _pendingInitialUnitNumber = null;
      _unitInitialized = true;
      return;
    }

    if (_selectedUnitPrefix == null && _unitPrefixes.isNotEmpty) {
      final defaultPrefix = _unitPrefixes.cast<PlantUnitPrefix?>().firstWhere(
        (p) => p?.isDefault == true,
        orElse: () => null,
      );

      setState(() {
        _selectedUnitPrefix =
            defaultPrefix?.prefix ?? _unitPrefixes.first.prefix;
      });
    }

    _unitInitialized = true;
  }

  void _initializeModelSelection() {
    if (_modelInitialized) return;

    if (_pendingInitialModelNumber != null &&
        _pendingInitialModelNumber!.trim().isNotEmpty) {
      _splitInitialModelNumber(_pendingInitialModelNumber!);
      _pendingInitialModelNumber = null;
      _modelInitialized = true;
      return;
    }

    if (_selectedProductLineCode == null && _productLines.isNotEmpty) {
      final defaultLine = _productLines
          .cast<PlantProductLineOption?>()
          .firstWhere((p) => p?.isDefault == true, orElse: () => null);

      setState(() {
        _selectedProductLineCode =
            defaultLine?.code ?? _productLines.first.code;
      });
    }

    _modelInitialized = true;
  }

  void _splitInitialUnitNumber(String unitNumber) {
    final trimmed = unitNumber.trim().toUpperCase();

    if (trimmed.isEmpty) return;

    final prefixes = _unitPrefixes.map((p) => p.prefix).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final prefix in prefixes) {
      if (trimmed.startsWith(prefix)) {
        setState(() {
          _selectedUnitPrefix = prefix;
          _unitSuffixController.text = trimmed.substring(prefix.length);
        });
        return;
      }
    }

    setState(() {
      _selectedUnitPrefix = null;
      _unitSuffixController.text = trimmed;
    });
  }

  void _splitInitialModelNumber(String modelNumber) {
    final trimmed = modelNumber.trim().toUpperCase();

    if (trimmed.isEmpty) return;

    final codes = _productLines.map((p) => p.code).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final code in codes) {
      if (trimmed.startsWith(code)) {
        setState(() {
          _selectedProductLineCode = code;
          _modelSuffixController.text = trimmed.substring(code.length);
        });
        return;
      }
    }

    setState(() {
      _selectedProductLineCode = null;
      _modelSuffixController.text = trimmed;
    });
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

  List<String> _unitPrefixOptions() {
    final prefixes = _unitPrefixes.map((p) => p.prefix).toList();
    final currentValue = _selectedUnitPrefix?.trim();

    if (currentValue != null &&
        currentValue.isNotEmpty &&
        !prefixes.contains(currentValue)) {
      prefixes.add(currentValue);
      prefixes.sort();
    }

    return prefixes;
  }

  List<String> _productLineOptions() {
    final codes = _productLines.map((p) => p.code).toList();
    final currentValue = _selectedProductLineCode?.trim();

    if (currentValue != null &&
        currentValue.isNotEmpty &&
        !codes.contains(currentValue)) {
      codes.add(currentValue);
      codes.sort();
    }

    return codes;
  }

  Future<void> _searchRviaCode() async {
    final selectedCode = await Navigator.push<RviaCode>(
      context,
      MaterialPageRoute(builder: (_) => const RviaSearchScreen()),
    );

    if (selectedCode != null) {
      setState(() {
        _selectedRviaCode = selectedCode;

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
        unitNumber:
            '${_selectedUnitPrefix ?? ''}${_unitSuffixController.text.trim()}',
        modelNumber:
            '${_selectedProductLineCode ?? ''}${_modelSuffixController.text.trim().toUpperCase()}',
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
          flex: 4,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _unitPrefixOptions().contains(_selectedUnitPrefix)
                      ? _selectedUnitPrefix
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Prefix',
                    border: OutlineInputBorder(),
                  ),
                  items: _unitPrefixOptions()
                      .map(
                        (prefix) => DropdownMenuItem<String>(
                          value: prefix,
                          child: Text(prefix),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoadingUnitPrefixes
                      ? null
                      : (value) {
                          setState(() {
                            _selectedUnitPrefix = value;
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
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _unitSuffixController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Unit #',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Required';
                    }
                    if (text.length != 6) {
                      return 'Must be 6 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value:
                      _productLineOptions().contains(_selectedProductLineCode)
                      ? _selectedProductLineCode
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Model Code',
                    border: OutlineInputBorder(),
                  ),
                  items: _productLineOptions()
                      .map(
                        (code) => DropdownMenuItem<String>(
                          value: code,
                          child: Text(code),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoadingProductLines
                      ? null
                      : (value) {
                          setState(() {
                            _selectedProductLineCode = value;
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
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _modelSuffixController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9\- ]'),
                    ),
                    UpperCaseTextFormatter(),
                  ],
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
            ],
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

                              if (value) {
                                final current =
                                    int.tryParse(
                                      _timesRepeatController.text.trim(),
                                    ) ??
                                    0;
                                if (current < 1) {
                                  _timesRepeatController.text = '1';
                                }
                              } else {
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
