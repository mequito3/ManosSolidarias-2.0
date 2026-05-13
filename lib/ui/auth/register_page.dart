import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../pages/policies/policies_info_page.dart';
import '../../utils/supabase_redirects.dart';
import '../../models/auth_flow_result.dart';
import '../widgets/app_banners.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late final AnimationController _anim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  bool _acceptsPolicies = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  String _mapSignupAuthError(AuthException error) {
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
        lower.contains('network is unreachable')) {
      return 'Sin conexión a internet. Verifica tu Wi-Fi o datos móviles e inténtalo de nuevo.';
    }

    if (lower.contains('signups not allowed')) {
      return 'Los registros están deshabilitados temporalmente. Ponte en contacto con el administrador de la plataforma.';
    }
    if (lower.contains('email rate limit')) {
      return 'Has realizado demasiados intentos. Espera unos minutos y vuelve a intentarlo.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Ya existe una cuenta con este correo. Inicia sesión o usa otro correo.';
    }
    if (lower.contains('invalid email') ||
        lower.contains('invalid login credentials')) {
      return 'Revisa que el correo electrónico tenga un formato válido.';
    }
    if (lower.contains('password')) {
      return 'La contraseña no cumple los requisitos de seguridad. Asegúrate de que tenga al menos 8 caracteres.';
    }

    return 'No pudimos completar el registro. Revisa tus datos e inténtalo nuevamente.';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (!_acceptsPolicies) {
      setState(() => _error = 'Debes aceptar las políticas de uso y privacidad.');
      return;
    }
    if (form == null || !form.validate()) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final trimmedEmail = _emailCtrl.text.trim();
      final response = await supabase.auth.signUp(
        email: trimmedEmail,
        password: _passwordCtrl.text,
        data: {'display_name': _nameCtrl.text.trim()},
        emailRedirectTo: SupabaseRedirects.oauthRedirectUri,
      );
      if (!mounted) return;
      if (response.user == null) {
        setState(() {
          _error = 'No pudimos crear tu cuenta. Revisa tu conexión e inténtalo nuevamente.';
          _submitting = false;
        });
        return;
      }
      if (response.session != null) {
        Navigator.of(context).pop(AuthFlowResult.signedIn);
        return;
      }
      setState(() => _submitting = false);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final result = await navigator.push<AuthFlowResult?>(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            initialEmail: trimmedEmail,
            infoMessage:
                'Te enviamos un correo para verificar tu cuenta. Confírmalo y luego inicia sesión con tus credenciales.',
          ),
        ),
      );
      if (!mounted) return;
      if (result == AuthFlowResult.signedIn) {
        navigator.pop(AuthFlowResult.signedIn);
      } else {
        navigator.pop(AuthFlowResult.requiresEmailVerification);
      }
    } on AuthException catch (error) {
      setState(() {
        _error = _mapSignupAuthError(error);
        _submitting = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Email sign-up error: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        _error = 'Ocurrió un error inesperado al crear tu cuenta. Intenta más tarde o verifica tu conexión.';
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
          // ── Hero header verde ──────────────────────────────────────
          SizedBox(
            height: headerH,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(36)),
                  ),
                ),
                Positioned(
                  top: -30,
                  right: -50,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -25,
                  left: -20,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      // Botón back arriba a la izquierda
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20),
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).maybePop(),
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
                              'Crea tu cuenta solidaria',
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

          // ── Formulario ─────────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _buildForm(context),
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

  Widget _buildForm(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crear cuenta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Los administradores revisarán tu registro para garantizar campañas confiables.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mediumText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameCtrl,
                label: 'Nombre y apellido',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppColors.space20),
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
              const SizedBox(height: AppColors.space20),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Contraseña',
                obscureText: true,
                enableObscureToggle: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppColors.space20),
              AppTextField(
                controller: _confirmCtrl,
                label: 'Confirmar contraseña',
                obscureText: true,
                enableObscureToggle: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value != _passwordCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppColors.space24),
              // Políticas
              InkWell(
                onTap: () => setState(() => _acceptsPolicies = !_acceptsPolicies),
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppColors.space16),
                  decoration: BoxDecoration(
                    color: _acceptsPolicies
                        ? AppColors.bluePrimary.withValues(alpha: 0.08)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    border: Border.all(
                      color: _acceptsPolicies
                          ? AppColors.bluePrimary.withValues(alpha: 0.4)
                          : AppColors.dividerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _acceptsPolicies ? AppColors.bluePrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _acceptsPolicies ? AppColors.bluePrimary : AppColors.grayNeutral,
                            width: 2,
                          ),
                        ),
                        child: _acceptsPolicies
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: AppColors.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.darkText,
                                      height: 1.5,
                                    ),
                                children: [
                                  const TextSpan(text: 'Acepto las '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const PoliciesInfoPage(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Políticas de Uso y Privacidad',
                                        style: TextStyle(
                                          color: AppColors.bluePrimary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.bluePrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppColors.space4),
                            Text(
                              'Incluye políticas de donaciones y transparencia',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mediumText,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppColors.space16),
                AppErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppColors.space24),
              AppPrimaryButton(
                label: _submitting ? 'Creando cuenta...' : 'Crear cuenta',
                onPressed: _submitting ? null : _submit,
                icon: _submitting ? null : Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: AppColors.space16),
              AppSecondaryButton(
                label: 'Iniciar sesión',
                onPressed: _submitting
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final result = await navigator.push<AuthFlowResult?>(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                        if (!mounted) return;
                        if (result == AuthFlowResult.signedIn) {
                          navigator.pop(AuthFlowResult.signedIn);
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}