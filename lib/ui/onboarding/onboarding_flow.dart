import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_logo.dart';
import 'onboarding_page_model.dart';

// ─── Datos de cada slide ───────────────────────────────────────────────────────
class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.badge,
    required this.badgeIcon,
  });
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final String badge;
  final IconData badgeIcon;
}

const _slides = [
  _SlideData(
    title: 'Causas\nverificadas',
    subtitle: 'Confianza en cada paso',
    description:
        'Cada campaña pasa por un proceso de verificación. Tu donación llega a donde más se necesita, con total transparencia.',
    icon: Icons.shield_outlined,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF2196F3)],
    ),
    accentColor: AppColors.bluePrimary,
    badge: '100% verificadas',
    badgeIcon: Icons.verified_rounded,
  ),
  _SlideData(
    title: 'Impacto\nreal',
    subtitle: 'Evidencias y resultados',
    description:
        'Recibe fotos, reportes y actualizaciones de las causas que apoyaste. Ve cómo tu contribución transforma vidas.',
    icon: Icons.bar_chart_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E7D32), Color(0xFF388E3C), Color(0xFF4CAF50)],
    ),
    accentColor: AppColors.greenHope,
    badge: 'Reportes en tiempo real',
    badgeIcon: Icons.insights_rounded,
  ),
  _SlideData(
    title: 'Tu comunidad\nte necesita',
    subtitle: 'Únete y marca la diferencia',
    description:
        'Organizaciones, ciudadanos y voluntarios bolivianos trabajando juntos para construir un futuro solidario.',
    icon: Icons.favorite_rounded,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFF9800)],
    ),
    accentColor: AppColors.orangeAction,
    badge: 'Comunidad activa',
    badgeIcon: Icons.groups_rounded,
  ),
];

// ─── Widget principal ──────────────────────────────────────────────────────────
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.onCompleted,
    this.onLogin,
  });

  final VoidCallback onCompleted;
  final VoidCallback? onLogin;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _bgAnim;
  late final AnimationController _iconAnim;
  int _currentIndex = 0;

  bool get _isLastPage => _currentIndex == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnim.dispose();
    _iconAnim.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleNext() {
    if (_isLastPage) {
      widget.onCompleted();
    } else {
      _goTo(_currentIndex + 1);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _bgAnim
      ..reset()
      ..forward();
    _iconAnim
      ..reset()
      ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo animado con gradiente ──────────────────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) {
              final t = CurvedAnimation(parent: _bgAnim, curve: Curves.easeOut).value;
              return Opacity(
                opacity: t,
                child: Container(
                  decoration: BoxDecoration(gradient: slide.gradient),
                ),
              );
            },
          ),

          // ── Círculos decorativos de fondo ──────────────────────────
          Positioned(
            top: -size.height * 0.05,
            right: -size.width * 0.15,
            child: AnimatedBuilder(
              animation: _iconAnim,
              builder: (_, __) => Transform.rotate(
                angle: _iconAnim.value * 0.3,
                child: Container(
                  width: size.width * 0.65,
                  height: size.width * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── Contenido ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header: logo + saltar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // Logo blanco
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.favorite,
                                  color: AppColors.orangeAction, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Manos\nSolidarias',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onCompleted,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.85),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Saltar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

                // ── Zona de la ilustración (ocupa ~35% de la pantalla) ─
                SizedBox(
                  height: size.height * 0.35,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _slides.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, index) => _IllustrationPanel(
                      slide: _slides[index],
                      iconAnim: _iconAnim,
                      isActive: index == _currentIndex,
                    ),
                  ),
                ),

                // ── Panel inferior blanco redondeado ─────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge
                          _SlideBadge(slide: slide),
                          const SizedBox(height: 14),

                          // Título
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topLeft,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: Text(
                              slide.title,
                              key: ValueKey(slide.title),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Descripción
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topLeft,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: Text(
                              slide.description,
                              key: ValueKey(slide.description),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.mediumText,
                                height: 1.55,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Dots
                          _DotsRow(
                            count: _slides.length,
                            current: _currentIndex,
                            accentColor: slide.accentColor,
                          ),
                          const SizedBox(height: 20),

                          // Botones
                          AppPrimaryButton(
                            label: _isLastPage ? 'Comenzar ahora' : 'Siguiente',
                            onPressed: _handleNext,
                            icon: _isLastPage
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          const SizedBox(height: 10),
                          AppSecondaryButton(
                            label: 'Ya tengo una cuenta',
                            onPressed: widget.onLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel de ilustración ─────────────────────────────────────────────────────
class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({
    required this.slide,
    required this.iconAnim,
    required this.isActive,
  });

  final _SlideData slide;
  final Animation<double> iconAnim;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: iconAnim,
        builder: (_, __) {
          final float = math.sin(iconAnim.value * math.pi) * 8.0;
          return Transform.translate(
            offset: Offset(0, float),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo exterior
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                // Halo medio
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                // Círculo principal blanco
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(slide.icon, size: 56, color: slide.accentColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Badge de slide ───────────────────────────────────────────────────────────
class _SlideBadge extends StatelessWidget {
  const _SlideBadge({required this.slide});
  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: Container(
        key: ValueKey(slide.badge),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: slide.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppColors.radiusRound),
          border: Border.all(
            color: slide.accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(slide.badgeIcon, size: 14, color: slide.accentColor),
            const SizedBox(width: 6),
            Text(
              slide.badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: slide.accentColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Indicador de puntos ──────────────────────────────────────────────────────
class _DotsRow extends StatelessWidget {
  const _DotsRow({
    required this.count,
    required this.current,
    required this.accentColor,
  });

  final int count;
  final int current;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: active ? 32 : 8,
          decoration: BoxDecoration(
            color: active ? accentColor : AppColors.grayNeutral.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppColors.radiusRound),
          ),
        );
      }),
    );
  }
}
