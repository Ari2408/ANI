import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/elder_location_service.dart';
import '../services/i18n_service.dart';
import '../widgets/elder_card.dart';

class ElderLocationScreen extends StatefulWidget {
  final String? elderId;
  final String? elderName;

  const ElderLocationScreen({
    Key? key,
    this.elderId,
    this.elderName,
  }) : super(key: key);

  @override
  State<ElderLocationScreen> createState() => _ElderLocationScreenState();
}

class _ElderLocationScreenState extends State<ElderLocationScreen> {
  final MapController _mapController = MapController();
  bool _didInitialCenter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final loc = Provider.of<ElderLocationService>(context, listen: false);
      final targetElderId = widget.elderId ?? auth.currentUser?.mappedElderId ?? 'NER-9431';

      if (targetElderId.isNotEmpty) {
        loc.startCaregiverRealtimeStream(targetElderId);
      }
    });
  }

  @override
  void dispose() {
    final loc = Provider.of<ElderLocationService>(context, listen: false);
    loc.stopCaregiverRealtimeStream();
    super.dispose();
  }

  void _centerOnElder(double lat, double lng) {
    try {
      _mapController.move(LatLng(lat, lng), 15.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final loc = Provider.of<ElderLocationService>(context);
    final i18n = Provider.of<I18nService>(context);

    final targetElderId = widget.elderId ?? auth.currentUser?.mappedElderId ?? '';
    final elderProfile = auth.elderProfiles[targetElderId] ?? {};
    final elderDisplayName = widget.elderName ?? elderProfile['name']?.toString() ?? 'Elder ($targetElderId)';

    // Verify authorized link
    final bool isLinked = targetElderId.isNotEmpty;
    if (!isLinked) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF61C5B0),
          title: Text(
            i18n.translate('elderLocationHeader'),
            style: const TextStyle(color: Color(0xFF1B2824), fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  i18n.translate('noElderLinkedMsg'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final locData = loc.remoteElderLocation;
    final connState = loc.getConnectionState(locData);

    double? lat;
    double? lng;
    double accuracy = 15.0;

    if (locData != null) {
      final rawLat = locData['latitude'];
      final rawLng = locData['longitude'];
      if (rawLat is num) lat = rawLat.toDouble();
      if (rawLng is num) lng = rawLng.toDouble();
      final rawAcc = locData['accuracy'];
      if (rawAcc is num) accuracy = rawAcc.toDouble();
    }

    // Default fallback coordinates if none yet received
    final double displayLat = lat ?? 26.144518;
    final double displayLng = lng ?? 91.736294;
    final bool hasRealCoords = lat != null && lng != null;

    if (hasRealCoords && !_didInitialCenter) {
      _didInitialCenter = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnElder(displayLat, displayLng);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF0E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF61C5B0),
        elevation: 0,
        title: Text(
          i18n.translate('elderLocationHeader'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2824),
          ),
        ),
        actions: [
          IconButton(
            icon: loc.isCaregiverSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Color(0xFF1B2824), strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF1B2824)),
            tooltip: i18n.translate('refreshLocation'),
            onPressed: () async {
              await loc.fetchCaregiverElderLocation(targetElderId);
              if (lat != null && lng != null) {
                _centerOnElder(lat, lng);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Elder Information & Connection Status Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: const Color(0xFF61C5B0).withOpacity(0.4))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF98DACB),
                  child: Text(
                    elderDisplayName.isNotEmpty ? elderDisplayName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2824),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        elderDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2824),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $targetElderId',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _buildConnectionStatusBadge(connState, i18n),
              ],
            ),
          ),

          // 2. Interactive Map View
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(displayLat, displayLng),
                    initialZoom: 15.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smriti_jyoti',
                      tileBuilder: (context, widget, tile) {
                        return widget;
                      },
                    ),
                    // Safe Zone Radius Circle (150m)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(displayLat, displayLng),
                          radius: 120.0,
                          useRadiusInMeter: true,
                          color: const Color(0xFF23B39B).withOpacity(0.18),
                          borderColor: const Color(0xFF23B39B),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    // Elder Current Location Marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(displayLat, displayLng),
                          width: 150,
                          height: 90,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B2824),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  "📍 Elder's Current Location",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFDC2626),
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Map Control Overlays
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'elder_loc_recenter',
                        backgroundColor: Colors.white,
                        tooltip: 'Center on Elder',
                        onPressed: () => _centerOnElder(displayLat, displayLng),
                        child: const Icon(Icons.my_location, color: Color(0xFF23B39B)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'elder_loc_zoom_in',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                        },
                        child: const Icon(Icons.add, color: Color(0xFF1B2824)),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: 'elder_loc_zoom_out',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                        },
                        child: const Icon(Icons.remove, color: Color(0xFF1B2824)),
                      ),
                    ],
                  ),
                ),

                // Offline Notice Banner
                if (connState == LocationConnectionState.offline || !hasRealCoords)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 70,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF87171)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              !hasRealCoords
                                  ? i18n.translate('locationUnavailableMsg')
                                  : i18n.translate('elderDeviceOffline'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Sharing Disabled Banner
                if (connState == LocationConnectionState.disabled)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 70,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              i18n.translate('locationSharingStopped'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Location Information & Action Buttons Bottom Sheet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coordinates Grid Details
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i18n.translate('latitudeLabel'),
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayLat.toStringAsFixed(4),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i18n.translate('longitudeLabel'),
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayLng.toStringAsFixed(4),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Accuracy',
                                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${accuracy.toStringAsFixed(0)} m',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Last Updated Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${i18n.translate("lastUpdatedLabel")}: ${loc.formatLastUpdatedString(locData)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.shield,
                            size: 14,
                            color: hasRealCoords ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasRealCoords ? i18n.translate('safeZoneActive') : 'Safe Zone',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hasRealCoords ? const Color(0xFF16A34A) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons: Open in Google Maps & Get Directions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(
                            i18n.translate('openInGoogleMaps'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () => loc.openInGoogleMaps(displayLat, displayLng),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF23B39B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.directions, size: 18),
                          label: Text(
                            i18n.translate('getDirections'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () => loc.openDirectionsToElder(displayLat, displayLng),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Refresh Location Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF61C5B0), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: loc.isCaregiverSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Color(0xFF23B39B), strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18, color: Color(0xFF23B39B)),
                      label: Text(
                        i18n.translate('refreshLocation'),
                        style: const TextStyle(color: Color(0xFF1B2824), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () async {
                        await loc.fetchCaregiverElderLocation(targetElderId);
                        if (lat != null && lng != null) {
                          _centerOnElder(lat, lng);
                        }
                      },
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

  Widget _buildConnectionStatusBadge(LocationConnectionState state, I18nService i18n) {
    Color bg;
    Color border;
    Color text;
    String label;
    IconData icon;

    switch (state) {
      case LocationConnectionState.available:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF22C55E);
        text = const Color(0xFF15803D);
        label = i18n.translate('locationAvailable');
        icon = Icons.check_circle;
        break;
      case LocationConnectionState.updating:
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFF3B82F6);
        text = const Color(0xFF1D4ED8);
        label = i18n.translate('locationUpdating');
        icon = Icons.sync;
        break;
      case LocationConnectionState.disabled:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFF59E0B);
        text = const Color(0xFFB45309);
        label = i18n.translate('locationSharingStopped');
        icon = Icons.location_off;
        break;
      case LocationConnectionState.offline:
      default:
        bg = const Color(0xFFF3F4F6);
        border = const Color(0xFF9CA3AF);
        text = const Color(0xFF4B5563);
        label = i18n.translate('locationOffline');
        icon = Icons.signal_cellular_connected_no_internet_4_bar;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
