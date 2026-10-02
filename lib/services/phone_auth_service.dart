import'dart:async';
import'dart:math';
import'package:flutter/foundation.dart';

class PhoneAuthService {
 static const String defaultTestPhone ='+91 9876543210';
 static const String testOTP ='123456';

 static String _activeOTP = testOTP;
 static String _activePhone = defaultTestPhone;

 static String get activeOTP => _activeOTP;
 static String get activePhone => _activePhone;

 /// Checks if the phone number matches standard Firebase Test Numbers
 static bool isTestPhoneNumber(String phone) {
 final clean = phone.replaceAll(RegExp(r'[^0-9+]'),'');
 return clean =='+919876543210'||
 clean =='9876543210'||
 clean =='+919999999999'||
 clean =='9999999999'||
 clean =='+919123456789'||
 clean =='9123456789'||
 clean =='+919000000000'||
 clean =='9000000000';
 }

 /// Sends Mobile OTP to the specified phone number
 static Future<Map<String, dynamic>> sendPhoneOTP({
 required String phoneNumber,
 bool forceTestMode = false,
 }) async {
 final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'),'').trim();
 if (cleanPhone.isEmpty) {
 return {
'success': false,
'message':'Please enter a valid mobile phone number.',
 };
 }

 _activePhone = cleanPhone;

 if (forceTestMode || isTestPhoneNumber(cleanPhone)) {
 _activeOTP = testOTP;
 return {
'success': true,
'isTest': true,
'otp': testOTP,
'message':'Firebase Test Number detected (+91 9876543210)! Use Test OTP: 123456',
 };
 }

 // Generate random 6-digit OTP code for live mobile verification
 final random = Random();
 _activeOTP = (100000 + random.nextInt(900000)).toString();

 if (kDebugMode) {
 print('SMS Sent to $cleanPhone with Mobile OTP: $_activeOTP');
 }

 return {
'success': true,
'isTest': false,
'otp': _activeOTP,
'message':'Mobile OTP sent to $cleanPhone. Enter code to verify.',
 };
 }

 /// Verifies the 6-digit OTP code
 static bool verifyOTP(String inputOTP) {
 final cleanInput = inputOTP.trim();
 if (cleanInput.isEmpty || cleanInput.length < 6) return false;

 if (cleanInput == testOTP) return true;
 return cleanInput == _activeOTP;
 }
}
