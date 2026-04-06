// lib/components/AuthDialog.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  VANI — Auth Dialog / Screen  · UX4G Redesign  v0.0.1             ║
// ║  Matches VANI homepage: floating blobs, arc rings, frosted card   ║
// ╚══════════════════════════════════════════════════════════════════════╝

// ignore_for_file: unused_element, unused_local_variable

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/AppLocalizations.dart';
import '../services/SupabaseService.dart';
import '../services/EmergencyService.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/EmergencyContact.dart';

const _fontFamily = 'Google Sans';

TextStyle _heading(double size, Color c, {FontWeight w = FontWeight.w600}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.3, letterSpacing: -0.2);

TextStyle _body(double size, Color c, {FontWeight w = FontWeight.w400}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.6);

TextStyle _label(double size, Color c, {FontWeight w = FontWeight.w500}) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w,
        color: c, height: 1.4, letterSpacing: 0.1);

const _sp4  = 4.0;
const _sp6  = 6.0;
const _sp8  = 8.0;
const _sp12 = 12.0;
const _sp16 = 16.0;
const _sp20 = 20.0;
const _sp24 = 24.0;

// ── Brand blue (matches homepage) ────────────────────────────────────
const _kBrandBlue   = Color(0xFF3B6BFF);
const _kCyan        = Color(0xFF06B6D4);
const _kViolet      = Color(0xFF7C3AED);
const _kBg          = Color(0xFFE8EDF8);   // homepage lavender-blue
const _kBlobA       = Color(0x60B4C3F0);   // soft blue blob
const _kBlobB       = Color(0x48C8B9F0);   // soft purple blob
const _kBlobC       = Color(0x38A0B9E6);   // lighter blue blob
const _kArcColor    = Color(0x3CA0B4E6);   // ring border color
const _kCardBg      = Color(0xE1FFFFFF);   // frosted white
const _kCardBorder  = Color(0xB0C8D2F0);

// ══════════════════════════════════════════════════════════════════════
//  PUBLIC API
// ══════════════════════════════════════════════════════════════════════
void showAuthDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.40),
    builder: (_) => const _VaniAuthDialog(),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  AUTH SCREEN  (full-screen, non-dismissible)
// ══════════════════════════════════════════════════════════════════════
class AuthScreen extends StatelessWidget {
  final VoidCallback? onAuthenticated;
  const AuthScreen({super.key, this.onAuthenticated});

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(children: [
          const _VaniBlobBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: _sp20, vertical: _sp24),
                child: VaniAuthCard(
                    embedded: true,
                    canClose: false,
                    onAuthenticated: onAuthenticated),
              ),
            ),
          ),
        ]),
      ));
}

// ══════════════════════════════════════════════════════════════════════
//  DIALOG WRAPPER  — wraps card in blob background
// ══════════════════════════════════════════════════════════════════════
class _VaniAuthDialog extends StatelessWidget {
  const _VaniAuthDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: _sp20, vertical: _sp24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Blob layer clipped to rounded rect
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 420,
              child: Container(
                color: _kBg,
                child: const SizedBox(height: 600, child: _VaniBlobBackground()),
              ),
            ),
          ),
          // Card on top
          const VaniAuthCard(embedded: false, canClose: true),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  BLOB BACKGROUND PAINTER
