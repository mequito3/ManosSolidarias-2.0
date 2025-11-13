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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirma tus datos',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verifica que la información de tu perfil esté actualizada y coincida con la persona responsable de la iniciativa. Si necesitas ajustar algo, regresa a tu perfil desde el menú principal antes de continuar.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        RequesterSummary(profile: profile, tipo: tipo),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppSecondaryButton(
              label: 'Atrás',
              expanded: false,
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
            AppPrimaryButton(
              label: 'Ir al formulario',
              icon: Icons.assignment_turned_in_outlined,
              expanded: false,
              onPressed: onNext,
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.bluePrimary,
                      fontWeight: FontWeight.bold,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.style_outlined, size: 16, color: AppColors.darkText.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              tipo.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.darkText.withValues(alpha: 0.7),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
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
                icon: Icons.qr_code_2_outlined,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.bluePrimary.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText,
                    height: 1.3,
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
        IconButton(
          tooltip: isVisible ? 'Ocultar' : 'Mostrar',
          icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggleVisibility,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.bluePrimary.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.darkText.withValues(alpha: 0.75)),
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
