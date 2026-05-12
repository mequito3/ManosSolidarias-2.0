import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/solicitud.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';

class SolicitudProfileReviewStep extends StatelessWidget {
  const SolicitudProfileReviewStep({
    super.key,
    required this.profile,
    required this.tipo,
    required this.onBack,
    required this.onNext,
  });

  final UserProfile profile;
  final SolicitudTipo tipo;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.shadowSm,
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirma tus datos',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verifica que la información coincida con la persona responsable. Si necesitas ajustar algo, ve a tu perfil desde el menú principal.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.55),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RequesterSummary(profile: profile, tipo: tipo),
        const SizedBox(height: 24),
        Row(
          children: [
            AppSecondaryButton(
              label: 'Atrás',
              expanded: false,
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                label: 'Ir al formulario',
                icon: Icons.assignment_turned_in_rounded,
                expanded: true,
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RequesterSummary extends StatefulWidget {
  const RequesterSummary({super.key, required this.profile, required this.tipo});

  final UserProfile profile;
  final SolicitudTipo tipo;

  @override
  State<RequesterSummary> createState() => _RequesterSummaryState();
}

class _RequesterSummaryState extends State<RequesterSummary> {
  bool _showBankDetails = false;
  bool _showQrDetails = false;

  String _sanitize(String? value) => value?.trim() ?? '';

  String _maskAccountNumber(String value) {
    if (value.isEmpty) {
      return '';
    }
    if (value.length <= 4) {
      return '••••';
    }
    final lastDigits = value.substring(value.length - 4);
    return '•••• $lastDigits';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final tipo = widget.tipo;

    final name = _sanitize(profile.displayName).isNotEmpty
        ? _sanitize(profile.displayName)
        : 'Nombre pendiente de actualizar';
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Correo no disponible';

    final phone = _sanitize(profile.phone);
    final city = _sanitize(profile.city);
    final address = _sanitize(profile.address);

    final bankHolder = _sanitize(profile.bankHolder);
    final bankName = _sanitize(profile.bankName);
    final bankType = _sanitize(profile.bankAccountType);
    final bankAccount = _sanitize(profile.bankAccountNumber);
    final hasBankDetails = [bankHolder, bankName, bankType, bankAccount].any((value) => value.isNotEmpty);

    final qrUrl = _sanitize(profile.donationQrUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle with gradient
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volunteer_activism_rounded,
                              size: 13,
                              color: AppColors.bluePrimary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                tipo.displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.bluePrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
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
            const SizedBox(height: 16),
            if (phone.isNotEmpty || city.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (phone.isNotEmpty) InfoPill(icon: Icons.phone_outlined, label: phone),
                  if (city.isNotEmpty) InfoPill(icon: Icons.place_outlined, label: city),
                ],
              ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 16),
              SummaryLine(
                icon: Icons.home_outlined,
                label: 'Dirección de referencia',
                value: address,
              ),
            ],
            const SizedBox(height: 16),
            SummaryLine(icon: Icons.mail_outline, label: 'Correo de contacto', value: email),
            if (hasBankDetails) ...[
              const Divider(height: 28),
              SensitiveSummaryLine(
                icon: Icons.account_balance_outlined,
                label: 'Cuenta para recibir donaciones',
                value: _composeBankDetails(
                  holder: bankHolder,
                  bank: bankName,
                  type: bankType,
                  account: bankAccount,
                ),
                obscuredValue: _composeBankDetails(
                  holder: bankHolder,
                  bank: bankName,
                  type: bankType,
                  account: bankAccount.isNotEmpty ? _maskAccountNumber(bankAccount) : '',
                ),
                isVisible: _showBankDetails,
                onToggleVisibility: () => setState(() => _showBankDetails = !_showBankDetails),
                helperText: 'Oculta tu número de cuenta para evitar capturas accidentales.',
              ),
            ],
            if (qrUrl.isNotEmpty) ...[
              const Divider(height: 28),
              SensitiveSummaryLine(
                icon: Icons.qr_code_2_rounded,
                label: 'Canal QR registrado',
                value: 'Código listo para escanear',
                obscuredValue: 'Disponible para compartir',
                isVisible: _showQrDetails,
                onToggleVisibility: () => setState(() => _showQrDetails = !_showQrDetails),
                helperText: 'Muestra el código solo cuando quieras que lo escaneen.',
                visibleChild: _QrPreview(url: qrUrl),
              ),
            ],
          ],
        ),
    );
  }

  String _composeBankDetails({
    required String holder,
    required String bank,
    required String type,
    required String account,
  }) {
    final lines = <String>[];
    if (holder.isNotEmpty) {
      lines.add('Titular: $holder');
    }
    if (bank.isNotEmpty) {
      lines.add('Banco: $bank');
    }
    if (type.isNotEmpty) {
      lines.add('Tipo de cuenta: $type');
    }
    if (account.isNotEmpty) {
      lines.add('Cuenta: $account');
    }
    return lines.join('\n');
  }
}

class SummaryLine extends StatelessWidget {
  const SummaryLine({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.bluePrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.50),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontSize: 13,
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

class SensitiveSummaryLine extends StatelessWidget {
  const SensitiveSummaryLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.obscuredValue,
    required this.isVisible,
    required this.onToggleVisibility,
    this.helperText,
    this.visibleChild,
  });

  final IconData icon;
  final String label;
  final String value;
  final String obscuredValue;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final String? helperText;
  final Widget? visibleChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = isVisible ? value : obscuredValue;
    final Widget? child = isVisible ? visibleChild : null;
    final helperTopPadding = child != null ? 0.0 : 4.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SummaryLine(icon: icon, label: label, value: displayValue),
              if (child != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 4, 0, 12),
                  child: child,
                ),
              if (helperText != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(30, helperTopPadding, 0, 12),
                  child: Text(
                    helperText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: AppColors.bluePrimary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            tooltip: isVisible ? 'Ocultar' : 'Mostrar',
            icon: Icon(
              isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 19,
              color: AppColors.bluePrimary,
            ),
            onPressed: onToggleVisibility,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ],
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.bluePrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.darkText.withValues(alpha: 0.80),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: AppColors.bluePrimary.withValues(alpha: 0.04),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                final total = loadingProgress.expectedTotalBytes;
                final loaded = loadingProgress.cumulativeBytesLoaded;
                return Center(
                  child: CircularProgressIndicator(
                    value: total != null && total > 0 ? loaded / total : null,
                    color: AppColors.bluePrimary,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.darkText.withValues(alpha: 0.6),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pudimos cargar el código QR.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
