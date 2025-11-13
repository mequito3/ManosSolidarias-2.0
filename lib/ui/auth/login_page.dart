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

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _mapLoginAuthError(AuthException error) {
    final lower = error.message.toLowerCase();

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

    if (lower.contains('network')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
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
      final friendly = _mapLoginAuthError(error);
      setState(() {
        _error = friendly;
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
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const AppLogo(symbolSize: 36),
        elevation: 0, // MEJORA: Sin sombra para look más limpio
        backgroundColor: Colors.transparent, // MEJORA: AppBar transparente
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.space24, // MEJORA: Usar sistema de espaciados
              vertical: AppColors.space40, // MEJORA: Más espacio vertical
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono de bienvenida centrado
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppColors.space16),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppColors.radiusLg),
                        ),
                        child: const Icon(
                          Icons.waving_hand_rounded,
                          size: AppColors.iconSizeXl,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.space24),
                    Text(
                      'Bienvenido de nuevo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 28, // MEJORA: Título más grande
                            letterSpacing: -0.5, // MEJORA: Mejor spacing
                          ),
                    ),
                    const SizedBox(height: AppColors.space12),
                    Text(
                      'Ingresa tus credenciales para continuar gestionando tus campañas o apoyando causas.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.mediumText, // MEJORA: Usar color del sistema
                            height: 1.5, // MEJORA: Mejor line height
                          ),
                    ),
                    const SizedBox(height: AppColors.space32), // MEJORA: Más espacio
                    if (widget.infoMessage != null) ...[
                      AppInfoBanner(message: widget.infoMessage!),
                      const SizedBox(height: AppColors.space24),
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
                    const SizedBox(height: AppColors.space20), // MEJORA: Espaciado consistente
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
                    const SizedBox(height: AppColors.space20),
                    if (_error != null) ...[
                      AppErrorBanner(message: _error!),
                      const SizedBox(height: AppColors.space20),
                    ],
                    const SizedBox(height: AppColors.space8),
                    AppPrimaryButton(
                      label: _submitting ? 'Ingresando...' : 'Iniciar sesión',
                      icon: _submitting ? null : Icons.login_rounded, // MEJORA: Ícono rounded
                      onPressed: _submitting ? null : _submit,
                    ),
                    const SizedBox(height: AppColors.space16), // MEJORA: Más espacio entre botones
                    AppSecondaryButton(
                      label: '¿Necesitas crear una cuenta?',
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
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
