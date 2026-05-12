class UserProfile {
  const UserProfile({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.city,
    this.address,
    this.documentType,
    this.documentNumber,
    this.bankHolder,
    this.bankName,
    this.bankAccountType,
    this.bankAccountNumber,
    this.donationQrUrl,
    required this.isAdmin,
    required this.isProfileComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['telefono'] as String?,
      city: json['ciudad'] as String?,
      address: json['direccion'] as String?,
      documentType: json['documento_tipo'] as String?,
      documentNumber: json['documento_numero'] as String?,
      bankHolder: json['banco_titular'] as String?,
      bankName: json['banco_nombre'] as String?,
      bankAccountType: json['banco_tipo_cuenta'] as String?,
      bankAccountNumber: json['banco_numero_cuenta'] as String?,
      donationQrUrl: json['donacion_qr_url'] as String?,
      isAdmin: (json['is_admin'] as bool?) ?? false,
      isProfileComplete: (json['perfil_completo'] as bool?) ?? false,
    );
  }

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? city;
  final String? address;
  final String? documentType;
  final String? documentNumber;
  final String? bankHolder;
  final String? bankName;
  final String? bankAccountType;
  final String? bankAccountNumber;
  final String? donationQrUrl;
  final bool isAdmin;
  final bool isProfileComplete;

  // Datos básicos requeridos para DONAR
  bool get hasBasicProfile {
    final hasDisplayName = displayName?.trim().isNotEmpty ?? false;
    final hasIdentity = (documentType?.trim().isNotEmpty ?? false) && 
                       (documentNumber?.trim().isNotEmpty ?? false);
    final hasContact = (phone?.trim().isNotEmpty ?? false) && 
                      (city?.trim().isNotEmpty ?? false) && 
                      (address?.trim().isNotEmpty ?? false);
    return hasDisplayName && hasIdentity && hasContact;
  }

  // Datos financieros requeridos para CREAR CAMPAÑAS (recibir fondos)
  bool get hasFinancialData {
    final hasBanking = (bankHolder?.trim().isNotEmpty ?? false) &&
        (bankName?.trim().isNotEmpty ?? false) &&
        (bankAccountType?.trim().isNotEmpty ?? false) &&
        (bankAccountNumber?.trim().isNotEmpty ?? false);
    final hasQR = donationQrUrl?.trim().isNotEmpty ?? false;
    return hasBanking || hasQR;
  }

  // Perfil completo: datos básicos + datos financieros
  bool get meetsCompletionCriteria {
    return hasBasicProfile && hasFinancialData;
  }

  // Puede donar: solo necesita datos básicos
  bool get canDonate {
    return hasBasicProfile;
  }

  // Puede crear campañas: necesita perfil completo (básico + financiero)
  bool get canCreateCampaign {
    return meetsCompletionCriteria;
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? city,
    String? address,
    String? documentType,
    String? documentNumber,
    String? bankHolder,
    String? bankName,
    String? bankAccountType,
    String? bankAccountNumber,
    String? donationQrUrl,
    bool? isAdmin,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      bankHolder: bankHolder ?? this.bankHolder,
      bankName: bankName ?? this.bankName,
      bankAccountType: bankAccountType ?? this.bankAccountType,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      donationQrUrl: donationQrUrl ?? this.donationQrUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  Map<String, dynamic> toUpsertPayload() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'telefono': phone,
      'ciudad': city,
      'direccion': address,
      'documento_tipo': documentType,
      'documento_numero': documentNumber,
      'banco_titular': bankHolder,
      'banco_nombre': bankName,
      'banco_tipo_cuenta': bankAccountType,
      'banco_numero_cuenta': bankAccountNumber,
      'donacion_qr_url': donationQrUrl,
      // SEGURIDAD: 'is_admin' se omite intencionalmente — solo puede modificarse desde la BD
      'perfil_completo': meetsCompletionCriteria,
    }..removeWhere((_, value) => value == null);
  }
}
