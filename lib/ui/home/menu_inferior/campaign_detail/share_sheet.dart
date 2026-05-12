part of 'campaign_detail_page.dart';

// ─── Share Sheet ──────────────────────────────────────────────────────────────
// flutter-animations skill: staggered list entry (slide+fade per row).
// flutter-expert skill: const constructors, separate widget classes, AnimatedScale.

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.campaignTitle,
    required this.options,
  });

  final String campaignTitle;
  final List<_ShareOption> options;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Acento degradado superior
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                ),
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grayNeutral.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.bluePrimary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.share_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Compartir campaña',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                                fontSize: 18,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Difunde esta causa y ayuda a alcanzar la meta',
                              style: TextStyle(
                                color: AppColors.darkText.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Preview card con título de campaña
                _SharePreviewCard(title: widget.campaignTitle),
                // Separador invisible sin lineas duras
                const SizedBox(height: 10),
                // Lista de opciones con stagger
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bluePrimary.withValues(alpha: 0.03),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < widget.options.length; i++) ...[
                          _StaggeredShareRow(
                            index: i,
                            total: widget.options.length,
                            controller: _staggerController,
                            child: _ShareOptionRow(
                              option: widget.options[i],
                              isFirst: i == 0,
                              isLast: i == widget.options.length - 1,
                            ),
                          ),
                          if (i < widget.options.length - 1)
                            Divider(
                              height: 1,
                              indent: 74,
                              color:
                                  AppColors.dividerColor.withValues(alpha: 0.6),
                            ),
                        ],
                      ],
                    ),
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

// ─── Preview card ──────────────────────────────────────────────────────────────

class _SharePreviewCard extends StatelessWidget {
  const _SharePreviewCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bluePrimary.withValues(alpha: 0.08),
              AppColors.blueSecondary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluePrimary.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.bluePrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'Campaña solidaria',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                      fontSize: 14,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.bluePrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 10,
                              color: AppColors.bluePrimary
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Manos Solidarias · App',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.bluePrimary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ─── Staggered row wrapper ────────────────────────────────────────────────────
// Per flutter-animations skill: cache Tween/CurvedAnimation in State,
// never recreate them inside build().

class _StaggeredShareRow extends StatefulWidget {
  const _StaggeredShareRow({
    required this.index,
    required this.total,
    required this.controller,
    required this.child,
  });

  final int index;
  final int total;
  final AnimationController controller;
  final Widget child;

  @override
  State<_StaggeredShareRow> createState() => _StaggeredShareRowState();
}

class _StaggeredShareRowState extends State<_StaggeredShareRow> {
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    const itemWindow = 0.6;
    final step =
        widget.total > 1 ? (1.0 - itemWindow) / (widget.total - 1) : 0.0;
    final start = (widget.index * step).clamp(0.0, 1.0);
    final end = (start + itemWindow).clamp(0.0, 1.0);

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─── Option row ───────────────────────────────────────────────────────────────
// AnimatedScale implicit para el tap — sin AnimationController extra.

class _ShareOptionRow extends StatefulWidget {
  const _ShareOptionRow({
    required this.option,
    required this.isFirst,
    required this.isLast,
  });

  final _ShareOption option;
  final bool isFirst;
  final bool isLast;

  @override
  State<_ShareOptionRow> createState() => _ShareOptionRowState();
}

class _ShareOptionRowState extends State<_ShareOptionRow> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _pressed = false);
    await widget.option.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final opt = widget.option;
    final radius = BorderRadius.vertical(
      top: widget.isFirst ? const Radius.circular(20) : Radius.zero,
      bottom: widget.isLast ? const Radius.circular(20) : Radius.zero,
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: radius,
          splashColor: opt.accentColor.withValues(alpha: 0.08),
          highlightColor: opt.accentColor.withValues(alpha: 0.04),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Ícono de la plataforma
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: opt.accentColor,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: opt.accentColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(opt.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                          fontSize: 15,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        opt.description,
                        style: TextStyle(
                          color: AppColors.darkText.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grayNeutral.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Modelo de datos ──────────────────────────────────────────────────────────

class _ShareOption {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final Future<void> Function() onTap;
}
