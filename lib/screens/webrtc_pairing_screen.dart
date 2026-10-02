import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/webrtc_service.dart';
import '../services/schedule_service.dart';
import '../services/i18n_service.dart';
import '../services/hive_service.dart';

class WebRTCPairingScreen extends StatefulWidget {
  const WebRTCPairingScreen({Key? key}) : super(key: key);

  @override
  State<WebRTCPairingScreen> createState() => _WebRTCPairingScreenState();
}

class _WebRTCPairingScreenState extends State<WebRTCPairingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _offerCtrl = TextEditingController();
  final TextEditingController _answerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _offerCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${Provider.of<I18nService>(context, listen: false).translate("codeCopiedToast")} ($label)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final webRtc = Provider.of<WebRTCService>(context);
    final schedule = Provider.of<ScheduleService>(context, listen: false);
    final i18n = Provider.of<I18nService>(context);

    final hiveRemindersCount = HiveService.getReminders().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.translate('p2pPairingTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF61C5B0),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: const Icon(Icons.qr_code), text: i18n.translate('elderRole')),
            Tab(icon: const Icon(Icons.phonelink_setup), text: i18n.translate('caregiverRole')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            color: webRtc.isConnected ? const Color(0xFF059669) : const Color(0xFF0F172A),
            child: Row(
              children: [
                Icon(
                  webRtc.isConnected ? Icons.wifi_tethering_sharp : Icons.wifi_off_rounded,
                  color: webRtc.isConnected ? Colors.white : Colors.orangeAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        webRtc.isConnected
                            ? i18n.translate('connectedP2PStatus')
                            : i18n.translate('deviceOfflineStatus'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${i18n.translate("historyLogTitle")}: $hiveRemindersCount ${i18n.translate("remindersHeader")}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (webRtc.isConnected)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF059669),
                    ),
                    icon: const Icon(Icons.sync, size: 16),
                    label: Text(i18n.translate('syncAllBtn')),
                    onPressed: () {
                      webRtc.syncAllRemindersOverP2P();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(i18n.translate("syncingStatus"))),
                      );
                    },
                  ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: ELDER / HOST PHONE (Generate Offer Code)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                i18n.translate('generateHostOfferBtn'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF61C5B0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                ),
                                icon: const Icon(Icons.lock_open),
                                label: Text(i18n.translate('generateHostOfferBtn')),
                                onPressed: () async {
                                  schedule.attachWebRTCService(webRtc);
                                  await webRtc.createOfferCode();
                                },
                              ),
                              if (webRtc.localSdpOffer.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                QrImageView(
                                  data: webRtc.localSdpOffer,
                                  version: QrVersions.auto,
                                  size: 180.0,
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  webRtc.localSdpOffer.substring(0, webRtc.localSdpOffer.length > 50 ? 50 : webRtc.localSdpOffer.length) + '...',
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: Text(i18n.translate('shareCodeBtn')),
                                  onPressed: () => _copyToClipboard(webRtc.localSdpOffer, i18n.translate('hostOfferLabel')),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                i18n.translate('answerCodeLabel'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _answerCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: i18n.translate('enterCodeHint'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(i18n.translate('completePairingBtn')),
                                onPressed: () async {
                                  if (_answerCtrl.text.trim().isEmpty) return;
                                  await webRtc.completePairingWithAnswer(_answerCtrl.text.trim());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(i18n.translate("syncSuccessToast"))),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 2: CAREGIVER / JOINER PHONE (Paste Offer & Generate Answer)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                i18n.translate('hostOfferLabel'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _offerCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: i18n.translate('enterCodeHint'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF61C5B0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: const Icon(Icons.sync_alt),
                                label: Text(i18n.translate('generateAnswerCodeBtn')),
                                onPressed: () async {
                                  if (_offerCtrl.text.trim().isEmpty) return;
                                  schedule.attachWebRTCService(webRtc);
                                  await webRtc.createAnswerCode(_offerCtrl.text.trim());
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (webRtc.localSdpAnswer.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  i18n.translate('answerCodeLabel'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                QrImageView(
                                  data: webRtc.localSdpAnswer,
                                  version: QrVersions.auto,
                                  size: 180.0,
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: Text(i18n.translate('shareCodeBtn')),
                                  onPressed: () => _copyToClipboard(webRtc.localSdpAnswer, i18n.translate('answerCodeLabel')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}
