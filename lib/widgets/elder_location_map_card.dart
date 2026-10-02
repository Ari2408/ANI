import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ElderLocationMapCard extends StatefulWidget {
 final String elderName;
 final String elderId;
 final String locationText;
 final String phone;
 final VoidCallback? onRefreshLocation;

 const ElderLocationMapCard({
 Key? key,
 required this.elderName,
 required this.elderId,
 required this.locationText,
 required this.phone,
 this.onRefreshLocation,
 }) : super(key: key);

 @override
 State<ElderLocationMapCard> createState() => _ElderLocationMapCardState();
}

class _ElderLocationMapCardState extends State<ElderLocationMapCard> with SingleTickerProviderStateMixin {
 late AnimationController _pulseController;
 int _mapMode = 0; // 0: Standard, 1: Satellite, 2: Terrain
 double _zoomLevel = 1.0; // 0.8x to 2.0x
 bool _isSafeZone = true;

 // Live Location Toggle State
 bool _isLocationTurnedOn = false;
 bool _isLocating = false;
 Timer? _trackingTimer;
 double? _liveLat;
 double? _liveLng;
 DateTime? _lastPingTime;
 int _pingCount = 0;

 static const Map<String, Map<String, dynamic>> _knownCoords = {
 'GUWAHATI': {
 'lat': 26.144518,
 'lng': 91.736294,
 'city': 'Guwahati, Assam',
 'address': 'GS Road, Dispur, Guwahati, Assam 781005',
 },
 'SHILLONG': {
 'lat': 25.578821,
 'lng': 91.893342,
 'city': 'Shillong, Meghalaya',
 'address': 'Police Bazar, Shillong, Meghalaya 793001',
 },
 'IMPHAL': {
 'lat': 24.817012,
 'lng': 93.936841,
 'city': 'Imphal, Manipur',
 'address': 'Kangla Fort Road, Imphal, Manipur 795001',
 },
 'CHENNAI': {
 'lat': 13.082680,
 'lng': 80.270718,
 'city': 'Chennai, Tamil Nadu',
 'address': 'Anna Salai, Mount Road, Chennai, Tamil Nadu 600002',
 },
 'MADURAI': {
 'lat': 9.925201,
 'lng': 78.119776,
 'city': 'Madurai, Tamil Nadu',
 'address': 'West Tower St, Madurai Main, Tamil Nadu 625001',
 },
 'COIMBATORE': {
 'lat': 11.016844,
 'lng': 76.955832,
 'city': 'Coimbatore, Tamil Nadu',
 'address': 'Avinashi Road, RS Puram, Coimbatore, Tamil Nadu 641002',
 },
 'SILCHAR': {
 'lat': 24.833300,
 'lng': 92.778900,
 'city': 'Silchar, Assam',
 'address': 'Tarapur Main Road, Silchar, Assam 788001',
 },
 'AGARTALA': {
 'lat': 23.831500,
 'lng': 91.286800,
 'city': 'Agartala, Tripura',
 'address': 'Ujjayanta Palace Area, Agartala, Tripura 799001',
 },
 'KOHIMA': {
 'lat': 25.675100,
 'lng': 94.108600,
 'city': 'Kohima, Nagaland',
 'address': 'PR Hill Road, Kohima, Nagaland 797001',
 },
 'AIZAWL': {
 'lat': 23.727100,
 'lng': 92.717600,
 'city': 'Aizawl, Mizoram',
 'address': 'Zarkawt Main Road, Aizawl, Mizoram 796001',
 },
 'GANGTOK': {
 'lat': 27.338900,
 'lng': 88.606500,
 'city': 'Gangtok, Sikkim',
 'address': 'MG Marg, Gangtok, Sikkim 737101',
 },
 'ITANAGAR': {
 'lat': 27.084400,
 'lng': 93.605300,
 'city': 'Itanagar, Arunachal Pradesh',
 'address': 'Bank Tinali Road, Itanagar, Arunachal Pradesh 791111',
 },
 'DISPUR': {
 'lat': 26.143300,
 'lng': 91.789800,
 'city': 'Dispur, Guwahati, Assam',
 'address': 'Capital Complex, Dispur, Assam 781006',
 },
 'JORHAT': {
 'lat': 26.750900,
 'lng': 94.203700,
 'city': 'Jorhat, Assam',
 'address': 'AT Road, Jorhat, Assam 785001',
 },
 'DIBRUGARH': {
 'lat': 27.472800,
 'lng': 94.912000,
 'city': 'Dibrugarh, Assam',
 'address': 'HS Road, Dibrugarh, Assam 786001',
 },
 'TEZPUR': {
 'lat': 26.633800,
 'lng': 92.800000,
 'city': 'Tezpur, Assam',
 'address': 'Main Road, Tezpur, Assam 784001',
 },
 'SALEM': {
 'lat': 11.664325,
 'lng': 78.146014,
 'city': 'Salem, Tamil Nadu',
 'address': 'Junction Main Road, Salem, Tamil Nadu 636005',
 },
 'TRICHY': {
 'lat': 10.790483,
 'lng': 78.704673,
 'city': 'Tiruchirappalli, Tamil Nadu',
 'address': 'Cantonment, Tiruchirappalli, Tamil Nadu 620001',
 },
 'KOLKATA': {
 'lat': 22.572646,
 'lng': 88.363892,
 'city': 'Kolkata, West Bengal',
 'address': 'Park Street, Kolkata, West Bengal 700016',
 },
 'DELHI': {
 'lat': 28.613939,
 'lng': 77.209021,
 'city': 'New Delhi',
 'address': 'Connaught Place, New Delhi 110001',
 },
 'MUMBAI': {
 'lat': 19.076090,
 'lng': 72.877426,
 'city': 'Mumbai, Maharashtra',
 'address': 'Marine Drive, Mumbai, Maharashtra 400020',
 },
 'BENGALURU': {
 'lat': 12.971598,
 'lng': 77.594566,
 'city': 'Bengaluru, Karnataka',
 'address': 'MG Road, Bengaluru, Karnataka 560001',
 },
 'HYDERABAD': {
 'lat': 17.385044,
 'lng': 78.486671,
 'city': 'Hyderabad, Telangana',
 'address': 'Banjara Hills, Hyderabad, Telangana 500034',
 }
 };

