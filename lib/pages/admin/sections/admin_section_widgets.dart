import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';

enum AdminDashboardSection { metrics, campaignRequests, donations, organizations }

class AdminNavItem {
	const AdminNavItem({
		required this.section,
		required this.label,
		required this.icon,
		required this.count,
	});

	final AdminDashboardSection section;
	final String label;
	final IconData icon;
	final int count;
}

class AdminNavIcon extends StatelessWidget {
	const AdminNavIcon({
		super.key,
		required this.icon,
		required this.count,
		this.selected = false,
	});

	final IconData icon;
	final int count;
	final bool selected;

	@override
	Widget build(BuildContext context) {
		final color = selected ? AppColors.bluePrimary : AppColors.darkText;
		return Stack(
			clipBehavior: Clip.none,
			children: [
				Icon(icon, color: color),
				if (count > 0)
					Positioned(
						right: -6,
						top: -6,
						child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
							decoration: BoxDecoration(
								color: AppColors.orangeAction,
								borderRadius: BorderRadius.circular(999),
							),
							child: Text(
								count.toString(),
								style: Theme.of(context).textTheme.labelSmall?.copyWith(
											color: Colors.white,
											fontWeight: FontWeight.bold,
										),
							),
						),
					),
			],
		);
	}
}

class AdminSectionHeading extends StatelessWidget {
	const AdminSectionHeading({
		super.key,
		required this.title,
		required this.description,
	});

	final String title;
	final String description;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					title,
					style: theme.textTheme.titleMedium?.copyWith(
								fontWeight: FontWeight.w700,
								color: AppColors.darkText,
							),
				),
				const SizedBox(height: 6),
				Text(
					description,
					style: theme.textTheme.bodyMedium?.copyWith(
								color: AppColors.darkText.withValues(alpha: 0.68),
							),
				),
			],
		);
	}
}


class AdminEmptyState extends StatelessWidget {
	const AdminEmptyState({super.key, required this.message});

	final String message;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(18),
				border: Border.all(color: AppColors.grayNeutral.withValues(alpha: 0.35)),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Icon(Icons.inbox_outlined, color: AppColors.grayNeutral),
					const SizedBox(width: 12),
					Expanded(
						child: Text(
							message,
							style: theme.textTheme.bodyMedium?.copyWith(
										color: AppColors.darkText.withValues(alpha: 0.65),
									),
						),
					),
				],
			),
		);
	}
}

class AdminWelcomeHeader extends StatelessWidget {
	const AdminWelcomeHeader({
		super.key,
		required this.profile,
		this.pendingCampaigns = 0,
		this.pendingDonations = 0,
		this.pendingOrganizations = 0,
	});

	final UserProfile profile;
	final int pendingCampaigns;
	final int pendingDonations;
	final int pendingOrganizations;

