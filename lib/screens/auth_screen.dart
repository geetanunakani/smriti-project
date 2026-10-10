import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/doctor_hero.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = MockAuthService.instance;

  final _nameC = TextEditingController();
  final _idC = TextEditingController();
  final _passC = TextEditingController();
  final _ageC = TextEditingController();

  static const _languages = ['English', 'తెలుగు (Telugu)', 'हिन्दी (Hindi)'];
  String _language = _languages.first;

  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _idC.dispose();
    _passC.dispose();
    _ageC.dispose();
    super.dispose();
  }

  void _setMode(bool login) {
    if (_isLogin == login) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLogin = login);
    _formKey.currentState?.reset();
  }

  // ---------- validation ----------
  String? _vRequired(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Please enter $label' : null;

  String? _vIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email or phone number';
    final s = v.trim();
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phone = RegExp(r'^\+?[0-9]{10,13}$');
    if (!email.hasMatch(s) && !phone.hasMatch(s)) {
      return 'Enter a valid email or 10-digit phone number';
    }
    return null;
  }

  String? _vPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    if (!_isLogin && v.length < 8) return 'Use at least 8 characters';
    if (_isLogin && v.length < 6) return 'Password is too short';
    return null;
  }

  String? _vAge(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter your age';
    if (n < 1 || n > 120) return 'Enter a valid age';
    return null;
  }

  // ---------- submit ----------
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final SmritiUser user = _isLogin
          ? await _auth.signIn(_idC.text, _passC.text)
          : await _auth.signUp(
        name: _nameC.text,
        identifier: _idC.text,
        password: _passC.text,
        age: int.parse(_ageC.text.trim()),
        language: _language,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => HomeScreen(user: user),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SmritiColors.plum,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: SmritiColors.roseLight),
            const SizedBox(width: 10),
            Expanded(child: Text(e.message)),
          ]),
        ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroH = (size.height * 0.36).clamp(270.0, 330.0);
    const overlap = 32.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH,
            child: const DoctorHero(),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  SizedBox(height: heroH - overlap),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: size.height - heroH + overlap,
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(34)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tabs(),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _isLogin ? 'Welcome back 👋' : 'Create your account',
                            key: ValueKey('title$_isLogin'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: SmritiColors.plum,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin
                              ? 'Log in to continue your care thread.'
                              : 'Your health memory starts here.',
                          style: const TextStyle(color: SmritiColors.ink),
                        ),
                        const SizedBox(height: 18),
                        Form(
                          key: _formKey,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOut,
                              child: _isLogin
                                  ? _loginFields()
                                  : _signupFields(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _submitButton(),
                        const SizedBox(height: 18),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock_outline_rounded,
                                  size: 15, color: SmritiColors.mauve),
                              SizedBox(width: 6),
                              Text(
                                'Your health data stays private to you.',
                                style: TextStyle(
                                    fontSize: 12, color: SmritiColors.mauve),
                              ),
                            ],
                          ),
                        ),
                        if (_isLogin) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Demo: demo@smriti.app  /  demo1234',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: SmritiColors.ink.withOpacity(0.6),
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
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    Widget tab(String label, bool login) {
      final selected = _isLogin == login;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setMode(login),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : SmritiColors.ink,
              ),
              child: Text(label),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SmritiColors.blush,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: _isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC24B78), SmritiColors.rose],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SmritiColors.rose.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(children: [tab('Login', true), tab('Sign Up', false)]),
        ],
      ),
    );
  }

  Widget _loginFields() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _Reveal(
          index: 0,
          child: _field(
            controller: _idC,
            label: 'Email or phone number',
            icon: Icons.person_outline_rounded,
            keyboard: TextInputType.emailAddress,
            validator: _vIdentifier,
          ),
        ),
        _Reveal(index: 1, child: _passwordField()),
        _Reveal(
          index: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password reset will be added with the backend.'),
                ));
              },
              child: const Text('Forgot password?',
                  style: TextStyle(
                      color: SmritiColors.rose, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signupFields() {
    return Column(
      key: const ValueKey('signup'),
      children: [
        _Reveal(
          index: 0,
          child: _field(
            controller: _nameC,
            label: 'Full name',
            icon: Icons.badge_outlined,
            capitalization: TextCapitalization.words,
            validator: (v) => _vRequired(v, 'your name'),
          ),
        ),
        _Reveal(
          index: 1,
          child: _field(
            controller: _idC,
            label: 'Email or phone number',
            icon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
            validator: _vIdentifier,
          ),
        ),
        _Reveal(index: 2, child: _passwordField()),
        _Reveal(
          index: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: _field(
                  controller: _ageC,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  keyboard: TextInputType.number,
                  validator: _vAge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _languageDropdown()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return _field(
      controller: _passC,
      label: 'Password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscure,
      validator: _vPassword,
      suffix: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: SmritiColors.mauve,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }

  Widget _languageDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _language,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: SmritiColors.mauve),
        decoration: _decoration('Language', Icons.translate_rounded),
        items: _languages
            .map((l) => DropdownMenuItem(
          value: l,
          child: Text(l, overflow: TextOverflow.ellipsis),
        ))
            .toList(),
        onChanged: (v) => setState(() => _language = v ?? _language),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: SmritiColors.ink),
      floatingLabelStyle: const TextStyle(color: SmritiColors.rose),
      prefixIcon: Icon(icon, color: SmritiColors.mauve),
      suffixIcon: suffix,
      filled: true,
      fillColor: SmritiColors.blush.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(SmritiColors.rose, 1.6),
      errorBorder: border(const Color(0xFFD64545)),
      focusedErrorBorder: border(const Color(0xFFD64545), 1.6),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        textCapitalization: capitalization,
        validator: validator,
        style: const TextStyle(
            color: SmritiColors.plum, fontWeight: FontWeight.w600),
        decoration: _decoration(label, icon, suffix: suffix),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFC24B78), SmritiColors.rose, Color(0xFF8E2C52)],
          ),
          boxShadow: [
            BoxShadow(
              color: SmritiColors.rose.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _loading
                ? const SizedBox(
              key: ValueKey('loading'),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.6, color: Colors.white),
            )
                : Row(
              key: ValueKey('label$_isLogin'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Log In' : 'Create Account',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggered fade + slide-up entrance for form rows.
class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}