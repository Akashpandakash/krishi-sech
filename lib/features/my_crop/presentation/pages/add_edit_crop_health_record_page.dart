import 'dart:io';

import 'package:flutter/material.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/image_picker_repository.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_health_photo_store.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_health_photo_store.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_health_record_labels.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_health_record_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';

class CropHealthRecordFormArguments {
  const CropHealthRecordFormArguments({required this.cropId, this.recordId});

  final String cropId;
  final String? recordId;
}

class AddEditCropHealthRecordPage extends StatefulWidget {
  const AddEditCropHealthRecordPage({
    super.key,
    required this.arguments,
    this.photoStore = const LocalCropHealthPhotoStore(),
  });

  final CropHealthRecordFormArguments arguments;
  final CropHealthPhotoStore photoStore;

  @override
  State<AddEditCropHealthRecordPage> createState() =>
      _AddEditCropHealthRecordPageState();
}

class _AddEditCropHealthRecordPageState
    extends State<AddEditCropHealthRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;
  CropHealthRecordType _type = CropHealthRecordType.disease;
  DateTime _date = DateTime.now();
  String? _photoPath;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final existing = widget.arguments.recordId == null
        ? null
        : CropHealthRecordScope.of(
            context,
          ).recordById(widget.arguments.recordId!);
    _type = existing?.type ?? CropHealthRecordType.disease;
    _date = existing?.occurredAt ?? DateTime.now();
    _photoPath = existing?.photoPath;
    _titleController = TextEditingController(text: existing?.title);
    _detailsController = TextEditingController(text: existing?.details);
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(bool camera) async {
    try {
      final picker = ImagePickerRepository();
      final source = camera
          ? await picker.takePhoto()
          : await picker.chooseFromGallery();
      if (source == null) return;
      final saved = await widget.photoStore.savePhoto(source);
      if (mounted) setState(() => _photoPath = saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imageCouldNotBeOpened)),
      );
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final controller = CropHealthRecordScope.of(context);
    final existing = widget.arguments.recordId == null
        ? null
        : controller.recordById(widget.arguments.recordId!);
    final now = DateTime.now();
    final record = CropHealthRecord(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      cropId: widget.arguments.cropId,
      type: _type,
      title: _titleController.text.trim(),
      details: _emptyToNull(_detailsController.text),
      photoPath: _photoPath,
      occurredAt: _date,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (existing == null) {
      await controller.addRecord(record);
    } else {
      await controller.updateRecord(record);
    }
    if (mounted) Navigator.pop(context);
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.arguments.recordId == null
              ? context.l10n.addRecord
              : context.l10n.editRecord,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<CropHealthRecordType>(
                      initialValue: _type,
                      decoration: InputDecoration(
                        labelText: context.l10n.recordType,
                      ),
                      items: CropHealthRecordType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                cropHealthRecordTypeLabel(context, type),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('health_record_title'),
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: context.l10n.recordTitle,
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true
                          ? context.l10n.recordTitleRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.recordDate,
                        ),
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(_date),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.l10n.recordDetails,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_photoPath case final path?) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(path),
                          height: 180,
                          cacheWidth:
                              (MediaQuery.sizeOf(context).width *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(true),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(context.l10n.takePhoto),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(false),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(context.l10n.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppPressable(
                      enabled: !_saving,
                      haptic: AppPressableHaptic.medium,
                      child: FilledButton(
                        key: const Key('save_health_record'),
                        onPressed: _saving ? null : _save,
                        child: Text(context.l10n.saveRecord),
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