	@override
	Widget build(BuildContext context) {
		final greeting = _buildGreeting();
		final displayName = profile.displayName?.trim().isNotEmpty == true
				? profile.displayName!
				: 'Administrador';
		final total = pendingCampaigns + pendingDonations + pendingOrganizations;

		return ClipRRect(
			borderRadius: BorderRadius.circular(AppColors.radiusXl),
			child: Stack(
				children: [
					// Gradiente oficial
					Container(
						decoration: BoxDecoration(
							gradient: AppColors.primaryGradient,
							boxShadow: [
								BoxShadow(
									color: AppColors.bluePrimary.withValues(alpha: 0.35),
									blurRadius: 18,
									offset: const Offset(0, 8),
								),
							],
						),
					),
					// Blobs decorativos (sup-der + inf-izq)
					Positioned(
						top: -36,
						right: -28,
						child: _DecorativeBlob(
							size: 140,
							color: Colors.white.withValues(alpha: 0.10),
						),
					),
					Positioned(
						bottom: -40,
						left: -24,
						child: _DecorativeBlob(
							size: 120,
							color: Colors.white.withValues(alpha: 0.06),
						),
					),
					Padding(
						padding: const EdgeInsets.all(AppColors.space20),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								// Saludo + avatar
								Row(
									crossAxisAlignment: CrossAxisAlignment.center,
									children: [
										_AdminAvatar(
											avatarUrl: profile.avatarUrl,
											displayName: displayName,
										),
										const SizedBox(width: AppColors.space12),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												mainAxisSize: MainAxisSize.min,
												children: [
													Text(
														greeting,
														style: TextStyle(
															color: Colors.white.withValues(alpha: 0.78),
															fontSize: AppColors.fontSizeXs,
															fontWeight: AppColors.fontWeightSemiBold,
															letterSpacing: 0.4,
														),
													),
													const SizedBox(height: 2),
													Text(
														displayName,
														maxLines: 1,
														overflow: TextOverflow.ellipsis,
														style: const TextStyle(
															color: Colors.white,
															fontSize: AppColors.fontSizeXl,
															fontWeight: AppColors.fontWeightExtraBold,
															letterSpacing: -0.4,
															height: 1.15,
														),
													),
												],
											),
										),
										if (total > 0)
											Container(
												padding: const EdgeInsets.symmetric(
													horizontal: AppColors.space12,
													vertical: 6,
												),
												decoration: BoxDecoration(
													color: AppColors.orangeAction,
													borderRadius: BorderRadius.circular(AppColors.radiusRound),
													boxShadow: [
														BoxShadow(
															color: AppColors.orangeAction.withValues(alpha: 0.45),
															blurRadius: 10,
															offset: const Offset(0, 3),
														),
													],
												),
												child: Row(
													mainAxisSize: MainAxisSize.min,
													children: [
														Container(
															width: 6,
															height: 6,
															decoration: const BoxDecoration(
																color: Colors.white,
																shape: BoxShape.circle,
															),
														),
														const SizedBox(width: 6),
														Text(
															'$total',
															style: const TextStyle(
																color: Colors.white,
																fontSize: AppColors.fontSizeSm,
																fontWeight: AppColors.fontWeightExtraBold,
																letterSpacing: 0.2,
															),
														),
													],
												),
											),
									],
								),
								const SizedBox(height: AppColors.space20),
								// Pills grandes de pendientes
								Row(
									children: [
										Expanded(
											child: _AdminStatPill(
												icon: Icons.assignment_outlined,
												label: 'Solicitudes',
												count: pendingCampaigns,
											),
										),
										const SizedBox(width: AppColors.space8),
										Expanded(
											child: _AdminStatPill(
												icon: Icons.receipt_long_outlined,
												label: 'Donaciones',
												count: pendingDonations,
											),
										),
										const SizedBox(width: AppColors.space8),
										Expanded(
											child: _AdminStatPill(
												icon: Icons.approval_outlined,
												label: 'Organizaciones',
												count: pendingOrganizations,
											),
										),
									],
								),
							],
						),
					),
				],
			),
		);
	}

	String _buildGreeting() {
		final hour = DateTime.now().hour;
		if (hour < 12) return 'BUENOS DÍAS';
		if (hour < 19) return 'BUENAS TARDES';
		return 'BUENAS NOCHES';
	}
}

class _DecorativeBlob extends StatelessWidget {
	const _DecorativeBlob({required this.size, required this.color});

	final double size;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: size,
			height: size,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				color: color,
			),
		);
	}
}

class _AdminAvatar extends StatelessWidget {
	const _AdminAvatar({required this.avatarUrl, required this.displayName});

	final String? avatarUrl;
	final String displayName;

	String get _initials {
		final parts = displayName
				.trim()
				.split(RegExp(r'\s+'))
				.where((p) => p.isNotEmpty)
				.toList();
		if (parts.isEmpty) return 'A';
		if (parts.length == 1) return parts.first.characters.first.toUpperCase();
		return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
	}

	@override
	Widget build(BuildContext context) {
		final hasAvatar = (avatarUrl ?? '').trim().isNotEmpty;
		return Container(
			width: 52,
			height: 52,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				color: Colors.white.withValues(alpha: 0.20),
				border: Border.all(
					color: Colors.white.withValues(alpha: 0.45),
					width: 2,
				),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.18),
						blurRadius: 10,
						offset: const Offset(0, 3),
					),
				],
			),
			child: ClipOval(
				child: hasAvatar
						? Image.network(
								avatarUrl!,
								fit: BoxFit.cover,
								errorBuilder: (_, __, ___) => _initialsFallback(),
								loadingBuilder: (context, child, progress) {
									if (progress == null) return child;
									return _initialsFallback();
								},
							)
						: _initialsFallback(),
			),
		);
	}

	Widget _initialsFallback() {
		return Container(
			alignment: Alignment.center,
			color: Colors.white.withValues(alpha: 0.10),
			child: Text(
				_initials,
				style: const TextStyle(
					color: Colors.white,
					fontSize: AppColors.fontSizeLg,
					fontWeight: AppColors.fontWeightExtraBold,
					letterSpacing: -0.3,
				),
			),
		);
	}
}

