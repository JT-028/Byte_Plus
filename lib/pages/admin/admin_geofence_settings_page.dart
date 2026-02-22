// lib/pages/admin/admin_geofence_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_theme.dart';

class AdminGeofenceSettingsPage extends StatefulWidget {
  const AdminGeofenceSettingsPage({super.key});

  @override
  State<AdminGeofenceSettingsPage> createState() =>
      _AdminGeofenceSettingsPageState();
}

class _AdminGeofenceSettingsPageState extends State<AdminGeofenceSettingsPage> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  double _radius = 500; // Default 500m for campus
  bool _isEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _mapReady = false;

  // Default to Systems Plus College, Balibago, Angeles City, Pampanga
  static const _defaultLat = 15.1350;
  static const _defaultLng = 120.5927;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadSettings();
  }

  @override
  void dispose() {
    _mapReady = false;
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('geofence')
              .doc('campus')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isEnabled = data['enabled'] ?? false;
          _radius = (data['radius'] ?? 500).toDouble();
          if (data['latitude'] != null && data['longitude'] != null) {
            _selectedLocation = LatLng(
              data['latitude'].toDouble(),
              data['longitude'].toDouble(),
            );
          }
        });
      }

      // Mark map as ready after a brief delay to ensure it's initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapReady = true;
        _mapController.move(
          _selectedLocation ?? LatLng(_defaultLat, _defaultLng),
          15,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
      // Even on error, center on default location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapReady = true;
        _mapController.move(LatLng(_defaultLat, _defaultLng), 15);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to set the campus center'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('geofence')
          .doc('campus')
          .set({
            'enabled': _isEnabled,
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'radius': _radius,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campus geofence settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

      if (!mounted) return;

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      if (mounted && _mapReady) {
        _mapController.move(_selectedLocation!, 15);
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

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      children: [
        // Settings header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? AppColors.surfaceDark : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.location, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus Geofence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Set the allowed area for students to use the app',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Enable/Disable toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.backgroundDark : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _isEnabled
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            _isEnabled
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEnabled ? Iconsax.shield_tick : Iconsax.shield_cross,
                        color: _isEnabled ? AppColors.primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geofence Restriction',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _isEnabled
                                ? 'Students can only order within the campus area'
                                : 'Students can order from anywhere',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isEnabled,
                      onChanged: (value) => setState(() => _isEnabled = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Map section
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _selectedLocation ?? LatLng(_defaultLat, _defaultLng),
                  initialZoom: 15,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.byteplus.app',
                  ),
                  // Show geofence circle
                  if (_selectedLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation!,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withOpacity(0.2),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  // Show center marker
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Instruction overlay
              if (_selectedLocation == null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on the map to set the campus center',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Map controls - aligned to right side
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
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
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
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
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

        // Radius slider and save button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Radius slider
                Row(
                  children: [
                    Icon(
                      Iconsax.maximize_circle,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Radius:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_radius.toInt()}m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '(${(_radius / 1000).toStringAsFixed(1)}km)',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => _radius = value),
                ),
                // Quick radius buttons
                Wrap(
                  spacing: 8,
                  children:
                      [200, 500, 1000, 2000, 3000, 5000].map((r) {
                        final isSelected = (_radius - r).abs() < 50;
                        return ChoiceChip(
                          label: Text(r >= 1000 ? '${r ~/ 1000}km' : '${r}m'),
                          selected: isSelected,
                          onSelected:
                              (_) => setState(() => _radius = r.toDouble()),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                // Save button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.tick_circle, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Save Geofence Settings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ),
      ],
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
