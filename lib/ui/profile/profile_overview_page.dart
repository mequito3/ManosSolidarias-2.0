import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
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
    if (!mounted) {
      return;
    }
    setState(() => _loading = true);
    try {
      final latest = await widget.profileService.fetchProfileByUserId(_profile.userId);
      if (latest != null && mounted) {
        setState(() => _profile = latest);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_profile);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Mi perfil'),
          actions: [
            IconButton(
              tooltip: 'Editar perfil',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _loading ? null : _openSettings,
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(profile: _profile, loading: _loading),
                    const SizedBox(height: 16),
                    _ProfileSection(
                      title: 'Contacto',
                      children: [
                        _ProfileRow(
                          icon: Icons.mail_outline,
                          label: 'Correo',
                          value: _userEmail ?? '—',
                        ),
                        _ProfileRow(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: _profile.phone,
                        ),
                        _ProfileRow(
                          icon: Icons.location_on_outlined,
                          label: 'Departamento',
                          value: _profile.city,
                        ),
                        _ProfileRow(
                          icon: Icons.home_outlined,
                          label: 'Dirección',
                          value: _profile.address,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProfileSection(
                      title: 'Identidad',
                      children: [
                        _ProfileRow(
                          icon: Icons.badge_outlined,
                          label: 'Nombre completo',
                          value: _profile.displayName,
                        ),
                        _ProfileRow(
                          icon: Icons.credit_card_outlined,
                          label: 'Documento',
                          value: _formatDocument(),
                        ),
                        _ProfileRow(
                          icon: Icons.info_outline,
                          label: 'Presentación',
                          value: _profile.bio,
                          multiline: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProfileSection(
                      title: 'Datos financieros',
                      children: [
                        _ProfileRow(
                          icon: Icons.person_outline,
                          label: 'Titular de cuenta',
                          value: _profile.bankHolder,
                        ),
                        _ProfileRow(
                          icon: Icons.account_balance_outlined,
                          label: 'Banco',
                          value: _profile.bankName,
                        ),
                        _ProfileRow(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Tipo de cuenta',
                          value: _profile.bankAccountType,
                        ),
                        _ProfileRow(
                          icon: Icons.numbers,
                          label: 'Número de cuenta',
                          value: _profile.bankAccountNumber,
                          obscure: !_showAccountNumber,
                          action: (_profile.bankAccountNumber?.trim().isNotEmpty ?? false)
                              ? IconButton(
                                  tooltip: _showAccountNumber ? 'Ocultar cuenta' : 'Ver cuenta',
                                  icon: Icon(
                                    _showAccountNumber
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() => _showAccountNumber = !_showAccountNumber),
                                  splashRadius: 18,
                                )
                              : null,
                        ),
                        if (_profile.donationQrUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'QR de donación',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkText.withValues(alpha: 0.85),
                                          ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => setState(() => _showQr = !_showQr),
                                      icon: Icon(_showQr ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      label: Text(_showQr ? 'Ocultar' : 'Ver'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.bluePrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 200),
                                  crossFadeState:
                                      _showQr ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                  firstChild: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.network(
                                        _profile.donationQrUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.qr_code_2_outlined, size: 48, color: AppColors.grayNeutral),
                                        ),
                                      ),
                                    ),
                                  ),
                                  secondChild: Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: AppColors.grayNeutral.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.grayNeutral.withValues(alpha: 0.35)),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.qr_code_2_outlined, size: 48, color: AppColors.grayNeutral),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Actualizar datos',
                      icon: Icons.settings_outlined,
                      onPressed: _loading ? null : _openSettings,
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _formatDocument() {
    if ((_profile.documentType?.isNotEmpty ?? false) && (_profile.documentNumber?.isNotEmpty ?? false)) {
      return '${_profile.documentType}: ${_profile.documentNumber}';
    }
    return _profile.documentNumber ?? _profile.documentType;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.loading});

  final UserProfile profile;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = profile.meetsCompletionCriteria ? AppColors.greenHope : AppColors.orangeAction;
    final statusLabel = profile.meetsCompletionCriteria ? 'Perfil verificado' : 'Información pendiente';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.12),
              backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
              child: profile.avatarUrl == null
                  ? const Icon(Icons.person_outline, color: AppColors.bluePrimary, size: 48)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final maxContentWidth = innerConstraints.maxWidth;
                  final statusChip = Chip(
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile.meetsCompletionCriteria
                              ? Icons.verified_outlined
                              : Icons.pending_outlined,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(color: statusColor.withValues(alpha: 0.25), width: 1),
                    ),
                  );

                  const double chipHorizontalPadding = 16;
                  final availableForName = math.max(0.0, maxContentWidth - 12 - chipHorizontalPadding - 120);

                  final headerLine = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: availableForName > 0 ? availableForName : maxContentWidth),
                        child: Text(
                          profile.displayName ?? 'Miembro Solidario',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      statusChip,
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerLine,
                      const SizedBox(height: 8),
                      Text(
                        profile.bio?.isNotEmpty == true
                            ? profile.bio!
                            : 'Completa tu historia para conectar con donantes y acelerar la aprobación de tus campañas.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.72),
                          height: 1.45,
                        ),
                      ),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    final displayValue = value?.trim().isNotEmpty == true
        ? (obscure ? '••••••••' : value!.trim())
        : 'Sin registrar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.bluePrimary.withValues(alpha: 0.85), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkText,
                        height: multiline ? 1.4 : 1.2,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 4),
            action!,
          ],
        ],
      ),
    );
  }
}
