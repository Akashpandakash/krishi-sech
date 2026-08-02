import 'package:flutter/material.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class ManualLocationPage extends StatefulWidget {
  const ManualLocationPage({super.key});

  @override
  State<ManualLocationPage> createState() => _ManualLocationPageState();
}

class _ManualLocationPageState extends State<ManualLocationPage> {
  static const _locations = <String, Map<String, List<String>>>{
    'Rajasthan': {
      'Jaipur': ['Jaipur', 'Chomu', 'Sanganer'],
      'Jodhpur': ['Jodhpur', 'Bilara', 'Osian'],
      'Udaipur': ['Udaipur', 'Gogunda', 'Salumber'],
    },
    'Uttar Pradesh': {
      'Lucknow': ['Lucknow', 'Malihabad', 'Mohanlalganj'],
      'Varanasi': ['Varanasi', 'Ramnagar', 'Pindra'],
      'Agra': ['Agra', 'Fatehpur Sikri', 'Kiraoli'],
    },
    'Bihar': {
      'Patna': ['Patna', 'Danapur', 'Barh'],
      'Gaya': ['Gaya', 'Bodh Gaya', 'Tekari'],
    },
    'West Bengal': {
      'Kolkata': ['Kolkata'],
      'Hooghly': ['Chinsurah', 'Serampore', 'Arambagh'],
      'Nadia': ['Krishnanagar', 'Ranaghat', 'Kalyani'],
    },
    'Maharashtra': {
      'Pune': ['Pune', 'Baramati', 'Junnar'],
      'Nashik': ['Nashik', 'Malegaon', 'Sinnar'],
    },
    'Madhya Pradesh': {
      'Bhopal': ['Bhopal', 'Berasia'],
      'Indore': ['Indore', 'Mhow', 'Depalpur'],
    },
  };

  final _searchController = TextEditingController();
  final _villageController = TextEditingController();
  String _searchQuery = '';
  String? _state;
  String? _district;
  String? _city;
  bool _saving = false;
  bool _detecting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_state == null || _district == null || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectRequiredLocation)),
      );
      return;
    }

    setState(() => _saving = true);
    await LocationScope.of(context).selectManualLocation(
      FarmLocation(
        state: _state!,
        district: _district!,
        city: _city!,
        village: _villageController.text,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _detecting = true);
    final controller = LocationScope.of(context);
    final failure = await controller.detectCurrentLocation(force: true);

    if (!mounted) {
      return;
    }
    setState(() => _detecting = false);

    if (failure == null && controller.hasLocation) {
      Navigator.of(context).pop(true);
      return;
    }

    final needsLocationSettings =
        failure == LocationFailureType.serviceDisabled;
    final needsAppSettings =
        failure == LocationFailureType.reducedAccuracy ||
        failure == LocationFailureType.permissionPermanentlyDenied;
    final message = switch (failure) {
      LocationFailureType.serviceDisabled =>
        context.l10n.locationServicesDisabled,
      LocationFailureType.reducedAccuracy =>
        context.l10n.preciseLocationRequired,
      LocationFailureType.permissionPermanentlyDenied =>
        context.l10n.locationPermissionPermanentlyDenied,
      LocationFailureType.detectionTimedOut =>
        context.l10n.locationDetectionTimedOut,
      LocationFailureType.addressUnavailable =>
        context.l10n.locationAddressUnavailable,
      _ => context.l10n.locationDeniedFriendly,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: needsLocationSettings || needsAppSettings
            ? SnackBarAction(
                label: needsLocationSettings
                    ? context.l10n.openLocationSettings
                    : context.l10n.openAppSettings,
                onPressed: () {
                  if (needsLocationSettings) {
                    controller.openLocationSettings();
                  } else {
                    controller.openAppSettings();
                  }
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = _state == null
        ? const <String>[]
        : _locations[_state]!.keys.toList();
    final cities = _district == null
        ? const <String>[]
        : _locations[_state]![_district]!;
    final suggestions = <({String state, String district, String city})>[];
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      for (final stateEntry in _locations.entries) {
        for (final districtEntry in stateEntry.value.entries) {
          for (final city in districtEntry.value) {
            final searchable = '${stateEntry.key} ${districtEntry.key} $city'
                .toLowerCase();
            if (searchable.contains(query)) {
              suggestions.add((
                state: stateEntry.key,
                district: districtEntry.key,
                city: city,
              ));
            }
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.selectLocation)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('manual_location_search'),
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchLocation,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: suggestions.take(5).map((suggestion) {
                          return ListTile(
                            key: ValueKey(
                              'location_suggestion_${suggestion.city}',
                            ),
                            dense: true,
                            onTap: () {
                              setState(() {
                                _state = suggestion.state;
                                _district = suggestion.district;
                                _city = suggestion.city;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              FocusScope.of(context).unfocus();
                            },
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(suggestion.city),
                            subtitle: Text(
                              '${suggestion.district}, ${suggestion.state}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('manual_use_current_location'),
                    onPressed: _detecting ? null : _useCurrentLocation,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      alignment: Alignment.centerLeft,
                    ),
                    icon: _detecting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(context.l10n.useCurrentLocation),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    initialValue: 'India',
                    decoration: InputDecoration(
                      labelText: context.l10n.country,
                      prefixIcon: const Icon(Icons.public),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SearchableDropdown(
                    key: ValueKey('state_$_state'),
                    label: context.l10n.state,
                    hint: context.l10n.chooseState,
                    value: _state,
                    values: _locations.keys.toList(),
                    icon: Icons.map_outlined,
                    onSelected: (value) {
                      setState(() {
                        _state = value;
                        _district = null;
                        _city = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _SearchableDropdown(
                    key: ValueKey('district_$_state'),
                    label: context.l10n.district,
                    hint: context.l10n.chooseDistrict,
                    value: _district,
                    values: districts,
                    icon: Icons.location_city_outlined,
                    onSelected: _state == null
                        ? null
                        : (value) {
                            setState(() {
                              _district = value;
                              _city = null;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  _SearchableDropdown(
                    key: ValueKey('city_$_district'),
                    label: context.l10n.city,
                    hint: context.l10n.chooseCity,
                    value: _city,
                    values: cities,
                    icon: Icons.location_on_outlined,
                    onSelected: _district == null
                        ? null
                        : (value) => setState(() => _city = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('manual_village'),
                    controller: _villageController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.villageOptional,
                      hintText: context.l10n.enterVillage,
                      prefixIcon: const Icon(Icons.holiday_village_outlined),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    key: const Key('manual_save_location'),
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(context.l10n.saveLocation),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableDropdown extends StatelessWidget {
  const _SearchableDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.values,
    required this.icon,
    required this.onSelected,
    super.key,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> values;
  final IconData icon;
  final ValueChanged<String?>? onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      width: double.infinity,
      initialSelection: value,
      enabled: onSelected != null,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      label: Text(label),
      hintText: hint,
      leadingIcon: Icon(icon),
      onSelected: onSelected,
      dropdownMenuEntries: values
          .map((value) => DropdownMenuEntry(value: value, label: value))
          .toList(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
