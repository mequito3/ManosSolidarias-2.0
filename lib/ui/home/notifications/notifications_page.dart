import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controllers/notification_controller.dart';
import '../../../models/notification_entry.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/time_formatter.dart';
import '../../../utils/notification_navigation_helper.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.controller});

  final NotificationController controller;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationController get _controller => widget.controller;

  Future<void> _handleRefresh() => _controller.refreshNotifications();

  Future<void> _handleMarkAll() async {
    try {
      await _controller.markAllAsRead();
    } on NotificationActionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _handleMarkAsRead(NotificationEntry entry) async {
    try {
      await _controller.markAsRead(entry.id);
    } on NotificationActionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _openDetail(NotificationEntry entry) async {
    if (entry.isUnread) {
      await _handleMarkAsRead(entry);
    }
    if (!mounted) return;
    await NotificationNavigationHelper.navigateFromNotification(
      context: context,
      notificationType: entry.type,
      payload: entry.payload,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isLoading = _controller.isLoading;
          final hasLoaded = _controller.hasLoaded;
          final notifications = _controller.notifications;
          final error = _controller.errorMessage;
          final unread = _controller.unreadCount;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.lightBackground,
                surfaceTintColor: AppColors.lightBackground,
                scrolledUnderElevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                elevation: 0,
                pinned: true,
                centerTitle: false,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: AppColors.darkText,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: _AppBarTitle(unreadCount: unread),
                actions: [
                  if (unread > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: _controller.isMarkingAll ? null : _handleMarkAll,
                        tooltip: 'Marcar todas como leídas',
                        icon: _controller.isMarkingAll
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.bluePrimary,
                                ),
                              )
                            : const Icon(
                                Icons.done_all_rounded,
                                color: AppColors.bluePrimary,
                              ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.bluePrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: RefreshIndicator(
                  color: AppColors.bluePrimary,
                  onRefresh: _handleRefresh,
                  child: _buildBody(
                    isLoading: isLoading,
                    hasLoaded: hasLoaded,
                    notifications: notifications,
                    error: error,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required bool hasLoaded,
    required List<NotificationEntry> notifications,
    required String? error,
  }) {
    if (isLoading && !hasLoaded) {
      return const _NotificationsSkeleton();
    }

    if (error != null && notifications.isEmpty) {
      return _NotificationsError(message: error, onRetry: _handleRefresh);
    }

    if (notifications.isEmpty) {
      return const _NotificationsEmpty();
    }

    final sections = _groupNotifications(notifications);
    final children = <Widget>[];

    if (error != null) {
      children
        ..add(const SizedBox(height: 8))
        ..add(_InlineError(message: error, onRetry: _handleRefresh));
    }

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      children.add(SizedBox(height: i == 0 ? 8 : 28));
      children.add(_SectionHeader(
        title: section.title,
        count: section.entries.length,
      ));
      children.add(const SizedBox(height: 14));

      for (var j = 0; j < section.entries.length; j++) {
        final entry = section.entries[j];
        children.add(
          _NotificationCard(
            entry: entry,
            onTap: () => _openDetail(entry),
            onMarkAsRead: () => _handleMarkAsRead(entry),
            isProcessing: _controller.isProcessing(entry.id),
          ).animate().fade(duration: 220.ms).slideY(
                begin: 0.06,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
        );
        if (j != section.entries.length - 1) {
          children.add(const SizedBox(height: 12));
        }
      }
    }

    children.add(const SizedBox(height: 40));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.darkText,
          ),
        ),
        if (unreadCount > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.bluePrimary, AppColors.blueSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bluePrimary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.bluePrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '· $count',
            style: TextStyle(
              color: AppColors.darkText.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.entry,
    required this.onTap,
    required this.onMarkAsRead,
    required this.isProcessing,
  });

  final NotificationEntry entry;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final isUnread = entry.isUnread;
    final accent = _resolveColor(entry.type);
    final icon = _resolveIcon(entry.type);
    final ctaLabel = _resolveCta(entry.type);
    final categoryLabel = _categoryLabel(entry.type);

    return Dismissible(
      key: Key(entry.id),
      direction: isUnread ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: isUnread
          ? (_) async {
              onMarkAsRead();
              return false;
            }
          : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.greenSuccess,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isUnread
                        ? [
                            Colors.white,
                            accent.withValues(alpha: 0.10),
                          ]
                        : [Colors.white, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isUnread
                        ? accent.withValues(alpha: 0.28)
                        : AppColors.dividerColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUnread ? accent : Colors.black)
                          .withValues(alpha: isUnread ? 0.10 : 0.04),
                      blurRadius: isUnread ? 20 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CategoryChip(
                          label: categoryLabel,
                          icon: icon,
                          accent: accent,
                        ),
                        const Spacer(),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      entry.message,
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.darkText.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatRelativeTime(entry.createdAt),
                          style: TextStyle(
                            color: AppColors.darkText.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (isProcessing)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: accent,
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ctaLabel,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: accent,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Positioned(
                  left: 0,
                  top: 18,
                  bottom: 18,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _skeletonHeader(),
          const SizedBox(height: 14),
          for (var i = 0; i < 5; i++) ...[
            _skeletonCard(),
            if (i != 4) const SizedBox(height: 12),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _skeletonHeader() {
    return Shimmer.fromColors(
      baseColor: AppColors.dividerColor.withValues(alpha: 0.35),
      highlightColor: Colors.white,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.dividerColor.withValues(alpha: 0.35),
      highlightColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 110,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 70,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 90,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.bluePrimary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.bluePrimary.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluePrimary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bluePrimary,
                    AppColors.blueSecondary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bluePrimary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todo al día',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando recibas donaciones, comentarios o aprobaciones aparecerán aquí.',
              style: TextStyle(
                color: AppColors.darkText.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.orangeAction.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.orangeAction.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.orangeAction,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar tus notificaciones',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: AppColors.darkText.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.orangeAction.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.orangeAction, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.orangeAction,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.orangeAction,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

List<_NotificationSection> _groupNotifications(List<NotificationEntry> entries) {
  final now = DateTime.now();
  final today = <NotificationEntry>[];
  final yesterday = <NotificationEntry>[];
  final thisWeek = <NotificationEntry>[];
  final older = <NotificationEntry>[];

  for (final entry in entries) {
    final created = entry.createdAt.toLocal();
    final difference = now.difference(created).inDays;

    if (difference <= 0) {
      today.add(entry);
    } else if (difference == 1) {
      yesterday.add(entry);
    } else if (difference < 7) {
      thisWeek.add(entry);
    } else {
      older.add(entry);
    }
  }

  final sections = <_NotificationSection>[];
  if (today.isNotEmpty) {
    sections.add(_NotificationSection(title: 'Hoy', entries: today));
  }
  if (yesterday.isNotEmpty) {
    sections.add(_NotificationSection(title: 'Ayer', entries: yesterday));
  }
  if (thisWeek.isNotEmpty) {
    sections.add(_NotificationSection(title: 'Esta semana', entries: thisWeek));
  }
  if (older.isNotEmpty) {
    sections.add(_NotificationSection(title: 'Anteriores', entries: older));
  }

  return sections;
}

class _NotificationSection {
  const _NotificationSection({required this.title, required this.entries});

  final String title;
  final List<NotificationEntry> entries;
}

String _categoryLabel(String type) {
  final n = type.toLowerCase();
  if (n.startsWith('donacion')) return 'DONACIÓN';
  if (n == 'nuevo_comentario') return 'COMENTARIO';
  if (n == 'nuevo_favorito') return 'FAVORITO';
  if (n.startsWith('seguimiento')) return 'SEGUIMIENTO';
  if (n == 'campania_25' ||
      n == 'campania_50' ||
      n == 'campania_75' ||
      n == 'campania_100' ||
      n.startsWith('hito') ||
      n == 'meta_alcanzada') {
    return 'HITO';
  }
  if (n.startsWith('ranking')) return 'RANKING';
  if (n.startsWith('solicitud')) return 'SOLICITUD';
  if (n.startsWith('organizacion')) return 'ORGANIZACIÓN';
  if (n.startsWith('campania')) return 'CAMPAÑA';
  return 'AVISO';
}

String _resolveCta(String type) {
  final n = type.toLowerCase();
  if (n == 'nuevo_comentario') return 'Responder';
  if (n.startsWith('organizacion')) return 'Ver organización';
  if (n.startsWith('ranking')) return 'Ver ranking';
  if (n.startsWith('donacion') ||
      n.startsWith('solicitud') ||
      n.startsWith('campania') ||
      n.startsWith('hito') ||
      n.startsWith('seguimiento') ||
      n == 'meta_alcanzada' ||
      n == 'nuevo_favorito') {
    return 'Ver campaña';
  }
  return 'Ver detalle';
}

IconData _resolveIcon(String type) {
  final normalized = type.toLowerCase();
  if (normalized == 'donacion_aprobada') return Icons.paid_outlined;
  if (normalized == 'donacion_confirmada') return Icons.check_circle_outline;
  if (normalized == 'donacion_rechazada') return Icons.cancel_outlined;
  if (normalized == 'nuevo_comentario') return Icons.chat_bubble_outline;
  if (normalized == 'nuevo_favorito') return Icons.favorite_outline;
  if (normalized == 'seguimiento_campania') return Icons.campaign_outlined;
  if (normalized == 'seguimiento_meta_completa') return Icons.celebration_outlined;
  if (normalized == 'seguimiento_finalizando') return Icons.alarm_outlined;
  if (normalized == 'hito_25' || normalized == 'hito_50') return Icons.trending_up;
  if (normalized == 'hito_75') return Icons.rocket_launch_outlined;
  if (normalized == 'meta_alcanzada') return Icons.emoji_events_outlined;
  if (normalized == 'ranking_top_1') return Icons.workspace_premium;
  if (normalized == 'ranking_top_2') return Icons.military_tech;
  if (normalized == 'ranking_top_3') return Icons.stars;
  if (normalized.startsWith('ranking')) return Icons.leaderboard;
  if (normalized == 'solicitud_aprobada') return Icons.check_circle_outline;
  if (normalized == 'solicitud_rechazada') return Icons.info_outline;
  if (normalized == 'organizacion_aprobada') return Icons.verified_outlined;
  if (normalized == 'organizacion_rechazada') return Icons.report_problem_outlined;
  if (normalized == 'campania_25') return Icons.trending_up;
  if (normalized == 'campania_50') return Icons.rocket_launch_outlined;
  if (normalized == 'campania_75') return Icons.rocket_launch_outlined;
  if (normalized == 'campania_100') return Icons.emoji_events_outlined;
  if (normalized == 'campania_publicada') return Icons.campaign_outlined;
  if (normalized == 'campania_finalizando') return Icons.access_time;
  if (normalized.startsWith('campania')) return Icons.flag_outlined;
  if (normalized.startsWith('donacion')) return Icons.volunteer_activism_outlined;
  if (normalized.startsWith('solicitud')) return Icons.assignment_turned_in_outlined;
  if (normalized.startsWith('organizacion')) return Icons.approval_outlined;
  if (normalized.contains('perfil')) return Icons.verified_user_outlined;
  return Icons.notifications_active_outlined;
}

Color _resolveColor(String type) {
  final normalized = type.toLowerCase();
  if (normalized == 'donacion_aprobada') return AppColors.greenSuccess;
  if (normalized == 'donacion_confirmada') return AppColors.greenSuccess;
  if (normalized == 'donacion_rechazada') return Colors.red.shade400;
  if (normalized == 'nuevo_comentario') return AppColors.bluePrimary;
  if (normalized == 'nuevo_favorito') return Colors.pink.shade400;
  if (normalized == 'seguimiento_campania') return AppColors.blueSecondary;
  if (normalized == 'seguimiento_meta_completa') return Colors.green.shade600;
  if (normalized == 'seguimiento_finalizando') return Colors.orange.shade600;
  if (normalized == 'hito_25') return AppColors.blueSecondary;
  if (normalized == 'hito_50') return AppColors.orangeAction;
  if (normalized == 'hito_75') return AppColors.greenHope;
  if (normalized == 'meta_alcanzada') return Colors.amber.shade600;
  if (normalized == 'ranking_top_1') return Colors.amber.shade700;
  if (normalized == 'ranking_top_2') return Colors.grey.shade500;
  if (normalized == 'ranking_top_3') return Colors.orange.shade800;
  if (normalized.startsWith('ranking')) return AppColors.bluePrimary;
  if (normalized == 'solicitud_aprobada') return AppColors.greenSuccess;
  if (normalized == 'solicitud_rechazada') return Colors.orange.shade600;
  if (normalized == 'organizacion_aprobada') return AppColors.greenSuccess;
  if (normalized == 'organizacion_rechazada') return Colors.red.shade400;
  if (normalized == 'campania_25') return AppColors.blueSecondary;
  if (normalized == 'campania_50') return AppColors.orangeAction;
  if (normalized == 'campania_75') return AppColors.greenHope;
  if (normalized == 'campania_100') return Colors.amber.shade600;
  if (normalized == 'campania_publicada') return AppColors.greenHope;
  if (normalized == 'campania_finalizando') return AppColors.orangeAction;
  if (normalized.startsWith('campania')) return AppColors.greenHope;
  if (normalized.startsWith('donacion')) return AppColors.orangeAction;
  if (normalized.startsWith('solicitud')) return AppColors.bluePrimary;
  if (normalized.startsWith('organizacion')) return AppColors.blueSecondary;
  if (normalized.contains('perfil')) return AppColors.bluePrimary;
  return AppColors.bluePrimary;
}
