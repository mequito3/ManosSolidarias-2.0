String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.isNegative) {
    final minutes = difference.inMinutes.abs();
    if (minutes <= 1) {
      return 'En instantes';
    }
    if (minutes < 60) {
      return 'En $minutes minutos';
    }
    final hours = difference.inHours.abs();
    if (hours < 24) {
      return 'En $hours horas';
    }
    final days = difference.inDays.abs();
    return days == 1 ? 'Mañana' : 'En $days días';
  }

  if (difference.inMinutes <= 1) {
    return 'Hace un momento';
  }
  if (difference.inMinutes < 60) {
    return 'Hace ${difference.inMinutes} minutos';
  }
  if (difference.inHours < 24) {
    return 'Hace ${difference.inHours} horas';
  }
  if (difference.inDays == 1) {
    return 'Ayer';
  }
  if (difference.inDays < 7) {
    return 'Hace ${difference.inDays} días';
  }

  return formatFullDateTime(date);
}

String formatFullDateTime(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = _monthNames[local.month - 1];
  final year = local.year;
  final hours = local.hour.toString().padLeft(2, '0');
  final minutes = local.minute.toString().padLeft(2, '0');
  return '$day $month $year · $hours:$minutes';
}

const List<String> _monthNames = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
