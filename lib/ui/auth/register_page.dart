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

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _acceptsPolicies = false;
  bool _submitting = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _mapSignupAuthError(AuthException error) {
    final lower = error.message.toLowerCase();

    if (lower.contains('signups not allowed')) {
      return 'Los registros están deshabilitados temporalmente. Ponte en contacto con el administrador de la plataforma.';
    }

    if (lower.contains('email rate limit')) {
      return 'Has realizado demasiados intentos con este correo. Espera unos minutos y vuelve a intentarlo.';
    }

    if (lower.contains('invalid email') || lower.contains('invalid login credentials')) {
      return 'Revisa que el correo electrónico tenga un formato válido.';
    }

    if (lower.contains('password')) {
      return 'La contraseña no cumple los requisitos de seguridad. Asegúrate de que tenga al menos 8 caracteres.';
    }

    return error.message;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (!_acceptsPolicies) {
      setState(() => _error = 'Debes aceptar las políticas de uso y privacidad.');
      return;
    }
    if (form == null || !form.validate()) {
      return;
    }

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
        data: {
          'display_name': _nameCtrl.text.trim(),
        },
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

      setState(() {
        _submitting = false;
      });

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
      final friendly = _mapSignupAuthError(error);
      setState(() {
        _error = friendly;
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

  Future<void> _signUpWithGoogle() async {
    if (_googleLoading || _submitting) return;

    setState(() {
      _error = null;
      _googleLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseRedirects.oauthRedirectUri,
        scopes: 'email profile',
      );

      if (!mounted) return;

      final session = supabase.auth.currentSession;
      if (session != null) {
        Navigator.of(context).pop(AuthFlowResult.signedIn);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Continúa el flujo en la ventana de Google y regresa a la app cuando finalices.'),
        ),
      );
    } on AuthException catch (error) {
      final lower = error.message.toLowerCase();
      String friendlyMessage;
      
      if (lower.contains('provider is not enabled')) {
        friendlyMessage = 'El inicio de sesión con Google no está habilitado. Contacta al administrador.';
      } else if (lower.contains('network') || lower.contains('connection')) {
        friendlyMessage = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
      } else {
        friendlyMessage = 'No pudimos iniciar sesión con Google. Intenta más tarde.';
      }
      
      setState(() {
        _error = friendlyMessage;
      });
    } catch (error, stackTrace) {
      debugPrint('Google sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        _error = 'No pudimos iniciar sesión con Google. Intenta más tarde.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _googleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), // MEJORA: Ícono rounded más moderno
          onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
        ),
        title: const AppLogo(symbolSize: 36),
        foregroundColor: AppColors.darkText,
        elevation: 0, // MEJORA: Sin sombra para look más limpio
        backgroundColor: Colors.transparent, // MEJORA: AppBar transparente
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space24, // MEJORA: Usar sistema de espaciados
              vertical: AppColors.space32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MEJORA: Ícono decorativo de bienvenida centrado
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppColors.space16),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              boxShadow: AppColors.shadowSm,
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              size: AppColors.iconSizeXl,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppColors.space24),
        Text(
          'Únete a la comunidad solidaria',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 28, // MEJORA: Título más grande
                letterSpacing: -0.5, // MEJORA: Mejor spacing
              ),
        ),
        const SizedBox(height: AppColors.space12),
        Text(
          'Los administradores revisarán tu registro para garantizar campañas confiables para toda la comunidad.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.mediumText, // MEJORA: Usar color del sistema
                height: 1.5, // MEJORA: Mejor line height
              ),
        ),
        const SizedBox(height: AppColors.space32),
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
              const SizedBox(height: AppColors.space20), // MEJORA: Espaciado consistente
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
              // Políticas - Diseño moderno y minimalista
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
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
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
                                      child: Text(
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
                icon: _submitting ? null : Icons.arrow_forward_rounded, // MEJORA: Ícono rounded
              ),
              const SizedBox(height: AppColors.space16), // MEJORA: Más espacio
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
