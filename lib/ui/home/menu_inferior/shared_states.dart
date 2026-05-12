import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

typedef RetryCallback = Future<void> Function();

/// Reusable loading placeholder for home tabs.
class HomeTabLoadingState extends StatelessWidget {
  const HomeTabLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: _CampaignCardSkeleton(),
        );
      },
    );
  }
}

class _CampaignCardSkeleton extends StatefulWidget {
  const _CampaignCardSkeleton();

  @override
  State<_CampaignCardSkeleton> createState() => _CampaignCardSkeletonState();
}

class _CampaignCardSkeletonState extends State<_CampaignCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: _ShimmerBox(
                  height: 180,
                  shimmerController: _shimmerController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip skeleton
                    _ShimmerBox(
                      width: 100,
                      height: 28,
                      borderRadius: 14,
                      shimmerController: _shimmerController,
                    ),
                    const SizedBox(height: 12),
                    // Title skeleton
                    _ShimmerBox(
                      height: 24,
                      borderRadius: 6,
                      shimmerController: _shimmerController,
                    ),
                    const SizedBox(height: 8),
                    _ShimmerBox(
                      width: 200,
                      height: 24,
                      borderRadius: 6,
                      shimmerController: _shimmerController,
                    ),
                    const SizedBox(height: 16),
                    // Progress bar skeleton
                    _ShimmerBox(
                      height: 10,
                      borderRadius: 5,
                      shimmerController: _shimmerController,
                    ),
                    const SizedBox(height: 12),
                    // Stats skeleton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ShimmerBox(
                          width: 80,
                          height: 16,
                          borderRadius: 4,
                          shimmerController: _shimmerController,
                        ),
                        _ShimmerBox(
                          width: 80,
                          height: 16,
                          borderRadius: 4,
                          shimmerController: _shimmerController,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    this.height,
    this.borderRadius = 8,
    required this.shimmerController,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    final shimmerGradient = LinearGradient(
      colors: [
        AppColors.grayNeutral.withValues(alpha: 0.1),
        AppColors.grayNeutral.withValues(alpha: 0.2),
        AppColors.grayNeutral.withValues(alpha: 0.1),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(-1.0 - shimmerController.value * 2, 0.0),
      end: Alignment(1.0 - shimmerController.value * 2, 0.0),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: shimmerGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Full-page error placeholder used across home tabs.
class HomeTabErrorState extends StatelessWidget {
  const HomeTabErrorState({
    super.key,
    required this.onRetry,
    required this.message,
  });

  final RetryCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wifi_off_outlined, color: AppColors.orangeAction, size: 40),
              const SizedBox(height: 16),
              Text(
                'Ups...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact inline error tile that keeps the list scrollable.
class HomeTabInlineError extends StatelessWidget {
  const HomeTabInlineError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final RetryCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.orangeAction),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.orangeAction,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
