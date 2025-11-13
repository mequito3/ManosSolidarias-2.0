import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';

class CampaignHero extends StatelessWidget {
  const CampaignHero({
    super.key,
    required this.onExploreTap,
    required this.onSearchTap,
    this.highlightedCategories = const ['Salud', 'Educación', 'Comunidad', 'Emergencias'],
  });

  final VoidCallback onExploreTap;
  final VoidCallback onSearchTap;
  final List<String> highlightedCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.bluePrimary, AppColors.blueSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppLogo(
                symbolSize: 32,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onSearchTap,
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: 'Buscar campañas',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Campañas con corazón solidario',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Explora iniciativas transparentes y cercanas, impulsadas por comunidades latinoamericanas que transforman realidades.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: highlightedCategories
                .map(
                  (category) => Chip(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    label: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onExploreTap,
              label: const Text('Explorar campañas'),
              icon: const Icon(Icons.explore_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeAction,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
