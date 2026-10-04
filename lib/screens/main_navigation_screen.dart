import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i18n_service.dart';
import '../services/auth_service.dart';
import '../services/schedule_service.dart';
import '../services/memory_lane_service.dart';
import 'patient_home_screen.dart';
import 'cognitive_games_screen.dart';
import 'schedule_reminders_screen.dart';
import 'memory_lane_screen.dart';
import 'caregiver_dashboard_screen.dart';
import 'elder_location_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthService>(context, listen: false);
      final i18n = Provider.of<I18nService>(context, listen: false);
      final schedule = Provider.of<ScheduleService>(context, listen: false);
      final memory = Provider.of<MemoryLaneService>(context, listen: false);

      if (auth.currentUser != null && auth.currentUser!.language.isNotEmpty) {
        i18n.setLanguage(auth.currentUser!.language);
      }

      final activeElderId = auth.currentUser?.effectiveElderId ?? '';
      if (activeElderId.isNotEmpty) {
        await auth.fetchElderProfileCloud(activeElderId);
        await schedule.updateElderId(activeElderId);
        memory.setCurrentElderId(activeElderId);
      }
    });
  }

  void _showAccountDialog(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final i18n = Provider.of<I18nService>(context, listen: false);
    final user = auth.currentUser;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          user?.name ?? i18n.translate('userProfileTitle'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              avatar: Icon(Icons.verified, size: 16, color: Colors.white),
              label: Text(
                i18n.translate('verifiedOtp'),
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Color(0xFF61C5B0),
            ),
            SizedBox(height: 10),
            Text('${i18n.translate("email")}: ${user?.emergencyPhone.isNotEmpty == true ? user!.emergencyPhone : (user?.caretakerPhone.isNotEmpty == true ? user!.caretakerPhone : (user?.email ?? 'N/A'))}', style: TextStyle(fontSize: 13)),
            SizedBox(height: 4),
            Text('${i18n.translate("roleLabel")}: ${user?.role == 'elder' ? i18n.translate('elderRoleTitle') : i18n.translate('elderRoleTitle')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('${i18n.translate("region")}: ${user?.location ?? 'Assam'}', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            if (user?.mappedElderId != null && user!.mappedElderId.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFF59E0B)),
                ),
                child: Column(
                  children: [
                    Text(i18n.translate('mapElderIdLabel'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    const SizedBox(height: 4),
                    Text(
                      user.mappedElderId,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD97706), letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            child: Text(i18n.translate('logoutBtn'), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF61C5B0)),
            onPressed: () => Navigator.pop(ctx),
            child: Text(i18n.translate('closeBtn'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNotificationBanner(BuildContext context) {
    final schedule = Provider.of<ScheduleService>(context);
    final i18n = Provider.of<I18nService>(context);
    final notif = schedule.activeNotification;

    if (notif == null) return const SizedBox.shrink();

    final isHydration = notif['isHydration'] == true;
    final titleKey = notif['titleKey'] ?? (isHydration ? 'hourlyHydrationTitle' : 'scheduledNotificationTitle');
    final descKey = notif['descKey'] ?? (isHydration ? 'hourlyHydrationDesc' : 'scheduledNotificationDesc');

    String descText = i18n.translate(descKey);
    if (!isHydration && notif['itemTitle'] != null && notif['time'] != null) {
      final timeStr = notif['time'];
      descText = i18n.translate('scheduledNotificationDesc').replaceAll('{time}', '$timeStr (${notif['itemTitle']})');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHydration ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHydration ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(isHydration ? Icons.water_drop : Icons.notifications, color: isHydration ? const Color(0xFF23B39B) : const Color(0xFF4A90E2), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.translate(titleKey),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isHydration ? const Color(0xFF1E40AF) : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descText,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => schedule.dismissNotification(),
              ),
            ],
          ),
          if (isHydration) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1D4ED8),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.local_drink, size: 16, color: Colors.white),
                  label: Text(i18n.translate('logWaterBtn'), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    schedule.logWaterGlass();
                    _showHydrationSuccessDialog(context, i18n, schedule);
                  },
                ),
              ],
            )
          ] else ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                  label: Text(
                    (notif['isRoutine'] == true) ? i18n.translate('notStartedBtn') : i18n.translate('yetToTakeBtn'),
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => schedule.markReminderYetToTake(notif['reminderId'] ?? ''),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.check_circle, size: 16, color: Colors.white),
                  label: Text(
                    (notif['isRoutine'] == true) ? i18n.translate('startedBtn') : i18n.translate('takenBtn'),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => schedule.markReminderTaken(notif['reminderId'] ?? ''),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final auth = Provider.of<AuthService>(context);
    final schedule = Provider.of<ScheduleService>(context, listen: false);
    final user = auth.currentUser;

    if (user != null) {
      final activeElderId = user.effectiveElderId;
      if (activeElderId.isNotEmpty) {
        schedule.setCurrentElderId(activeElderId);
      }
    }

    final bool isCaretaker = user?.role == 'caretaker';

    // Screens configured strictly based on logged in Role: Caretaker vs Elder
    final List<Widget> screens = isCaretaker
        ? [
            CaregiverDashboardScreen(), // Caregiver's primary homepage dashboard
            PatientHomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
            ScheduleRemindersScreen(),
            MemoryLaneScreen(),
          ]
        : [
            PatientHomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
            CognitiveGamesScreen(),
            ScheduleRemindersScreen(),
            MemoryLaneScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isCaretaker
        ? [
            BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined, size: 22), label: i18n.translate('caregiver')),
            BottomNavigationBarItem(icon: Icon(Icons.elderly_outlined, size: 22), label: i18n.translate('elderVitals')),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined, size: 22), label: i18n.translate('schedules')),
            BottomNavigationBarItem(icon: Image.asset('assets/images/camera_icon.png', width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (ctx, err, stack) => const Icon(Icons.photo_library, size: 22)), label: i18n.translate('memory')),
          ]
        : [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 22), label: i18n.translate('home')),
            BottomNavigationBarItem(icon: Icon(Icons.extension_outlined, size: 22), label: i18n.translate('games')),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined, size: 22), label: i18n.translate('schedule')),
            BottomNavigationBarItem(icon: Image.asset('assets/images/camera_icon.png', width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (ctx, err, stack) => const Icon(Icons.photo_library, size: 22)), label: i18n.translate('memory')),
          ];

    final activeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF61C5B0),
        elevation: 0,
        title: Row(
          children: [
            // Custom Purb Chetana Mascot Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 26, color: Colors.teal),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                i18n.translate('appName'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                softWrap: true,
              ),
            ),
          ],
        ),
        actions: [
          // Instant Refresh App Data Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1B2824)),
            tooltip: i18n.translate('refreshBtn'),
            onPressed: () async {
              final schedule = Provider.of<ScheduleService>(context, listen: false);
              await auth.loadState();
              final mappedId = auth.currentUser?.mappedElderId ?? 'NER-9431';
              await schedule.loadSchedules(elderId: mappedId);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(i18n.translate("syncSuccessToast"))),
              );
            },
          ),

          // Caregiver Live Location Tracker Icon
          if (isCaretaker)
            IconButton(
              icon: const Icon(Icons.location_on, color: Color(0xFF1B2824)),
              tooltip: i18n.translate('elderLiveLocationTitle'),
              onPressed: () {
                final mappedId = user?.mappedElderId ?? 'NER-9431';
                final elderProfile = auth.elderProfiles[mappedId];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ElderLocationScreen(
                      elderId: mappedId,
                      elderName: elderProfile?['name']?.toString() ?? 'Elder ($mappedId)',
                    ),
                  ),
                );
              },
            ),

          // Account Profile Icon
          IconButton(
            icon: Icon(
              user?.role == 'elder' ? Icons.account_circle : Icons.health_and_safety,
              color: Color(0xFF1B2824),
            ),
            tooltip: i18n.translate('userAccountTooltip'),
            onPressed: () => _showAccountDialog(context),
          ),

          // Language Selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Color(0xFF1B2824)),
            onSelected: (langCode) async {
              i18n.setLanguage(langCode);
              await auth.updateUserLanguage(langCode);
              schedule.updateI18n(i18n);
              if (mounted) {
                setState(() {});
              }
            },
            itemBuilder: (ctx) => i18n.languageNames.entries.map((e) => PopupMenuItem(
              value: e.key,
              child: Text(e.value),
            )).toList(),
          ),
        ],
      ),

      body: Column(
        children: [
          _buildTopNotificationBanner(context),
          Expanded(
            child: IndexedStack(
              index: activeIndex,
              children: screens,
            ),
          ),
        ],
      ),



      bottomNavigationBar: Container(
        color: const Color(0xFFFDF0E6),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: BottomNavigationBar(
          currentIndex: activeIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFDF0E6),
          elevation: 0,
          selectedItemColor: const Color(0xFF1B2824),
          unselectedItemColor: const Color(0xFF555555),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          items: navItems,
        ),
      ),
    );
  }

  void _showHydrationSuccessDialog(BuildContext context, I18nService i18n, ScheduleService schedule) {
    final current = schedule.hydrationCurrentGlasses;
    final target = schedule.hydrationTargetGlasses;
    final liters = schedule.hydrationCurrentLiters.toStringAsFixed(1);
    final targetLiters = schedule.hydrationTargetLiters.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFDF0E6),
        title: Column(
          children: [
            const Icon(Icons.local_drink, size: 44, color: Color(0xFF23B39B)),
            SizedBox(height: 8),
            Text(
              i18n.translate('hydrationLoggedTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF23B39B)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${i18n.translate("logged1GlassSuccess")}\n\n${i18n.translate("currentProgress")}: $current / $target ${i18n.translate("glasses")} ($liters / $targetLiters L)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2824)),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF61C5B0),
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              i18n.translate('okBtn'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
