import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/emailjs_service.dart';
import '../services/i18n_service.dart';
import '../services/schedule_service.dart';
import '../services/ai_cognitive_engine.dart';

class AuthOnboardingScreen extends StatefulWidget {
 final VoidCallback onComplete;

 const AuthOnboardingScreen({Key? key, required this.onComplete}) : super(key: key);

 @override
 State<AuthOnboardingScreen> createState() => _AuthOnboardingScreenState();
}

class _AuthOnboardingScreenState extends State<AuthOnboardingScreen> {
 int _step = 1; // 1: Role select, 0: Account choice, 10: Login, 2: Email Reg, 25: OTP, 3: Details, 4: Elder Success
 String _selectedRole = 'elder'; // 'elder' or 'caretaker'

 // Controllers
 final _loginNerIdController = TextEditingController();
 final _loginPasswordController = TextEditingController();

 final _nameController = TextEditingController();
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();
 final _confirmPasswordController = TextEditingController();
 final _ageController = TextEditingController(text: '72');
 final _phoneController = TextEditingController();
 final _mappedElderIdController = TextEditingController();

 bool _obscureLoginPassword = true;
 bool _obscurePassword = true;
 bool _obscureConfirmPassword = true;

 final List<TextEditingController> _otpControllers =
 List.generate(6, (_) => TextEditingController());
 final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

 String _generatedOTP = '';
 String _generatedElderId = '';
 String _location = 'Guwahati, Assam';
 String _language = 'ta';

 bool _isSendingEmail = false;
 String? _errorMessage;
 int _timerSeconds = 30;
 Timer? _timer;

 String _otpMode = 'working'; // 'test' (123456 test code) or 'working' (live EmailJS dispatch)

 final List<Map<String, String>> _locations = [
 {'state': 'Assam', 'city': 'Guwahati'},
 {'state': 'Manipur', 'city': 'Imphal'},
 {'state': 'Meghalaya', 'city': 'Shillong'},
 {'state': 'Mizoram', 'city': 'Aizawl'},
 {'state': 'Nagaland', 'city': 'Kohima'},
 {'state': 'Sikkim', 'city': 'Gangtok'},
 {'state': 'Tripura', 'city': 'Agartala'},
 {'state': 'Arunachal Pradesh', 'city': 'Itanagar'},
 {'state': 'Tamil Nadu', 'city': 'Chennai'},
 {'state': 'Other Region', 'city': 'General'},
 ];

