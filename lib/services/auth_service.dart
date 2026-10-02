import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';

class UserAccount {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role; // 'elder' or 'caretaker'
  final int age;
  final String location;
  final String language;
  final String mappedElderId;
  final String emergencyPhone;
  final String caretakerPhone;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '+91 9876543210',
    required this.password,
    required this.role,
    required this.age,
    required this.location,
    required this.language,
    required this.mappedElderId,
    this.emergencyPhone = '',
    this.caretakerPhone = '',
  });

  String get effectiveElderId {
    if (mappedElderId.trim().isNotEmpty) {
      return mappedElderId.trim().toUpperCase();
    }
    if (email.contains('ner-')) {
      final parts = email.split('@');
      if (parts.isNotEmpty && parts[0].toUpperCase().startsWith('NER-')) {
        return parts[0].toUpperCase();
      }
    }
    if (name.contains('NER-')) {
      final match = RegExp(r'NER-\d+').firstMatch(name);
      if (match != null) return match.group(0)!;
    }
    return id.trim().toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'age': age,
        'location': location,
        'language': language,
        'mappedElderId': mappedElderId,
        'emergencyPhone': emergencyPhone,
        'caretakerPhone': caretakerPhone,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? json['emergencyPhone'] ?? json['caretakerPhone'] ?? '+91 9876543210',
        password: json['password'] ?? '',
        role: json['role'] ?? 'elder',
        age: json['age'] ?? 70,
        location: json['location'] ?? 'Guwahati, Assam',
        language: json['language'] ?? 'en',
        mappedElderId: json['mappedElderId'] ?? '',
        emergencyPhone: json['emergencyPhone'] ?? '',
        caretakerPhone: json['caretakerPhone'] ?? '',
      );
}


class AuthService extends ChangeNotifier {
  UserAccount? _currentUser;
  final Map<String, UserAccount> _registeredUsers = {};
  final Map<String, Map<String, dynamic>> _elderProfiles = {};
  bool _initialized = false;

  UserAccount? get currentUser => _currentUser;
  bool get isInitialized => _initialized;
  bool get isLoggedIn => _currentUser != null;
  bool get isElder => _currentUser?.role == 'elder';
  bool get isCaretaker => _currentUser?.role == 'caretaker';
  Map<String, Map<String, dynamic>> get elderProfiles => _elderProfiles;
  Map<String, UserAccount> get registeredUsers => _registeredUsers;

  AuthService() {
    loadState();
  }

  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRaw = prefs.getString('purb_chetana_user');
      if (userRaw != null) {
        _currentUser = UserAccount.fromJson(jsonDecode(userRaw));
      }

