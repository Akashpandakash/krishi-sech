import 'dart:math';

import 'package:flutter/material.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class AddEditCropPage extends StatefulWidget {
  const AddEditCropPage({this.cropId, super.key});

  final String? cropId;

  @override
  State<AddEditCropPage> createState() => _AddEditCropPageState();
}

class _AddEditCropPageState extends State<AddEditCropPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _varietyController;
  late final TextEditingController _customNameController;
  late final TextEditingController _areaController;
  late final TextEditingController _farmController;
  late final TextEditingController _notesController;
  late final TextEditingController _seedBrandController;
  late final TextEditingController _fertilizerController;
  late final TextEditingController _pesticideController;
  CropKind? _kind;
  DateTime? _sowingDate;
  DateTime? _harvestDate;
  LandAreaUnit _areaUnit = LandAreaUnit.acre;
  GrowthStage _stage = GrowthStage.sowing;
  IrrigationType _irrigation = IrrigationType.manual;
  SoilType _soilType = SoilType.other;
  PlantingMethod _plantingMethod = PlantingMethod.other;
  CropHealth _health = CropHealth.healthy;
  bool _initialized = false;
  bool _saving = false;
  late final String _createRequestId = widget.cropId ?? _uuidV4();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final crop = widget.cropId == null
        ? null
        : CropScope.of(context).cropById(widget.cropId!);
    _kind = crop?.kind;
    _sowingDate = crop?.sowingDate;
    _harvestDate = crop?.expectedHarvestDate;
    _areaUnit = crop?.landAreaUnit ?? LandAreaUnit.acre;
    _stage = crop?.growthStage ?? GrowthStage.sowing;
    _irrigation = crop?.irrigationType ?? IrrigationType.manual;
    _soilType = crop?.soilType ?? SoilType.other;
    _plantingMethod = crop?.plantingMethod ?? PlantingMethod.other;
    _health = crop?.health ?? CropHealth.healthy;
    _varietyController = TextEditingController(text: crop?.variety);
    _customNameController = TextEditingController(text: crop?.customName);
    _areaController = TextEditingController(
      text: crop == null ? '' : crop.landArea.toString(),
    );
    _farmController = TextEditingController(text: crop?.farmName);
    _notesController = TextEditingController(text: crop?.notes);
    _seedBrandController = TextEditingController(text: crop?.seedBrand);
    _fertilizerController = TextEditingController(
      text: crop?.lastFertilizerUsed,
    );
    _pesticideController = TextEditingController(text: crop?.lastPesticideUsed);
    _initialized = true;
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _customNameController.dispose();
    _areaController.dispose();
    _farmController.dispose();
    _notesController.dispose();
    _seedBrandController.dispose();
    _fertilizerController.dispose();
    _pesticideController.dispose();
    super.dispose();
  }

  Future<void> _pickSowingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _sowingDate = date);
  }

  Future<void> _pickHarvestDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? DateTime.now().add(const Duration(days: 60)),
      firstDate: _sowingDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1500)),
    );
    if (date != null) setState(() => _harvestDate = date);
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (_kind == null || _sowingDate == null) {
      setState(() {});
      return;
    }
    if (!valid) return;
    if (_sowingDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sowingDateFutureError)),
      );
      return;
    }

    setState(() => _saving = true);
    final controller = CropScope.of(context);
    final existing = widget.cropId == null
        ? null
        : controller.cropById(widget.cropId!);
    final now = DateTime.now();
    final crop = Crop(
      id: _createRequestId,
      userId: existing?.userId ?? 'local-user',
      kind: _kind!,
      customName: _kind == CropKind.other
          ? _customNameController.text.trim()
          : null,
      variety: _varietyController.text.trim(),
      sowingDate: _sowingDate!,
      landArea: double.parse(_areaController.text.trim()),
      landAreaUnit: _areaUnit,
      growthStage: _stage,
      irrigationType: _irrigation,
      soilType: _soilType,
      plantingMethod: _plantingMethod,
      seedBrand: _emptyToNull(_seedBrandController.text),
      lastFertilizerUsed: _emptyToNull(_fertilizerController.text),
      lastPesticideUsed: _emptyToNull(_pesticideController.text),
      farmName: _emptyToNull(_farmController.text),
      expectedHarvestDate: _harvestDate,
      notes: _emptyToNull(_notesController.text),
      health: _health,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final saved = widget.cropId == null
        ? await controller.addCrop(crop)
        : await controller.updateCrop(crop);
    if (!mounted) return;
    if (saved) {
      if (widget.cropId == null) {
        Navigator.of(context).pop(true);
        return;
      }
      final current = controller.cropById(crop.id);
      if (current != null &&
          current.variety == crop.variety &&
          current.health == crop.health) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cropServerError)));
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cropServerError)));
    }
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cropId == null ? context.l10n.addCrop : context.l10n.editCrop,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const Key('add_crop_scroll_view'),
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: 28 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: ResponsiveContent(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<CropKind>(
                        key: const Key('crop_name_field'),
                        isExpanded: true,
                        initialValue: _kind,
                        decoration: InputDecoration(
                          labelText: context.l10n.cropName,
                        ),
                        items: CropKind.values
                            .map(
                              (kind) => DropdownMenuItem(
                                value: kind,
                                child: Text(cropKindOptionLabel(context, kind)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _kind = value),
                        validator: (value) => value == null
                            ? context.l10n.cropNameRequired
                            : null,
                      ),
                      if (_kind == CropKind.other) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customNameController,
                          decoration: InputDecoration(
                            labelText: context.l10n.otherCropName,
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? context.l10n.cropNameRequired
                              : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('crop_variety_field'),
                        controller: _varietyController,
                        decoration: InputDecoration(
                          labelText: context.l10n.variety,
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true
                            ? context.l10n.varietyRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _DateField(
                        key: const Key('crop_sowing_date'),
                        label: context.l10n.sowingDate,
                        date: _sowingDate,
                        errorText: _sowingDate == null
                            ? context.l10n.sowingDateRequired
                            : null,
                        onTap: _pickSowingDate,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('crop_land_area'),
                              controller: _areaController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: context.l10n.landArea,
                              ),
                              validator: (value) {
                                final area = double.tryParse(
                                  value?.trim() ?? '',
                                );
                                return area == null || area <= 0
                                    ? context.l10n.landAreaPositive
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<LandAreaUnit>(
                              isExpanded: true,
                              initialValue: _areaUnit,
                              decoration: InputDecoration(
                                labelText: context.l10n.landAreaUnit,
                              ),
                              items: LandAreaUnit.values
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(areaUnitLabel(context, unit)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _areaUnit = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _EnumDropdown<GrowthStage>(
                        label: context.l10n.currentGrowthStage,
                        value: _stage,
                        values: GrowthStage.values,
                        labelBuilder: (value) =>
                            growthStageLabel(context, value),
                        onChanged: (value) => setState(() => _stage = value),
                      ),
                      const SizedBox(height: 12),
                      _EnumDropdown<IrrigationType>(
                        label: context.l10n.irrigationMethod,
                        value: _irrigation,
                        values: IrrigationType.values,
                        labelBuilder: (value) =>
                            irrigationLabel(context, value),
                        onChanged: (value) =>
                            setState(() => _irrigation = value),
                      ),
                      const SizedBox(height: 12),
                      _EnumDropdown<SoilType>(
                        label: context.l10n.soilType,
                        value: _soilType,
                        values: SoilType.values,
                        labelBuilder: (value) => soilTypeLabel(context, value),
                        onChanged: (value) => setState(() => _soilType = value),
                      ),
                      const SizedBox(height: 12),
                      _EnumDropdown<PlantingMethod>(
                        label: context.l10n.plantingMethod,
                        value: _plantingMethod,
                        values: PlantingMethod.values,
                        labelBuilder: (value) =>
                            plantingMethodLabel(context, value),
                        onChanged: (value) =>
                            setState(() => _plantingMethod = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _seedBrandController,
                        decoration: InputDecoration(
                          labelText: context.l10n.seedBrand,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fertilizerController,
                        decoration: InputDecoration(
                          labelText: context.l10n.lastFertilizerUsed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pesticideController,
                        decoration: InputDecoration(
                          labelText: context.l10n.lastPesticideUsed,
                        ),
                      ),
                      if (widget.cropId != null) ...[
                        const SizedBox(height: 12),
                        _EnumDropdown<CropHealth>(
                          label: context.l10n.healthStatus,
                          value: _health,
                          values: CropHealth.values,
                          labelBuilder: (value) =>
                              cropHealthLabel(context, value),
                          onChanged: (value) => setState(() => _health = value),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _farmController,
                        decoration: InputDecoration(
                          labelText: context.l10n.villageFarmOptional,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DateField(
                        label: context.l10n.expectedHarvestOptional,
                        date: _harvestDate,
                        onTap: _pickHarvestDate,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('crop_notes_field'),
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: context.l10n.notesOptional,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: AppPressable(
                          enabled: !_saving,
                          haptic: AppPressableHaptic.medium,
                          child: FilledButton(
                            key: const Key('save_crop_button'),
                            onPressed: _saving ? null : _save,
                            child: Text(context.l10n.saveCrop),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    isExpanded: true,
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: values
        .map(
          (item) =>
              DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
        )
        .toList(),
    onChanged: (item) {
      if (item != null) onChanged(item);
    },
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.errorText,
    super.key,
  });
  final String label;
  final DateTime? date;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, errorText: errorText),
      child: Text(
        date == null
            ? context.l10n.selectDate
            : MaterialLocalizations.of(context).formatMediumDate(date!),
      ),
    ),
  );
}
