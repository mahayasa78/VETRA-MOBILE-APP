import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_colors.dart';

/// Screen untuk pilih lokasi dari peta (GoFood-style).
/// Mengembalikan [String] alamat yang dipilih via Navigator.pop.
class LocationPickerScreen extends StatefulWidget {
  /// Koordinat awal (opsional). Jika null, akan coba ambil GPS.
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(-6.9175, 107.6191); // Default: Bandung
  String _address = "Geser peta untuk memilih lokasi...";
  bool _isLoadingAddress = false;
  bool _isMapMoving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _center = widget.initialPosition!;
    }
    // Reverse geocode posisi awal setelah build selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_center);
    });
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[];
        if ((p.street ?? '').isNotEmpty) parts.add(p.street!);
        if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
        if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
        if ((p.subAdministrativeArea ?? '').isNotEmpty) parts.add(p.subAdministrativeArea!);
        if ((p.administrativeArea ?? '').isNotEmpty) parts.add(p.administrativeArea!);

        setState(() {
          _address = parts.isNotEmpty ? parts.join(', ') : "Lokasi tidak ditemukan";
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onMapMoveStart(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _isMapMoving = true;
        _address = "Memindahkan...";
      });
    }
  }

  void _onMapMoveEnd(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    final newCenter = camera.center;
    setState(() {
      _center = newCenter;
      _isMapMoving = false;
    });
    _reverseGeocode(newCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Pilih Lokasi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── PETA ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  _onMapMoveStart(event.camera, event.source != MapEventSource.mapController);
                } else if (event is MapEventMoveEnd) {
                  _onMapMoveEnd(event.camera, event.source != MapEventSource.mapController);
                }
              },
            ),
            children: [
              // Tile OpenStreetMap (gratis, tanpa API key)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.vetra_app',
              ),
            ],
          ),

          // ── PIN TENGAH (selalu di center peta) ──
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(
                0,
                _isMapMoving ? -12 : 0,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 26),
                  ),
                  // Bayangan pin
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(top: 4),
                    width: _isMapMoving ? 10 : 16,
                    height: _isMapMoving ? 4 : 6,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TOMBOL LOKASIKU (kanan atas peta) ──
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // ── PANEL BAWAH: Alamat + Tombol Konfirmasi ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    "Lokasi yang dipilih",
                    style: TextStyle(fontSize: 12, color: AppColors.darkGrey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isMapMoving ? "Memindahkan..." : "Mencari alamat...",
                                    style: const TextStyle(color: AppColors.darkGrey, fontSize: 14),
                                  ),
                                ],
                              )
                            : Text(
                                _address,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: (_isLoadingAddress || _isMapMoving)
                          ? null
                          : () {
                              Navigator.pop(context, _address);
                            },
                      child: const Text(
                        "Konfirmasi Lokasi Ini",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Izin lokasi ditolak.")),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izin lokasi diblokir. Aktifkan di Pengaturan.")),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newPos = LatLng(pos.latitude, pos.longitude);
      _mapController.move(newPos, 16.0);
      setState(() => _center = newPos);
      _reverseGeocode(newPos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mendapatkan lokasi: $e")),
        );
      }
    }
  }
}