class _AdminStatPill extends StatelessWidget {
	const _AdminStatPill({
		required this.icon,
		required this.label,
		required this.count,
	});

	final IconData icon;
	final String label;
	final int count;

	@override
	Widget build(BuildContext context) {
		final hasPending = count > 0;
		return Container(
			padding: const EdgeInsets.symmetric(
				horizontal: AppColors.space12,
				vertical: AppColors.space12,
			),
			decoration: BoxDecoration(
				color: Colors.white.withValues(alpha: hasPending ? 0.18 : 0.10),
				borderRadius: BorderRadius.circular(AppColors.radiusMd),
				border: Border.all(
					color: Colors.white.withValues(alpha: hasPending ? 0.38 : 0.20),
					width: 1,
				),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisSize: MainAxisSize.min,
				children: [
					Row(
						children: [
							Icon(
								icon,
								color: Colors.white.withValues(alpha: 0.85),
								size: 14,
							),
							const Spacer(),
							if (hasPending)
								Container(
									width: 8,
									height: 8,
									decoration: const BoxDecoration(
										color: AppColors.orangeAction,
										shape: BoxShape.circle,
									),
								),
						],
					),
					const SizedBox(height: AppColors.space8),
					Text(
						'$count',
						style: const TextStyle(
							color: Colors.white,
							fontSize: AppColors.fontSizeXl,
							fontWeight: AppColors.fontWeightExtraBold,
							letterSpacing: -0.4,
							height: 1.1,
						),
					),
					const SizedBox(height: 2),
					Text(
						label,
						maxLines: 1,
						overflow: TextOverflow.ellipsis,
						style: TextStyle(
							color: Colors.white.withValues(alpha: 0.78),
							fontSize: AppColors.fontSizeXs,
							fontWeight: AppColors.fontWeightSemiBold,
							letterSpacing: 0.2,
						),
					),
				],
			),
		);
	}
}

class AdminErrorState extends StatelessWidget {
	const AdminErrorState({super.key, required this.message, required this.onRetry});

	final String message;
	final Future<void> Function() onRetry;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 24),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						const Icon(Icons.error_outline, size: 48, color: AppColors.orangeAction),
						const SizedBox(height: 16),
						Text(
							message,
							textAlign: TextAlign.center,
							style: theme.textTheme.bodyLarge,
						),
						const SizedBox(height: 16),
						FilledButton.icon(
							onPressed: () => onRetry(),
							icon: const Icon(Icons.refresh),
							label: const Text('Intentar de nuevo'),
						),
					],
				),
			),
		);
	}
}

class AdminInfoBadge extends StatelessWidget {
	const AdminInfoBadge({
		super.key,
		required this.icon,
		required this.label,
		required this.value,
	});

	final IconData icon;
	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: AppColors.lightBackground,
				borderRadius: BorderRadius.circular(14),
				border: Border.all(color: AppColors.grayNeutral.withValues(alpha: 0.4)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				mainAxisAlignment: MainAxisAlignment.center,
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, size: 18, color: AppColors.bluePrimary),
					const SizedBox(width: 8),
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								label,
								style: theme.textTheme.labelSmall?.copyWith(
											color: AppColors.darkText.withValues(alpha: 0.7),
											letterSpacing: 0.1,
										),
							),
							const SizedBox(height: 2),
							Text(
								value,
								style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
							),
						],
					),
				],
			),
		);
	}
}

	String formatAdminDateTime(DateTime date) {
		final local = date.toLocal();
		final day = local.day.toString().padLeft(2, '0');
		final month = local.month.toString().padLeft(2, '0');
		final year = local.year;
		final hour = local.hour.toString().padLeft(2, '0');
		final minute = local.minute.toString().padLeft(2, '0');
		return '$day/$month/$year · $hour:$minute';
	}

	String formatAdminDate(DateTime date) {
		final local = date.toLocal();
		final day = local.day.toString().padLeft(2, '0');
		final month = local.month.toString().padLeft(2, '0');
		final year = local.year;
		return '$day/$month/$year';
	}
