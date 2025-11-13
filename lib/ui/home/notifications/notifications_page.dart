import 'package:flutter/material.dart';

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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _handleMarkAsRead(NotificationEntry entry) async {
    try {
      await _controller.markAsRead(entry.id);
    } on NotificationActionException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _openDetail(NotificationEntry entry) async {
    // Marcar como leída
    if (entry.isUnread) {
      await _handleMarkAsRead(entry);
    }

    if (!mounted) return;

    // 🔔 NAVEGACIÓN CONTEXTUAL: Llevar al usuario al contexto de la notificación
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
      appBar: AppBar(
        title: const Text('Notificaciones'),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isLoading = _controller.isLoading;
          final hasLoaded = _controller.hasLoaded;
          final notifications = _controller.notifications;
          final error = _controller.errorMessage;

          if (isLoading && !hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null && notifications.isEmpty) {
            return _NotificationsError(
              message: error,
              onRetry: _handleRefresh,
            );
          }

          if (notifications.isEmpty) {
            return _NotificationsEmpty(onRefresh: _handleRefresh);
          }

          final sections = _groupNotifications(notifications);

          final children = <Widget>[
            _NotificationsHeroBanner(
              unreadCount: _controller.unreadCount,
              totalCount: notifications.length,
              isProcessingMarkAll: _controller.isMarkingAll,
              onMarkAll: _controller.unreadCount > 0 ? _handleMarkAll : null,
            ),
          ];

          if (error != null) {
            children
              ..add(const SizedBox(height: 16))
              ..add(_InlineError(message: error, onRetry: _handleRefresh));
          }

          for (var i = 0; i < sections.length; i++) {
            final section = sections[i];
            children.add(SizedBox(height: i == 0 ? 24 : 32));
            children.add(_NotificationsSectionHeader(title: section.title));
            children.add(const SizedBox(height: 12));

            for (var j = 0; j < section.entries.length; j++) {
              final entry = section.entries[j];
              children.add(
                _NotificationTile(
                  entry: entry,
                  onTap: () => _openDetail(entry),
                  onMarkAsRead: () => _handleMarkAsRead(entry),
                  isProcessing: _controller.isProcessing(entry.id),
                ),
              );

              if (j != section.entries.length - 1) {
                children.add(const SizedBox(height: 16));
              }
            }
          }

          children.add(const SizedBox(height: 32));

          return RefreshIndicator(
            color: AppColors.bluePrimary,
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: children,
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTypeChip extends StatelessWidget {
  const _NotificationTypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _PayloadPill extends StatelessWidget {
  const _PayloadPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.bluePrimary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.bluePrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPayloadLabel(String key) {
  final labelMap = {
    'monto': '💰 Monto donado',
    'titulo': '📢 Campaña',
    'descripcion': '📝 Descripción',
    'estado': '✓ Estado',
    'donante': '👤 Donante',
    'email_donante': '📧 Email del donante',
    'creador': '👤 Organizador',
    'metodo_pago': '💳 Método de pago',
    'fecha_donacion': '� Fecha de donación',
    'fecha_aprobacion': '✅ Fecha de aprobación',
    'fecha_rechazo': '❌ Fecha de rechazo',
    'recompensa': '🎁 Recompensa',
    'mensaje_donante': '💬 Mensaje del donante',
    'tu_mensaje': '💬 Tu mensaje',
    'motivo': '⚠️ Motivo',
    
    // Interacciones
    'comentario': '💬 Comentario',
    'autor': '👤 Autor',
    'usuario': '👤 Usuario',
    'total_favoritos': '⭐ Total favoritos',
    
    // Hitos y progreso
    'porcentaje': '📊 Progreso',
    'monto_actual': '💵 Recaudado',
    'monto_objetivo': '🎯 Meta',
    'monto_final': '💰 Monto final',
    'dias_restantes': '⏰ Días restantes',
    'fecha_fin': '📅 Finaliza',
    'fecha_publicacion': '📅 Publicada',
    
    // Ranking
    'ranking': '🏆 Posición',
    
    // Organizaciones
    'organizacion': '🏢 Organización',
    
    // Genéricos
    'nombre': '👤 Nombre',
    'fecha': '📅 Fecha',
    'cantidad': '🔢 Cantidad',
    'tipo': '🏷️ Tipo',
    'mensaje': '💬 Mensaje',
    'nivel': '⭐ Nivel',
    'puntos': '🎯 Puntos',
  };
  return labelMap[key.toLowerCase()] ?? key;
}

String? _formatPayloadValue(dynamic value, String key) {
  if (value == null) {
    return null;
  }
  
  // Formatear monto como moneda
  if ((key.toLowerCase().contains('monto') || key.toLowerCase() == 'monto_final') && value is num) {
    return 'Bs ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }
  
  // Formatear porcentaje
  if (key.toLowerCase() == 'porcentaje' && value is num) {
    return '${value.toInt()}%';
  }
  
  // Formatear ranking
  if (key.toLowerCase() == 'ranking' && value is num) {
    final rank = value.toInt();
    if (rank == 1) return '🥇 #1';
    if (rank == 2) return '🥈 #2';
    if (rank == 3) return '🥉 #3';
    return '#$rank';
  }
  
  // Formatear estado con emoji
  if (key.toLowerCase() == 'estado' && value is String) {
    final estadoMap = {
      'aprobada': '✅ Aprobada',
      'rechazada': '❌ Rechazada',
      'pendiente': '⏳ Pendiente',
      'publicada': '📢 Publicada',
    };
    return estadoMap[value.toLowerCase()] ?? value;
  }
  
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length > 35) {
      return '${trimmed.substring(0, 32)}…';
    }
    return trimmed;
  }
  
  if (value is num) {
    return value.toString();
  }
  
  if (value is bool) {
    return value ? '✓ Sí' : '✗ No';
  }
  
  return value.toString();
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

class _NotificationsSectionHeader extends StatelessWidget {
  const _NotificationsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: AppColors.darkText,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _NotificationsHeroBanner extends StatelessWidget {
  const _NotificationsHeroBanner({
    required this.unreadCount,
    required this.totalCount,
    required this.isProcessingMarkAll,
    this.onMarkAll,
  });

  final int unreadCount;
  final int totalCount;
  final bool isProcessingMarkAll;
  final Future<void> Function()? onMarkAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = unreadCount > 0;
    final title = hasUnread
        ? '$unreadCount ${unreadCount == 1 ? 'nueva' : 'nuevas'}'
        : 'Todo al día';
    final subtitle = hasUnread
        ? 'Tienes notificaciones sin revisar'
        : 'No hay notificaciones nuevas';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUnread 
            ? AppColors.bluePrimary.withValues(alpha: 0.2)
            : AppColors.grayNeutral.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hasUnread 
                ? AppColors.bluePrimary.withValues(alpha: 0.12)
                : AppColors.grayNeutral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasUnread ? Icons.notifications_active : Icons.notifications_none,
              color: hasUnread ? AppColors.bluePrimary : AppColors.grayNeutral,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkText.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (hasUnread && onMarkAll != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: isProcessingMarkAll ? null : onMarkAll,
              icon: isProcessingMarkAll
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bluePrimary,
                      ),
                    )
                  : Icon(
                      Icons.done_all_rounded,
                      color: AppColors.bluePrimary,
                    ),
              tooltip: 'Marcar todo como leído',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
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
    final theme = Theme.of(context);
    final isUnread = entry.isUnread;
    final iconData = _resolveIcon(entry.type);
    final accentColor = _resolveColor(entry.type);

    // Solo mostrar información relevante, excluir IDs técnicos
    final payloadPills = <Widget>[];
    final excludedKeys = {
      'id', 
      'donacion_id', 
      'campania_id', 
      'user_id', 
      'donante_id',
      'creador_id',
      'recompensa_id',
      'created_at',
      'updated_at',
    };
    
    for (final entryData in entry.payload.entries) {
      if (payloadPills.length >= 2) {
        break;
      }
      
      // Saltar campos técnicos
      if (excludedKeys.contains(entryData.key)) {
        continue;
      }
      
      final value = _formatPayloadValue(entryData.value, entryData.key);
      if (value == null) {
        continue;
      }
      
      payloadPills.add(
        _PayloadPill(
          label: _formatPayloadLabel(entryData.key),
          value: value,
        ),
      );
    }

    return Dismissible(
      key: Key(entry.id),
      direction: isUnread ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: isUnread ? (_) async {
        onMarkAsRead();
        return false; // No eliminamos el widget, solo marcamos como leído
      } : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.greenSuccess,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnread 
                ? accentColor.withValues(alpha: 0.04)
                : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? accentColor.withValues(alpha: 0.15)
                    : AppColors.grayNeutral.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.typeLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Text(
                            formatRelativeTime(entry.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.darkText.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkText,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (payloadPills.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: payloadPills,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({required this.entry});

  final NotificationEntry entry;

  List<Widget> _buildDetailItems(BuildContext context, Map<String, dynamic> payload) {
    final theme = Theme.of(context);
    final items = <Widget>[];
    
    // IDs técnicos que NO queremos mostrar
    final excludedKeys = {
      'id', 
      'donacion_id', 
      'campania_id', 
      'user_id', 
      'donante_id',
      'creador_id',
      'recompensa_id',
      'organizacion_id',
      'solicitud_id',
      'created_at',
      'updated_at',
    };
    
    // Ordenar los campos importantes primero
    final priorityOrder = [
      'titulo',
      'ranking',
      'porcentaje',
      'monto',
      'monto_actual',
      'monto_objetivo',
      'monto_final',
      'estado',
      'donante',
      'creador',
      'usuario',
      'autor',
      'total_favoritos',
      'recompensa',
      'metodo_pago',
      'dias_restantes',
      'fecha_donacion',
      'fecha_aprobacion',
      'fecha_rechazo',
      'fecha_fin',
      'fecha_publicacion',
      'fecha',
      'descripcion',
      'comentario',
      'mensaje_donante',
      'tu_mensaje',
      'email_donante',
      'organizacion',
      'motivo',
    ];
    final sortedEntries = payload.entries.toList()
      ..sort((a, b) {
        final aIndex = priorityOrder.indexOf(a.key);
        final bIndex = priorityOrder.indexOf(b.key);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        return a.key.compareTo(b.key);
      });
    
    for (final data in sortedEntries) {
      // Saltar campos técnicos
      if (excludedKeys.contains(data.key)) {
        continue;
      }
      
      final formattedValue = _formatPayloadValue(data.value, data.key);
      if (formattedValue == null || formattedValue.trim().isEmpty) {
        continue;
      }
      
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grayNeutral.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatPayloadLabel(data.key),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.bluePrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                formattedValue,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final accentColor = _resolveColor(entry.type);
    final iconData = _resolveIcon(entry.type);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accentColor.withValues(alpha: 0.18),
                    foregroundColor: accentColor,
                    radius: 24,
                    child: Icon(iconData),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.typeLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatFullDateTime(entry.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                entry.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkText,
                  height: 1.4,
                ),
              ),
              if (entry.payload.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Detalles',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                ..._buildDetailItems(context, entry.payload),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      color: AppColors.bluePrimary,
      onRefresh: onRefresh,
      child: ListView(
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
                const Icon(Icons.notifications_none, color: AppColors.bluePrimary, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Sin notificaciones por ahora',
                  style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando aprueben tus campañas, validen evidencias o recibas nuevas interacciones aparecerán aquí.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkText.withValues(alpha: 0.72),
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

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              const Icon(Icons.error_outline, color: AppColors.orangeAction, size: 40),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tus notificaciones',
                style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkText.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeAction.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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

IconData _resolveIcon(String type) {
  final normalized = type.toLowerCase();
  
  // Donaciones
  if (normalized == 'donacion_aprobada') return Icons.paid_outlined;
  if (normalized == 'donacion_confirmada') return Icons.check_circle_outline;
  if (normalized == 'donacion_rechazada') return Icons.cancel_outlined;
  
  // Interacciones sociales
  if (normalized == 'nuevo_comentario') return Icons.chat_bubble_outline;
  if (normalized == 'nuevo_favorito') return Icons.favorite_outline;
  
  // Seguimiento de favoritos
  if (normalized == 'seguimiento_campania') return Icons.campaign_outlined;
  if (normalized == 'seguimiento_meta_completa') return Icons.celebration_outlined;
  if (normalized == 'seguimiento_finalizando') return Icons.alarm_outlined;
  
  // Hitos de campaña
  if (normalized == 'hito_25' || normalized == 'hito_50') return Icons.trending_up;
  if (normalized == 'hito_75') return Icons.rocket_launch_outlined;
  if (normalized == 'meta_alcanzada') return Icons.emoji_events_outlined;
  
  // Ranking
  if (normalized == 'ranking_top_1') return Icons.workspace_premium;
  if (normalized == 'ranking_top_2') return Icons.military_tech;
  if (normalized == 'ranking_top_3') return Icons.stars;
  if (normalized.startsWith('ranking')) return Icons.leaderboard;
  
  // Solicitudes y organizaciones
  if (normalized == 'solicitud_aprobada') return Icons.check_circle_outline;
  if (normalized == 'solicitud_rechazada') return Icons.info_outline;
  if (normalized == 'organizacion_aprobada') return Icons.verified_outlined;
  if (normalized == 'organizacion_rechazada') return Icons.report_problem_outlined;
  
  // Campañas
  if (normalized == 'campania_publicada') return Icons.campaign_outlined;
  if (normalized == 'campania_finalizando') return Icons.access_time;
  
  // Genéricos
  if (normalized.startsWith('campania')) return Icons.flag_outlined;
  if (normalized.startsWith('donacion')) return Icons.volunteer_activism_outlined;
  if (normalized.startsWith('solicitud')) return Icons.assignment_turned_in_outlined;
  if (normalized.startsWith('organizacion')) return Icons.approval_outlined;
  if (normalized.contains('perfil')) return Icons.verified_user_outlined;
  
  return Icons.notifications_active_outlined;
}

Color _resolveColor(String type) {
  final normalized = type.toLowerCase();
  
  // Donaciones
  if (normalized == 'donacion_aprobada') return AppColors.greenSuccess;
  if (normalized == 'donacion_confirmada') return AppColors.greenSuccess;
  if (normalized == 'donacion_rechazada') return Colors.red.shade400;
  
  // Interacciones sociales
  if (normalized == 'nuevo_comentario') return AppColors.bluePrimary;
  if (normalized == 'nuevo_favorito') return Colors.pink.shade400;
  
  // Seguimiento de favoritos
  if (normalized == 'seguimiento_campania') return AppColors.blueSecondary;
  if (normalized == 'seguimiento_meta_completa') return Colors.green.shade600;
  if (normalized == 'seguimiento_finalizando') return Colors.orange.shade600;
  
  // Hitos de campaña
  if (normalized == 'hito_25') return AppColors.blueSecondary;
  if (normalized == 'hito_50') return AppColors.orangeAction;
  if (normalized == 'hito_75') return AppColors.greenHope;
  if (normalized == 'meta_alcanzada') return Colors.amber.shade600;
  
  // Ranking
  if (normalized == 'ranking_top_1') return Colors.amber.shade700;
  if (normalized == 'ranking_top_2') return Colors.grey.shade500;
  if (normalized == 'ranking_top_3') return Colors.orange.shade800;
  if (normalized.startsWith('ranking')) return AppColors.bluePrimary;
  
  // Solicitudes y organizaciones
  if (normalized == 'solicitud_aprobada') return AppColors.greenSuccess;
  if (normalized == 'solicitud_rechazada') return Colors.orange.shade600;
  if (normalized == 'organizacion_aprobada') return AppColors.greenSuccess;
  if (normalized == 'organizacion_rechazada') return Colors.red.shade400;
  
  // Campañas
  if (normalized == 'campania_publicada') return AppColors.greenHope;
  if (normalized == 'campania_finalizando') return AppColors.orangeAction;
  
  // Genéricos
  if (normalized.startsWith('campania')) return AppColors.greenHope;
  if (normalized.startsWith('donacion')) return AppColors.orangeAction;
  if (normalized.startsWith('solicitud')) return AppColors.bluePrimary;
  if (normalized.startsWith('organizacion')) return AppColors.blueSecondary;
  if (normalized.contains('perfil')) return AppColors.bluePrimary;
  
  return AppColors.bluePrimary;
}
