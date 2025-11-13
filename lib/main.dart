import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/profile_controller.dart';
import 'models/auth_flow_result.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'services/profile_service.dart';
import 'theme/app_colors.dart';
import 'ui/auth/login_page.dart';
import 'ui/auth/register_page.dart';
import 'ui/home/home_page.dart';
import 'ui/onboarding/onboarding_flow.dart';
import 'ui/widgets/app_buttons.dart';
import 'ui/widgets/app_logo.dart';

const _fallbackSupabaseUrl = 'https://gvdlsypoqstbifdbhafv.supabase.co';
const _fallbackSupabaseAnonKey = 'YOUR_SUPABASE_PUBLISHABLE_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('ℹ️  No .env file found. Continuing with fallback Supabase configuration.');
  }

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? _fallbackSupabaseUrl;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: _fallbackSupabaseAnonKey,
      );

  if (supabaseAnonKey == _fallbackSupabaseAnonKey) {
    debugPrint(
      '⚠️  Define SUPABASE_URL and SUPABASE_ANON_KEY in .env or pass them with --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(brightness: Brightness.light);
    final baseTextTheme = baseTheme.textTheme.apply(
          bodyColor: AppColors.darkText,
          displayColor: AppColors.darkText,
        );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.bluePrimary,
      brightness: Brightness.light,
      secondary: AppColors.greenHope,
      tertiary: AppColors.orangeAction,
    ).copyWith(
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: AppColors.darkText,
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'Manos Solidarias',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.lightBackground,
        useMaterial3: true,
        textTheme: baseTextTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.darkText,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.greenSoft.withValues(alpha: 0.3),
          disabledColor: AppColors.grayNeutral.withValues(alpha: 0.2),
          selectedColor: AppColors.bluePrimary.withValues(alpha: 0.15),
          secondarySelectedColor: AppColors.bluePrimary.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          labelStyle: const TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: AppColors.bluePrimary,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const AppEntryShell(),
    );
  }
}

class AppEntryShell extends StatefulWidget {
  const AppEntryShell({super.key});

  @override
  State<AppEntryShell> createState() => _AppEntryShellState();
}

class _AppEntryShellState extends State<AppEntryShell> {
  bool _readyForHome = false;
  bool _checkingSession = true;
  bool _emailPending = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;

    _authSubscription = auth.onAuthStateChange.listen((event) {
      _handleSession(event.session);
    });

    _handleSession(auth.currentSession);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleSession(Session? session) {
    if (!mounted) return;

    if (session == null) {
      setState(() {
        _readyForHome = false;
        _emailPending = false;
        _checkingSession = false;
      });
      return;
    }

    final emailConfirmed = session.user.emailConfirmedAt != null;
    setState(() {
      _readyForHome = emailConfirmed;
      _emailPending = !emailConfirmed;
      _checkingSession = false;
    });
  }

  Future<bool> _refreshSessionStatus() async {
    final auth = Supabase.instance.client.auth;
    try {
      final existingSession = auth.currentSession;
      if (existingSession == null) {
        debugPrint('No session available to refresh – user must log in after verifying email.');
        return false;
      }

      final response = await auth.refreshSession();
      final session = response.session ?? auth.currentSession;
      _handleSession(session);

      if (session != null && session.user.emailConfirmedAt != null) {
        return true;
      }

      return false;
    } catch (error) {
      debugPrint('Refresh session error: $error');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar el estado de verificación. Intenta nuevamente.')),
      );
      return false;
    }
  }

  void _goToHome() {
    if (mounted) {
      setState(() => _readyForHome = true);
    }
  }

  Future<void> _openRegistration() async {
    final outcome = await Navigator.of(context).push<AuthFlowResult?>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    switch (outcome) {
      case AuthFlowResult.signedIn:
        _goToHome();
        break;
      case AuthFlowResult.requiresEmailVerification:
        setState(() {
          _emailPending = true;
          _readyForHome = false;
        });
        break;
      default:
        break;
    }
  }

  Future<void> _openLogin() async {
    final outcome = await Navigator.of(context).push<AuthFlowResult?>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    if (outcome == AuthFlowResult.signedIn) {
      _goToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_readyForHome) {
      return const AuthenticatedHome();
    }

    if (_emailPending) {
      return PendingVerificationView(
        onLogin: _openLogin,
        onRefreshStatus: _refreshSessionStatus,
      );
    }

    return OnboardingFlow(
      onCompleted: () {
        _openRegistration();
      },
      onLogin: () {
        _openLogin();
      },
    );
  }
}

