import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../ui/widgets/app_logo.dart';

class PoliciesInfoPage extends StatelessWidget {
  const PoliciesInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const AppLogo(symbolSize: 32),
        foregroundColor: AppColors.darkText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Políticas de uso y protección de datos',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cuidar tu información y garantizar campañas transparentes es la base de Manos Solidarias. Estos principios resumen lo que aceptas al crear una cuenta.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.8),
                  height: 1.4,
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
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Necesitas ayuda?',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escríbenos a soporte@manossolidarias.org para resolver dudas, solicitar tus datos o reportar un problema.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Al continuar declaras haber leído y aceptado estas políticas.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkText.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.points,
  });

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.bluePrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map(
          (point) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 20, color: AppColors.greenHope),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.78),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
