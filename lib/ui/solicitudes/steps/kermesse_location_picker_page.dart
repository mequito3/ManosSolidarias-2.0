import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../widgets/app_buttons.dart';
import 'solicitud_form_step.dart';

class KermesseLocationPickerPage extends StatefulWidget {
  const KermesseLocationPickerPage({super.key, this.initialLocation});

  final SolicitudKermesseLocation? initialLocation;

  @override
  State<KermesseLocationPickerPage> createState() => _KermesseLocationPickerPageState();
}

class _KermesseLocationPickerPageState extends State<KermesseLocationPickerPage> {
  static final latlng.LatLng _boliviaCenter = latlng.LatLng(-16.290154, -63.588653);

  final MapController _mapController = MapController();
  latlng.LatLng _cameraTarget = _boliviaCenter;
  latlng.LatLng? _selected;
  String? _address;
  bool _loading = true;
  bool _locationPermissionGranted = false;
  bool _resolvingAddress = false;
  double _initialZoom = 13;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    latlng.LatLng target = _boliviaCenter;
    latlng.LatLng? selected;
    String? address;
    bool permissionGranted = false;

    if (widget.initialLocation != null) {
      selected = latlng.LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude);
      address = widget.initialLocation!.address;
      target = selected;
      permissionGranted = true;
    } else {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          permissionGranted = false;
        } else if (permission == LocationPermission.denied) {
          permissionGranted = false;
        } else {
          permissionGranted = true;
        }

        if (permissionGranted && serviceEnabled) {
          final position = await Geolocator.getCurrentPosition();
          target = latlng.LatLng(position.latitude, position.longitude);
        }
      } catch (_) {
        permissionGranted = false;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _cameraTarget = target;
      _selected = selected;
      _address = address;
      _locationPermissionGranted = permissionGranted;
      _loading = false;
      _initialZoom = selected != null ? 16 : 13;
    });

    if (_selected != null && (_address == null || _address!.isEmpty)) {
      unawaited(_updateAddress(_selected!));
    }
  }

  Future<void> _updateAddress(latlng.LatLng position) async {
    setState(() => _resolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (!mounted) {
        return;
      }
      if (placemarks.isEmpty) {
        setState(() {
          _address = null;
          _resolvingAddress = false;
        });
        return;
      }
      final placemark = placemarks.first;
      final parts = <String>[
        placemark.street ?? '',
        placemark.subLocality ?? '',
        placemark.locality ?? '',
      ]
          .where((part) => part.trim().isNotEmpty)
          .toList();
      setState(() {
        _address = parts.join(', ');
        _resolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _address = null;
        _resolvingAddress = false;
      });
    }
  }

  Future<String?> _lookupAddress(latlng.LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) {
        return null;
      }
      final placemark = placemarks.first;
      final parts = <String>[
        placemark.street ?? '',
        placemark.subLocality ?? '',
        placemark.locality ?? '',
      ]
          .where((part) => part.trim().isNotEmpty)
          .toList();
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _onMapTap(latlng.LatLng position) async {
    setState(() {
      _selected = position;
      _address = null;
    });
    await _updateAddress(position);
  }

  Future<void> _confirmSelection() async {
    if (_selected == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toca el mapa para marcar el punto exacto.')),
      );
      return;
    }

    var address = _address;
    if ((address == null || address.isEmpty) && !_resolvingAddress) {
      address = await _lookupAddress(_selected!);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      SolicitudKermesseLocation(
        latitude: _selected!.latitude,
        longitude: _selected!.longitude,
        address: address,
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (!_locationPermissionGranted) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa los permisos de ubicacion para centrar el mapa.')),
      );
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      final target = latlng.LatLng(position.latitude, position.longitude);
      _mapController.move(target, 16);
      await _onMapTap(target);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos obtener tu ubicacion actual.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicacion')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _cameraTarget,
                    initialZoom: _initialZoom,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                    onTap: (tapPosition, point) => unawaited(_onMapTap(point)),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.manosolidarias.app',
                    ),
                    if (_selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected!,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selected == null
                                    ? 'Toca el mapa para seleccionar el lugar donde se realizara la kermesse.'
                                    : 'Ubicacion seleccionada',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              if (_selected != null && _resolvingAddress)
                                Row(
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('Obteniendo direccion de referencia...')),
                                  ],
                                )
                              else if (_selected != null && _address != null)
                                Text(
                                  _address!,
                                  style: theme.textTheme.bodySmall,
                                )
                              else if (_selected != null)
                                Text(
                                  'Lat: ${_selected!.latitude.toStringAsFixed(6)} · Lng: ${_selected!.longitude.toStringAsFixed(6)}',
                                  style: theme.textTheme.bodySmall,
                                )
                              else
                                Text(
                                  'Puedes acercar el mapa o usar tu ubicacion actual para mayor precision.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Mapa provisto por OpenStreetMap. Sujeto a disponibilidad de conexion.',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: 'Confirmar ubicacion',
                        icon: Icons.check_rounded,
                        onPressed: _selected == null ? null : _confirmSelection,
                      ),
                      const SizedBox(height: 8),
                      AppSecondaryButton(
                        label: _locationPermissionGranted ? 'Centrar en mi ubicacion' : 'Cerrar',
                        icon: _locationPermissionGranted ? Icons.my_location : Icons.close,
                        onPressed:
                            _locationPermissionGranted ? _goToCurrentLocation : () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
