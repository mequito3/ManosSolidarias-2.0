import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_logo.dart';
import 'onboarding_page_model.dart';

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

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final PageController _controller;
  int _currentIndex = 0;

  static const _pages = [
    OnboardingPageModel(
      title: 'Impulsa causas confiables',
      description:
          'Manos Solidarias reúne campañas verificadas que transforman comunidades, con transparencia en cada paso.',
      icon: Icons.verified_user_outlined,
      accentColor: AppColors.bluePrimary,
    ),
    OnboardingPageModel(
      title: 'Seguimiento con evidencias',
      description:
          'Solicitamos comprobantes, evidencias y reportes para que donantes y administradores sigan el impacto real.',
      icon: Icons.verified_user_outlined,
      accentColor: AppColors.greenHope,
    ),
    OnboardingPageModel(
      title: 'Tu comunidad, tu historia',
      description:
          'Organizaciones y ciudadanos pueden contar su historia, recibir apoyo y celebrar hitos juntos.',
      icon: Icons.groups_outlined,
      accentColor: AppColors.orangeAction,
    ),
  ];

  bool get _isLastPage => _currentIndex == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleNext() {
    if (_isLastPage) {
      widget.onCompleted();
      return;
    }
    _goTo(_currentIndex + 1);
  }

  void _handleSkip() => widget.onCompleted();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  const AppLogo(symbolSize: 46),
                  const Spacer(),
                  TextButton(
                    onPressed: _handleSkip,
                    child: const Text('Saltar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final model = _pages[index];
                  return _OnboardingSlide(model: model);
                },
              ),
            ),
            _DotsIndicator(length: _pages.length, currentIndex: _currentIndex),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  AppPrimaryButton(
                    label: _isLastPage ? 'Crear mi cuenta' : 'Siguiente',
                    onPressed: _handleNext,
                    icon: _isLastPage ? Icons.arrow_forward : null,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Ya tengo una cuenta',
                    onPressed: widget.onLogin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.model});

  final OnboardingPageModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  (model.accentColor ?? AppColors.bluePrimary).withValues(alpha: 0.15),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: _OnboardingArtwork(model: model),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            model.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            model.description,
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppColors.darkText.withValues(alpha: 0.75),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingArtwork extends StatelessWidget {
  const _OnboardingArtwork({required this.model});

  final OnboardingPageModel model;

  @override
  Widget build(BuildContext context) {
    if (model.assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          model.assetPath!,
          height: 160,
          fit: BoxFit.contain,
          color: model.accentColor?.withValues(alpha: 0.85),
          colorBlendMode: BlendMode.modulate,
        ),
      );
    }

    return Icon(
      model.icon,
      size: 128,
      color: model.accentColor ?? AppColors.bluePrimary,
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.length, required this.currentIndex});

  final int length;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 10,
          width: isActive ? 28 : 10,
          decoration: BoxDecoration(
            color: isActive ? AppColors.bluePrimary : AppColors.grayNeutral.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}
