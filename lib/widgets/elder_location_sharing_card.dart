import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/elder_location_service.dart';
import '../services/i18n_service.dart';
import '../services/auth_service.dart';
import 'elder_card.dart';

class ElderLocationSharingCard extends StatelessWidget {
  const ElderLocationSharingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<ElderLocationService>(context);
    final i18n = Provider.of<I18nService>(context);
    final auth = Provider.of<AuthService>(context);

    final elderId = auth.currentUser?.effectiveElderId ?? '';
    final isSharing = locationService.isSharingActive && locationService.hasLocationPermission;
    final pos = locationService.currentPosition;
    final lastSync = locationService.lastSyncTime;

    return ElderCard(
      backgroundColor: isSharing ? const Color(0xFFE6F4F1) : const Color(0xFFFFFBEB),
      border: Border.all(
        color: isSharing ? const Color(0xFF61C5B0) : const Color(0xFFF59E0B),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSharing ? const Color(0xFF23B39B).withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSharing ? Icons.location_on : Icons.location_off,
                      color: isSharing ? const Color(0xFF23B39B) : const Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    i18n.translate('locationSharing'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2824),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSharing ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSharing ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSharing ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSharing ? 'Active' : 'Stopped',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSharing ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Informative message
          Text(
            isSharing
                ? i18n.translate('locationSharingActive')
                : (locationService.hasLocationPermission
                    ? i18n.translate('locationSharingStopped')
                    : i18n.translate('locationPermRequired')),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSharing ? const Color(0xFF1B2824) : const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 8),

          // Location info when sharing
          if (isSharing && pos != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 16, color: Color(0xFF23B39B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'GPS: ${pos.latitude.toStringAsFixed(4)}°, ${pos.longitude.toStringAsFixed(4)}° (±${pos.accuracy.toStringAsFixed(0)}m)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                    ),
                  ),
                  if (lastSync != null)
                    Text(
                      '${lastSync.minute}m ago',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Permission Request Banner if permission missing
          if (!locationService.hasLocationPermission) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.translate('locationPermRequired'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => locationService.requestLocationPermission(),
                      icon: const Icon(Icons.security, color: Colors.white, size: 18),
                      label: Text(
                        i18n.translate('allowLocationAccess'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Toggle Sharing Button
          if (locationService.hasLocationPermission) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSharing ? const Color(0xFFDC2626) : const Color(0xFF23B39B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => locationService.toggleLocationSharing(elderId),
                icon: Icon(
                  isSharing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  isSharing ? i18n.translate('stopLocationSharing') : i18n.translate('startLocationSharing'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