 final List<Map<String, String>> _languages = [
 {'code': 'en', 'name': 'English', 'native': 'English'},
 {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
 {'code': 'ne', 'name': 'Nepali', 'native': 'नेपाली'},
 {'code': 'as', 'name': 'Assamese', 'native': 'অসমীয়া'},
 {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
 {'code': 'mni', 'name': 'Manipuri', 'native': 'মৈতৈলোন্'},
 {'code': 'lus', 'name': 'Mizo', 'native': 'Mizo'},
 {'code': 'kha', 'name': 'Khasi', 'native': 'Khasi'},
 {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
 ];

 @override
 void initState() {
 super.initState();
 _step = 1; // Enforce Step 1 (Select Role) on application open
 }

 @override
 void dispose() {
 _timer?.cancel();
 _loginNerIdController.dispose();
 _loginPasswordController.dispose();
 _nameController.dispose();
 _emailController.dispose();
 _passwordController.dispose();
 _confirmPasswordController.dispose();
 _ageController.dispose();
 _phoneController.dispose();
 _mappedElderIdController.dispose();
 for (var c in _otpControllers) {
 c.dispose();
 }
 for (var f in _otpFocusNodes) {
 f.dispose();
 }
 super.dispose();
 }

 void _startTimer() {
 _timer?.cancel();
 setState(() => _timerSeconds = 30);
 _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
 if (_timerSeconds > 0) {
 setState(() => _timerSeconds--);
 } else {
 timer.cancel();
 }
 });
 }

 Future<void> _showSuccessDialog({
 required String title,
 required String message,
 String? code,
 required VoidCallback onProceed,
 }) async {
 return showDialog(
 context: context,
 barrierDismissible: false,
 builder: (ctx) => Dialog(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
 backgroundColor: Colors.white,
 child: Padding(
 padding: const EdgeInsets.all(28.0),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 72,
 height: 72,
 decoration: const BoxDecoration(
 color: Color(0xFFE6FFFA),
 shape: BoxShape.circle,
 ),
 child: const Icon(Icons.check_circle, size: 48, color: Color(0xFF61C5B0)),
 ),
 const SizedBox(height: 18),
 Text(
 title,
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 const SizedBox(height: 8),
 Text(
 message,
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 14, color: Colors.black87),
 ),
 if (code != null && code.isNotEmpty) ...[
 const SizedBox(height: 14),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
 decoration: BoxDecoration(
 color: const Color(0xFFFEF3C7),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: const Color(0xFFF59E0B)),
 ),
 child: Text(
 'Elder ID: $code',
 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
 ),
 ),
 ],
 const SizedBox(height: 24),
 SizedBox(
 width: double.infinity,
 child: ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF61C5B0),
 padding: const EdgeInsets.symmetric(vertical: 14),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: () {
 Navigator.of(ctx).pop();
 onProceed();
 },
 child: const Text(
 'Proceed to Dashboard ',
 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
 ),
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Future<void> _sendOTP() async {
 final phone = _phoneController.text.trim();
 final name = _nameController.text.trim();
 final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');

 if (phone.isEmpty || cleanDigits.length < 10) {
 final i18n = Provider.of<I18nService>(context, listen: false);
 setState(() => _errorMessage = i18n.translate('invalidEmailError'));
 return;
 }

 if (_otpMode == 'test') {
 _generatedOTP = '123456';
 setState(() {
 _errorMessage = null;
 _step = 25; // Step 2.5 (OTP Verification)
 });
 _startTimer();
 return;
 }

 setState(() {
 _isSendingEmail = true;
 _errorMessage = null;
 });

 _generatedOTP = EmailJSService.generateOTP();
 final targetEmail = cleanDigits.length >= 10 ? '${cleanDigits}@purbchetana.org' : 'user@purbchetana.org';
 await EmailJSService.sendOTPEmail(
 recipientEmail: targetEmail,
 recipientName: name.isNotEmpty ? name : 'User ($phone)',
 otpCode: _generatedOTP,
 );

 setState(() {
 _isSendingEmail = false;
 _errorMessage = null;
 _step = 25; // Step 2.5 (OTP Verification)
 });
 _startTimer();
 }

 void _verifyOTP() {
 final entered = _otpControllers.map((c) => c.text).join();
 if (entered.length < 6) {
 final i18n = Provider.of<I18nService>(context, listen: false);
 setState(() => _errorMessage = i18n.translate('otpLengthError'));
 return;
 }

 if (entered == _generatedOTP || entered == '123456') {
 setState(() {
 _errorMessage = null;
 _step = 3;
 });
 } else {
 final i18n = Provider.of<I18nService>(context, listen: false);
 setState(() => _errorMessage = i18n.translate('invalidVerifCodeError'));
 }
 }

 Future<void> _submitProfile() async {
 final auth = Provider.of<AuthService>(context, listen: false);
 final i18n = Provider.of<I18nService>(context, listen: false);
 i18n.setLanguage(_language);

 final name = _nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim();
 final phone = _phoneController.text.trim();
 final password = _passwordController.text.trim();
 final confirmPassword = _confirmPasswordController.text.trim();
 final age = int.tryParse(_ageController.text.trim()) ?? 70;

 if (password.isEmpty || password.length < 6) {
 setState(() => _errorMessage = i18n.translate('minPassLengthError'));
 return;
 }

 if (password != confirmPassword) {
 setState(() => _errorMessage = i18n.translate('passMismatchError'));
 return;
 }

 final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
 final email = cleanDigits.length >= 10 ? '${cleanDigits}@purbchetana.org' : 'user@purbchetana.org';

 final schedule = Provider.of<ScheduleService>(context, listen: false);

 if (_selectedRole == 'elder') {
 final elderId = await auth.registerElderAccount(
 name: name,
 email: email,
 password: password,
 age: age,
 location: _location,
 language: _language,
 emergencyPhone: phone,
 );
 final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
 await schedule.clearAndResetForNewUser(elderId);
 aiEngine.resetForNewUser();
 i18n.setLanguage(_language);
 setState(() {
 _generatedElderId = elderId;
 _step = 4;
 });
 } else {
 final mappedId = _mappedElderIdController.text.trim();
 if (mappedId.isEmpty) {
 setState(() => _errorMessage = 'Please enter an Elder Unique ID (e.g. NER-9431)');
 return;
 }

 final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
 await auth.registerCaretakerAccount(
 name: name,
 email: email,
 password: password,
 age: age,
 location: _location,
 language: _language,
 caretakerPhone: phone,
 mappedElderId: mappedId,
 );
 await schedule.clearAndResetForNewUser(mappedId);
 aiEngine.resetForNewUser();
 i18n.setLanguage(_language);
 await _showSuccessDialog(
 title: 'Account Created Successfully! ',
 message: 'Your Caregiver account has been registered successfully.',
 onProceed: widget.onComplete,
 );
 }
 }

 @override
 Widget build(BuildContext context) {
 final i18n = Provider.of<I18nService>(context);

 return Scaffold(
 backgroundColor: const Color(0xFF61C5B0), // Application Primary Color
 body: SafeArea(
 child: Center(
 child: SingleChildScrollView(
 padding: const EdgeInsets.all(20),
 child: Container(
 constraints: const BoxConstraints(maxWidth: 540),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(24),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withOpacity(0.08),
 blurRadius: 20,
 offset: const Offset(0, 8),
 )
 ],
 ),
 padding: const EdgeInsets.all(24),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // Top Language Selection Dropdown
 _buildTopLanguageSelector(i18n),
 const SizedBox(height: 16),
 _buildStepContent(),
 ],
 ),
 ),
 ),
 ),
 ),
 );
 }

  Widget _buildTopLanguageSelector(I18nService i18n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF61C5B0), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Language / ভাষা:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: i18n.languageNames.containsKey(i18n.currentLang) ? i18n.currentLang : 'en',
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF61C5B0)),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                onChanged: (newLang) {
                  if (newLang != null) {
                    i18n.setLanguage(newLang);
                    setState(() {
                      _language = newLang;
                    });
                  }
                },
                items: i18n.languageNames.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildStepContent() {
 if (_step == 1) return _buildStep1Role(); // 1. First screen: Select Role
 if (_step == 0) return _buildStep0Landing(); // 2. Second screen: Have account or not?
 if (_step == 10) return _buildStep10Login(); // 3A. Login screen (NER ID & Password)
 if (_step == 2) return _buildStep2Email(); // 3B. Registration Email & OTP Mode
 if (_step == 25) return _buildStep25OTP(); // 3C. OTP Verification
 if (_step == 3) return _buildStep3Details(); // 3D. Password setup & Details
 if (_step == 4) return _buildStep4ElderSuccess(); // Elder ID generated
 return _buildStep1Role();
 }

 Widget _buildStep1Role() {
 final i18n = Provider.of<I18nService>(context);

 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Purb Chetana Logo & Welcome Header
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Image.asset(
 'assets/images/app_logo.png',
 width: 38,
 height: 38,
 fit: BoxFit.contain,
 errorBuilder: (ctx, err, stack) => const Icon(Icons.psychology, size: 28, color: Color(0xFF61C5B0)),
 ),
 const SizedBox(width: 8),
 Flexible(
 child: Text(
 i18n.translate("welcomeMessage"),
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 ),
 ),
 ],
 ),
 const SizedBox(height: 4),
 Text(
 i18n.translate('appName'),
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 18),
 Text(
 i18n.translate('selectRoleTitle'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 const SizedBox(height: 12),

 // Role 1: Senior Elder
 InkWell(
 onTap: () => setState(() => _selectedRole = 'elder'),
 borderRadius: BorderRadius.circular(16),
 child: Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: _selectedRole == 'elder' ? const Color(0xFFFEF3C7) : Colors.grey[50],
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: _selectedRole == 'elder' ? const Color(0xFFF59E0B) : const Color(0xFFE0E0E0),
 width: _selectedRole == 'elder' ? 2 : 1,
 ),
 ),
 child: Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(i18n.translate('seniorElder'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824))),
 const SizedBox(height: 2),
 Text(i18n.translate('elderRoleDesc'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
 ],
 ),
 ),
 Icon(
 _selectedRole == 'elder' ? Icons.check_circle : Icons.radio_button_unchecked,
 color: _selectedRole == 'elder' ? const Color(0xFFF59E0B) : Colors.grey,
 ),
 ],
 ),
 ),
 ),
 const SizedBox(height: 12),

 // Role 2: Health Worker / Caregiver
 InkWell(
 onTap: () => setState(() => _selectedRole = 'caretaker'),
 borderRadius: BorderRadius.circular(16),
 child: Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: _selectedRole == 'caretaker' ? const Color(0xFFE6FFFA) : Colors.grey[50],
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: _selectedRole == 'caretaker' ? const Color(0xFF61C5B0) : const Color(0xFFE0E0E0),
 width: _selectedRole == 'caretaker' ? 2 : 1,
 ),
 ),
 child: Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(i18n.translate('healthWorker'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824))),
 const SizedBox(height: 2),
 Text(i18n.translate('caretakerRoleDesc'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
 ],
 ),
 ),
 Icon(
 _selectedRole == 'caretaker' ? Icons.check_circle : Icons.radio_button_unchecked,
 color: _selectedRole == 'caretaker' ? const Color(0xFF61C5B0) : Colors.grey,
 ),
 ],
 ),
 ),
 ),
 const SizedBox(height: 22),

 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFF61C5B0),
 padding: EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: () => setState(() => _step = 0), // Go to Step 0: Have Account or Not
 child: Text(i18n.translate('proceed'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
 ),
 ],
 );
 }

 Widget _buildStep0Landing() {
 final i18n = Provider.of<I18nService>(context);
 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Role Selected: ${_selectedRole == 'elder' ? i18n.translate('seniorElder') : i18n.translate('healthWorker')}',
 style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 ),
 Text(i18n.translate('step2AccountQuestion'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
 ],
 ),
 ),
 ],
 ),
 SizedBox(height: 24),

 Text(
 i18n.translate('chooseProceed'),
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706), letterSpacing: 1.2),
 ),
 const SizedBox(height: 16),

 // Option 1: Already Created an Account -> Log In
 InkWell(
 onTap: () => setState(() {
 _errorMessage = null;
 _step = 10; // Go to Login screen
 }),
 borderRadius: BorderRadius.circular(16),
 child: Container(
 padding: const EdgeInsets.all(18),
 decoration: BoxDecoration(
 color: const Color(0xFFEFF6FF),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFF3B82F6), width: 2),
 ),
 child: Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(i18n.translate('haveAccount'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
 const SizedBox(height: 4),
 Text(i18n.translate('haveAccountDesc'), style: const TextStyle(fontSize: 11, color: Colors.black87)),
 ],
 ),
 ),
 const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF1E40AF)),
 ],
 ),
 ),
 ),
 const SizedBox(height: 14),

 // Option 2: Create New Account (Email & OTP)
 InkWell(
 onTap: () => setState(() {
 _errorMessage = null;
 _step = 2; // Start Account Creation Flow (Email & OTP)
 }),
 borderRadius: BorderRadius.circular(16),
 child: Container(
 padding: const EdgeInsets.all(18),
 decoration: BoxDecoration(
 color: const Color(0xFFF0FDF4),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFF22C55E), width: 2),
 ),
 child: Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(i18n.translate('createAccount'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
 const SizedBox(height: 4),
 Text(i18n.translate('createAccountDesc'), style: const TextStyle(fontSize: 11, color: Colors.black87)),
 ],
 ),
 ),
 const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF15803D)),
 ],
 ),
 ),
 ),
 SizedBox(height: 16),
 TextButton(
 onPressed: () => setState(() => _step = 1),
 child: Text(i18n.translate('backToRole'), style: TextStyle(color: Colors.grey)),
 ),
 ],
 );
 }

 Widget _buildStep10Login() {
 final i18n = Provider.of<I18nService>(context);
 final isElder = _selectedRole == 'elder';

 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '${i18n.translate("signInAs")} ${isElder ? i18n.translate('seniorElder') : i18n.translate('caretaker')}',
 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isElder ? const Color(0xFFB45309) : const Color(0xFF1E40AF)),
 ),
 Text(i18n.translate('enterRegisteredNerIdAndPass'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
 ],
 ),
 ),
 ],
 ),
 const SizedBox(height: 20),

 if (_errorMessage != null) ...[
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
 child: Text(_errorMessage ?? '', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
 ),
 const SizedBox(height: 14),
 ],

 TextField(
 controller: _loginNerIdController,
 keyboardType: TextInputType.text,
 decoration: InputDecoration(
 labelText: i18n.translate('nerIdLabel'),
 hintText: 'e.g. 9876543210 or NER-9431',
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.phone_android),
 ),
 ),
 const SizedBox(height: 14),

 TextField(
 controller: _loginPasswordController,
 obscureText: _obscureLoginPassword,
 decoration: InputDecoration(
 labelText: i18n.translate('passwordLabel'),
 hintText: i18n.translate('enterAccPasswordHint'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.lock),
 suffixIcon: IconButton(
 icon: Icon(_obscureLoginPassword ? Icons.visibility_off : Icons.visibility),
 onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
 ),
 ),
 ),
 const SizedBox(height: 24),

 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: isElder ? const Color(0xFFD97706) : const Color(0xFF1E40AF),
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: () async {
 FocusScope.of(context).unfocus();
 final auth = Provider.of<AuthService>(context, listen: false);
 final i18n = Provider.of<I18nService>(context, listen: false);
 final nerId = _loginNerIdController.text.trim();
 final pass = _loginPasswordController.text.trim();

 if (nerId.isEmpty) {
 setState(() => _errorMessage = i18n.translate('enterBothNerIdAndPass'));
 return;
 }
 final effectivePass = pass.isEmpty ? '123' : pass;

 final success = await auth.loginWithNerId(
 nerId: nerId,
 password: effectivePass,
 selectedRole: _selectedRole,
 currentLanguage: i18n.currentLang,
 );
 if (success) {
 if (auth.currentUser != null && auth.currentUser!.language.isNotEmpty) {
 i18n.setLanguage(auth.currentUser!.language);
 }
 final targetElderId = auth.currentUser?.effectiveElderId ?? nerId;
 final scheduleService = Provider.of<ScheduleService>(context, listen: false);
 final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
 await scheduleService.clearAndResetForNewUser(targetElderId);
 aiEngine.resetForNewUser();
 await _showSuccessDialog(
 title: 'Login Successful! ',
 message: 'Welcome back to Purb Chetana!',
 onProceed: widget.onComplete,
 );
 } else {
 setState(() => _errorMessage = i18n.translate('invalidNerIdOrPass'));
 }
 },
 child: Text(i18n.translate('loginBtn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
 ),
 const SizedBox(height: 12),

 TextButton(
 onPressed: () => setState(() {
 _errorMessage = null;
 _step = 2; // Switch to Account Registration Email & OTP
 }),
 child: Text(i18n.translate('dontHaveAccount'), style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
 ),
 TextButton(
 onPressed: () => setState(() {
 _errorMessage = null;
 _step = 0; // Back to Have Account choice
 }),
 child: Text(i18n.translate('backToPrevious'), style: TextStyle(color: Colors.grey)),
 ),
 ],
 );
 }

 Widget _buildStep2Email() {
 final i18n = Provider.of<I18nService>(context);
 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Text(i18n.translate("emailVerification"), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0))),
 const SizedBox(height: 16),

 if (_errorMessage != null) ...[
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
 child: Text(_errorMessage ?? '', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
 ),
 const SizedBox(height: 14),
 ],

 TextField(
 controller: _nameController,
 decoration: InputDecoration(
 labelText: i18n.translate('fullName'),
 hintText: i18n.translate('enterFullNameHint'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.person),
 ),
 ),
 const SizedBox(height: 16),

 TextField(
 controller: _phoneController,
 keyboardType: TextInputType.phone,
 decoration: InputDecoration(
 labelText: i18n.translate('targetEmail'),
 hintText: i18n.translate('enterEmailHint'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.phone_android),
 ),
 ),
 const SizedBox(height: 18),

 // Verification Mode: Test Mode (123456)
 Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: const Color(0xFFFEF3C7),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
 ),
 child: Row(
 children: [
 const Icon(Icons.science, color: Color(0xFFD97706), size: 24),
 const SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 i18n.translate('testModeTitle'),
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
 ),
 const SizedBox(height: 2),
 Text(
 i18n.translate('testModeSub'),
 style: const TextStyle(fontSize: 11, color: Colors.black54),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 const SizedBox(height: 22),

 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF61C5B0),
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: _isSendingEmail ? null : _sendOTP,
 child: _isSendingEmail
 ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
 : Text(
 i18n.translate('sendOtpBtn'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
 ),
 ),
 SizedBox(height: 12),
 TextButton(
 onPressed: () => setState(() => _step = 1),
 child: Text(i18n.translate('backToRoleSelect'), style: TextStyle(color: Colors.grey)),
 ),
 ],
 );
 }

 Widget _buildStep25OTP() {
 final i18n = Provider.of<I18nService>(context);
 final bool isTest = _otpMode == 'test';

 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Icon(isTest ? Icons.science : Icons.phonelink_ring, size: 56, color: isTest ? Color(0xFFD97706) : Color(0xFF10B981)),
 SizedBox(height: 12),
 Text(isTest ? i18n.translate('testModeVerifTitle') : i18n.translate('verifCodeSentTitle'), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
 SizedBox(height: 6),
 Text(
 isTest
 ? i18n.translate('testModeVerifDesc')
 : i18n.translate('liveOtpDispatchedDesc'),
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 12, color: Colors.black87),
 ),
 const SizedBox(height: 14),

 if (isTest) ...[
 GestureDetector(
 onTap: () {
 const testCode = ['1', '2', '3', '4', '5', '6'];
 for (int i = 0; i < 6; i++) {
 _otpControllers[i].text = testCode[i];
 }
 setState(() => _errorMessage = null);
 },
 child: Container(
 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
 decoration: BoxDecoration(
 color: const Color(0xFFFEF3C7),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: Color(0xFFF59E0B)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Text(i18n.translate('autofillTestCodeBanner'), style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12)),
 ],
 ),
 ),
 ),
 const SizedBox(height: 14),
 ],

 if (_errorMessage != null) ...[
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
 child: Text(_errorMessage ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
 ),
 const SizedBox(height: 14),
 ],

 FittedBox(
 fit: BoxFit.scaleDown,
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: List.generate(6, (idx) {
 return Container(
 width: 44,
 margin: const EdgeInsets.symmetric(horizontal: 4),
 child: TextField(
 controller: _otpControllers[idx],
 focusNode: _otpFocusNodes[idx],
 keyboardType: TextInputType.number,
 textAlign: TextAlign.center,
 maxLength: 1,
 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
 decoration: InputDecoration(
 counterText: '',
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
 ),
 onChanged: (val) {
 if (val.isNotEmpty && idx < 5) {
 _otpFocusNodes[idx + 1].requestFocus();
 } else if (val.isEmpty && idx > 0) {
 _otpFocusNodes[idx - 1].requestFocus();
 }
 },
 ),
 );
 }),
 ),
 ),
 SizedBox(height: 20),

 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text('${i18n.translate("resendCodeIn")} ${_timerSeconds}s', style: TextStyle(fontSize: 12, color: Colors.grey)),
 TextButton(
 onPressed: _timerSeconds == 0 ? _sendOTP : null,
 child: Text(i18n.translate('resendCode'), style: TextStyle(fontWeight: FontWeight.bold)),
 ),
 ],
 ),
 const SizedBox(height: 16),

 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFF61C5B0),
 padding: EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: _verifyOTP,
 child: Text(i18n.translate('verifyCode'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
 ),
 SizedBox(height: 12),

 TextButton(
 onPressed: () => setState(() => _step = 2),
 child: Text(i18n.translate('changeEmail'), style: TextStyle(color: Colors.grey)),
 ),
 ],
 );
 }

 Widget _buildStep3Details() {
 final i18n = Provider.of<I18nService>(context);

 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Text(i18n.translate('profileSetup'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0))),
 SizedBox(height: 4),
 Text(
 i18n.translate('enterAccountDetailsDesc'),
 style: const TextStyle(fontSize: 12, color: Colors.grey),
 ),
 const SizedBox(height: 20),

 if (_errorMessage != null) ...[
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
 child: Text(_errorMessage ?? '', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
 ),
 const SizedBox(height: 14),
 ],

 TextField(
 controller: _passwordController,
 obscureText: _obscurePassword,
 decoration: InputDecoration(
 labelText: i18n.translate('createPassLabel'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.lock),
 suffixIcon: IconButton(
 icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
 onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
 ),
 ),
 ),
 const SizedBox(height: 14),

 TextField(
 controller: _confirmPasswordController,
 obscureText: _obscureConfirmPassword,
 decoration: InputDecoration(
 labelText: i18n.translate('confirmPassLabel'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.lock_clock),
 suffixIcon: IconButton(
 icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
 onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
 ),
 ),
 ),
 const SizedBox(height: 14),

 Row(
 children: [
 Expanded(
 child: TextField(
 controller: _ageController,
 keyboardType: TextInputType.number,
 decoration: InputDecoration(
 labelText: i18n.translate('ageLabel'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.cake),
 ),
 ),
 ),
 SizedBox(width: 12),
 Expanded(
 child: DropdownButtonFormField<String>(
 value: _locations.any((loc) => '${loc['city']}, ${loc['state']}' == _location)
 ? _location
 : '${_locations.first['city']}, ${_locations.first['state']}',
 decoration: InputDecoration(
 labelText: i18n.translate('regionLabel'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 items: _locations.map((loc) => DropdownMenuItem(
 value: '${loc['city']}, ${loc['state']}',
 child: Text(loc['state'] ?? '', style: const TextStyle(fontSize: 12)),
 )).toList(),
 onChanged: (val) {
 if (val != null) setState(() => _location = val);
 },
 ),
 ),
 ],
 ),
 const SizedBox(height: 14),

 DropdownButtonFormField<String>(
 value: _languages.any((lang) => lang['code'] == _language) ? _language : 'en',
 decoration: InputDecoration(
 labelText: i18n.translate('prefLangLabel'),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.language),
 ),
 items: _languages.map((lang) => DropdownMenuItem(
 value: lang['code'],
 child: Text(lang['code'] == 'en' ? '${lang['native']}' : '${lang['native']} (${lang['name']})', style: const TextStyle(fontSize: 13)),
 )).toList(),
 onChanged: (val) {
 if (val != null) {
 setState(() => _language = val);
 i18n.setLanguage(val);
 }
 },
 ),
 const SizedBox(height: 14),

 if (_selectedRole == 'caretaker') ...[
 TextField(
 controller: _mappedElderIdController,
 textCapitalization: TextCapitalization.characters,
 decoration: InputDecoration(
 labelText: i18n.translate('mapElderIdLabel'),
 hintText: i18n.translate('assignElderIdHint'),
 helperText: ' ${i18n.translate("cloudSyncActiveLabel")}',
 helperStyle: const TextStyle(color: Color(0xFF61C5B0), fontWeight: FontWeight.w600, fontSize: 11),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.link, color: Color(0xFF61C5B0)),
 ),
 ),
 const SizedBox(height: 14),
 ],

 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFF61C5B0),
 padding: EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: _submitProfile,
 child: Text(i18n.translate('createAccountBtn'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
 ),
 ],
 );
 }

 Widget _buildStep4ElderSuccess() {
 final i18n = Provider.of<I18nService>(context);

 return Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF61C5B0)),
 SizedBox(height: 16),
 Text(i18n.translate('elderRegSuccessTitle'), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
 SizedBox(height: 8),
 Text(
 i18n.translate('elderRegSuccessDesc'),
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 13, color: Colors.black87),
 ),
 const SizedBox(height: 20),

 Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: const Color(0xFFFEF3C7),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: Color(0xFFF59E0B), width: 2),
 ),
 child: Column(
 children: [
 Text(i18n.translate('uniqueElderId'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
 const SizedBox(height: 8),
 Text(
 _generatedElderId,
 style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD97706), letterSpacing: 2),
 ),
 SizedBox(height: 6),
 Text(i18n.translate('shareElderIdWarning'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
 ],
 ),
 ),
 const SizedBox(height: 24),

 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF61C5B0),
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 onPressed: () async {
 await _showSuccessDialog(
 title: 'Account Ready! ',
 message: 'Your Elder account is ready. Welcome to Purb Chetana!',
 code: _generatedElderId,
 onProceed: widget.onComplete,
 );
 },
 child: Text(i18n.translate('goToDashboardBtn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
 ),
 ],
 );
 }
}