// ══════════════════════════════════════════════════════════════════════
class _VaniBlobBackground extends StatelessWidget {
  const _VaniBlobBackground();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final s = math.min(w, h);
        return Stack(
          children: [
            Positioned(
              top: -s * 0.48,
              left: -s * 0.48,
              child: _Orb(
                size: s * 1.62,
                color: _kBrandBlue.withOpacity(0.18),
              ),
            ),
            Positioned(
              top: h * 0.22,
              right: -s * 0.42,
              child: _Orb(
                size: s * 1.34,
                color: _kViolet.withOpacity(0.14),
              ),
            ),
            Positioned(
              bottom: s * 0.12,
              left: w * 0.24,
              child: _Orb(
                size: s * 1.08,
                color: _kCyan.withOpacity(0.12),
              ),
            ),
            Positioned(
              top: h * 0.22,
              left: w * 0.32,
              child: _AmbientBeam(
                width: s * 0.95,
                height: s * 0.40,
                color: _kBrandBlue,
              ),
            ),
            Positioned(
              bottom: h * 0.24,
              right: w * 0.14,
              child: _AmbientBeam(
                width: s * 0.82,
                height: s * 0.34,
                color: _kCyan,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _kBrandBlue.withOpacity(0.06),
                        Colors.transparent,
                        _kCyan.withOpacity(0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  color: _kBrandBlue.withOpacity(0.060),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: _ArcDecor(size: s * 0.68, color: _kBrandBlue, flip: false),
            ),
            Positioned(
              top: s * 0.03,
              right: s * 0.22,
              child: _ArcDecor(size: s * 0.50, color: _kCyan, flip: true),
            ),
            Positioned(
              bottom: s * 0.26,
              left: -s * 0.10,
              child: _ArcDecor(size: s * 0.43, color: _kBrandBlue, flip: false),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _ArcDecor(size: s * 0.82, color: _kViolet, flip: true),
            ),
            Positioned(
              top: s * 0.18,
              right: s * 0.06,
              child: _BorderCircle(size: s * 0.35, color: _kBrandBlue, stroke: 1.0),
            ),
            Positioned(
              bottom: s * 0.20,
              right: s * 0.12,
              child: _BorderCircle(size: s * 0.27, color: _kCyan, stroke: 0.9),
            ),
            Positioned(
              top: s * 0.52,
              left: -s * 0.09,
              child: _BorderCircle(size: s * 0.34, color: _kViolet, stroke: 0.95),
            ),
          ],
        );
      });
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _BorderCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double stroke;
  const _BorderCircle({
    required this.size,
    required this.color,
    this.stroke = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.22),
          width: stroke,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class _AmbientBeam extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const _AmbientBeam({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.20,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              color.withOpacity(0.08),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcDecor extends StatelessWidget {
  final double size;
  final Color color;
  final bool flip;
  const _ArcDecor({
    required this.size,
    required this.color,
    required this.flip,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: flip
          ? (Matrix4.identity()..rotateZ(math.pi))
          : Matrix4.identity(),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ArcPainter(color: color),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    void arc(double r, double op) {
      final glow = Paint()
        ..color = color.withOpacity(op * 0.052)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi / 2,
        false,
        glow,
      );

      final p = Paint()
        ..color = color.withOpacity(op * 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0,
        math.pi / 2,
        false,
        p,
      );
    }

    arc(s.width * 0.34, 0.32);
    arc(s.width * 0.66, 0.20);
    arc(s.width * 0.88, 0.11);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.color != color;
}

// ══════════════════════════════════════════════════════════════════════
//  AUTH CARD
// ══════════════════════════════════════════════════════════════════════
class VaniAuthCard extends StatefulWidget {
  final bool embedded, canClose;
  final VoidCallback? onAuthenticated;

  const VaniAuthCard({
    super.key,
    this.embedded = false,
    this.canClose = true,
    this.onAuthenticated,
  });

  @override
  State<VaniAuthCard> createState() => _VaniAuthCardState();
}

class _VaniAuthCardState extends State<VaniAuthCard>
    with SingleTickerProviderStateMixin {

  static const bool _authBackendEnabled = true;

  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();

  bool _isLogin     = true;
  bool _loading     = false;
  bool _obscurePass = true;

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340))
      ..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() => _isLogin = !_isLogin);
    _anim.reset(); _anim.forward();
  }

  String _fakeEmail(String u) =>
      '${u.toLowerCase().replaceAll(' ', '_')}@vani.app';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final l = AppLocalizations.of(context);

    try {
      if (!_authBackendEnabled) {
        _onSuccess(l.t('auth_backend_disabled')); return;
      }

      final sb    = Supabase.instance.client;
      final email = _fakeEmail(_usernameCtrl.text.trim());

      if (_isLogin) {
        final res = await sb.auth.signInWithPassword(
            email: email, password: _passCtrl.text.trim());
        if (res.session == null) {
          _showError(l.t('auth_login_failed')); return;
        }
        final box = Hive.box<EmergencyContact>('emergency_contacts');
        await box.clear();
        await SupabaseService.instance.upsertUserProfile();
        await EmergencyService.instance.syncFromSupabase();
      } else {
        final res = await sb.auth.signUp(
            email: email, password: _passCtrl.text.trim());
        if (res.session == null) {
          _showError(l.t('auth_signup_failed')); return;
        }
        await SupabaseService.instance.upsertUserProfile(
            fullName: _nameCtrl.text.trim(),
            phone:    _phoneCtrl.text.trim());
        await EmergencyService.instance.pushLocalContactsToSupabase();
      }
      _onSuccess(_isLogin
          ? l.t('auth_welcome_back')
          : l.t('auth_account_created'));
    } on AuthException    catch (e) { _showError('${l.t('auth_error_prefix')}: ${e.message}'); }
    on PostgrestException catch (e) { _showError('${l.t('auth_database_error_prefix')}: ${e.message}'); }
    catch (e)                       { _showError('${l.t('auth_unexpected_error_prefix')}: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _onSuccess(String msg) {
    if (!mounted) return;
    if (!widget.embedded) Navigator.pop(context);
    widget.onAuthenticated?.call();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: _body(13, Colors.white, w: FontWeight.w500)),
        backgroundColor: _kBrandBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: _body(13, Colors.white, w: FontWeight.w500)),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final isWide   = MediaQuery.of(context).size.width > 600;

    const textPri   = Color(0xFF1E2340);
    const textMuted = Color(0xFF8892B0);
    const surface   = Color(0xFFECEFF8);
    const border    = Color(0xFFD0D8F0);
    const errorC    = Color(0xFFD93025);

    final card = FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: EdgeInsets.all(isWide ? 32 : 24),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kCardBorder, width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────────────
                  Row(children: [
                    // Logo mark
                    Container(
                        width: 3, height: 18,
                        decoration: BoxDecoration(
                            color: _kBrandBlue,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: _sp8),
                    Text('VANI',
                        style: _label(15, _kBrandBlue, w: FontWeight.w900)
                            .copyWith(letterSpacing: 3.5)),
                    const Spacer(),
                    // Version badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0x18B4C3F0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0x55C8D2F0), width: 1)),
                      child: Text('v 0.0.1 · Beta',
                          style: _label(10, textMuted)),
                    ),
                    if (widget.canClose) ...[
                      const SizedBox(width: _sp8),
                      Semantics(
                        label: l.t('common_close'), button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: border, width: 1)),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: textMuted)),
                        ),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 4),
                  Text(l.t('auth_footer_tagline'),
                      style: _body(11.5, textMuted.withOpacity(0.75))),
                  const SizedBox(height: _sp20),

                  // ── Segment tabs ─────────────────────────────────────
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE6E9F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFC8D0EC), width: 1)),
                    padding: const EdgeInsets.all(3),
                    child: Row(children: [
                      _AuthTab(
                          label: l.t('auth_tab_login'),
                          selected: _isLogin,
                          onTap: _isLogin ? null : _switchMode),
                      _AuthTab(
                          label: l.t('auth_tab_signup'),
                          selected: !_isLogin,
                          onTap: _isLogin ? _switchMode : null),
                    ]),
                  ),
                  const SizedBox(height: _sp20),

                  // ── Username ─────────────────────────────────────────
                  _AuthField(
                    ctrl: _usernameCtrl,
                    fieldLabel: l.t('auth_username_label'),
                    hint: l.t('auth_username_hint'),
                    prefix: Icons.alternate_email_rounded,
                    errorColor: errorC,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return l.t('auth_username_required');
                      if (v.trim().length < 3) return l.t('auth_min_3_chars');
                      return null;
                    },
                  ),

                  // ── Sign-up only fields ──────────────────────────────
                  if (!_isLogin) ...[
                    const SizedBox(height: _sp14),
                    _AuthField(
                      ctrl: _nameCtrl,
                      fieldLabel: l.t('auth_full_name_label'),
                      hint: l.t('auth_full_name_hint'),
                      prefix: Icons.person_outline_rounded,
                      errorColor: errorC,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.t('auth_name_required') : null,
                    ),
                    const SizedBox(height: _sp14),
                    _AuthField(
                      ctrl: _phoneCtrl,
                      fieldLabel: l.t('auth_phone_label'),
                      hint: l.t('auth_phone_hint'),
                      prefix: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorColor: errorC,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return l.t('auth_phone_required');
                        if (v.trim().length < 7) return l.t('auth_phone_invalid');
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: _sp14),

                  // ── Password ─────────────────────────────────────────
                  _AuthField(
                    ctrl: _passCtrl,
                    fieldLabel: l.t('auth_password_label'),
                    hint: '••••••••',
                    prefix: Icons.lock_outline_rounded,
                    obscureText: _obscurePass,
                    errorColor: errorC,
                    suffix: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 17,
                          color: textMuted),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.t('auth_required');
                      if (!_isLogin && v.length < 6)
                        return l.t('auth_min_6_chars');
                      return null;
                    },
                  ),

                  // Forgot password
                  if (_isLogin) ...[
                    const SizedBox(height: _sp8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: l.t('auth_forgot_password'), button: true,
                        child: InkWell(
                          onTap: () {},
                          child: Text(l.t('auth_forgot_password'),
                              style: _label(11.5, _kBrandBlue)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: _sp24),

                  // ── Submit ───────────────────────────────────────────
                  Semantics(
                    label: _isLogin
                        ? l.t('auth_sign_in')
                        : l.t('auth_create_account'),
                    button: true, enabled: !_loading,
                    child: SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _kBrandBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _kBrandBlue.withOpacity(0.55),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white))
                            : Text(
                                _isLogin
                                    ? l.t('auth_sign_in')
                                    : l.t('auth_create_account'),
                                style: _label(14, Colors.white,
                                    w: FontWeight.w700)),
                      ),
                    ),
                  ),

                  const SizedBox(height: _sp16),

                  // ── Footer ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                              color: _kBrandBlue.withOpacity(0.25),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                          'Empowering India\'s deaf & mute community',
                          style: _body(10, textMuted.withOpacity(0.60))),
                      const SizedBox(width: 8),
                      Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                              color: _kBrandBlue.withOpacity(0.25),
                              shape: BoxShape.circle)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) return card;
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: _sp20, vertical: _sp24),
        child: card);
  }
}

