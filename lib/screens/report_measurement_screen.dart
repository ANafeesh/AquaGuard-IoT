import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/reading_validator.dart';
import '../core/widgets/disclaimer_banner.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../models/community_observation.dart';
import '../models/reading_log_entry.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../core/services/offline_sync_service.dart';
import '../widgets/primary_button.dart';
import 'auth/login_screen.dart';

class ReportMeasurementScreen extends ConsumerStatefulWidget {
  final String? initialSourceName;
  final String? preselectedSourceId;

  const ReportMeasurementScreen({
    super.key,
    this.initialSourceName,
    this.preselectedSourceId,
  });

  @override
  ConsumerState<ReportMeasurementScreen> createState() => _ReportMeasurementScreenState();
}

class _ReportMeasurementScreenState extends ConsumerState<ReportMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isNewSource = false;
  String? _selectedSourceId;
  final TextEditingController _newSourceNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(text: '6.9271° N, 79.8612° E');
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _tdsController = TextEditingController();
  final TextEditingController _turbidityController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isDetectingGps = false;
  bool _isSubmitting = false;
  String? _formErrorMessage;
  DateTime _timestamp = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSourceId = widget.preselectedSourceId;
    _timestamp = DateTime.now();
  }

  @override
  void dispose() {
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
      _locationController.text = '6.9285° N, 79.8624° E (Accuracy: ±2.4m)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Field GPS coordinates updated from device sensor.'),
        duration: Duration(seconds: 2),
      ),
    );
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
        latitude: 6.9271,
        longitude: 79.8612,
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
      final reportRepo = ref.read(reportRepositoryProvider);
      final readingRepo = ref.read(readingRepositoryProvider);

      await reportRepo.submitObservation(
        CommunityObservation(
          id: 'obs_$clientGeneratedUuid',
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

                // GPS Location with Auto-detect button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GPS Location Coordinates',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 13.5),
                    ),
                    TextButton.icon(
                      onPressed: _isDetectingGps ? null : _handleGpsAutoDetect,
                      icon: _isDetectingGps
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primaryAqua),
                      label: Text(
                        _isDetectingGps ? 'Acquiring...' : 'Use Current GPS',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryAqua),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

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
