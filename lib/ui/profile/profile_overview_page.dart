import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_network_image.dart';
import '../widgets/premium_app_bar.dart';
import 'profile_settings_page.dart';

class ProfileOverviewPage extends StatefulWidget {
  const ProfileOverviewPage({
    super.key,
    required this.initialProfile,
    required this.profileService,
  });

  final UserProfile initialProfile;
  final ProfileService profileService;

  @override
  State<ProfileOverviewPage> createState() => _ProfileOverviewPageState();
}

class _ProfileOverviewPageState extends State<ProfileOverviewPage> {
  late UserProfile _profile;
  bool _loading = false;
  String? _userEmail;
  bool _showQr = false;
  bool _showAccountNumber = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _userEmail = Supabase.instance.client.auth.currentUser?.email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfile();
    });
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final latest = await widget.profileService.fetchProfileByUserId(_profile.userId);
      if (latest != null && mounted) {
        setState(() => _profile = latest);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<UserProfile?>(
      MaterialPageRoute(
        builder: (_) => ProfileSettingsPage(
          initialProfile: _profile,
          profileService: widget.profileService,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  String get _initials {
    final name = _profile.displayName?.trim() ?? '';
    if (name.isEmpty) {
      final email = _userEmail ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : 'M';
    }
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String? _formatDocument() {
    if ((_profile.documentType?.isNotEmpty ?? false) &&
        (_profile.documentNumber?.isNotEmpty ?? false)) {
      return '${_profile.documentType}: ${_profile.documentNumber}';
    }
    return _profile.documentNumber ?? _profile.documentType;
  }

  @override
  Widget build(BuildContext context) {
    final verified = _profile.meetsCompletionCriteria;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_profile);
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: PremiumAppBar(
          title: 'Mi perfil',
          onBack: () => Navigator.of(context).pop(_profile),
          actions: [
            PremiumAppBarAction(
              icon: Icons.edit_rounded,
              tooltip: 'Editar perfil',
              onPressed: _loading ? null : _openSettings,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: AppColors.bluePrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(
              AppColors.space20,
              AppColors.space12,
              AppColors.space20,
              AppColors.space32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHero(
                      profile: _profile,
                      email: _userEmail,
                      initials: _initials,
                      verified: verified,
                      loading: _loading,
                      onEdit: _loading ? null : _openSettings,
                    ),
                    const SizedBox(height: AppColors.space16),
                    _StatusBanner(verified: verified),
                            const SizedBox(height: AppColors.space16),
                            _ProfileSection(
                              icon: Icons.contact_mail_rounded,
                              iconColor: AppColors.bluePrimary,
                              title: 'Contacto',
                              children: [
                                _ProfileRow(
                                  icon: Icons.mail_outline_rounded,
                                  label: 'Correo',
                                  value: _userEmail,
                                ),
                                _ProfileRow(
                                  icon: Icons.phone_iphone_rounded,
                                  label: 'Teléfono',
                                  value: _profile.phone,
                                ),
                                _ProfileRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'Departamento',
                                  value: _profile.city,
                                ),
                                _ProfileRow(
                                  icon: Icons.home_rounded,
                                  label: 'Dirección',
                                  value: _profile.address,
                                  multiline: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppColors.space16),
                            _ProfileSection(
                              icon: Icons.badge_rounded,
                              iconColor: AppColors.greenHope,
                              title: 'Identidad',
                              children: [
                                _ProfileRow(
                                  icon: Icons.person_rounded,
                                  label: 'Nombre completo',
                                  value: _profile.displayName,
                                ),
                                _ProfileRow(
                                  icon: Icons.credit_card_rounded,
                                  label: 'Documento',
                                  value: _formatDocument(),
                                ),
                                _ProfileRow(
                                  icon: Icons.auto_stories_rounded,
                                  label: 'Presentación',
                                  value: _profile.bio,
                                  multiline: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppColors.space16),
                            _ProfileSection(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: AppColors.orangeAction,
                              title: 'Datos financieros',
                              children: [
                                _ProfileRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Titular de cuenta',
                                  value: _profile.bankHolder,
                                ),
                                _ProfileRow(
                                  icon: Icons.account_balance_rounded,
                                  label: 'Banco',
                                  value: _profile.bankName,
                                ),
                                _ProfileRow(
                                  icon: Icons.list_alt_rounded,
                                  label: 'Tipo de cuenta',
                                  value: _profile.bankAccountType,
                                ),
                                _ProfileRow(
                                  icon: Icons.tag_rounded,
                                  label: 'Número de cuenta',
                                  value: _profile.bankAccountNumber,
                                  obscure: !_showAccountNumber,
                                  action: (_profile.bankAccountNumber?.trim().isNotEmpty ?? false)
                                      ? _RowToggleButton(
                                          visible: _showAccountNumber,
                                          onTap: () => setState(
                                              () => _showAccountNumber = !_showAccountNumber),
                                        )
                                      : null,
                                ),
                                if (_profile.donationQrUrl != null) ...[
                                  const SizedBox(height: AppColors.space12),
                                  _QrPanel(
                                    url: _profile.donationQrUrl!,
                                    visible: _showQr,
                                    onToggle: () => setState(() => _showQr = !_showQr),
                                  ),
                                ],
                              ],
                            ),
                    const SizedBox(height: AppColors.space24),
                    AppPrimaryButton(
                      label: 'Editar mi perfil',
                      icon: Icons.tune_rounded,
                      onPressed: _loading ? null : _openSettings,
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

// ─── Compact, soft profile card (no harsh blue header) ──────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.email,
    required this.initials,
    required this.verified,
    required this.loading,
    required this.onEdit,
  });

  final UserProfile profile;
  final String? email;
  final String initials;
  final bool verified;
  final bool loading;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = (profile.avatarUrl?.trim().isNotEmpty ?? false);
    final ringColor =
        verified ? AppColors.greenHope : AppColors.orangeAction;

    return Container(
      padding: const EdgeInsets.all(AppColors.space20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grayLight,
              ),
              child: ClipOval(
                child: hasAvatar
                    ? AppNetworkImage(
                        url: profile.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: _InitialsAvatar(initials: initials),
                      )
                    : _InitialsAvatar(initials: initials),
              ),
            ),
          ),
          const SizedBox(width: AppColors.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.displayName?.trim().isNotEmpty == true
                      ? profile.displayName!
                      : 'Miembro Solidario',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeLg,
                    fontWeight: AppColors.fontWeightExtraBold,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    style: const TextStyle(
                      color: AppColors.mediumText,
                      fontSize: AppColors.fontSizeSm,
                      fontWeight: AppColors.fontWeightMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppColors.space8),
                _HeroBadge(verified: verified),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.only(top: AppColors.space8),
                    child: SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        backgroundColor:
                            AppColors.grayLight.withValues(alpha: 0.6),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.bluePrimary),
                        minHeight: 2,
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bluePrimary.withValues(alpha: 0.10),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.bluePrimary,
            fontSize: AppColors.fontSizeXl,
            fontWeight: AppColors.fontWeightExtraBold,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.greenHope : AppColors.orangeAction;
    final label = verified ? 'Perfil verificado' : 'Información pendiente';
    final icon =
        verified ? Icons.verified_rounded : Icons.pending_actions_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppColors.fontSizeXs,
              fontWeight: AppColors.fontWeightBold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status banner under hero ────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.greenHope : AppColors.orangeAction;
    final title = verified
        ? '¡Tu perfil está completo!'
        : 'Completa tu perfil para publicar campañas';
    final subtitle = verified
        ? 'Los donantes pueden confiar en tus datos y aprobar tus solicitudes más rápido.'
        : 'Añade tu información financiera y de contacto para enviar solicitudes de campaña.';
    final icon =
        verified ? Icons.verified_rounded : Icons.info_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppColors.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeMd,
                    fontWeight: AppColors.fontWeightBold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppColors.space4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mediumText,
                    fontSize: AppColors.fontSizeBase,
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

// ─── Section card ────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppColors.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: AppColors.space12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: AppColors.fontSizeLg,
                      fontWeight: AppColors.fontWeightBold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppColors.space16),
            const Divider(height: 1, color: AppColors.grayLight),
            const SizedBox(height: AppColors.space8),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Row inside a section ────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.value,
    this.obscure = false,
    this.multiline = false,
    this.action,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool obscure;
  final bool multiline;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.trim().isNotEmpty == true;
    final displayValue = hasValue
        ? (obscure ? '•••• •••• ••••' : value!.trim())
        : 'Sin registrar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppColors.space12),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
            ),
            child: Icon(icon, color: AppColors.bluePrimary, size: 18),
          ),
          const SizedBox(width: AppColors.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.lightText.withValues(alpha: 0.95),
                    fontSize: AppColors.fontSizeXs,
                    fontWeight: AppColors.fontWeightBold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.darkText
                        : AppColors.lightText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: hasValue
                        ? AppColors.fontWeightSemiBold
                        : AppColors.fontWeightMedium,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                    height: multiline ? 1.45 : 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppColors.space8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _RowToggleButton extends StatelessWidget {
  const _RowToggleButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bluePrimary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppColors.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppColors.space8),
          child: Icon(
            visible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppColors.bluePrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Donation QR card inside finance section ─────────────────────────────────

class _QrPanel extends StatelessWidget {
  const _QrPanel({
    required this.url,
    required this.visible,
    required this.onToggle,
  });

  final String url;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.space16),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: AppColors.bluePrimary, size: 20),
              const SizedBox(width: AppColors.space8),
              const Expanded(
                child: Text(
                  'QR de donación',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: AppColors.fontSizeBase,
                    fontWeight: AppColors.fontWeightBold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.space12, vertical: AppColors.space4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  ),
                ),
                icon: Icon(
                  visible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                ),
                label: Text(visible ? 'Ocultar' : 'Ver'),
              ),
            ],
          ),
          const SizedBox(height: AppColors.space12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                child: AppNetworkImage(
                  url: url,
                  fit: BoxFit.cover,
                  errorWidget: const Center(
                    child: Icon(Icons.qr_code_2_rounded,
                        size: 56, color: AppColors.grayNeutral),
                  ),
                ),
              ),
            ),
            secondChild: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                border: Border.all(
                  color: AppColors.grayNeutral.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded,
                    size: 64, color: AppColors.grayNeutral),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
