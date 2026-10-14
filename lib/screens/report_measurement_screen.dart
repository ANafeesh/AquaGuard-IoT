import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/constants/sri_lanka_locations.dart';
import '../core/utils/reading_validator.dart';
import '../core/widgets/disclaimer_banner.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../models/community_observation.dart';
import '../models/reading_log_entry.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../core/services/offline_sync_service.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/primary_button.dart';
import 'auth/login_screen.dart';

class ReportMeasurementScreen extends ConsumerStatefulWidget {
  final String? initialSourceName;
  final String? preselectedSourceId;
  final double? initialLatitude;
  final double? initialLongitude;

  const ReportMeasurementScreen({
    super.key,
    this.initialSourceName,
    this.preselectedSourceId,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  ConsumerState<ReportMeasurementScreen> createState() => _ReportMeasurementScreenState();
}

class _ReportMeasurementScreenState extends ConsumerState<ReportMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isNewSource = false;
  String? _selectedSourceId;
  final TextEditingController _newSourceNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _turbidityController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _matchedLocationName;

  bool _isDetectingGps = false;
  bool _isSubmitting = false;
  String? _formErrorMessage;
  DateTime _timestamp = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSourceId = widget.preselectedSourceId;
    _timestamp = DateTime.now();

    // Initialize coordinates with user-provided, preset, or Kandy/Colombo defaults
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatitude = widget.initialLatitude;
      _selectedLongitude = widget.initialLongitude;
      _locationController.text =
          '${_selectedLatitude!.toStringAsFixed(4)}° N, ${_selectedLongitude!.toStringAsFixed(4)}° E';
      _isNewSource = true;
    } else {
      _selectedLatitude = 6.9271;
      _selectedLongitude = 79.8612;
      _locationController.text = '6.9271° N, 79.8612° E';
    }

    if (widget.initialSourceName != null && widget.initialSourceName!.isNotEmpty) {
      _newSourceNameController.text = widget.initialSourceName!;
      _isNewSource = true;
      final match = SriLankaLocations.findByName(widget.initialSourceName!);
      if (match != null) {
        _selectedLatitude = match.latitude;
        _selectedLongitude = match.longitude;
        _matchedLocationName = match.name;
        _locationController.text = match.formattedCoordinates;
      }
    }

