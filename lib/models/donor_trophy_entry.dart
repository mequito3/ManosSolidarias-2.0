class DonorTrophyEntry {
  const DonorTrophyEntry({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.totalDonated,
    required this.donationsCount,
    required this.position,
    required this.level,
  });

  factory DonorTrophyEntry.fromJson(Map<String, dynamic> json) {
    return DonorTrophyEntry(
      userId: (json['user_id'] ?? '').toString(),
      displayName: _readString(json['display_name']) ?? 'Donante solidario',
      avatarUrl: _readString(json['avatar_url']),
      totalDonated: _readDouble(json['total_donated']),
      donationsCount: _readInt(json['donations_count']) ?? 0,
      position: _readInt(json['position']) ?? 0,
      level: TrophyLevelX.fromDatabase(json['trophy_level'] as String?),
    );
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double totalDonated;
  final int donationsCount;
  final int position;
  final TrophyLevel level;

  bool get isTopThree => position >= 1 && position <= 3;
}

class DonorTrophyProfile {
  const DonorTrophyProfile({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.totalDonated,
    required this.donationsCount,
    required this.position,
    required this.level,
    required this.currentLevelMinAmount,
    this.nextLevelAmount,
    this.nextLevelLevel,
  });

  factory DonorTrophyProfile.fromJson(Map<String, dynamic> json) {
    return DonorTrophyProfile(
      userId: (json['user_id'] ?? '').toString(),
      displayName: _readString(json['display_name']) ?? 'Donante solidario',
      avatarUrl: _readString(json['avatar_url']),
      totalDonated: _readDouble(json['total_donated']),
      donationsCount: _readInt(json['donations_count']) ?? 0,
      position: _readInt(json['position']),
      level: TrophyLevelX.fromDatabase(json['trophy_level'] as String?),
      currentLevelMinAmount: _readDouble(json['current_level_min_amount']),
      nextLevelAmount: _readDoubleOrNull(json['next_level_amount']),
      nextLevelLevel: TrophyLevelX.tryFromDatabase(json['next_level_level'] as String?),
    );
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double totalDonated;
  final int donationsCount;
  final int? position;
  final TrophyLevel level;
  final double currentLevelMinAmount;
  final double? nextLevelAmount;
  final TrophyLevel? nextLevelLevel;

  bool get hasRanking => position != null && position! > 0;
}

enum TrophyLevel {
  top1,
  top2,
  top3,
  legend,
  champion,
  hero,
  ally,
  supporter,
  friend,
  starter,
}

extension TrophyLevelX on TrophyLevel {
  static const Map<String, TrophyLevel> _map = {
    'top_1': TrophyLevel.top1,
    'top_2': TrophyLevel.top2,
    'top_3': TrophyLevel.top3,
    'legend': TrophyLevel.legend,
    'champion': TrophyLevel.champion,
    'hero': TrophyLevel.hero,
    'ally': TrophyLevel.ally,
    'supporter': TrophyLevel.supporter,
    'friend': TrophyLevel.friend,
    'starter': TrophyLevel.starter,
  };

  static TrophyLevel fromDatabase(String? raw) {
    return _map[raw] ?? TrophyLevel.starter;
  }

  static TrophyLevel? tryFromDatabase(String? raw) {
    if (raw == null) {
      return null;
    }
    return _map[raw];
  }

  String get label {
    switch (this) {
      case TrophyLevel.top1:
        return 'Primer lugar';
      case TrophyLevel.top2:
        return 'Segundo lugar';
      case TrophyLevel.top3:
        return 'Tercer lugar';
      case TrophyLevel.legend:
        return 'Leyenda solidaria';
      case TrophyLevel.champion:
        return 'Campeón solidario';
      case TrophyLevel.hero:
        return 'Héroe solidario';
      case TrophyLevel.ally:
        return 'Aliado solidario';
      case TrophyLevel.supporter:
        return 'Acompañante solidario';
      case TrophyLevel.friend:
        return 'Amigo solidario';
      case TrophyLevel.starter:
        return 'Nuevo donante';
    }
  }

  String get badgeAsset {
    switch (this) {
      case TrophyLevel.top1:
        return 'gold';
      case TrophyLevel.top2:
        return 'silver';
      case TrophyLevel.top3:
        return 'bronze';
      case TrophyLevel.legend:
        return 'legend';
      case TrophyLevel.champion:
        return 'champion';
      case TrophyLevel.hero:
        return 'hero';
      case TrophyLevel.ally:
        return 'ally';
      case TrophyLevel.supporter:
        return 'supporter';
      case TrophyLevel.friend:
        return 'friend';
      case TrophyLevel.starter:
        return 'starter';
    }
  }

  int get priority {
    switch (this) {
      case TrophyLevel.top1:
        return 0;
      case TrophyLevel.top2:
        return 1;
      case TrophyLevel.top3:
        return 2;
      case TrophyLevel.legend:
        return 3;
      case TrophyLevel.champion:
        return 4;
      case TrophyLevel.hero:
        return 5;
      case TrophyLevel.ally:
        return 6;
      case TrophyLevel.supporter:
        return 7;
      case TrophyLevel.friend:
        return 8;
      case TrophyLevel.starter:
        return 9;
    }
  }
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readDoubleOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int? _readInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

String? _readString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}
