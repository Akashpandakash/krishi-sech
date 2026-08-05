import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/profile/domain/entities/farm_profile.dart';
import 'package:krishi_sech/features/profile/domain/entities/user_profile.dart';
import 'package:krishi_sech/features/profile/data/repositories/in_memory_profile_repository.dart';
import 'package:krishi_sech/features/profile/presentation/controllers/profile_controller.dart';
import 'package:krishi_sech/features/profile/presentation/profile_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';
import 'package:krishi_sech/shared/presentation/widgets/app_pressable.dart';
import 'package:krishi_sech/shared/presentation/widgets/responsive_content.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _requestedLoad = false;
  ProfileController? _profileController;
  bool _ownsProfileController = false;

  ProfileController get _controller => _profileController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileController == null) {
      _profileController = ProfileScope.maybeOf(context);
      if (_profileController == null) {
        _profileController = ProfileController(InMemoryProfileRepository());
        _ownsProfileController = true;
      }
    }
    final controller = _controller;
    if (!_requestedLoad &&
        controller.user == null &&
        (AuthScope.maybeOf(context)?.isAuthenticated ?? false)) {
      _requestedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.load());
    }
  }

  @override
  void dispose() {
    if (_ownsProfileController) _profileController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final user = controller.user;
    final authController = AuthScope.maybeOf(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.profile,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.retry,
                      onPressed: controller.isLoading ? null : controller.load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileAvatar(
                  user: user,
                  onTap: user == null ? null : () => _pickPhoto(context, user),
                ),
                const SizedBox(height: 14),
                Text(
                  controller.greetingName,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  user == null
                      ? context.l10n.profileUnavailable
                      : _summary(user),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                if (controller.failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      context.l10n.profileLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline,
                        title: context.l10n.personalDetails,
                        subtitle: user?.fullName,
                        onTap: user == null
                            ? null
                            : () => _editUser(context, user),
                      ),
                      const Divider(height: 1, indent: 64),
                      _ProfileTile(
                        icon: Icons.location_on_outlined,
                        title: context.l10n.farmDetails,
                        subtitle:
                            controller.farm?.farmName ??
                            context.l10n.notAvailable,
                        onTap: () => _editFarm(context, controller.farm),
                      ),
                      const Divider(height: 1, indent: 64),
                      _ProfileTile(
                        icon: Icons.language,
                        title: context.l10n.language,
                        subtitle: _languageName(context),
                        onTap: () => _showLanguagePicker(context),
                      ),
                      const Divider(height: 1, indent: 64),
                      _ProfileTile(
                        icon: Icons.help_outline,
                        title: context.l10n.helpSupport,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.featureComingSoon),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.farm case final farm?) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.farmName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${farm.totalLandArea} ${farm.landUnit} • ${farm.soilType}',
                          ),
                          Text(farm.mainCrops.join(', ')),
                          if (farm.updatedAt != null)
                            Text(
                              '${context.l10n.lastUpdated}: ${MaterialLocalizations.of(context).formatShortDate(farm.updatedAt!.toLocal())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AppPressable(
                  enabled: !(authController?.isLoading ?? false),
                  haptic: AppPressableHaptic.medium,
                  child: OutlinedButton.icon(
                    onPressed:
                        authController == null || authController.isLoading
                        ? null
                        : () async {
                            await authController.logout();
                            if (!context.mounted) return;
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (_) => false,
                            );
                          },
                    icon: const Icon(Icons.logout),
                    label: Text(context.l10n.logOut),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summary(UserProfile user) => [
    user.phone,
    user.village,
    user.district,
    user.state,
  ].whereType<String>().where((e) => e.isNotEmpty).join(' • ');
  String _languageName(BuildContext context) =>
      switch (LocaleScope.of(context).locale.languageCode) {
        'hi' => context.l10n.hindi,
        'en' => context.l10n.english,
        _ => context.l10n.bangla,
      };

  Future<void> _pickPhoto(BuildContext context, UserProfile user) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (file == null || !context.mounted) return;
    final documents = await getApplicationDocumentsDirectory();
    final extension = file.path.contains('.')
        ? file.path.split('.').last
        : 'jpg';
    final persisted = await File(
      file.path,
    ).copy('${documents.path}/profile_${user.id}.$extension');
    if (!context.mounted) return;
    await _controller.saveUser(
      UserProfile(
        id: user.id,
        phone: user.phone,
        fullName: user.fullName,
        preferredLanguage: user.preferredLanguage,
        profilePhotoPath: persisted.path,
        profilePhotoUrl: user.profilePhotoUrl,
        state: user.state,
        district: user.district,
        village: user.village,
        updatedAt: user.updatedAt,
      ),
    );
  }

  Future<void> _editUser(BuildContext context, UserProfile user) async {
    final name = TextEditingController(text: user.fullName);
    final state = TextEditingController(text: user.state);
    final district = TextEditingController(text: user.district);
    final village = TextEditingController(text: user.village);
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.personalDetails),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: context.l10n.fullName),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? context.l10n.requiredField
                      : null,
                ),
                TextFormField(
                  initialValue: user.phone,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.mobileNumber,
                    suffixIcon: const Icon(Icons.verified_outlined),
                  ),
                ),
                TextFormField(
                  controller: state,
                  decoration: InputDecoration(labelText: context.l10n.state),
                ),
                TextFormField(
                  controller: district,
                  decoration: InputDecoration(labelText: context.l10n.district),
                ),
                TextFormField(
                  controller: village,
                  decoration: InputDecoration(
                    labelText: context.l10n.villageOptional,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await _controller.saveUser(
                UserProfile(
                  id: user.id,
                  phone: user.phone,
                  fullName: name.text.trim(),
                  preferredLanguage: LocaleScope.of(
                    context,
                  ).locale.languageCode,
                  profilePhotoPath: user.profilePhotoPath,
                  profilePhotoUrl: user.profilePhotoUrl,
                  state: state.text.trim(),
                  district: district.text.trim(),
                  village: village.text.trim(),
                  updatedAt: user.updatedAt,
                ),
              );
              if (ok && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    name.dispose();
    state.dispose();
    district.dispose();
    village.dispose();
  }

  Future<void> _editFarm(BuildContext context, FarmProfile? farm) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _FarmDetailsDialog(farm: farm, profileController: _controller),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final locale = LocaleScope.of(context);
    final profileController = _controller;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                    (const Locale('bn'), sheetContext.l10n.bangla),
                    (const Locale('hi'), sheetContext.l10n.hindi),
                    (const Locale('en'), sheetContext.l10n.english),
                  ]
                  .map(
                    (option) => ListTile(
                      leading: Icon(
                        locale.locale.languageCode == option.$1.languageCode
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primary,
                      ),
                      title: Text(option.$2),
                      onTap: () async {
                        final value = option.$1.languageCode;
                        await locale.setLocale(Locale(value));
                        final current = profileController.user;
                        if (current != null) {
                          await profileController.saveUser(
                            UserProfile(
                              id: current.id,
                              phone: current.phone,
                              fullName: current.fullName,
                              preferredLanguage: value,
                              profilePhotoPath: current.profilePhotoPath,
                              profilePhotoUrl: current.profilePhotoUrl,
                              state: current.state,
                              district: current.district,
                              village: current.village,
                              updatedAt: current.updatedAt,
                            ),
                          );
                        }
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _FarmDetailsDialog extends StatefulWidget {
  const _FarmDetailsDialog({
    required this.farm,
    required this.profileController,
  });

  final FarmProfile? farm;
  final ProfileController profileController;

  @override
  State<_FarmDetailsDialog> createState() => _FarmDetailsDialogState();
}

class _FarmDetailsDialogState extends State<_FarmDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _farmName;
  late final TextEditingController _farmerType;
  late final TextEditingController _area;
  late final TextEditingController _unit;
  late final TextEditingController _soil;
  late final TextEditingController _irrigation;
  late final TextEditingController _crops;
  late final TextEditingController _location;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final farm = widget.farm;
    _farmName = TextEditingController(text: farm?.farmName);
    _farmerType = TextEditingController(text: farm?.farmerType);
    _area = TextEditingController(text: farm?.totalLandArea.toString());
    _unit = TextEditingController(text: farm?.landUnit);
    _soil = TextEditingController(text: farm?.soilType);
    _irrigation = TextEditingController(text: farm?.irrigationSource);
    _crops = TextEditingController(text: farm?.mainCrops.join(', '));
    _location = TextEditingController(text: farm?.coarseLocation);
  }

  @override
  void dispose() {
    _farmName.dispose();
    _farmerType.dispose();
    _area.dispose();
    _unit.dispose();
    _soil.dispose();
    _irrigation.dispose();
    _crops.dispose();
    _location.dispose();
    super.dispose();
  }

  TextFormField _requiredField(
    TextEditingController controller,
    String label,
  ) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    validator: (value) =>
        (value?.trim().isEmpty ?? true) ? context.l10n.requiredField : null,
  );

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final ok = await widget.profileController.saveFarm(
      FarmProfile(
        farmName: _farmName.text.trim(),
        farmerType: _farmerType.text.trim(),
        totalLandArea: double.parse(_area.text),
        landUnit: _unit.text.trim(),
        soilType: _soil.text.trim(),
        irrigationSource: _irrigation.text.trim(),
        mainCrops: _crops.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        coarseLocation: _location.text.trim().isEmpty
            ? null
            : _location.text.trim(),
        updatedAt: widget.farm?.updatedAt,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.farmDetails),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _requiredField(_farmName, context.l10n.farmName),
            _requiredField(_farmerType, context.l10n.farmerType),
            TextFormField(
              controller: _area,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.totalLandArea,
              ),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                  ? context.l10n.landAreaGreaterThanZero
                  : null,
            ),
            _requiredField(_unit, context.l10n.landAreaUnit),
            _requiredField(_soil, context.l10n.soilType),
            _requiredField(_irrigation, context.l10n.irrigationSource),
            _requiredField(_crops, context.l10n.mainCrops),
            TextFormField(
              controller: _location,
              decoration: InputDecoration(
                labelText: context.l10n.coarseLocationOptional,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.l10n.save),
      ),
    ],
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, this.onTap});
  final UserProfile? user;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final path = user?.profilePhotoPath;
    return Center(
      child: AppPressable(
        onTap: onTap,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.lightGreen,
              backgroundImage: path != null && File(path).existsSync()
                  ? FileImage(File(path))
                  : null,
              child: path == null || !File(path).existsSync()
                  ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                  : null,
            ),
            if (onTap != null)
              const Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt, size: 17, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: AppColors.lightGreen,
      child: Icon(icon, color: AppColors.primary),
    ),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
