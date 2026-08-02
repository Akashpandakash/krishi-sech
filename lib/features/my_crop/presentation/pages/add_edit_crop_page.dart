import 'package:flutter/material.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

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
  CropKind? _kind;
  DateTime? _sowingDate;
  DateTime? _harvestDate;
  LandAreaUnit _areaUnit = LandAreaUnit.acre;
  GrowthStage _stage = GrowthStage.sowing;
  IrrigationType _irrigation = IrrigationType.manual;
  CropHealth _health = CropHealth.healthy;
  bool _initialized = false;
  bool _saving = false;

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
    _health = crop?.health ?? CropHealth.healthy;
    _varietyController = TextEditingController(text: crop?.variety);
    _customNameController = TextEditingController(text: crop?.customName);
    _areaController = TextEditingController(
      text: crop == null ? '' : crop.landArea.toString(),
    );
    _farmController = TextEditingController(text: crop?.farmName);
    _notesController = TextEditingController(text: crop?.notes);
    _initialized = true;
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _customNameController.dispose();
    _areaController.dispose();
    _farmController.dispose();
    _notesController.dispose();
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
      id: widget.cropId ?? now.microsecondsSinceEpoch.toString(),
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
      farmName: _emptyToNull(_farmController.text),
      expectedHarvestDate: _harvestDate,
      notes: _emptyToNull(_notesController.text),
      health: _health,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.cropId == null) {
      await controller.addCrop(crop);
    } else {
      await controller.updateCrop(crop);
    }
    if (mounted) Navigator.of(context).pop();
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              ResponsiveContent(
                child: Column(
                  children: [
                    DropdownButtonFormField<CropKind>(
                      key: const Key('crop_name_field'),
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
                      validator: (value) =>
                          value == null ? context.l10n.cropNameRequired : null,
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: context.l10n.landArea,
                            ),
                            validator: (value) {
                              final area = double.tryParse(value?.trim() ?? '');
                              return area == null || area <= 0
                                  ? context.l10n.landAreaPositive
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<LandAreaUnit>(
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
                      labelBuilder: (value) => growthStageLabel(context, value),
                      onChanged: (value) => setState(() => _stage = value),
                    ),
                    const SizedBox(height: 12),
                    _EnumDropdown<IrrigationType>(
                      label: context.l10n.irrigationType,
                      value: _irrigation,
                      values: IrrigationType.values,
                      labelBuilder: (value) => irrigationLabel(context, value),
                      onChanged: (value) => setState(() => _irrigation = value),
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
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.l10n.notesOptional,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('save_crop_button'),
                        onPressed: _saving ? null : _save,
                        child: Text(context.l10n.saveCrop),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
