import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/home_tank.dart';
import '../../../models/water_source.dart';
import '../../../providers/app_state_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_preferences_provider.dart';
import '../../../widgets/location_picker_dialog.dart';
import '../../../widgets/primary_button.dart';

class RegisterTankScreen extends ConsumerStatefulWidget {
  final HomeTank? initialTank;

  const RegisterTankScreen({
    super.key,
    this.initialTank,
  });

  @override
  ConsumerState<RegisterTankScreen> createState() => _RegisterTankScreenState();
}

class _RegisterTankScreenState extends ConsumerState<RegisterTankScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _deviceIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _notesController;

  HomeTankType _selectedType = HomeTankType.rooftop;
  String _locationMethod = 'gps'; // 'gps' | 'map' | 'manual'
  double _latitude = 6.9271;
  double _longitude = 79.8612;
  bool _isLocationConfirmed = false;
  bool _isDetectingGps = false;
  bool _isVerifyingDevice = false;
  bool _isSubmitting = false;
  String? _deviceError;
  String? _generalError;

  bool get _isEditing => widget.initialTank != null;

  @override
  void initState() {
    super.initState();
    final tank = widget.initialTank;

    _nameController = TextEditingController(text: tank?.tankName ?? 'My Home Tank');
    _capacityController = TextEditingController(
      text: tank?.capacityLiters != null ? tank!.capacityLiters.toString() : '1000',
    );
    _deviceIdController = TextEditingController(text: tank?.deviceId ?? '');
    _notesController = TextEditingController(text: tank?.notes ?? '');

    if (tank != null) {
      _selectedType = tank.tankType;
      _latitude = tank.location.latitude;
      _longitude = tank.location.longitude;
      _locationMethod = tank.location.locationMethod;
      _isLocationConfirmed = tank.location.isConfirmed;
      _addressController = TextEditingController(text: tank.location.address);
      _latController = TextEditingController(text: _latitude.toStringAsFixed(5));
      _lngController = TextEditingController(text: _longitude.toStringAsFixed(5));
    } else {
      _addressController = TextEditingController(text: 'Residential Area, Colombo 05');
      _latController = TextEditingController(text: _latitude.toStringAsFixed(5));
      _lngController = TextEditingController(text: _longitude.toStringAsFixed(5));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _deviceIdController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleGpsDetect() async {
    setState(() {
      _isDetectingGps = true;
      _generalError = null;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    // Simulate GPS acquisition with high accuracy
    setState(() {
      _isDetectingGps = false;
      _locationMethod = 'gps';
      _latitude = 6.9214;
      _longitude = 79.8652;
      _latController.text = _latitude.toStringAsFixed(5);
      _lngController.text = _longitude.toStringAsFixed(5);
      _addressController.text = 'Colombo 07, Western Province (GPS ±2.1m)';
      _isLocationConfirmed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Installation location captured via GPS and confirmed.'),
        backgroundColor: AppColors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleMapPicker() async {
    final result = await LocationPickerDialog.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      title: 'Pick Tank Installation Location',
    );

    if (result != null && mounted) {
      setState(() {
        _locationMethod = 'map';
        _latitude = result.latitude;
        _longitude = result.longitude;
        _latController.text = _latitude.toStringAsFixed(5);
        _lngController.text = _longitude.toStringAsFixed(5);
        if (result.locationName != null && result.locationName!.isNotEmpty) {
          _addressController.text = '${result.locationName}, Sri Lanka';
        } else {
          _addressController.text =
              'Selected Location (${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E)';
        }
        _isLocationConfirmed = true;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _generalError = null;
      _deviceError = null;
    });

    final user = ref.read(currentUserProvider).value;
    final effectiveUid = (user != null && user.id.isNotEmpty) ? user.id : 'usr_demo_01';
    final repo = ref.read(homeTankRepositoryProvider);
    final prefs = ref.read(userPreferencesProvider);

    // Verify Device Availability if device ID is specified
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isNotEmpty) {
      setState(() => _isVerifyingDevice = true);
      final isAvailable = await repo.verifyDeviceAvailability(
        deviceId,
        effectiveUid,
        isDemo: prefs.isDemoMode,
      );
      setState(() => _isVerifyingDevice = false);

      if (!isAvailable) {
        setState(() {
          _isSubmitting = false;
          _deviceError = 'Device node "$deviceId" is already registered to another user account.';
        });
        return;
      }
    }

    // Parse lat/long
    final lat = double.tryParse(_latController.text.trim()) ?? _latitude;
    final lng = double.tryParse(_lngController.text.trim()) ?? _longitude;
    final capacity = int.tryParse(_capacityController.text.trim());

    final location = HomeTankInstallationLocation(
      latitude: lat,
      longitude: lng,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'Private Home Location',
      locationMethod: _locationMethod,
      isConfirmed: _isLocationConfirmed,
    );

    final now = DateTime.now();

    final tank = HomeTank(
      id: widget.initialTank?.id ?? 'tank_${const Uuid().v4().substring(0, 8)}',
      ownerUid: effectiveUid,
      tankName: _nameController.text.trim(),
      tankType: _selectedType,
      capacityLiters: capacity,
      location: location,
      deviceId: deviceId.isNotEmpty ? deviceId : null,
      visibility: 'private', // Strictly enforce private
      createdAt: widget.initialTank?.createdAt ?? now,
      updatedAt: now,
      lastReadingAt: widget.initialTank?.lastReadingAt,
      isActive: true,
      ph: widget.initialTank?.ph,
      tdsEc: widget.initialTank?.tdsEc,
      turbidity: widget.initialTank?.turbidity,
      temperature: widget.initialTank?.temperature,
      status: widget.initialTank?.status ?? WaterQualityStatus.noRecentData,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    try {
      if (_isEditing) {
        await repo.updateTank(tank, isDemo: prefs.isDemoMode);
      } else {
        await repo.registerTank(tank, isDemo: prefs.isDemoMode);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.teal,
            content: Text(
              _isEditing ? 'Home tank updated successfully.' : 'Home water tank registered privately.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _generalError = 'Error saving tank: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Home Water Tank' : 'Register Home Water Tank',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Privacy Assurance Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.teal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Private Residential Monitoring',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'This tank and its exact installation location are strictly confidential. '
                              'They are visible ONLY to you and will NEVER be shown on the public community map.',
                              style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                                  .copyWith(fontSize: 11.5, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Tank Details
                Text(
                  'Tank Details',
                  style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)
                      .copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Tank Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tank Name *',
                    hintText: 'e.g. My Home Tank, Rooftop Overhead Tank',
                    prefixIcon: const Icon(Icons.water_rounded, color: AppColors.primaryDeepOcean),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a tank name' : null,
                ),
                const SizedBox(height: 14),

                // Tank Type Selector
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tank Type',
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<HomeTankType>(
                      value: _selectedType,
                      isDense: true,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkCardBackground : Colors.white,
                      items: HomeTankType.values.map((type) {
                        return DropdownMenuItem<HomeTankType>(
                          value: type,
                          child: Text(type.displayName, style: const TextStyle(fontSize: 13.5)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Capacity (Optional Liters)
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Capacity (Liters, Optional)',
                    hintText: 'e.g. 500, 1000, 2000',
                    prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primaryAqua),
                    suffixText: 'L',
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Section 2: ESP32 Hardware Node Association
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ESP32 Sensor Association',
                      style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)
                          .copyWith(fontSize: 16),
                    ),
                    Text(
                      'Optional',
                      style: AppTypography.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Associate an ESP32 hardware device node deployed at your tank to receive live telemetry.',
                  style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _deviceIdController,
                  decoration: InputDecoration(
                    labelText: 'Sensor Node Device ID',
                    hintText: 'e.g. esp32_tank_node_01',
                    prefixIcon: const Icon(Icons.memory_rounded, color: AppColors.primaryDeepOcean),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                if (_deviceError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _deviceError!,
                    style: const TextStyle(color: AppColors.statusAttention, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),

                // Section 3: Installation Location
                Text(
                  'Installation Location',
                  style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)
                      .copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Specify where your water tank is installed. Choose one of the 3 methods below:',
                  style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),

                // 3 Location Action Buttons
                Row(
                  children: [
                    // Option 1: GPS
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isDetectingGps
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                              )
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Use GPS', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _locationMethod == 'gps' ? AppColors.teal : null,
                          side: BorderSide(
                            color: _locationMethod == 'gps' ? AppColors.teal : (isDark ? AppColors.darkBorder : AppColors.border),
                            width: _locationMethod == 'gps' ? 1.5 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isDetectingGps ? null : _handleGpsDetect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Option 2: Select on Map
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text('Pick on Map', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _locationMethod == 'map' ? AppColors.primaryAqua : null,
                          side: BorderSide(
                            color: _locationMethod == 'map' ? AppColors.primaryAqua : (isDark ? AppColors.darkBorder : AppColors.border),
                            width: _locationMethod == 'map' ? 1.5 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleMapPicker,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Option 3: Manual
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                        label: const Text('Manual', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _locationMethod == 'manual' ? AppColors.primaryDeepOcean : null,
                          side: BorderSide(
                            color: _locationMethod == 'manual' ? AppColors.primaryDeepOcean : (isDark ? AppColors.darkBorder : AppColors.border),
                            width: _locationMethod == 'manual' ? 1.5 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _locationMethod = 'manual';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Confirmed Location Banner / Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isLocationConfirmed ? AppColors.teal : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: _isLocationConfirmed ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isLocationConfirmed ? Icons.check_circle_rounded : Icons.pending_rounded,
                                size: 16,
                                color: _isLocationConfirmed ? AppColors.teal : AppColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isLocationConfirmed ? 'Location Confirmed' : 'Confirmation Needed',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isLocationConfirmed ? AppColors.teal : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Method: ${_locationMethod.toUpperCase()}',
                            style: AppTypography.muted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Address Field
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address or Location Description *',
                          hintText: 'e.g. 24 Havelock Road, Colombo 05',
                          prefixIcon: const Icon(Icons.home_rounded, color: AppColors.primaryDeepOcean),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter the installation address' : null,
                      ),
                      const SizedBox(height: 10),

                      // Coordinates row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) _latitude = parsed;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) _longitude = parsed;
                              },
                            ),
                          ),
                        ],
                      ),

                      if (!_isLocationConfirmed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Confirm This Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setState(() {
                                _isLocationConfirmed = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes / Description
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes or Maintenance Log (Optional)',
                    hintText: 'e.g. Tank cleaned on Oct 1st, fitted with fine mesh filter',
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                if (_generalError != null) ...[
                  Text(
                    _generalError!,
                    style: const TextStyle(color: AppColors.statusAttention, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],

                // Submit Button
                PrimaryButton(
                  text: _isEditing ? 'Save Changes' : 'Register Tank Privately',
                  isLoading: _isSubmitting || _isVerifyingDevice,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