// ── Missing spacing constant ──────────────────────────────────────────
const _sp14 = 14.0;

// ══════════════════════════════════════════════════════════════════════
//  AUTH TAB
// ══════════════════════════════════════════════════════════════════════
class _AuthTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _AuthTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected, button: true, label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
              color: selected ? _kBrandBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(7)),
          alignment: Alignment.center,
          child: Text(label,
              style: _label(
                  13,
                  selected ? Colors.white : const Color(0xFF8892B0),
                  w: selected ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
//  AUTH FIELD
// ══════════════════════════════════════════════════════════════════════
class _AuthField extends StatelessWidget {
  final TextEditingController ctrl;
  final String fieldLabel, hint;
  final IconData prefix;
  final Color errorColor;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.ctrl,
    required this.fieldLabel,
    required this.hint,
    required this.prefix,
    required this.errorColor,
    this.keyboardType = TextInputType.text,
    this.obscureText  = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const textPri   = Color(0xFF1E2340);
    const textMuted = Color(0xFF8892B0);
    const surface   = Color(0xFFECEFF8);
    const border    = Color(0xFFD0D8F0);
    final radius = BorderRadius.circular(10);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(fieldLabel,
          style: _label(11.5, textMuted, w: FontWeight.w600)),
      const SizedBox(height: _sp6),
      TextFormField(
        controller:   ctrl,
        keyboardType: keyboardType,
        obscureText:  obscureText,
        validator:    validator,
        style: _body(14, textPri),
        decoration: InputDecoration(
          hintText:   hint,
          hintStyle:  _body(14, textMuted.withOpacity(0.45)),
          prefixIcon: Icon(prefix, color: textMuted, size: 17),
          suffixIcon: suffix,
          filled:     true,
          fillColor:  surface,
          isDense:    true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: _sp16, vertical: _sp12),
          border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: border, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: border, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                  color: _kBrandBlue, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: errorColor, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: errorColor, width: 2)),
          errorStyle: _label(11, errorColor, w: FontWeight.w600),
        ),
      ),
    ]);
  }
}