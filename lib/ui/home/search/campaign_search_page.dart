import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/campaign.dart';
import '../../../models/category.dart' as my_category;
import '../../../services/campaign_service.dart';
import '../../../theme/app_colors.dart';
import '../../widgets/app_network_image.dart';

class CampaignSearchPage extends StatefulWidget {
  const CampaignSearchPage({
    super.key,
    required this.campaignService,
    required this.onOpenCampaign,
  });

  final CampaignService campaignService;
  final ValueChanged<CampaignSummary> onOpenCampaign;

  @override
  State<CampaignSearchPage> createState() => _CampaignSearchPageState();
}

class _CampaignSearchPageState extends State<CampaignSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String _query = '';
  List<CampaignSummary>? _results;
  String? _errorMessage;

  List<my_category.Category>? _dynamicCategories;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    // Empezar a buscar dinámicamente o cuando presionen enter
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
    // Autofocus en el siguiente frame para que las animaciones de ruta terminen antes de alzar el teclado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _loadCategories() async {
    final categories = await widget.campaignService.fetchCategories();
    if (mounted) {
      setState(() {
        _dynamicCategories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _query) return;

    setState(() {
      _query = query;
      if (query.isEmpty) {
        _results = null;
        _errorMessage = null;
      }
    });

    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.campaignService.searchCampaigns(query);
      if (!mounted) return;
      if (_query == query) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (_query == query) {
        setState(() {
          _errorMessage = 'No pudimos conectarnos para buscar. Intenta de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  void _handleCategoryTap(String category) {
    _searchController.text = category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 8,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.dividerColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    color: AppColors.darkText,
                    splashRadius: 24,
                    onPressed: () => Navigator.of(context).pop(),
                  ).animate().fade().scale(curve: Curves.easeOutBack, duration: 400.ms),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Encuentra campañas maravillosas...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkText.withValues(alpha: 0.35),
                          ),
                          prefixIcon: Hero(
                            tag: 'search_icon_hero',
                            child: Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: AppColors.bluePrimary.withValues(alpha: 0.8),
                            ),
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: AppColors.darkText.withValues(alpha: 0.5),
                                  splashRadius: 20,
                                  onPressed: () {
                                    _searchController.clear();
                                    _focusNode.requestFocus();
                                  },
                                ).animate().scale(curve: Curves.easeOutBack, duration: 250.ms)
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ).animate().fade().slideX(begin: 0.1, curve: Curves.easeOut, duration: 450.ms),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return _buildSuggestions();
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.bluePrimary,
          strokeWidth: 2.5,
        ),
      ).animate().fade(delay: 200.ms);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.orangeAction),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _performSearch(_query),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
      );
    }

    if (_results != null && _results!.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.grayNeutral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.search_off_rounded, size: 40, color: AppColors.grayNeutral),
                ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                const SizedBox(height: 20),
                const Text(
                  'Sin resultados',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: AppColors.darkText,
                  ),
                ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                const SizedBox(height: 8),
                Text(
                  'No encontramos campañas con ese término.\nPrueba con alternativas más simples.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkText.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
              ],
            ),
          ),
        ),
      );
    }

    if (_results != null && _results!.isNotEmpty) {
      return ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        itemCount: _results!.length,
        itemBuilder: (context, index) {
          final campaign = _results![index];
          // Staggered animation effect
          final delayMs = 50 * index;
          return _SearchResultTile(
            campaign: campaign,
            onTap: () {
              _focusNode.unfocus();
              widget.onOpenCampaign(campaign);
            },
          ).animate(delay: delayMs.ms).fade(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.orangeAction, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Categorías populares',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ).animate().fade(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),
          if (_isLoadingCategories)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_dynamicCategories != null && _dynamicCategories!.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _dynamicCategories!.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                return ActionChip(
                  label: Text(
                    cat.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppColors.dividerColor.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  onPressed: () => _handleCategoryTap(cat.nombre),
                ).animate(delay: (idx * 50).ms).fade().scale(curve: Curves.easeOutBack);
              }).toList(),
            )
          else
            const Text(
              'No hay categorías disponibles.',
              style: TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.travel_explore_rounded,
                        size: 32,
                        color: AppColors.bluePrimary,
                      ),
                    ),
                  ),
                ).animate().fade(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text(
                  '¿Qué impacto quieres generar hoy?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    color: AppColors.darkText,
                  ),
                ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                Text(
                  'Busca campañas escribiendo su nombre\no la causa a la que apoyan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkText.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatefulWidget {
  const _SearchResultTile({
    required this.campaign,
    required this.onTap,
  });

  final CampaignSummary campaign;
  final VoidCallback onTap;

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _pressed = false;

  Widget _buildMedia() {
    if (widget.campaign.coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AppNetworkImage(
          url: widget.campaign.coverUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorWidget: _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.actionGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeAction.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.volunteer_activism_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.campaign.goalAmount > 0
        ? (widget.campaign.raisedAmount / widget.campaign.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: AppColors.dividerColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMedia(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.campaign.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: AppColors.darkText,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.campaign.category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.people_alt_rounded, size: 12, color: AppColors.darkText.withValues(alpha: 0.35)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.campaign.donorCount}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.darkText.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar with glow
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.grayNeutral.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.bluePrimary, AppColors.blueSecondary],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.bluePrimary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$pct% recaudado',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.bluePrimary,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.darkText.withValues(alpha: 0.3),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
