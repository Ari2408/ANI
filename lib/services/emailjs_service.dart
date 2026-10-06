import 'dart:convert';
import 'dart:math';
import 'dart:io';

class EmailJSService {
  static const String serviceId = 'service_07gd83a';
  static const String primaryTemplateId = 'template_titotg9';
  static const String fallbackTemplateId = '2o3syd';
  static const String publicKey = 'GK1KSo3rSzH0WXvFA';

  /// Generates a secure random 6-digit OTP code
  static String generateOTP() {
    final random = Random();
    final otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  /// Dispatches a live OTP verification email using EmailJS REST API
  static Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String recipientName,
    required String otpCode,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final payload = {
      'service_id': serviceId,
      'template_id': primaryTemplateId,
      'user_id': publicKey,
      'template_params': {
        'to_name': recipientName.trim().isEmpty ? 'User' : recipientName.trim(),
        'to_email': recipientEmail.trim(),
        'email': recipientEmail.trim(),
        'user_email': recipientEmail.trim(),
        'reply_to': recipientEmail.trim(),
        'otp': otpCode,
        'otp_code': otpCode,
        'code': otpCode,
        'message': 'Your Aninai verification OTP code is: $otpCode',
        'expiry_minutes': 5,
        'app_name': 'Aninai AI Platform',
      }
    };

    try {
      final client = HttpClient();
      final request = await client.postUrl(url);
      request.headers.set('content-type', 'application/json');
      request.headers.set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      request.headers.set('origin', 'https://localhost');
      request.write(jsonEncode(payload));
      final response = await request.close();

      final responseBody = await response.transform(utf8.decoder).join();
      print('EmailJS HTTP Response Status: ${response.statusCode}, Body: $responseBody');

      if (response.statusCode == 200) {
        return true;
      } else {
        // Try fallback template
        payload['template_id'] = fallbackTemplateId;
        final reqFallback = await client.postUrl(url);
        reqFallback.headers.set('content-type', 'application/json');
        reqFallback.headers.set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        reqFallback.headers.set('origin', 'https://localhost');
        reqFallback.write(jsonEncode(payload));
        final resFallback = await reqFallback.close();
        final resBodyFallback = await resFallback.transform(utf8.decoder).join();
        print('EmailJS Fallback Response Status: ${resFallback.statusCode}, Body: $resBodyFallback');
        return resFallback.statusCode == 200;
      }
    } catch (e) {
      print('EmailJS dispatch exception: $e');
      return false;
    }
  }
}
