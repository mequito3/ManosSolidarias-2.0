import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/auth_flow_result.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_banners.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialEmail, this.infoMessage});

  final String? initialEmail;
  final String? infoMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final AnimationController _anim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideIn = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  String _mapLoginAuthError(AuthException error) {
    final lower = error.message.toLowerCase();

    // Errores de red (Supabase los envuelve dentro de AuthException)
    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated') ||
        lower.contains('connection failed') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('handshakeexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('network')) {
      return 'Sin conexión a internet. Verifica tu Wi-Fi o datos móviles e inténtalo de nuevo.';
    }

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Correo o contraseña incorrectos. Verifica tus credenciales.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de iniciar sesión.';
    }
    if (lower.contains('user not found')) {
      return 'No existe una cuenta con este correo electrónico.';
    }
    if (lower.contains('too many requests')) {
      return 'Demasiados intentos. Espera unos minutos antes de volver a intentarlo.';
    }
    return 'Error al iniciar sesión. Verifica tus datos e intenta nuevamente.';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      if (response.session == null) {
        setState(() {
          _error = 'No pudimos iniciar sesión. Verifica tus datos.';
          _submitting = false;
        });
        return;
      }
      Navigator.of(context).pop(AuthFlowResult.signedIn);
    } on AuthException catch (error) {
      setState(() {
        _error = _mapLoginAuthError(error);
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Ocurrió un error inesperado. Intenta más tarde.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final headerH = size.height * 0.25;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // ── Hero header con gradiente ────────────────────────────────
          SizedBox(
            height: headerH,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                ),
                // Círculo decorativo
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Back button + logo centrado
                SafeArea(
                  child: Stack(
                    children: [
                      // Botón back arriba a la izquierda
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      // Logo centrado
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.favorite,
                                  color: AppColors.orangeAction,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Manos Solidarias',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Bienvenido de nuevo',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Formulario ────────────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Ingresa tus credenciales para continuar.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mediumText,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (widget.infoMessage != null) ...[
                              AppInfoBanner(message: widget.infoMessage!),
                              const SizedBox(height: 20),
                            ],
                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Correo electrónico',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa un correo válido';
                                }
                                final emailRegex = RegExp(r'^.+@.+\..+$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Revisa el formato del correo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordCtrl,
                              label: 'Contraseña',
                              obscureText: true,
                              enableObscureToggle: true,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 16),
                            if (_error != null) ...[
                              AppErrorBanner(message: _error!),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 8),
                            AppPrimaryButton(
                              label: _submitting
                                  ? 'Ingresando...'
                                  : 'Iniciar sesión',
                              icon: _submitting ? null : Icons.login_rounded,
                              onPressed: _submitting ? null : _submit,
                            ),
                            const SizedBox(height: 12),
                            AppSecondaryButton(
                              label: '¿Necesitas crear una cuenta?',
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
