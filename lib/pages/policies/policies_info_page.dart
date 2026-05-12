import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PoliciesInfoPage extends StatelessWidget {
  const PoliciesInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.bluePrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text(
                'Políticas y privacidad',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 44,
                    left: 20,
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Manos Solidarias · Bolivia',
                          style: TextStyle(
                            color: Colors.white70,
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

          // ── Contenido ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta introductoria
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.bluePrimary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.bluePrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cuidar tu información y garantizar campañas transparentes es la base de Manos Solidarias.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.bluePrimary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
              const _PolicySection(
                title: 'Protección y tratamiento de datos personales',
                points: [
                  'Tu información se almacena en Supabase con cifrado en reposo y en tránsito.',
                  'Solo el equipo administrador autorizado puede ver documentos de verificación.',
                  'Puedes solicitar la actualización o eliminación de tus datos en cualquier momento escribiendo a soporte.',
                ],
              ),
              const SizedBox(height: 24),
              const _PolicySection(
                title: 'Uso aceptable de la plataforma',
                points: [
                  'Los datos que compartas deben ser verídicos y corresponder a tu identidad u organización.',
                  'No se permite utilizar la plataforma para actividades fraudulentas, lavado de dinero o campañas engañosas.',
                  'El incumplimiento puede derivar en la suspensión definitiva de la cuenta y reporte a las autoridades competentes.',
                ],
              ),
              const SizedBox(height: 24),
              const _PolicySection(
                title: 'Transparencia y evidencia',
                points: [
                  'Cada campaña debe respaldar el uso de fondos con evidencias verificables (facturas, fotos, reportes).',
                  'Los donantes pueden solicitar aclaraciones y reportes cuando hayan contribuido a una campaña.',
                  'Manos Solidarias puede auditar campañas en cualquier momento para proteger a la comunidad.',
                ],
              ),
              const SizedBox(height: 24),
              const _PolicySection(
                title: 'Seguridad y soporte',
                points: [
                  'Aplicamos políticas de acceso basadas en roles para proteger datos sensibles.',
                  'Se te notificará si detectamos actividad inusual en tu cuenta.',
                  'Si encuentras un problema de seguridad, repórtalo al equipo para que podamos resolverlo juntos.',
                ],
              ),
                  const SizedBox(height: 28),
                  // Tarjeta de contacto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.orangeAction.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mail_outline_rounded,
                              color: AppColors.orangeAction, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Necesitas ayuda?',
                                style: textTheme.titleSmall?.copyWith(
                                  color: AppColors.darkText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Escríbenos a soporte@manossolidarias.org para resolver dudas, solicitar tus datos o reportar un problema.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.mediumText,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.greenHope.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.greenHope.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.greenHope, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Al continuar declaras haber leído y aceptado estas políticas.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.greenHope,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
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
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.points,
    this.iconData = Icons.shield_outlined,
  });

  final String title;
  final List<String> points;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData,
                    size: 18, color: AppColors.bluePrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.greenHope),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumText,
                        height: 1.45,
                      ),
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
}
