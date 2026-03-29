// lib/components/AuthDialog.dart
//
// Colour scheme aligned to main.dart:
//   - All hardcoded purple/dark hex values replaced with Theme.of(context) tokens
//   - Uses colorScheme.primary (Apple Blue) as the accent instead of custom #7C3AED
//   - Surfaces, borders, and text pull from the same ColorScheme defined in VaniApp
//   - Dark/light mode handled automatically via ThemeData — no manual isDark branching
//     for colours

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/SupabaseService.dart';
import '../services/EmergencyService.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/EmergencyContact.dart';

void showAuthDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.60),
    builder: (_) => const _VaniAuthDialog(),
  );
}

class _VaniAuthDialog extends StatefulWidget {
  const _VaniAuthDialog();
  @override
  State<_VaniAuthDialog> createState() => _VaniAuthDialogState();
}

class _VaniAuthDialogState extends State<_VaniAuthDialog>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() => _isLogin = !_isLogin);
    _anim
      ..reset()
      ..forward();
  }

  String _fakeEmail(String username) =>
      '${username.toLowerCase().replaceAll(' ', '_')}@vani.app';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final sb = Supabase.instance.client;
      final fakeEmail = _fakeEmail(_usernameCtrl.text.trim());

      if (_isLogin) {
        final response = await sb.auth.signInWithPassword(
          email: fakeEmail,
          password: _passwordCtrl.text.trim(),
        );
        if (response.session == null) {
          _showError('Login failed — no session returned.');
          return;
        }
        final box = Hive.box<EmergencyContact>('emergency_contacts');
        await box.clear();
        await SupabaseService.instance.upsertUserProfile();
        await EmergencyService.instance.syncFromSupabase();
      } else {
        final response = await sb.auth.signUp(
          email: fakeEmail,
          password: _passwordCtrl.text.trim(),
        );
        if (response.session == null) {
          _showError('Signup failed. Try a different username.');
          return;
        }
        await SupabaseService.instance.upsertUserProfile(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
        await EmergencyService.instance.pushLocalContactsToSupabase();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Welcome back!' : 'Account created!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showError('Auth error: ${e.message}');
    } on PostgrestException catch (e) {
      if (mounted) _showError('Database error: ${e.message}');
    } catch (e) {
      if (mounted) _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Pull every colour from the same ThemeData defined in main.dart ──────
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary; // _kAppleBlue / _kAppleBlueDark
    final accentLight = cs.secondary; // _kAppleIndigo — used for glow
    final card = Theme.of(context).cardColor; // _lSurface / _dSurface
    final surface = cs.surfaceContainer; // _lSurface2 / _dSurface2
    final border = cs.outline; // _lSeparator / _dSeparator
    final textPrimary = cs.onSurface; // _lLabel / _dLabel
    final textMuted = cs.onSurface.withOpacity(0.55);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: accentLight.withOpacity(0.14),
                    blurRadius: 48,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 20,
                              decoration: BoxDecoration(
                                // Single solid accent — no gradient, matches
                                // main.dart's flat Apple colour usage
                                color: accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VANI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: accent,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: border.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Tab switcher ──────────────────────────────────────
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          _Tab(
                            label: 'Login',
                            selected: _isLogin,
                            accent: accent,
                            onTap: _isLogin ? null : _switchMode,
                            textMuted: textMuted,
                          ),
                          _Tab(
                            label: 'Sign Up',
                            selected: !_isLogin,
                            accent: accent,
                            onTap: _isLogin ? _switchMode : null,
                            textMuted: textMuted,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Username ──────────────────────────────────────────
                    _Field(
                      controller: _usernameCtrl,
                      label: 'Username',
                      hint: 'e.g. rahul123',
                      prefixIcon: Icons.alternate_email_rounded,
                      accent: accent,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Username is required';
                        if (v.trim().length < 3) return 'At least 3 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── Sign-up only fields ───────────────────────────────
                    if (!_isLogin) ...[
                      _Field(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        hint: 'Your name',
                        prefixIcon: Icons.person_outline_rounded,
                        accent: accent,
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hint: '+91 98765 43210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        accent: accent,
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Phone number is required';
                          if (v.trim().length < 7)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Password ──────────────────────────────────────────
                    _Field(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      accent: accent,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!_isLogin && v.length < 6) return 'Min 6 chars';
                        return null;
                      },
                    ),

                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            /* TODO: forgot password */
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Submit button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: _loading
                          ? Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: accent,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // ── Footer ────────────────────────────────────────────
                    Center(
                      child: Text(
                        'Built for accuracy. Designed for dignity.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: textMuted.withOpacity(0.65),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Tab pill
// ─────────────────────────────────────────────

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.textMuted,
  });
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final Color textMuted;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          // Selected tab uses the same Apple Blue from main.dart
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : textMuted,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  Text field
// ─────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.accent,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label, hint;
  final IconData prefixIcon;
  final Color accent, surface, border, textPrimary, textMuted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: TextStyle(color: textPrimary, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: textMuted.withOpacity(0.45),
            fontSize: 13,
          ),
          prefixIcon: Icon(prefixIcon, color: textMuted, size: 17),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            // Focus ring uses the same Apple Blue from main.dart
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            // Error uses colorScheme.error → _kAppleRed from main.dart
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );
}