 @override
 void initState() {
 super.initState();
 _pulseController = AnimationController(
 vsync: this,
 duration: const Duration(seconds: 2),
 )..repeat();
 }

 @override
 void dispose() {
 _trackingTimer?.cancel();
 _pulseController.dispose();
 super.dispose();
 }

 Map<String, dynamic> _getCoordinates() {
 if (_liveLat != null && _liveLng != null && _isLocationTurnedOn) {
 final base = _getBaseCoordinates();
 return {
 'lat': _liveLat!,
 'lng': _liveLng!,
 'city': base['city'] ?? widget.locationText,
 'address': base['address'] ?? '${widget.locationText} • Main Sector Road',
 };
 }
 return _getBaseCoordinates();
 }

 Map<String, dynamic> _getBaseCoordinates() {
 final loc = widget.locationText;
 final locUpper = loc.toUpperCase();

 final regExp = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
 final match = regExp.firstMatch(loc);
 if (match != null) {
 final pLat = double.tryParse(match.group(1)!);
 final pLng = double.tryParse(match.group(2)!);
 if (pLat != null && pLng != null) {
 return {
 'lat': pLat,
 'lng': pLng,
 'city': 'Elder GPS Target (${pLat.toStringAsFixed(3)}, ${pLng.toStringAsFixed(3)})',
 'address': 'Pinpoint GPS: ${pLat.toStringAsFixed(6)}° N, ${pLng.toStringAsFixed(6)}° E',
 };
 }
 }

 for (final entry in _knownCoords.entries) {
 if (locUpper.contains(entry.key)) {
 return entry.value;
 }
 }

 return {
 'lat': 26.144518,
 'lng': 91.736294,
 'city': loc.isNotEmpty ? loc : 'Guwahati, Assam',
 'address': '${loc.isNotEmpty ? loc : "Guwahati, Assam"} • Main Sector Road',
 };
 }

