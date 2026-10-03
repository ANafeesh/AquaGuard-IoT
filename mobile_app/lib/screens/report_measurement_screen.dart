import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/parameter_thresholds.dart';
import '../models/community_observation.dart';
import '../models/reading_log_entry.dart';
import '../models/water_source.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/primary_button.dart';

class ReportMeasurementScreen extends ConsumerStatefulWidget {
  final String? initialSourceName;

  const ReportMeasurementScreen({super.key, this.initialSourceName});

  @override
  ConsumerState<ReportMeasurementScreen> createState() => _ReportMeasurementScreenState();
}

class _ReportMeasurementScreenState extends ConsumerState<ReportMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSource;
  final TextEditingController _locationController = TextEditingController(text: '6.9271° N, 79.8612° E');
  final TextEditingController _phController = TextEditingController(text: '7.2');
  final TextEditingController _tdsController = TextEditingController(text: '320');
  final TextEditingController _turbidityController = TextEditingController(text: '3.4');
  final TextEditingController _tempController = TextEditingController(text: '28.4');
  final TextEditingController _notesController = TextEditingController();
  bool _isDetectingGps = false;
  String? _attachedPhotoName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.initialSourceName;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _turbidityController.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleGpsAutoDetect() async {
    final granted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.primaryAqua),
              SizedBox(width: 8),
              Text('Location Permission', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'AquaGuard requests location access to capture your sample GPS coordinates accurately for the community map.',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Deny', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeepOcean,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Allow GPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (granted != true) return;

    setState(() => _isDetectingGps = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    final allSources = ref.read(waterSourcesStreamProvider).value ?? [];
    final matchedSource = allSources.firstWhere(
      (s) => s.name == _selectedSource,
      orElse: () => allSources.first,
    );

    setState(() {
      _isDetectingGps = false;
      _locationController.text = '${matchedSource.coordinates} (Accuracy: ±3.8m)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS coordinates acquired with high accuracy.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Attach Sample Photo', style: AppTypography.sectionHeading),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Capture or select photo evidence of your water test site.', style: AppTypography.muted),
                const SizedBox(height: 16),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.altLightAquaBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.teal),
                  ),
                  title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Capture live water sample bottle or site condition', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _attachedPhotoName = 'sample_field_camera_test.jpg');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.altLightAquaBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.teal),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Select existing specimen photo from device storage', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _attachedPhotoName = 'water_specimen_vial.jpg');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final reportRepo = ref.read(reportRepositoryProvider);
      final readingRepo = ref.read(readingRepositoryProvider);
      final sources = ref.read(waterSourcesStreamProvider).value ?? [];

      final ph = double.tryParse(_phController.text) ?? 7.0;
      final tds = int.tryParse(_tdsController.text) ?? 300;
      final turb = double.tryParse(_turbidityController.text) ?? 3.0;
      final temp = double.tryParse(_tempController.text) ?? 28.0;

      final isTypical = ParameterThresholds.isPhTypical(ph) &&
          ParameterThresholds.isTdsTypical(tds.toDouble()) &&
          ParameterThresholds.isTurbidityTypical(turb) &&
          ParameterThresholds.isTempTypical(temp);

      final selectedSourceObj = sources.firstWhere(
        (s) => s.name == _selectedSource,
        orElse: () => sources.isNotEmpty
            ? sources.first
            : const WaterSource(
                id: 'ws-1',
                name: 'Lake View Point',
                coordinates: '6.9271° N, 79.8612° E',
                locationArea: 'Lake View Point Reservoir',
                ph: 7.2,
                tds: 320,
                turbidity: 3.4,
                temperature: 28.4,
                status: WaterQualityStatus.withinTypicalRange,
                lastUpdated: 'Just now',
                description: 'Urban municipal water catchment.',
                latitude: 6.9271,
                longitude: 79.8612,
              ),
      );

      final newObservation = CommunityObservation(
        id: 'obs-${DateTime.now().millisecondsSinceEpoch}',
        waterSourceName: _selectedSource ?? 'Selected Water Source',
        locationArea: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : selectedSourceObj.locationArea,
        userName: 'AquaGuard User',
        userAvatar: 'AU',
        timeAgo: 'Just now',
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Field observation submitted with calibrated sensor telemetry.',
        ph: ph,
        tds: tds,
        turbidity: turb,
        temperature: temp,
        status: isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual,
        hasPhoto: _attachedPhotoName != null,
        helpfulCount: 1,
      );

      // 1. Submit observation to ReportRepository
      await reportRepo.submitObservation(newObservation);

      // 2. Add reading entry to ReadingRepository so History and Trends immediately update
      final newReadingEntry = ReadingLogEntry(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        waterSourceId: selectedSourceObj.id,
        waterSourceName: selectedSourceObj.name,
        timestamp: DateTime.now(),
        ph: ph,
        tds: tds,
        turbidity: turb,
        temperature: temp,
        status: isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Observation recorded via Report Measurement flow.',
      );
      await readingRepo.addReadingEntry(newReadingEntry);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.statusNormal),
                SizedBox(width: 8),
                Text('Observation Submitted'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your water observation has been published and logged into community telemetry records.',
                  style: TextStyle(fontSize: 13.5),
                ),
                SizedBox(height: 12),
                Text(
                  'Notice: Submitted measurements are community observations and provide participatory tracking for water quality.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back
                },
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDeepOcean)),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Report Measurement'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
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
                // Disclaimer Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.altLightAquaBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Submitted measurements are community observations and may require further verification before formal records.',
                          style: AppTypography.secondary.copyWith(
                            color: AppColors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Water Source Dropdown
                Text('Water Source', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: sourcesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Loading sources...'),
                    ),
                    error: (err, stack) => const Text('Unable to load sources'),
                    data: (sources) {
                      _selectedSource ??= sources.first.name;

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSource,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
                          items: sources.map((s) {
                            return DropdownMenuItem(
                              value: s.name,
                              child: Text(s.name, style: AppTypography.body),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSource = val);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Location Coordinates with GPS Auto-detect
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Location / GPS Coordinates', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _isDetectingGps ? null : _handleGpsAutoDetect,
                      icon: _isDetectingGps
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAqua),
                            )
                          : const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primaryAqua),
                      label: Text(
                        _isDetectingGps ? 'Detecting...' : 'Auto-Detect GPS',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryAqua),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _locationController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Location coordinates required' : null,
                  decoration: InputDecoration(
                    hintText: 'e.g. 6.9271° N, 79.8612° E (manual override permitted)',
                    hintStyle: AppTypography.muted.copyWith(fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.place_outlined, color: AppColors.primaryAqua, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Parameter Inputs Grid with Strict Range Validation
                Text('Sensor / Test Parameters', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: ParameterThresholds.phLabel,
                        controller: _phController,
                        unit: 'pH',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null) return 'Invalid number';
                          if (val < 0.0 || val > 14.0) return '0.0 - 14.0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: ParameterThresholds.tdsLabel,
                        controller: _tdsController,
                        unit: ParameterThresholds.tdsUnit,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = int.tryParse(v);
                          if (val == null) return 'Invalid integer';
                          if (val < 0 || val > 5000) return '0 - 5000';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: ParameterThresholds.turbidityLabel,
                        controller: _turbidityController,
                        unit: ParameterThresholds.turbidityUnit,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null) return 'Invalid number';
                          if (val < 0.0 || val > 500.0) return '0.0 - 500.0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: ParameterThresholds.tempShortLabel,
                        controller: _tempController,
                        unit: ParameterThresholds.tempUnit,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null) return 'Invalid number';
                          if (val < 0.0 || val > 60.0) return '0.0 - 60.0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Observation Notes
                Text('Observation Notes', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe clarity, surface appearance, odor, or local weather conditions...',
                    hintStyle: AppTypography.muted,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Optional Photo Attachment with Picker
                Text('Optional Photo Evidence', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showPhotoPickerSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _attachedPhotoName != null ? AppColors.primaryAqua : AppColors.border,
                      ),
                    ),
                    child: _attachedPhotoName != null
                        ? Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.altLightAquaBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.water_drop_rounded, color: AppColors.teal),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _attachedPhotoName!,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const Text('Photo attached • Tap to change', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.statusAttention),
                                onPressed: () {
                                  setState(() => _attachedPhotoName = null);
                                },
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.mutedText),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to attach camera or gallery photo',
                                style: AppTypography.secondary.copyWith(
                                  color: AppColors.secondaryText,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                PrimaryButton(
                  text: 'Submit Observation',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.muted.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.mutedText),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

