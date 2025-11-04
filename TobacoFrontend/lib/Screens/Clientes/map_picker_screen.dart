import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/map_styles.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _selected;
  Position? _current;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Elegir ubicación', style: AppTheme.appBarTitleStyle),
      ),
      body: FutureBuilder<Position?>(
        future: _getCurrentPosition(),
        builder: (context, snapshot) {
          _current = snapshot.data;
          final start = widget.initial ??
              (snapshot.data != null
                  ? LatLng(snapshot.data!.latitude, snapshot.data!.longitude)
                  : const LatLng(-34.90330, -56.18825));
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: start, zoom: 15),
                onMapCreated: (c) {
                  _controller = c;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final style = isDark ? MapStyles.darkMode : MapStyles.lightMode;
                  c.setMapStyle(style);
                },
                onTap: (latLng) {
                  setState(() => _selected = latLng);
                },
                markers: {
                  if (_selected != null)
                    Marker(
                      markerId: const MarkerId('sel'),
                      position: _selected!,
                    ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    // Ubicación actual
                    FloatingActionButton(
                      heroTag: 'picker_loc',
                      mini: true,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      onPressed: _centerOnCurrent,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    // Ver selección / ajustar
                    FloatingActionButton(
                      heroTag: 'picker_fit',
                      mini: true,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      onPressed: _fitToSelection,
                      child: const Icon(Icons.zoom_out_map),
                    ),
                    const SizedBox(height: 8),
                    // Zoom in
                    FloatingActionButton(
                      heroTag: 'picker_zoom_in',
                      mini: true,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      onPressed: _zoomIn,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    // Zoom out
                    FloatingActionButton(
                      heroTag: 'picker_zoom_out',
                      mini: true,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      onPressed: _zoomOut,
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, [_selected!.latitude, _selected!.longitude]),
            icon: const Icon(Icons.check),
            label: const Text('Usar esta ubicación'),
          ),
        ),
      ),
    );
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;
      return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }

  void _centerOnCurrent() {
    if (_controller == null) return;
    final pos = _current;
    if (pos != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
      );
    }
  }

  void _fitToSelection() {
    if (_controller == null) return;
    final LatLng? a = _selected;
    final Position? b = _current;
    if (a == null && b == null) return;
    if (a != null && b != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          a.latitude < b.latitude ? a.latitude : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude,
        ),
        northeast: LatLng(
          a.latitude > b.latitude ? a.latitude : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude,
        ),
      );
      _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else {
      final target = a ?? LatLng(b!.latitude, b.longitude);
      _controller!.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    }
  }

  void _zoomIn() {
    _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _controller?.animateCamera(CameraUpdate.zoomOut());
  }
}


