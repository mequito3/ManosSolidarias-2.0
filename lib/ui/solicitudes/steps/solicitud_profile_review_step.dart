import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/solicitud.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_network_image.dart';

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

    final hasPaymentMethod = hasBankDetails || qrUrl.isNotEmpty;

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
            _IdentityHero(name: name, initials: initials, tipo: tipo),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: _SectionHeader(
                label: 'Contacto',
                accent: AppColors.bluePrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in contactRows)
                    _SpecRow(label: entry.label, value: entry.value),
                ],
              ),
            ),
            if (hasPaymentMethod) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: _SectionHeader(
                  label: 'Forma de cobro',
                  accent: AppColors.orangeAction,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        value: bankName.isNotEmpty ? bankName : 'Datos disponibles',
                        obscuredValue: bankAccount.isNotEmpty
                            ? 'Cuenta •••• ${bankAccount.length > 4 ? bankAccount.substring(bankAccount.length - 4) : bankAccount}'
                            : 'Datos protegidos',
                        richValueWhenVisible: _BankDetailsBlock(
                          holder: bankHolder,
                          bank: bankName,
                          type: bankType,
                          account: bankAccount,
                        ),
                        helperText:
                            'Oculta tu número de cuenta para evitar capturas accidentales.',
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
            ] else ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _NoPaymentMethodWarning(),
              ),
            ],
            const SizedBox(height: 16),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) =>
                    AppColors.primaryGradient.createShader(rect),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipoLabel,
                  softWrap: true,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
              letterSpacing: -0.3,
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText.withValues(alpha: 0.60),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
              letterSpacing: -0.2,
              height: 1.35,
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
    this.richValueWhenVisible,
  });

  final String label;
  final String value;
  final String obscuredValue;
  final bool isVisible;
  final VoidCallback onToggle;
  final String? helperText;
  final Widget? visibleChild;
  final Widget? richValueWhenVisible;

  @override
  Widget build(BuildContext context) {
    final displayValue = isVisible ? value : obscuredValue;
    final useRichValue = isVisible && richValueWhenVisible != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText.withValues(alpha: 0.60),
                  ),
                ),
              ),
              Material(
                color: AppColors.bluePrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: Text(
                      isVisible ? 'Ocultar' : 'Mostrar',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluePrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (useRichValue)
            richValueWhenVisible!
          else
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
                letterSpacing: -0.2,
                height: 1.35,
              ),
            ),
          if (isVisible && visibleChild != null) ...[
            const SizedBox(height: 14),
            visibleChild!,
          ],
          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkText.withValues(alpha: 0.60),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BankDetailsBlock extends StatelessWidget {
  const _BankDetailsBlock({
    required this.holder,
    required this.bank,
    required this.type,
    required this.account,
  });

  final String holder;
  final String bank;
  final String type;
  final String account;

  @override
  Widget build(BuildContext context) {
    final rows = <_SpecEntry>[
      if (holder.isNotEmpty) _SpecEntry(label: 'Titular', value: holder),
      if (bank.isNotEmpty) _SpecEntry(label: 'Banco', value: bank),
      if (type.isNotEmpty) _SpecEntry(label: 'Tipo de cuenta', value: type),
      if (account.isNotEmpty) _SpecEntry(label: 'Número de cuenta', value: account),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.darkText.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    rows[i].label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkText.withValues(alpha: 0.60),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                      letterSpacing: -0.1,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (i < rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _NoPaymentMethodWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.orangeAction.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 22,
            color: AppColors.orangeAction,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Falta configurar tu forma de cobro',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sin cuenta bancaria ni código QR registrados, los donantes no tendrán cómo enviarte el dinero. Configúralo desde tu perfil antes de continuar.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.darkText,
                    height: 1.4,
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
            child: AppNetworkImage(
              url: url,
              fit: BoxFit.contain,
              placeholder: const Center(
                child: CircularProgressIndicator(color: AppColors.bluePrimary),
              ),
              errorWidget: Container(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
