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
        // ── Header (clean, eyebrow + title + subtitle, accent bar a la izquierda)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.shadowSm,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppColors.orangeAction,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PASO 1 — VERIFICACIÓN',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orangeAction,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Confirma tus datos',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Verifica que la información coincida con la persona responsable. Si necesitas ajustar algo, ve a tu perfil desde el menú principal.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.60),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

    final initials = _initialsFor(name);

    final contactRows = <_SpecEntry>[
      if (phone.isNotEmpty) _SpecEntry(label: 'Teléfono', value: phone),
      if (city.isNotEmpty) _SpecEntry(label: 'Ciudad', value: city),
      if (address.isNotEmpty)
        _SpecEntry(label: 'Dirección de referencia', value: address),
      _SpecEntry(label: 'Correo de contacto', value: email),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banda hero con avatar overlapping ────────────────────
            _IdentityHero(name: name, initials: initials, tipo: tipo),
            const SizedBox(height: 16),
            // ── Sección contacto ─────────────────────────────────────
            _SectionHeader(label: 'Contacto', accent: AppColors.bluePrimary),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < contactRows.length; i++) ...[
                    _SpecRow(
                      label: contactRows[i].label,
                      value: contactRows[i].value,
                    ),
                    if (i < contactRows.length - 1)
                      Container(
                        height: 1,
                        color: AppColors.darkText.withValues(alpha: 0.06),
                      ),
                  ],
                ],
              ),
            ),
            // ── Sección cobro (si aplica) ────────────────────────────
            if (hasBankDetails || qrUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                label: 'Forma de cobro',
                accent: AppColors.orangeAction,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasBankDetails)
                      _SensitiveSpecRow(
                        label: 'Cuenta bancaria',
                        isVisible: _showBankDetails,
                        onToggle: () => setState(
                          () => _showBankDetails = !_showBankDetails,
                        ),
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
                          account: bankAccount.isNotEmpty
                              ? _maskAccountNumber(bankAccount)
                              : '',
                        ),
                        helperText:
                            'Oculta tu número de cuenta para evitar capturas accidentales.',
                      ),
                    if (hasBankDetails && qrUrl.isNotEmpty)
                      Container(
                        height: 1,
                        color: AppColors.darkText.withValues(alpha: 0.06),
                      ),
                    if (qrUrl.isNotEmpty)
                      _SensitiveSpecRow(
                        label: 'Código QR de pago',
                        isVisible: _showQrDetails,
                        onToggle: () => setState(
                          () => _showQrDetails = !_showQrDetails,
                        ),
                        value: 'Listo para escanear',
                        obscuredValue: 'Disponible para compartir',
                        helperText:
                            'Muestra el código solo cuando quieras que lo escaneen.',
                        visibleChild: _QrPreview(url: qrUrl),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _initialsFor(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
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

class _SpecEntry {
  const _SpecEntry({required this.label, required this.value});
  final String label;
  final String value;
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.name,
    required this.initials,
    required this.tipo,
  });

  final String name;
  final String initials;
  final SolicitudTipo tipo;

  @override
  Widget build(BuildContext context) {
    final tipoLabel = tipo.displayName;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banda gradient azul tipo cover hero (mismo lenguaje que org detail)
        Container(
          height: 92,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              // Círculo decorativo translúcido tipo brand
              Positioned(
                right: -28,
                top: -28,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 26,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: 20,
                right: 70,
                child: Text(
                  tipoLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: 40,
                right: 16,
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.15,
                    shadows: [
                      Shadow(color: Color(0x33000000), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Avatar overlapping
        Positioned(
          left: 18,
          top: 32,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.bluePrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 2,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText.withValues(alpha: 0.45),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensitiveSpecRow extends StatelessWidget {
  const _SensitiveSpecRow({
    required this.label,
    required this.value,
    required this.obscuredValue,
    required this.isVisible,
    required this.onToggle,
    this.helperText,
    this.visibleChild,
  });

  final String label;
  final String value;
  final String obscuredValue;
  final bool isVisible;
  final VoidCallback onToggle;
  final String? helperText;
  final Widget? visibleChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = isVisible ? value : obscuredValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText.withValues(alpha: 0.45),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    isVisible ? 'Ocultar' : 'Mostrar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluePrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
              height: 1.4,
            ),
          ),
          if (isVisible && visibleChild != null) ...[
            const SizedBox(height: 12),
            visibleChild!,
          ],
          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkText.withValues(alpha: 0.50),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
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
