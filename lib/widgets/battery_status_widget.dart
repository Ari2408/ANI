import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/battery_service.dart';
import '../services/i18n_service.dart';

class BatteryStatusWidget extends StatelessWidget {
  final bool showPercentageText;
  final Color? textColor;

  const BatteryStatusWidget({
    Key? key,
    this.showPercentageText = true,
    this.textColor,
  }) : super(key: key);

  IconData _getBatteryIcon(int level, BatteryState state) {
    if (state == BatteryState.charging || state == BatteryState.full) {
      return Icons.battery_charging_full;
    }
    if (level <= 15) {
      return Icons.battery_alert;
    } else if (level <= 30) {
      return Icons.battery_3_bar;
    } else if (level <= 60) {
      return Icons.battery_4_bar;
    } else if (level <= 90) {
      return Icons.battery_5_bar;
    }
    return Icons.battery_full;
  }

  Color _getBatteryColor(int level, BatteryState state) {
    if (state == BatteryState.charging || state == BatteryState.full) {
      return const Color(0xFF1B5E20); // Green
    }
    if (level < 20) {
      return const Color(0xFFC62828); // Red warning
    } else if (level < 40) {
      return const Color(0xFFE65100); // Orange
    }
    return const Color(0xFF1B2824); // Standard header color
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BatteryService>(
      builder: (context, battery, child) {
        final level = battery.batteryLevel;
        final state = battery.batteryState;
        final icon = _getBatteryIcon(level, state);
        final color = _getBatteryColor(level, state);

        final isCharging = battery.isCharging;
        final isLow = battery.isLowBattery;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final i18n = Provider.of<I18nService>(context, listen: false);
            final statusStr = isCharging
                ? 'Charging'
                : (isLow ? 'Low Battery (<20%)' : 'Discharging');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${i18n.translate("appName")}: Battery $level% ($statusStr)',
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLow
                  ? Colors.red.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLow
                    ? const Color(0xFFD32F2F)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                if (showPercentageText) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$level%${isCharging ? "⚡" : ""}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isLow
                          ? const Color(0xFFB71C1C)
                          : (textColor ?? const Color(0xFF1B2824)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