class PendingVerificationView extends StatefulWidget {
  const PendingVerificationView({
    super.key,
    required this.onLogin,
    required this.onRefreshStatus,
  });

  final Future<void> Function() onLogin;
  final Future<bool> Function() onRefreshStatus;

  @override
  State<PendingVerificationView> createState() => _PendingVerificationViewState();
}

class _PendingVerificationViewState extends State<PendingVerificationView> {
  bool _checking = false;

  Future<void> _handleRefresh() async {
    if (_checking) return;
    setState(() => _checking = true);
    final confirmed = await widget.onRefreshStatus();
    if (!mounted) return;
    setState(() => _checking = false);

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Listo! Ya detectamos tu correo verificado.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aún no detectamos la verificación. Si ya confirmaste, inicia sesión con tu correo y contraseña.',
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_checking) return;
    await widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(symbolSize: 42),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mark_email_unread_outlined, color: AppColors.greenHope, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Confirma tu correo',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                        color: AppColors.darkText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Revisa el correo que te enviamos y confirma tu cuenta. Cuando termines, toca "Ya confirmé mi correo" o entra directo a iniciar sesión.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.darkText.withValues(alpha: 0.78),
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 24),
                          AppPrimaryButton(
                            label: _checking ? 'Verificando...' : 'Ya confirmé mi correo',
                            icon: _checking ? null : Icons.verified_user_outlined,
                            onPressed: _checking ? null : _handleRefresh,
                          ),
                          const SizedBox(height: 12),
                          AppSecondaryButton(
                            label: 'Iniciar sesión',
                            icon: Icons.login,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¿No llegó el correo? Revisa spam o escríbenos a soporte@manossolidarias.org',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthenticatedHome extends StatefulWidget {
  const AuthenticatedHome({super.key});

  @override
  State<AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<AuthenticatedHome> {
  late final ProfileController _profileController;
  bool _viewAsAdmin = false;
  bool _initialModeResolved = false;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController(ProfileService(Supabase.instance.client));
    _loadProfile();
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    await _profileController.loadCurrentProfile();
    if (!mounted) return;
    if (!_initialModeResolved) {
      setState(() {
        _viewAsAdmin = _profileController.isAdmin;
        _initialModeResolved = true;
      });
    }
  }

  Future<void> _retryLoad() => _loadProfile();

  void _switchToAdmin() {
    if (!_profileController.isAdmin) {
      return;
    }
    setState(() => _viewAsAdmin = true);
  }

  void _switchToUser() {
    setState(() => _viewAsAdmin = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _profileController,
      builder: (context, _) {
        final profile = _profileController.profile;
        final isLoading = _profileController.isLoading;
        final error = _profileController.errorMessage;

        if (isLoading && profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (error != null && profile == null) {
          return _ProfileErrorView(message: error, onRetry: _retryLoad);
        }

        if (profile == null) {
          return _ProfileErrorView(
            message: 'No encontramos tu perfil. Intenta cerrar sesión e iniciar nuevamente.',
            onRetry: _retryLoad,
          );
        }

        final isAdmin = profile.isAdmin;
        final shouldShowAdmin = isAdmin && _viewAsAdmin;

        if (shouldShowAdmin) {
          return AdminDashboardPage(
            profile: profile,
            onViewAsUser: _switchToUser,
          );
        }

        return HomePage(
          showAdminShortcut: isAdmin,
          onOpenAdminPanel: isAdmin ? _switchToAdmin : null,
          profile: profile,
          onProfileUpdated: _loadProfile,
        );
      },
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_outlined, size: 48, color: AppColors.orangeAction),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Puedes intentar recargar los datos o cerrar sesión para iniciar nuevamente.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

