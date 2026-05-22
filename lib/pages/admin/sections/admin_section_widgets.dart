import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';

enum AdminDashboardSection { metrics, campaignRequests, donations }

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

		return Container(
			decoration: BoxDecoration(
				gradient: const LinearGradient(
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
					colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
				),
				borderRadius: BorderRadius.circular(20),
				boxShadow: [
					BoxShadow(
						color: AppColors.bluePrimary.withValues(alpha: 0.35),
						blurRadius: 16,
						offset: const Offset(0, 6),
					),
				],
			),
			child: ClipRRect(
				borderRadius: BorderRadius.circular(20),
				child: Stack(
				children: [
					// Círculo decorativo
					Positioned(
						top: -20,
						right: -20,
						child: Container(
							width: 110,
							height: 110,
							decoration: BoxDecoration(
								shape: BoxShape.circle,
								color: Colors.white.withValues(alpha: 0.08),
							),
						),
					),
					Padding(
						padding: const EdgeInsets.all(20),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								// Saludo
								Row(
									crossAxisAlignment: CrossAxisAlignment.center,
									children: [
										Container(
											padding: const EdgeInsets.all(7),
											decoration: BoxDecoration(
												color: Colors.white.withValues(alpha: 0.18),
												borderRadius: BorderRadius.circular(10),
											),
											child: const Icon(Icons.admin_panel_settings_rounded,
													color: Colors.white, size: 20),
										),
										const SizedBox(width: 12),
										Expanded(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(
														greeting,
														style: TextStyle(
															color: Colors.white.withValues(alpha: 0.80),
															fontSize: 12,
														),
													),
													Text(
														displayName,
														maxLines: 1,
														overflow: TextOverflow.ellipsis,
														style: const TextStyle(
															color: Colors.white,
															fontSize: 17,
															fontWeight: FontWeight.w800,
															letterSpacing: -0.3,
														),
													),
													if (total > 0) ...[
														const SizedBox(height: 4),
														Container(
															padding: const EdgeInsets.symmetric(
																	horizontal: 8, vertical: 3),
															decoration: BoxDecoration(
																color: AppColors.orangeAction,
																borderRadius: BorderRadius.circular(999),
															),
															child: Text(
																'$total pendientes',
																style: const TextStyle(
																	color: Colors.white,
																	fontSize: 11,
																	fontWeight: FontWeight.w700,
																),
															),
														),
													],
												],
											),
										),
									],
								),
								const SizedBox(height: 16),
								// Mini chips de pendientes
								Row(
									children: [
										Expanded(child: _PendingChip(
											icon: Icons.assignment_outlined,
											label: 'Solicitudes',
											count: pendingCampaigns,
										)),
										const SizedBox(width: 6),
										Expanded(child: _PendingChip(
											icon: Icons.receipt_long_outlined,
											label: 'Donaciones',
											count: pendingDonations,
										)),
										const SizedBox(width: 6),
										Expanded(child: _PendingChip(
											icon: Icons.approval_outlined,
											label: 'Orgs',
											count: pendingOrganizations,
										)),
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

	String _buildGreeting() {
		final hour = DateTime.now().hour;
		if (hour < 12) return 'Buenos días';
		if (hour < 19) return 'Buenas tardes';
		return 'Buenas noches';
	}
}

class _PendingChip extends StatelessWidget {
	const _PendingChip({
		required this.icon,
		required this.label,
		required this.count,
	});

	final IconData icon;
	final String label;
	final int count;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
			decoration: BoxDecoration(
				color: Colors.white.withValues(alpha: 0.15),
				borderRadius: BorderRadius.circular(999),
			),
			child: Row(
				mainAxisSize: MainAxisSize.max,
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(icon, color: Colors.white, size: 12),
					const SizedBox(width: 4),
					Flexible(
						child: Text(
							'$label: $count',
							overflow: TextOverflow.ellipsis,
							style: const TextStyle(
								color: Colors.white,
								fontSize: 10,
								fontWeight: FontWeight.w600,
							),
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