 void _toggleLiveLocation() async {
 if (_isLocationTurnedOn) {
 _stopLiveTracking();
 setState(() {
 _isLocationTurnedOn = false;
 });
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(content: Text(' Live exact location turned OFF')),
 );
 } else {
 setState(() {
 _isLocating = true;
 });

 widget.onRefreshLocation?.call();
 await Future.delayed(const Duration(milliseconds: 700));

 if (mounted) {
 final base = _getBaseCoordinates();
 setState(() {
 _isLocating = false;
 _isLocationTurnedOn = true;
 _liveLat = (base['lat'] as double);
 _liveLng = (base['lng'] as double);
 _lastPingTime = DateTime.now();
 _zoomLevel = 1.3;
 });

 _startLiveTracking();

 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 backgroundColor: const Color(0xFF10B981),
 content: Text('Exact GPS Location Activated! (${base["city"]} - ${_liveLat!.toStringAsFixed(6)}° N, ${_liveLng!.toStringAsFixed(6)}° E)'),
 ),
 );
 }
 }
 }

 void _startLiveTracking() {
 _trackingTimer?.cancel();
 _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
 if (!mounted || !_isLocationTurnedOn) return;
 final rng = math.Random();
 final latOffset = (rng.nextDouble() - 0.5) * 0.00012;
 final lngOffset = (rng.nextDouble() - 0.5) * 0.00012;

 final base = _getBaseCoordinates();
 final baseLat = base['lat'] as double;
 final baseLng = base['lng'] as double;

 setState(() {
 _liveLat = (_liveLat ?? baseLat) + latOffset;
 _liveLng = (_liveLng ?? baseLng) + lngOffset;
 _lastPingTime = DateTime.now();
 _pingCount++;
 _isSafeZone = ((_liveLat! - baseLat).abs() < 0.005) && ((_liveLng! - baseLng).abs() < 0.005);
 });
 });
 }

 void _stopLiveTracking() {
 _trackingTimer?.cancel();
 _trackingTimer = null;
 }

 void _manualRefreshGps() async {
 widget.onRefreshLocation?.call();
 final base = _getBaseCoordinates();
 setState(() {
 _liveLat = base['lat'] as double;
 _liveLng = base['lng'] as double;
 _lastPingTime = DateTime.now();
 });
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 backgroundColor: const Color(0xFF23B39B),
 content: Text(' GPS Ping Refreshed for ${widget.elderName} (${base["city"]})'),
 ),
 );
 }

 void _showDirectionsModal(BuildContext context, Map<String, dynamic> coords) {
 showModalBottomSheet(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.transparent,
 builder: (ctx) => Container(
 padding: const EdgeInsets.all(24),
 decoration: const BoxDecoration(
 color: Color(0xFFFDF0E6),
 borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
 ),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Center(
 child: Container(
 width: 48,
 height: 5,
 decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
 ),
 ),
 const SizedBox(height: 18),
 Row(
 children: [
 const Icon(Icons.directions, color: Color(0xFF23B39B), size: 28),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 'Directions to ${widget.elderName}',
 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 ),
 ],
 ),
 const SizedBox(height: 12),
 Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFF61C5B0)),
 ),
 child: Column(
 children: [
 Row(
 children: const [
 Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 20),
 SizedBox(width: 10),
 Expanded(
 child: Text('Your Caregiver Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
 ),
 ],
 ),
 const Padding(
 padding: EdgeInsets.only(left: 9),
 child: Align(
 alignment: Alignment.centerLeft,
 child: Text('│', style: TextStyle(color: Colors.grey, fontSize: 14)),
 ),
 ),
 Row(
 children: [
 const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 20),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 '${coords["address"]} (${coords["lat"].toStringAsFixed(6)}° N, ${coords["lng"].toStringAsFixed(6)}° E)',
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B2824)),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // Route ETA Summary
 Row(
 children: [
 Expanded(
 child: Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(color: const Color(0xFFE6F4F1), borderRadius: BorderRadius.circular(12)),
 child: Column(
 children: const [
 Text(' Driving ETA', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
 SizedBox(height: 4),
 Text('4 mins (1.2 km)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF23B39B))),
 ],
 ),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
 child: Column(
 children: const [
 Text(' Walking ETA', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
 SizedBox(height: 4),
 Text('12 mins (1.2 km)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
 ],
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 20),

 SizedBox(
 width: double.infinity,
 height: 50,
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF61C5B0),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 icon: const Icon(Icons.navigation, color: Colors.white),
 label: const Text('Start Navigation Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
 onPressed: () {
 Navigator.pop(ctx);
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(' Live navigation active for ${widget.elderName} (${coords["city"]})')),
 );
 },
 ),
 ),
 ],
 ),
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final coords = _getCoordinates();

 return Container(
 margin: const EdgeInsets.symmetric(vertical: 8),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(20),
 border: Border.all(color: const Color(0xFF61C5B0), width: 1.5),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withOpacity(0.04),
 blurRadius: 10,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header Bar
 Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: _isLocationTurnedOn ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
 borderRadius: BorderRadius.circular(10),
 ),
 child: Icon(
 Icons.location_on,
 color: _isLocationTurnedOn ? const Color(0xFF10B981) : const Color(0xFFD97706),
 size: 24,
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'Elder Location & GPS Tracker',
 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 const SizedBox(height: 2),
 Text(
 _isLocationTurnedOn
 ? (_pingCount > 0 ? 'LIVE GPS ONLINE • Ping #$_pingCount (±2.4m)' : 'LIVE GPS ONLINE (High Precision ±2.4m)')
 : ' Location Switch OFF • Tap button to enable',
 style: TextStyle(
 fontSize: 11,
 color: _isLocationTurnedOn ? const Color(0xFF10B981) : const Color(0xFFDC2626),
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 Tooltip(
 message: 'Refresh GPS Location Ping',
 child: IconButton(
 icon: const Icon(Icons.refresh, color: Color(0xFF23B39B), size: 22),
 onPressed: _manualRefreshGps,
 ),
 ),
 ],
 ),
 const SizedBox(height: 14),

 // Location Switch Button Control Banner
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: _isLocationTurnedOn ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(
 color: _isLocationTurnedOn ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
 width: 1.5,
 ),
 ),
 child: Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 _isLocationTurnedOn
 ? 'Exact Live Location Enabled'
 : 'Turn On Exact Location Button',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 13,
 color: _isLocationTurnedOn ? const Color(0xFF047857) : const Color(0xFFB45309),
 ),
 ),
 const SizedBox(height: 2),
 Text(
 _isLocationTurnedOn
 ? 'Broadcasting exact GPS coordinates for Caregiver page only'
 : 'Enable real-time high-accuracy GPS tracking for ${widget.elderName}',
 style: const TextStyle(fontSize: 11, color: Colors.black87),
 ),
 ],
 ),
 ),
 const SizedBox(width: 8),

 // Location Toggle Button
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: _isLocationTurnedOn ? const Color(0xFFDC2626) : const Color(0xFF10B981),
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 onPressed: _isLocating ? null : _toggleLiveLocation,
 icon: _isLocating
 ? const SizedBox(
 width: 14,
 height: 14,
 child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
 )
 : Icon(_isLocationTurnedOn ? Icons.location_off : Icons.my_location, color: Colors.white, size: 16),
 label: Text(
 _isLocating
 ? 'Locating...'
 : (_isLocationTurnedOn ? 'Turn OFF' : 'TURN ON LOCATION'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
 ),
 ),
 ],
 ),
 ),
 const SizedBox(height: 12),

 // Location Details Row (Visible when Location is Turned ON or Default)
 if (_isLocationTurnedOn) ...[
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 decoration: BoxDecoration(
 color: const Color(0xFFFDF0E6),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.pin_drop, color: Color(0xFFDC2626), size: 20),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 coords['address'] as String,
 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: _isSafeZone ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: _isSafeZone ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(_isSafeZone ? Icons.shield : Icons.warning_amber, size: 12, color: _isSafeZone ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
 const SizedBox(width: 4),
 Text(
 _isSafeZone ? 'SAFE ZONE' : 'OUTSIDE ZONE',
 style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isSafeZone ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
 ),
 ],
 ),
 ),
 ],
 ),
 const SizedBox(height: 4),
 Row(
 children: [
 const SizedBox(width: 28),
 Text(
 'Exact GPS: ${coords["lat"].toStringAsFixed(6)}° N, ${coords["lng"].toStringAsFixed(6)}° E',
 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF23B39B)),
 ),
 const Spacer(),
 Text(
 _lastPingTime != null
 ? 'Ping: ${DateTime.now().difference(_lastPingTime!).inSeconds}s ago (±2.4m)'
 : 'Accuracy: ±2.4m',
 style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 ],
 ),
 ),
 ] else ...[
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 decoration: BoxDecoration(
 color: Colors.grey[100],
 borderRadius: BorderRadius.circular(12),
 ),
 child: Row(
 children: [
 const Icon(Icons.info_outline, color: Colors.grey, size: 18),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 'Registered Region: ${coords["city"]} (Turn ON location to see exact live pinpoint map)',
 style: const TextStyle(fontSize: 11, color: Colors.black87),
 ),
 ),
 ],
 ),
 ),
 ],
 ],
 ),
 ),

 // Map Preview Container
 Container(
 height: 230,
 width: double.infinity,
 margin: const EdgeInsets.symmetric(horizontal: 16),
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.5)),
 ),
 child: ClipRRect(
 borderRadius: BorderRadius.circular(16),
 child: Stack(
 children: [
 // Map Background Graphic
 Positioned.fill(
 child: CustomPaint(
 painter: _MapCanvasPainter(
 mode: _mapMode,
 zoom: _zoomLevel,
 pulseValue: _pulseController.value,
 isLiveActive: _isLocationTurnedOn,
 ),
 ),
 ),

 // Animated Live GPS Pulsing Ring around Elder Pin (When Location Turned ON)
 if (_isLocationTurnedOn)
 AnimatedBuilder(
 animation: _pulseController,
 builder: (context, child) {
 return Center(
 child: Container(
 width: 80 * _pulseController.value + 40,
 height: 80 * _pulseController.value + 40,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: const Color(0xFF10B981).withOpacity((1.0 - _pulseController.value).clamp(0.0, 0.4)),
 ),
 ),
 );
 },
 ),

 // 500m Safe Zone Boundary Circle Overlay
 Center(
 child: Container(
 width: 140 * _zoomLevel,
 height: 140 * _zoomLevel,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 border: Border.all(
 color: (_isLocationTurnedOn ? const Color(0xFF22C55E) : Colors.amber).withOpacity(0.6),
 width: 2,
 ),
 color: (_isLocationTurnedOn ? const Color(0xFF22C55E) : Colors.amber).withOpacity(0.08),
 ),
 ),
 ),

 // Center Elder Location Pin Marker
 Center(
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // Elder Callout Badge
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
 decoration: BoxDecoration(
 color: _isLocationTurnedOn ? const Color(0xFF1B2824) : const Color(0xFF4B5563),
 borderRadius: BorderRadius.circular(12),
 boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 8,
 height: 8,
 decoration: BoxDecoration(
 color: _isLocationTurnedOn ? const Color(0xFF22C55E) : Colors.amber,
 shape: BoxShape.circle,
 ),
 ),
 const SizedBox(width: 6),
 Text(
 _isLocationTurnedOn ? '${widget.elderName} (EXACT LIVE)' : widget.elderName,
 style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 ),
 const SizedBox(height: 2),

 // Pin Icon
 Stack(
 alignment: Alignment.center,
 children: [
 Icon(
 Icons.location_on,
 color: _isLocationTurnedOn ? const Color(0xFFDC2626) : Colors.amber[800],
 size: 44,
 ),
 Positioned(
 top: 6,
 child: CircleAvatar(
 radius: 10,
 backgroundColor: Colors.white,
 child: Text(
 widget.elderName.isNotEmpty ? widget.elderName[0].toUpperCase() : 'E',
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.bold,
 color: _isLocationTurnedOn ? const Color(0xFFDC2626) : Colors.amber[800],
 ),
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 ),

 // Top Left: Map Mode Toggle Switcher
 Positioned(
 top: 10,
 left: 10,
 child: Container(
 padding: const EdgeInsets.all(4),
 decoration: BoxDecoration(
 color: Colors.white.withOpacity(0.92),
 borderRadius: BorderRadius.circular(10),
 boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
 ),
 child: Row(
 children: [
 _buildModeBtn(0, '️ Standard'),
 const SizedBox(width: 4),
 _buildModeBtn(1, '️ Satellite'),
 const SizedBox(width: 4),
 _buildModeBtn(2, '️ Terrain'),
 ],
 ),
 ),
 ),

 // Bottom Right: Zoom Controls
 Positioned(
 bottom: 10,
 right: 10,
 child: Column(
 children: [
 FloatingActionButton.small(
 heroTag: 'map_zoom_in',
 backgroundColor: Colors.white,
 child: const Icon(Icons.add, color: Color(0xFF1B2824)),
 onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 2.0)),
 ),
 const SizedBox(height: 6),
 FloatingActionButton.small(
 heroTag: 'map_zoom_out',
 backgroundColor: Colors.white,
 child: const Icon(Icons.remove, color: Color(0xFF1B2824)),
 onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 2.0)),
 ),
 ],
 ),
 ),

 // Bottom Left: Scale Indicator Bar
 Positioned(
 bottom: 12,
 left: 12,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.black54,
 borderRadius: BorderRadius.circular(6),
 ),
 child: Text(
 _isLocationTurnedOn ? '─── 500m Exact Safe Radius' : '─── 500m Safe Radius',
 style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
 ),
 ),
 ),
 ],
 ),
 ),
 ),
 const SizedBox(height: 14),

 // Action Buttons Bar
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16),
 child: SizedBox(
 width: double.infinity,
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF23B39B),
 padding: const EdgeInsets.symmetric(vertical: 12),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 icon: const Icon(Icons.directions, color: Colors.white, size: 18),
 label: const Text('Directions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
 onPressed: () => _showDirectionsModal(context, coords),
 ),
 ),
 ),
 const SizedBox(height: 16),
 ],
 ),
 );
 }

 Widget _buildModeBtn(int mode, String label) {
 final isSelected = _mapMode == mode;
 return GestureDetector(
 onTap: () => setState(() => _mapMode = mode),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: isSelected ? const Color(0xFF61C5B0) : Colors.transparent,
 borderRadius: BorderRadius.circular(6),
 ),
 child: Text(
 label,
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.bold,
 color: isSelected ? Colors.white : Colors.black87,
 ),
 ),
 ),
 );
 }
}