      final regRaw = prefs.getString('purb_chetana_reg_users');
      if (regRaw != null) {
        final decoded = jsonDecode(regRaw) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          _registeredUsers[key] = UserAccount.fromJson(Map<String, dynamic>.from(val));
        });
      }

      final eldersRaw = prefs.getString('purb_chetana_elders');
      if (eldersRaw != null) {
        final decoded = jsonDecode(eldersRaw) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          _elderProfiles[key] = Map<String, dynamic>.from(val);
        });
      }
    } catch (e) {
      print('AuthService load error: $e');
    } finally {
      _seedDefaultAccounts();
      NotificationService.isCaretakerMode = isCaretaker;
      _initialized = true;
      notifyListeners();
    }
  }

  void _seedDefaultAccounts() {
    if (!_elderProfiles.containsKey('NER-9431')) {
      _elderProfiles['NER-9431'] = {
        'id': 'NER-9431',
        'name': 'Senior Elder (NER-9431)',
        'email': 'elder9431@purbchetana.org',
        'phone': '+91 9876543210',
        'age': 72,
        'location': 'Guwahati, Assam',
        'language': 'en',
        'emergencyPhone': '+91 9876543210',
        'caretakerName': 'Dr. Sharma',
        'caretakerPhone': '+91 9876543210',
        'cognitiveScore': 85,
        'memoryScore': 90,
      };
    }

    if (!_registeredUsers.containsKey('caregiver_ner-9431') && !_registeredUsers.containsKey('caretaker_ner-9431')) {
      final defaultCaregiver = UserAccount(
        id: 'caregiver_default_1',
        name: 'Caregiver (Dr. Sharma)',
        email: 'caregiver@purbchetana.org',
        phone: '+91 9876543210',
        password: '123',
        role: 'caretaker',
        age: 38,
        location: 'Guwahati, Assam',
        language: 'en',
        mappedElderId: 'NER-9431',
        caretakerPhone: '+91 9876543210',
      );
      _registeredUsers['caregiver_ner-9431'] = defaultCaregiver;
      _registeredUsers['caretaker_ner-9431'] = defaultCaregiver;
      _registeredUsers['caregiver@purbchetana.org'] = defaultCaregiver;
      _registeredUsers['phone_9876543210'] = defaultCaregiver;
      _registeredUsers['phone_caretaker_9876543210'] = defaultCaregiver;
    }

    if (!_registeredUsers.containsKey('elder_ner-9431')) {
      final defaultElder = UserAccount(
        id: 'elder_default_1',
        name: 'Senior Elder (NER-9431)',
        email: 'elder9431@purbchetana.org',
        phone: '+91 9876543210',
        password: '123',
        role: 'elder',
        age: 72,
        location: 'Guwahati, Assam',
        language: 'en',
        mappedElderId: 'NER-9431',
        emergencyPhone: '+91 9876543210',
      );
      _registeredUsers['elder_ner-9431'] = defaultElder;
      _registeredUsers['elder9431@purbchetana.org'] = defaultElder;
      _registeredUsers['phone_elder_9876543210'] = defaultElder;
    }
  }

  Future<void> _saveState() async {
    try {
      NotificationService.isCaretakerMode = isCaretaker;
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setString('purb_chetana_user', jsonEncode(_currentUser!.toJson()));
      } else {
        await prefs.remove('purb_chetana_user');
      }

      final regMap = _registeredUsers.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString('purb_chetana_reg_users', jsonEncode(regMap));
      await prefs.setString('purb_chetana_elders', jsonEncode(_elderProfiles));
    } catch (e) {
      print('AuthService save error: $e');
    }
    notifyListeners();
  }

  String _generateUniqueElderId() {
    final random = Random();
    String uniqueId;
    do {
      final num = 1000 + random.nextInt(9000);
      uniqueId = 'NER-$num';
    } while (_elderProfiles.containsKey(uniqueId));
    return uniqueId;
  }

  Future<void> updateUserLanguage(String langCode) async {
    if (_currentUser != null) {
      _currentUser = UserAccount(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        password: _currentUser!.password,
        role: _currentUser!.role,
        age: _currentUser!.age,
        location: _currentUser!.location,
        language: langCode,
        mappedElderId: _currentUser!.mappedElderId,
        emergencyPhone: _currentUser!.emergencyPhone,
        caretakerPhone: _currentUser!.caretakerPhone,
      );
      final key = _currentUser!.email.trim().toLowerCase();
      if (key.isNotEmpty) {
        _registeredUsers[key] = _currentUser!;
      }
      final nerKey = _currentUser!.mappedElderId.trim().toLowerCase();
      if (nerKey.isNotEmpty) {
        _registeredUsers[nerKey] = _currentUser!;
      }
      await _saveState();
    }
  }

  Future<bool> loginWithNerId({
    required String nerId,
    required String password,
    required String selectedRole,
    String? currentLanguage,
  }) async {
    final targetNerId = nerId.trim().toUpperCase();
    final cleanDigits = nerId.trim().replaceAll(RegExp(r'\D'), '');
    final langToUse = currentLanguage ?? 'en';

    if (targetNerId.isEmpty && cleanDigits.isEmpty) return false;

    // 1. Search registered users for matching role and ID / Phone / Email
    UserAccount? matchedUser;
    for (var u in _registeredUsers.values) {
      final uPhoneDigits = u.phone.replaceAll(RegExp(r'\D'), '');
      final uEmergDigits = u.emergencyPhone.replaceAll(RegExp(r'\D'), '');
      final uCareDigits = u.caretakerPhone.replaceAll(RegExp(r'\D'), '');

      final isIdMatch = u.mappedElderId.toUpperCase() == targetNerId || u.id.toUpperCase() == targetNerId;
      final isPhoneMatch = cleanDigits.isNotEmpty && (
        (uPhoneDigits.length >= 7 && (uPhoneDigits.endsWith(cleanDigits) || cleanDigits.endsWith(uPhoneDigits))) ||
        (uEmergDigits.length >= 7 && (uEmergDigits.endsWith(cleanDigits) || cleanDigits.endsWith(uEmergDigits))) ||
        (uCareDigits.length >= 7 && (uCareDigits.endsWith(cleanDigits) || cleanDigits.endsWith(uCareDigits)))
      );
      final isEmailMatch = u.email.trim().toLowerCase() == nerId.trim().toLowerCase();

      final roleMatch = u.role == selectedRole || (selectedRole == 'caretaker' && (u.role == 'caretaker' || u.role == 'caretaker'));

      if ((isIdMatch || isPhoneMatch || isEmailMatch) && roleMatch) {
        if (u.password.isEmpty || password.isEmpty || u.password == password) {
          matchedUser = u;
          break;
        }
      }
    }

    if (matchedUser != null) {
      _currentUser = matchedUser;
      await _saveState();
      return true;
    }

    // 2. Dynamically create/link account session
    String mappedId = targetNerId.startsWith('NER-') ? targetNerId : 'NER-9431';
    for (var key in _elderProfiles.keys) {
      if (key.toUpperCase() == targetNerId) {
        mappedId = key.toUpperCase();
        break;
      }
    }

    final displayPhone = cleanDigits.length >= 7 ? nerId.trim() : '+91 9876543210';

    if (selectedRole == 'caretaker') {
      final caretakerAccount = UserAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Caregiver ($mappedId)',
        email: 'caregiver_${mappedId.toLowerCase()}@purbchetana.org',
        phone: displayPhone,
        password: password.isNotEmpty ? password : '123',
        role: 'caretaker',
        age: 38,
        location: 'Guwahati, Assam',
        language: langToUse,
        mappedElderId: mappedId,
        caretakerPhone: displayPhone,
      );

      _registeredUsers['caretaker_${mappedId.toLowerCase()}'] = caretakerAccount;
      _registeredUsers[caretakerAccount.email.toLowerCase()] = caretakerAccount;
      if (cleanDigits.isNotEmpty) {
        _registeredUsers['phone_caretaker_${cleanDigits}'] = caretakerAccount;
      }

      if (!_elderProfiles.containsKey(mappedId)) {
        _elderProfiles[mappedId] = {
          'id': mappedId,
          'name': 'Elder ($mappedId)',
          'caretakerName': caretakerAccount.name,
          'caretakerPhone': displayPhone,
          'cognitiveScore': 0,
          'memoryScore': 0,
        };
      } else {
        _elderProfiles.putIfAbsent(mappedId, () => {'id': mappedId});
        _elderProfiles[mappedId]?['caretakerName'] = caretakerAccount.name;
        _elderProfiles[mappedId]?['caretakerPhone'] = displayPhone;
      }

      _currentUser = caretakerAccount;
      await _saveState();
      return true;
    } else {
      final generatedNerId = targetNerId.startsWith('NER-') ? targetNerId : _generateUniqueElderId();
      final newAccount = UserAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Elder ($generatedNerId)',
        email: '${generatedNerId.toLowerCase()}@purbchetana.org',
        phone: displayPhone,
        password: password.isNotEmpty ? password : '123',
        role: 'elder',
        age: 70,
        location: 'Guwahati, Assam',
        language: langToUse,
        mappedElderId: generatedNerId,
        emergencyPhone: displayPhone,
      );

      _elderProfiles[generatedNerId] = {
        'id': generatedNerId,
        'name': newAccount.name,
        'email': newAccount.email,
        'phone': displayPhone,
        'age': 70,
        'location': 'Guwahati, Assam',
        'language': langToUse,
        'emergencyPhone': displayPhone,
        'caretakerName': '',
        'caretakerPhone': '',
        'cognitiveScore': 0,
        'memoryScore': 0,
      };

      _registeredUsers['elder_${generatedNerId.toLowerCase()}'] = newAccount;
      if (cleanDigits.isNotEmpty) {
        _registeredUsers['phone_elder_${cleanDigits}'] = newAccount;
      }

      _currentUser = newAccount;
      await _saveState();
      return true;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    final key = email.trim().toLowerCase();
    var account = _registeredUsers[key];
    if (account != null && account.password.isNotEmpty && account.password != password) {
      return false;
    }

    if (account != null && account.role == selectedRole) {
      _currentUser = account;
      await _saveState();
      return true;
    }

    final newElderId = _generateUniqueElderId();
    final newAccount = UserAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: email.split('@').first,
      email: email,
      password: password,
      role: selectedRole,
      age: 70,
      location: 'Guwahati, Assam',
      language: 'en',
      mappedElderId: selectedRole == 'elder' ? newElderId : 'NER-9431',
    );

    if (selectedRole == 'elder') {
      _elderProfiles[newElderId] = {
        'id': newElderId,
        'name': newAccount.name,
        'email': email,
        'age': 70,
        'location': 'Guwahati, Assam',
        'language': 'en',
        'emergencyPhone': '',
        'caretakerName': '',
        'caretakerPhone': '',
        'cognitiveScore': 0,
        'memoryScore': 0,
      };
    }

    _registeredUsers[key] = newAccount;
    _registeredUsers['${selectedRole}_${newAccount.mappedElderId.toLowerCase()}'] = newAccount;
    _currentUser = newAccount;
    await _saveState();
    return true;
  }

  Future<String> registerElderAccount({
    required String name,
    required String email,
    required String password,
    required int age,
    required String location,
    required String language,
    required String emergencyPhone,
  }) async {
    final elderId = _generateUniqueElderId();

    final profile = {
      'id': elderId,
      'name': name,
      'email': email,
      'age': age,
      'location': location,
      'language': language,
      'emergencyPhone': emergencyPhone,
      'caretakerName': '',
      'caretakerPhone': '',
      'cognitiveScore': 0,
      'memoryScore': 0,
    };

    _elderProfiles[elderId] = profile;

    final newAccount = UserAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      role: 'elder',
      age: age,
      location: location,
      language: language,
      mappedElderId: elderId,
      emergencyPhone: emergencyPhone,
    );

    _registeredUsers[email.trim().toLowerCase()] = newAccount;
    _registeredUsers['elder_${elderId.toLowerCase()}'] = newAccount;
    _currentUser = newAccount;

    await CloudSyncService().registerElderProfileCloud(elderId, profile);
    await _saveState();
    return elderId;
  }

  Future<bool> registerCaretakerAccount({
    required String name,
    required String email,
    required String password,
    required int age,
    required String location,
    required String language,
    required String caretakerPhone,
    required String mappedElderId,
  }) async {
    final cleanMappedId = mappedElderId.trim().toUpperCase();
    var elder = _elderProfiles[cleanMappedId];

    if (elder == null) {
      final cloudElder = await CloudSyncService().verifyElderIdCloud(cleanMappedId);
      if (cloudElder != null) {
        _elderProfiles[cleanMappedId] = cloudElder;
        elder = _elderProfiles[cleanMappedId];
      }
    }

    if (elder != null) {
      elder['caretakerName'] = name;
      elder['caretakerPhone'] = caretakerPhone;
    } else {
      _elderProfiles[cleanMappedId] = {
        'id': cleanMappedId,
        'name': 'Elder ($cleanMappedId)',
        'caretakerName': name,
        'caretakerPhone': caretakerPhone,
      };
    }

    final newAccount = UserAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      role: 'caretaker',
      age: age,
      location: location,
      language: language,
      mappedElderId: cleanMappedId,
      caretakerPhone: caretakerPhone,
    );

    _registeredUsers[email.trim().toLowerCase()] = newAccount;
    _registeredUsers['caretaker_${cleanMappedId.toLowerCase()}'] = newAccount;
    _currentUser = newAccount;

    final profileToPush = _elderProfiles[cleanMappedId] ?? {
      'id': cleanMappedId,
      'name': 'Elder ($cleanMappedId)',
      'caretakerName': name,
      'caretakerPhone': caretakerPhone,
    };
    await CloudSyncService().registerElderProfileCloud(cleanMappedId, profileToPush);

    await _saveState();
    return true;
  }

  Future<Map<String, dynamic>?> fetchElderProfileCloud(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return null;

    final cloudElder = await CloudSyncService().verifyElderIdCloud(cleanId);
    if (cloudElder != null) {
      _elderProfiles[cleanId] = cloudElder;
      notifyListeners();
      await _saveState();
      return cloudElder;
    }
    return _elderProfiles[cleanId];
  }

  Future<void> logout() async {
    _currentUser = null;
    await _saveState();
  }

  Future<void> updateMappedElderId(String newElderId) async {
    final cleanId = newElderId.trim().toUpperCase();
    if (cleanId.isEmpty || _currentUser == null) return;

    _currentUser = UserAccount(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      password: _currentUser!.password,
      role: _currentUser!.role,
      age: _currentUser!.age,
      location: _currentUser!.location,
      language: _currentUser!.language,
      mappedElderId: cleanId,
      caretakerPhone: _currentUser!.caretakerPhone,
      emergencyPhone: _currentUser!.emergencyPhone,
    );

    if (!_elderProfiles.containsKey(cleanId)) {
      _elderProfiles[cleanId] = {
        'id': cleanId,
        'name': 'Elder ($cleanId)',
        'caretakerName': _currentUser!.name,
        'caretakerPhone': _currentUser!.caretakerPhone,
      };
    }

    notifyListeners();
    await _saveState();
  }

  List<Map<String, String>> getRegisteredEldersList() {
    return _elderProfiles.entries.map((e) {
      return {
        'id': e.key,
        'name': e.value['name']?.toString() ?? 'Elder',
      };
    }).toList();
  }
}



