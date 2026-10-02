import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/reminder.dart';
import 'hive_service.dart';

enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

class WebRTCService extends ChangeNotifier {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  WebRTCConnectionState _connectionState = WebRTCConnectionState.disconnected;

  String _localSdpOffer = '';
  String _localSdpAnswer = '';
  final List<Map<String, dynamic>> _iceCandidates = [];

  void Function(ReminderItem reminder, String action)? _onReminderReceivedCallback;

  WebRTCConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == WebRTCConnectionState.connected;
  String get localSdpOffer => _localSdpOffer;
  String get localSdpAnswer => _localSdpAnswer;

  void setOnReminderReceivedCallback(void Function(ReminderItem reminder, String action) callback) {
    _onReminderReceivedCallback = callback;
  }

  /// Initialize WebRTC Peer Connection with Google STUN Servers
  Future<void> _initPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _iceCandidates.add(candidate.toMap());
        notifyListeners();
      }
    };

    _peerConnection?.onConnectionState = (state) {
      debugPrint('WebRTC Connection State Changed: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _connectionState = WebRTCConnectionState.connected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _connectionState = WebRTCConnectionState.connecting;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _connectionState = WebRTCConnectionState.disconnected;
          break;
        default:
          break;
      }
      notifyListeners();
    };

    _peerConnection?.onDataChannel = (channel) {
      _setupDataChannel(channel);
    };
  }

  /// Configure DataChannel listeners for message & sync events
  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    _dataChannel?.onDataChannelState = (state) {
      debugPrint('WebRTC DataChannel State: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _connectionState = WebRTCConnectionState.connected;
        notifyListeners();
        // Send initial full sync upon connection
        syncAllRemindersOverP2P();
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _connectionState = WebRTCConnectionState.disconnected;
        notifyListeners();
      }
    };

    _dataChannel?.onMessage = (data) {
      _handleIncomingDataChannelMessage(data.text);
    };
  }

  /// Generate Offer (Mother/Host role)
  Future<String> createOfferCode() async {
    await _initPeerConnection();
    _connectionState = WebRTCConnectionState.connecting;
    notifyListeners();

    RTCDataChannelInit dataChannelDict = RTCDataChannelInit();
    _dataChannel = await _peerConnection?.createDataChannel('smriti_jyoti_sync', dataChannelDict);
    if (_dataChannel != null) {
      _setupDataChannel(_dataChannel!);
    }

    RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    final payload = {
      'sdp': offer.sdp,
      'type': offer.type,
      'candidates': _iceCandidates,
    };

    _localSdpOffer = base64Encode(utf8.encode(jsonEncode(payload)));
    notifyListeners();
    return _localSdpOffer;
  }

  /// Accept Offer & Generate Answer (Son/Receiver role)
  Future<String> createAnswerCode(String offerCodeBase64) async {
    await _initPeerConnection();
    _connectionState = WebRTCConnectionState.connecting;
    notifyListeners();

    final decodedStr = utf8.decode(base64Decode(offerCodeBase64.trim()));
    final Map<String, dynamic> offerPayload = jsonDecode(decodedStr);

    final offerSdp = RTCSessionDescription(offerPayload['sdp'], offerPayload['type']);
    await _peerConnection!.setRemoteDescription(offerSdp);

    if (offerPayload['candidates'] != null) {
      for (var candMap in (offerPayload['candidates'] as List)) {
        final candidate = RTCIceCandidate(candMap['candidate'], candMap['sdpMid'], candMap['sdpMLineIndex']);
        await _peerConnection!.addCandidate(candidate);
      }
    }

    RTCSessionDescription answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);

    final payload = {
      'sdp': answer.sdp,
      'type': answer.type,
      'candidates': _iceCandidates,
    };

    _localSdpAnswer = base64Encode(utf8.encode(jsonEncode(payload)));
    notifyListeners();
    return _localSdpAnswer;
  }

  /// Complete Connection by Setting Remote Answer (Mother/Host completes pairing)
  Future<void> completePairingWithAnswer(String answerCodeBase64) async {
    if (_peerConnection == null) return;
    final decodedStr = utf8.decode(base64Decode(answerCodeBase64.trim()));
    final Map<String, dynamic> answerPayload = jsonDecode(decodedStr);

    final answerSdp = RTCSessionDescription(answerPayload['sdp'], answerPayload['type']);
    await _peerConnection!.setRemoteDescription(answerSdp);

    if (answerPayload['candidates'] != null) {
      for (var candMap in (answerPayload['candidates'] as List)) {
        final candidate = RTCIceCandidate(candMap['candidate'], candMap['sdpMid'], candMap['sdpMLineIndex']);
        await _peerConnection!.addCandidate(candidate);
      }
    }
  }

  /// Transmit single reminder payload over WebRTC DataChannel
  Future<void> sendReminderPayload(ReminderItem item, {String action = 'REMINDER_ADD'}) async {
    if (_dataChannel == null || _connectionState != WebRTCConnectionState.connected) return;
    try {
      final payload = {
        'action': action,
        'reminder': item.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _dataChannel?.send(RTCDataChannelMessage(jsonEncode(payload)));
      debugPrint('Sent WebRTC DataChannel message: $action for ${item.title}');
    } catch (e) {
      debugPrint('Error sending WebRTC payload: $e');
    }
  }

  /// Transmit full reminder list sync payload over WebRTC DataChannel
  Future<void> syncAllRemindersOverP2P() async {
    if (_dataChannel == null || _connectionState != WebRTCConnectionState.connected) return;
    try {
      final items = HiveService.getReminders();
      final payload = {
        'action': 'REMINDER_SYNC_ALL',
        'reminders': items.map((r) => r.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _dataChannel?.send(RTCDataChannelMessage(jsonEncode(payload)));
      debugPrint('Sent full WebRTC P2P sync for ${items.length} reminders');
    } catch (e) {
      debugPrint('Error sending WebRTC full sync: $e');
    }
  }

  /// Handle incoming WebRTC DataChannel JSON message
  void _handleIncomingDataChannelMessage(String messageText) {
    try {
      final Map<String, dynamic> payload = jsonDecode(messageText);
      final String action = payload['action'] ?? 'REMINDER_ADD';

      if (action == 'REMINDER_SYNC_ALL') {
        final rawList = payload['reminders'] as List?;
        if (rawList != null) {
          final items = rawList.map((map) => ReminderItem.fromJson(Map<String, dynamic>.from(map))).toList();
          HiveService.saveAllReminders(items);
          if (_onReminderReceivedCallback != null && items.isNotEmpty) {
            for (var item in items) {
              _onReminderReceivedCallback!(item, 'REMINDER_SYNC_ALL');
            }
          }
        }
        return;
      }

      final rawItem = payload['reminder'];
      if (rawItem != null) {
        final item = ReminderItem.fromJson(Map<String, dynamic>.from(rawItem));
        if (action == 'REMINDER_DELETE') {
          HiveService.deleteReminder(item.id);
        } else {
          HiveService.saveReminder(item);
        }

        if (_onReminderReceivedCallback != null) {
          _onReminderReceivedCallback!(item, action);
        }
      }
    } catch (e) {
      debugPrint('Error handling WebRTC incoming data message: $e');
    }
  }

  /// Disconnect and cleanup WebRTC connection
  Future<void> disconnect() async {
    _dataChannel?.close();
    await _peerConnection?.close();
    _peerConnection = null;
    _dataChannel = null;
    _connectionState = WebRTCConnectionState.disconnected;
    _localSdpOffer = '';
    _localSdpAnswer = '';
    _iceCandidates.clear();
    notifyListeners();
  }
}
