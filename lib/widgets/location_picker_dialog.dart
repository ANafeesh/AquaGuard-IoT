import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_typography.dart';
import '../core/constants/sri_lanka_locations.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? locationName;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';
}

class LocationPickerDialog extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String? title;

  const LocationPickerDialog({
    super.key,
    this.initialLatitude = 7.2906, // Default to Kandy
    this.initialLongitude = 80.6337,
    this.title,
  });

  static Future<LocationPickerResult?> show(
    BuildContext context, {
    double initialLatitude = 7.2906,
    double initialLongitude = 80.6337,
    String? title,
  }) {
    return showDialog<LocationPickerResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LocationPickerDialog(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        title: title,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng _selectedPoint;
  late final MapController _mapController;
  String? _matchedLocationName;

  @override
  void initState() {
    super.initState();
    _selectedPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
    _mapController = MapController();
    _checkMatchingPreset(_selectedPoint);
  }

  void _checkMatchingPreset(LatLng point) {
    for (final loc in SriLankaLocations.catalog) {
      final dLat = (loc.latitude - point.latitude).abs();
      final dLng = (loc.longitude - point.longitude).abs();
      if (dLat < 0.05 && dLng < 0.05) {
        _matchedLocationName = loc.name;
        return;
      }
    }
    _matchedLocationName = null;
  }

  void _moveToLocation(double lat, double lng, {String? name}) {
    final target = LatLng(lat, lng);
    setState(() {
      _selectedPoint = target;
      _matchedLocationName = name;
    });
    _mapController.move(target, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        height: 620,
        color: isDark ? AppColors.darkBackground : AppColors.mainBackground,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAqua.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pin_drop_rounded,
                      color: AppColors.primaryDeepOcean,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? 'Select Location on Map',
                          style: (isDark
                                  ? AppTypography.darkCardTitle
                                  : AppTypography.cardTitle)
                              .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap anywhere on the map or choose a preset location',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Horizontal preset chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF1F5F9),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: SriLankaLocations.catalog.map((loc) {
                    final isCurrent = _matchedLocationName == loc.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.location_on,
                          size: 14,
                          color: isCurrent ? Colors.white : AppColors.primaryDeepOcean,
                        ),
                        label: Text(loc.name),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? Colors.white
                              : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                        ),
                        backgroundColor: isCurrent
                            ? AppColors.primaryDeepOcean
                            : (isDark ? AppColors.darkCardBackground : Colors.white),
                        side: BorderSide(
                          color: isCurrent
                              ? AppColors.primaryDeepOcean
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        onPressed: () => _moveToLocation(
                          loc.latitude,
                          loc.longitude,
                          name: loc.name,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Map Area
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPoint,
                      initialZoom: 13.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedPoint = point;
                          _checkMatchingPreset(point);
                        });
                      },
                    ),
                    children: [
                      // High-speed CDN CartoDB Voyager tiles (instant loading worldwide)
                      TileLayer(
                        urlTemplate: AppConfig.getMapTileUrl(isDark: false),
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'io.aquaguard.app',
                        errorTileCallback: (tile, error, stackTrace) {},
                      ),
                      // Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 50,
                            height: 50,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.statusAttention,
                                  size: 38,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Crosshair / instructions badge
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Tap anywhere to place the pin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Zoom Controls
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'picker_zoom_in',
                          backgroundColor:
                              isDark ? AppColors.darkCardBackground : Colors.white,
                          foregroundColor: AppColors.primaryDeepOcean,
                          child: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        FloatingActionButton.small(
                          heroTag: 'picker_zoom_out',
                          backgroundColor:
                              isDark ? AppColors.darkCardBackground : Colors.white,
                          foregroundColor: AppColors.primaryDeepOcean,
                          child: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom selection status & confirm button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded,
                          size: 18, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _matchedLocationName != null
                                  ? '$_matchedLocationName, Sri Lanka'
                                  : 'Custom Coordinates',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.primaryText,
                              ),
                            ),
                            Text(
                              '${_selectedPoint.latitude.toStringAsFixed(4)}° N, ${_selectedPoint.longitude.toStringAsFixed(4)}° E',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.secondaryText,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Confirm Location',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDeepOcean,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(
                              LocationPickerResult(
                                latitude: _selectedPoint.latitude,
                                longitude: _selectedPoint.longitude,
                                locationName: _matchedLocationName,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
