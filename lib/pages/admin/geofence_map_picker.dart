// lib/pages/admin/geofence_map_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_theme.dart';

class GeofenceMapPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final double initialRadius;
  final String storeName;

  const GeofenceMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialRadius = 100,
    required this.storeName,
  });

  @override
  State<GeofenceMapPicker> createState() => _GeofenceMapPickerState();
}

class _GeofenceMapPickerState extends State<GeofenceMapPicker> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  late double _radius;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _mapReady = false;

  // Default to Systems Plus College, Balibago, Angeles City, Pampanga
  static const _defaultLat = 15.1350;
  static const _defaultLng = 120.5927;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );
    _radius = widget.initialRadius;

    // Mark map as ready after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapReady = true;
    });
  }

  @override
  void dispose() {
    _mapReady = false;
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      if (mounted && _mapReady) {
        _mapController.move(_selectedLocation, 17);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Geofence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'latitude': _selectedLocation.latitude,
                'longitude': _selectedLocation.longitude,
                'radius': _radius,
              });
            },
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Store name header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            child: Text(
              'Setting geofence for "${widget.storeName}"',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 17,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.byteplus.app',
                    ),
                    // Geofence circle
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    // Center marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.location,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Map controls - aligned to top right
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      // GPS button
                      _mapButton(
                        icon: Iconsax.gps,
                        onTap: _isLoading ? null : _getCurrentLocation,
                        isDark: isDark,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 8),
                      // Zoom in
                      _mapButton(
                        icon: Iconsax.add,
                        onTap: () {
                          if (!_mapReady) return;
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _selectedLocation,
                            currentZoom + 1,
                          );
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      // Zoom out
                      _mapButton(
                        icon: Iconsax.minus,
                        onTap: () {
                          if (!_mapReady) return;
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _selectedLocation,
                            currentZoom - 1,
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coordinates display
                Row(
                  children: [
                    Icon(
                      Iconsax.location,
                      size: 18,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Radius slider
                Row(
                  children: [
                    Icon(
                      Iconsax.maximize_circle,
                      size: 18,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Radius:',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_radius.toInt()}m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _radius,
                    min: 25,
                    max: 500,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                      });
                    },
                  ),
                ),

                // Preset radius buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [50, 100, 200, 300, 500].map((r) {
                        final isSelected = _radius == r.toDouble();
                        return GestureDetector(
                          onTap: () => setState(() => _radius = r.toDouble()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                              ),
                            ),
                            child: Text(
                              '${r}m',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 12),

                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 18,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap on the map to set the center. Students must be within this area to place orders.',
                          style: TextStyle(fontSize: 12, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
    bool isLoading = false,
  }) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child:
              isLoading
                  ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                  : Icon(
                    icon,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    size: 20,
                  ),
        ),
      ),
    );
  }
}

