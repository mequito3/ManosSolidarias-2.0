import 'package:flutter/material.dart';

import '../../../models/campaign.dart';
import '../../../theme/app_colors.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.onSupport,
    this.onToggleFavorite,
    this.showSupportButton = true,
  });

  final CampaignSummary campaign;
  final VoidCallback? onTap;
  final VoidCallback? onSupport;
  final VoidCallback? onToggleFavorite;
  final bool showSupportButton;

  @override
  Widget build(BuildContext context) {
    final hasOrganizer = campaign.organizerName != null && campaign.organizerName!.isNotEmpty;
    final shouldShowSupportButton = showSupportButton && !campaign.isCompleted;
    // MEJORA: Card profesional con mejor diseño
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusLg), // MEJORA: Border radius del sistema
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient, // MEJORA: Gradiente sutil
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(
            color: AppColors.dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: AppColors.shadowMd, // MEJORA: Sombra del sistema
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _CampaignImage(imageUrl: campaign.coverUrl),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _FavoriteButton(
                    isFavorite: campaign.isFavorite,
                    onPressed: onToggleFavorite,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppColors.space20), // MEJORA: Espaciado consistente
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _CategoryChip(label: 'Campaña'),
                      if (campaign.isCompleted)
                        const SizedBox(width: AppColors.space8),
                      if (campaign.isCompleted)
                        const _StatusChip(label: 'Meta alcanzada', color: AppColors.greenSuccess),
                      const Spacer(),
                      if (campaign.isVerified)
                        Container(
                          padding: const EdgeInsets.all(AppColors.space4),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppColors.radiusRound),
                          ),
                          child: const Icon(
                            Icons.verified_rounded, // MEJORA: Ícono rounded
                            color: AppColors.bluePrimary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppColors.space16),
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (hasOrganizer)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Por ${campaign.organizerName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.darkText.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  Text(
                    campaign.shortDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkText.withValues(alpha: 0.72),
                        ),
                  ),
                  const SizedBox(height: AppColors.space16),
                  // MEJORA: Progress bar profesional con sombra
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppColors.radiusRound),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bluePrimary.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.radiusRound),
                      child: LinearProgressIndicator(
                        value: campaign.normalizedProgress,
                        color: AppColors.bluePrimary,
                        backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
                        minHeight: 10, // MEJORA: Más alto
                      ),
                    ),
                  ),
                  const SizedBox(height: AppColors.space16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MoneyText(
                        label: 'Recaudado',
                        value: campaign.raisedAmount,
                        highlightColor: AppColors.bluePrimary,
                      ),
                      _MoneyText(
                        label: 'Meta',
                        value: campaign.goalAmount,
                        highlightColor: AppColors.darkText,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${campaign.completionPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.orangeAction,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${campaign.donorCount} donadores',
                            style: TextStyle(
                              color: AppColors.darkText.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (shouldShowSupportButton) ...[
                    const SizedBox(height: AppColors.space20),
                    // MEJORA: Botón con gradiente
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.actionGradient,
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orangeAction.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppColors.space16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            ),
                            elevation: 0,
                          ),
                          onPressed: onSupport,
                          icon: const Icon(Icons.volunteer_activism_rounded, size: 20), // MEJORA: Ícono apropiado
                          label: const Text(
                            'Apoyar esta causa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // MEJORA: Botón de favorito con gradiente cuando está activo
    return Container(
      decoration: BoxDecoration(
        gradient: isFavorite
            ? LinearGradient( // MEJORA: Gradiente cuando es favorito
                colors: [
                  AppColors.orangeAction,
                  AppColors.orangeActionLight,
                ],
              )
            : null,
        color: isFavorite ? null : Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppColors.shadowMd, // MEJORA: Sombra del sistema
        border: Border.all(
          color: isFavorite
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.dividerColor,
          width: isFavorite ? 2 : 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, // MEJORA: Íconos rounded
          color: isFavorite ? Colors.white : AppColors.orangeAction,
          size: 24,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // MEJORA: Chip con gradiente sutil y mejor diseño
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space12,
        vertical: AppColors.space8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bluePrimary.withValues(alpha: 0.15),
            AppColors.bluePrimary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_rounded, // MEJORA: Ícono de categoría
            size: 14,
            color: AppColors.bluePrimary,
          ),
          const SizedBox(width: AppColors.space4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.bluePrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // MEJORA: Status chip con gradiente de éxito
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.space12,
        vertical: AppColors.space8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusRound),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded, // MEJORA: Ícono de check
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: AppColors.space4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignImage extends StatelessWidget {
  const _CampaignImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    // MEJORA: Imagen con gradiente cuando no hay imagen
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
      child: imageUrl.isEmpty
          ? Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bluePrimary.withValues(alpha: 0.15),
                    AppColors.blueSecondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_rounded, // MEJORA: Ícono rounded
                  size: 56,
                  color: AppColors.blueSecondary,
                ),
              ),
            )
          : Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withValues(alpha: 0.1),
                        AppColors.error.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded, // MEJORA: Ícono rounded
                      size: 56,
                      color: AppColors.error,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MoneyText extends StatelessWidget {
  const _MoneyText({
    required this.label,
    required this.value,
    required this.highlightColor,
  });

  final String label;
  final double value;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            color: highlightColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'Bs ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'Bs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Bs ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}';
  }
}