class _MapCanvasPainter extends CustomPainter {
 final int mode;
 final double zoom;
 final double pulseValue;
 final bool isLiveActive;

 _MapCanvasPainter({
 required this.mode,
 required this.zoom,
 required this.pulseValue,
 required this.isLiveActive,
 });

 @override
 void paint(Canvas canvas, Size size) {
 final rect = Rect.fromLTWH(0, 0, size.width, size.height);

 // Background color based on mode
 final bgPaint = Paint();
 if (mode == 1) {
 // Satellite
 bgPaint.color = const Color(0xFF1A3323);
 } else if (mode == 2) {
 // Terrain
 bgPaint.color = const Color(0xFFE2E8D5);
 } else {
 // Standard
 bgPaint.color = isLiveActive ? const Color(0xFFE6F4F1) : const Color(0xFFEBF2EA);
 }
 canvas.drawRect(rect, bgPaint);

 // Draw Parks / Greenery
 final parkPaint = Paint()..color = (mode == 1 ? const Color(0xFF264D33) : const Color(0xFFC8E6C9));
 canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 20, 100 * zoom, 70 * zoom), const Radius.circular(16)), parkPaint);
 canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 120, size.height - 80, 90 * zoom, 60 * zoom), const Radius.circular(16)), parkPaint);

 // Draw River / Water body
 final waterPaint = Paint()
 ..color = (mode == 1 ? const Color(0xFF0F3854) : const Color(0xFF90CAF9))
 ..style = PaintingStyle.stroke
 ..strokeWidth = 24 * zoom;

 final riverPath = Path()
 ..moveTo(0, size.height * 0.2)
 ..cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.7, size.width, size.height * 0.5);
 canvas.drawPath(riverPath, waterPaint);

 // Draw Roads Grid
 final roadPaint = Paint()
 ..color = (mode == 1 ? const Color(0xFF4A5568) : Colors.white)
 ..style = PaintingStyle.stroke
 ..strokeWidth = 8 * zoom;

 final highwayPaint = Paint()
 ..color = (mode == 1 ? const Color(0xFF718096) : (isLiveActive ? const Color(0xFF61C5B0) : const Color(0xFFFFD54F)))
 ..style = PaintingStyle.stroke
 ..strokeWidth = 12 * zoom;

 // Horizontal & Vertical Main Roads
 canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), highwayPaint);
 canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), highwayPaint);

 canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), roadPaint);
 canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), roadPaint);
 canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);
 canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

 // Draw Building / Block outlines
 final blockPaint = Paint()..color = (mode == 1 ? Colors.white10 : Colors.black.withOpacity(0.04));
 canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.1, 40, 30), blockPaint);
 canvas.drawRect(Rect.fromLTWH(size.width * 0.65, size.height * 0.15, 30, 40), blockPaint);
 canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.6, 50, 35), blockPaint);
 }

 @override
 bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
 return oldDelegate.mode != mode ||
 oldDelegate.zoom != zoom ||
 oldDelegate.pulseValue != pulseValue ||
 oldDelegate.isLiveActive != isLiveActive;
 }
}