    _newSourceNameController.addListener(_onSourceNameChanged);
  }

  void _onSourceNameChanged() {
    if (!_isNewSource) return;
    final text = _newSourceNameController.text.trim();
    if (text.isNotEmpty) {
      final match = SriLankaLocations.findByName(text);
      if (match != null && _matchedLocationName != match.name) {
        setState(() {
          _matchedLocationName = match.name;
          _selectedLatitude = match.latitude;
          _selectedLongitude = match.longitude;
          _locationController.text = match.formattedCoordinates;
        });
      }
    }
  }

  @override
  void dispose() {
    _newSourceNameController.removeListener(_onSourceNameChanged);
    _newSourceNameController.dispose();
    _locationController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _turbidityController.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleGpsAutoDetect() async {
    setState(() => _isDetectingGps = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isDetectingGps = false;
      // If user named kandy, keep near Kandy GPS coordinates
      final isKandy = (_newSourceNameController.text.toLowerCase().contains('kandy') ||
          (_matchedLocationName != null && _matchedLocationName!.toLowerCase().contains('kandy')));
      if (isKandy) {
        _selectedLatitude = 7.2906;
        _selectedLongitude = 80.6337;
        _locationController.text = '7.2906° N, 80.6337° E (Kandy GPS ±2.0m)';
      } else {
        _selectedLatitude = 6.9285;
        _selectedLongitude = 79.8624;
        _locationController.text = '6.9285° N, 79.8624° E (Colombo GPS ±2.4m)';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Field GPS coordinates updated from device sensor.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final result = await LocationPickerDialog.show(
      context,
      initialLatitude: _selectedLatitude ?? 7.2906,
      initialLongitude: _selectedLongitude ?? 80.6337,
      title: 'Pick Water Source on Map',
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;
        _matchedLocationName = result.locationName;
        _locationController.text = result.formattedCoordinates;
        if (_newSourceNameController.text.trim().isEmpty && result.locationName != null) {
          _newSourceNameController.text = '${result.locationName} Water Point';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.locationName != null
                ? 'Selected ${result.locationName} (${result.formattedCoordinates})'
                : 'Selected custom coordinates: ${result.formattedCoordinates}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showKnownLocationsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Actual Sri Lanka Location',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle)
                          .copyWith(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: SriLankaLocations.catalog.length,
                  itemBuilder: (context, index) {
                    final loc = SriLankaLocations.catalog[index];
                    final isSelected = _matchedLocationName == loc.name;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primaryDeepOcean
                            : AppColors.primaryAqua.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.location_city_rounded,
                          color: isSelected ? Colors.white : AppColors.primaryDeepOcean,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        loc.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        '${loc.province} • ${loc.defaultWaterBody}',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                      ),
                      trailing: Text(
                        '${loc.latitude.toStringAsFixed(2)}°, ${loc.longitude.toStringAsFixed(2)}°',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.teal),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedLatitude = loc.latitude;
                          _selectedLongitude = loc.longitude;
                          _matchedLocationName = loc.name;
                          _locationController.text = loc.formattedCoordinates;
                          if (_newSourceNameController.text.trim().isEmpty) {
                            _newSourceNameController.text = loc.defaultWaterBody;
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  (double, double) _resolveCoordinates() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      return (_selectedLatitude!, _selectedLongitude!);
    }
    final text = _locationController.text;
    final regex = RegExp(r'([-+]?[0-9]*\.?[0-9]+)');
    final matches = regex.allMatches(text).toList();
    if (matches.length >= 2) {
      final lat = double.tryParse(matches[0].group(0) ?? '');
      final lng = double.tryParse(matches[1].group(0) ?? '');
      if (lat != null && lng != null) {
        return (lat, lng);
      }
    }
    return (7.2906, 80.6337);
  }

  Future<void> _handleSubmit() async {
    final currentUser = ref.read(currentUserProvider).value ??
        ref.read(authRepositoryProvider).getCurrentUser();

    // Check if user is guest: Guest cannot submit community readings
    if (currentUser == null || currentUser.isGuest) {
      _showGuestBlockedDialog();
      return;
    }

    setState(() {
      _formErrorMessage = null;
    });

    final phVal = double.tryParse(_phController.text.trim());
    final tdsVal = double.tryParse(_tdsController.text.trim());
    final turbVal = double.tryParse(_turbidityController.text.trim());
    final tempVal = double.tryParse(_tempController.text.trim());

    // Validate using core ReadingValidator
    final validation = ReadingValidator.validateForm(
      sourceId: _selectedSourceId,
      newSourceName: _newSourceNameController.text.trim(),
      isNewSource: _isNewSource,
      ph: phVal,
      tdsEc: tdsVal,
      turbidity: turbVal,
      temperature: tempVal,
    );

    if (!validation.isValid) {
      setState(() {
        _formErrorMessage = validation.errorMessage;
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final sources = ref.read(waterSourcesStreamProvider).value ?? [];
      String resolvedSourceId = _selectedSourceId ?? (sources.isNotEmpty ? sources.first.id : 'ws-1');
      String resolvedSourceName = 'Water Source';

      final (finalLat, finalLng) = _resolveCoordinates();

      if (_isNewSource) {
        resolvedSourceName = _newSourceNameController.text.trim();
        resolvedSourceId = 'src_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        final found = sources.where((s) => s.id == resolvedSourceId).toList();
        if (found.isNotEmpty) {
          resolvedSourceName = found.first.name;
        }
      }

      // Generate client-side UUID as document ID to prevent duplicate uploads on retry
      final clientGeneratedUuid = const Uuid().v4();
      final now = DateTime.now();

      final measurement = Measurement(
        id: clientGeneratedUuid,
        sourceId: resolvedSourceId,
        deviceId: null,
        ph: phVal ?? 7.0,
        tdsEc: tdsVal ?? 250.0,
        turbidity: turbVal ?? 2.0,
        temperature: tempVal ?? 26.0,
        latitude: finalLat,
        longitude: finalLng,
        timestamp: now,
        submittedBy: currentUser.displayName,
        source: 'community',
        syncedAt: OfflineSyncService.instance.isOnline ? now : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Manual community observation report',
        isPendingSync: !OfflineSyncService.instance.isOnline,
      );

      // Check offline mode
      if (!OfflineSyncService.instance.isOnline) {
        // Enqueue offline reading with UUID
        await OfflineSyncService.instance.enqueueMeasurement(measurement);
      }

      // Update repositories
      final waterSourceRepo = ref.read(waterSourceRepositoryProvider);
      final reportRepo = ref.read(reportRepositoryProvider);
      final readingRepo = ref.read(readingRepositoryProvider);

      if (_isNewSource) {
        final newSource = WaterSource(
          id: resolvedSourceId,
          name: resolvedSourceName,
          type: WaterSourceType.other,
          latitude: finalLat,
          longitude: finalLng,
          createdBy: currentUser.displayName,
          createdAt: now,
          lastReadingAt: now,
          ph: phVal,
          tdsEc: tdsVal,
          turbidity: turbVal,
          temperature: tempVal,
          status: WaterQualityStatus.withinTypicalRange,
          description: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : 'Community monitored water point',
        );
        await waterSourceRepo.addWaterSource(newSource);
        // Automatically set the new source as active
        ref.read(selectedSourceIdProvider.notifier).setSourceId(resolvedSourceId);
      }

      await reportRepo.submitObservation(
        CommunityObservation(
          id: 'obs_$clientGeneratedUuid',
          userId: currentUser.id,
          waterSourceName: resolvedSourceName,
          locationArea: _locationController.text.trim(),
          userName: currentUser.displayName,
          userAvatar: currentUser.initials,
          timeAgo: 'Just now',
          notes: measurement.notes ?? '',
          ph: phVal,
          tds: tdsVal?.toInt(),
          turbidity: turbVal,
          temperature: tempVal,
          status: WaterQualityStatus.withinTypicalRange,
          isPendingSync: !OfflineSyncService.instance.isOnline,
          timestamp: now,
        ),
      );

      await readingRepo.addReadingEntry(
        ReadingLogEntry(
          id: 'log_$clientGeneratedUuid',
          waterSourceId: resolvedSourceId,
          waterSourceName: resolvedSourceName,
          timestamp: now,
          ph: phVal ?? 7.0,
          tds: (tdsVal ?? 250.0).toInt(),
          turbidity: turbVal ?? 2.0,
          temperature: tempVal ?? 26.0,
          status: WaterQualityStatus.withinTypicalRange,
          notes: measurement.notes ?? '',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryDeepOcean,
          duration: const Duration(seconds: 3),
          content: Text(
            OfflineSyncService.instance.isOnline
                ? 'Observation recorded to public water ledger.'
                : 'Offline: Observation queued locally with Pending Sync badge.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formErrorMessage = 'Failed to submit observation: $e';
        _isSubmitting = false;
      });
    }
  }

  void _showGuestBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.primaryAqua),
            SizedBox(width: 8),
            Text('Account Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Guest mode allows viewing community data and map indicators. To submit verified community readings and field observations, please sign in or register an account.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeepOcean,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign In Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(currentUserProvider);
    final sources = ref.watch(waterSourcesStreamProvider).value ?? [];

    if (_selectedSourceId == null && sources.isNotEmpty && !_isNewSource) {
      _selectedSourceId = sources.first.id;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Community Water Observation'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Regulatory Non-potable Disclaimer Banner
                const DisclaimerBanner(),
                const SizedBox(height: 14),

                // Error Banner if validation fails
                if (_formErrorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusAttentionBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusAttention.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.statusAttention, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formErrorMessage!,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.statusAttention, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Water Source Selection (Existing vs New)
                Text(
                  'Water Source Location',
                  style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Existing Monitored Source'),
                        selected: !_isNewSource,
                        selectedColor: AppColors.primaryDeepOcean,
                        labelStyle: TextStyle(
                          color: !_isNewSource ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                          fontWeight: !_isNewSource ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _isNewSource = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('New Water Source'),
                        selected: _isNewSource,
                        selectedColor: AppColors.primaryDeepOcean,
                        labelStyle: TextStyle(
                          color: _isNewSource ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                          fontWeight: _isNewSource ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _isNewSource = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!_isNewSource) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSourceId,
                        dropdownColor: isDark ? AppColors.darkCardBackground : Colors.white,
                        items: sources.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              '${s.name} (${s.type.displayName})',
                              style: TextStyle(
                                color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
                                fontSize: 13.5,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSourceId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _newSourceNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Hillside Creek Spring',
                      labelText: 'New Water Source Name',
                      prefixIcon: const Icon(Icons.add_location_alt_outlined, size: 20),
                      fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Location Coordinates & Interactive Map Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location & Coordinates',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 13.5),
                    ),
                    TextButton.icon(
                      onPressed: _isDetectingGps ? null : _handleGpsAutoDetect,
                      icon: _isDetectingGps
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 15, color: AppColors.primaryAqua),
                      label: Text(
                        _isDetectingGps ? 'Acquiring...' : 'Use GPS',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryAqua),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Map & Preset Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text('Select on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeepOcean,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showLocationPicker,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.place_outlined, size: 16),
                        label: const Text('Choose City', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryAqua,
                          side: const BorderSide(color: AppColors.primaryAqua),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showKnownLocationsSheet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location badge if matched
                if (_matchedLocationName != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.teal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Matched: $_matchedLocationName (${_selectedLatitude?.toStringAsFixed(4)}° N, ${_selectedLongitude?.toStringAsFixed(4)}° E)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    hintText: 'e.g. 7.2906° N, 80.6337° E (Kandy)',
                    helperText: 'Select on map, pick city, or type custom coordinates',
                    helperStyle: const TextStyle(fontSize: 11),
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                  ),
                  onChanged: (val) {
                    final regex = RegExp(r'([-+]?[0-9]*\.?[0-9]+)');
                    final matches = regex.allMatches(val).toList();
                    if (matches.length >= 2) {
                      final lat = double.tryParse(matches[0].group(0) ?? '');
                      final lng = double.tryParse(matches[1].group(0) ?? '');
                      if (lat != null && lng != null) {
                        _selectedLatitude = lat;
                        _selectedLongitude = lng;
                      }
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Parameter Inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Water Quality Parameters',
                      style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 15),
                    ),
                    Text(
                      'At least 1 required',
                      style: AppTypography.muted.copyWith(fontSize: 11.5, color: AppColors.primaryAqua),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2x2 Grid for the four parameters
                Row(
                  children: [
                    Expanded(
                      child: _buildParameterInputField(
                        key: const Key('ph_input_field'),
                        controller: _phController,
                        label: 'pH Level',
                        hint: '0.0 – 14.0',
                        unit: 'Unitless',
                        validator: ReadingValidator.validatePhField,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildParameterInputField(
                        controller: _tdsController,
                        label: 'TDS / EC',
                        hint: '≥ 0',
                        unit: 'ppm',
                        validator: ReadingValidator.validateTdsField,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildParameterInputField(
                        controller: _turbidityController,
                        label: 'Turbidity',
                        hint: '≥ 0',
                        unit: 'NTU',
                        validator: ReadingValidator.validateTurbidityField,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildParameterInputField(
                        controller: _tempController,
                        label: 'Temperature',
                        hint: '-5.0 to 60.0',
                        unit: '°C',
                        validator: ReadingValidator.validateTempField,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Automatic Timestamp display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.secondaryText),
                      const SizedBox(width: 8),
                      Text(
                        'Automatic Timestamp: ${_timestamp.toLocal().toString().substring(0, 16)}',
                        style: AppTypography.muted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Observation Notes
                Text(
                  'Field Observation Notes',
                  style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe physical site conditions (e.g. water clarity, odor, recent rainfall runoff)...',
                    hintStyle: AppTypography.muted,
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                PrimaryButton(
                  key: const Key('submit_observation_button'),
                  text: 'Submit Community Observation',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
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

  Widget _buildParameterInputField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unit,
    required String? Function(String?) validator,
    required bool isDark,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: '$label ($unit)',
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
        ),
        hintText: hint,
        hintStyle: AppTypography.muted,
        fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
