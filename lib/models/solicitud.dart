enum SolicitudTipo { campania, kermesse, rifa }

extension SolicitudTipoX on SolicitudTipo {
	String get code {
		switch (this) {
			case SolicitudTipo.campania:
				return 'campania';
			case SolicitudTipo.kermesse:
				return 'kermesse';
			case SolicitudTipo.rifa:
				return 'rifa';
		}
	}

	String get displayName {
		switch (this) {
			case SolicitudTipo.campania:
				return 'Campaña solidaria';
			case SolicitudTipo.kermesse:
				return 'Kermesse solidaria';
			case SolicitudTipo.rifa:
				return 'Rifa solidaria';
		}
	}
}

SolicitudTipo solicitudTipoFromCode(String? code) {
	switch (code) {
		case 'kermesse':
			return SolicitudTipo.kermesse;
		case 'rifa':
			return SolicitudTipo.rifa;
		case 'campania':
		default:
			return SolicitudTipo.campania;
	}
}

class Solicitud {
	const Solicitud({
		required this.id,
		required this.userId,
		required this.titulo,
		required this.descripcion,
		required this.tipo,
		required this.estado,
		required this.createdAt,
		required this.updatedAt,
		this.organizationId,
		this.categoriaId,
		this.montoObjetivo,
		this.portadaUrl,
		this.qrOriginalUrl,
		this.motivoRechazo,
		this.esAnonimo = false,
	});

	final String id;
	final String userId;
	final String titulo;
	final String descripcion;
	final SolicitudTipo tipo;
	final String estado;
	final DateTime createdAt;
	final DateTime updatedAt;
	final String? organizationId;
	final String? categoriaId;
	final double? montoObjetivo;
	final String? portadaUrl;
	final String? qrOriginalUrl;
	final String? motivoRechazo;
	final bool esAnonimo;

	bool get isPending => estado == 'pendiente';
	bool get isApproved => estado == 'aprobada';
	bool get isRejected => estado == 'rechazada';

	factory Solicitud.fromJson(Map<String, dynamic> json) {
		return Solicitud(
			id: json['id'] as String,
			userId: json['user_id'] as String,
			titulo: json['titulo'] as String,
			descripcion: json['descripcion'] as String,
			tipo: solicitudTipoFromCode(json['tipo'] as String?),
			estado: json['estado'] as String,
			createdAt: _parseDate(json['created_at']),
			updatedAt: _parseDate(json['updated_at']),
			organizationId: json['organizacion_id'] as String?,
			categoriaId: json['categoria_id'] as String?,
			montoObjetivo: _parseNumeric(json['monto_objetivo']),
			portadaUrl: json['portada_url'] as String?,
			qrOriginalUrl: json['qr_original_url'] as String?,
			motivoRechazo: json['motivo_rechazo'] as String?,
			esAnonimo: (json['es_anonimo'] as bool?) ?? false,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'user_id': userId,
			'titulo': titulo,
			'descripcion': descripcion,
			'tipo': tipo.code,
			'estado': estado,
			'created_at': createdAt.toIso8601String(),
			'updated_at': updatedAt.toIso8601String(),
			'organizacion_id': organizationId,
			'categoria_id': categoriaId,
			'monto_objetivo': montoObjetivo,
			'portada_url': portadaUrl,
			'qr_original_url': qrOriginalUrl,
			'motivo_rechazo': motivoRechazo,
			'es_anonimo': esAnonimo,
		}..removeWhere((_, value) => value == null);
	}

	static double? _parseNumeric(dynamic value) {
		if (value == null) {
			return null;
		}
		if (value is num) {
			return value.toDouble();
		}
		if (value is String) {
			return double.tryParse(value);
		}
		return null;
	}

	static DateTime _parseDate(dynamic value) {
		if (value is DateTime) {
			return value;
		}
		if (value is String) {
			final parsed = DateTime.tryParse(value);
			if (parsed != null) {
				return parsed;
			}
		}
		throw ArgumentError('Invalid date value: $value');
	}
}

class SolicitudDraft {
	const SolicitudDraft({
		required this.titulo,
		required this.descripcion,
		required this.tipo,
		this.categoriaId,
		this.montoObjetivo,
		this.organizationId,
		this.portadaUrl,
		this.qrOriginalUrl,
		this.esAnonimo = false,
	});

	final String titulo;
	final String descripcion;
	final SolicitudTipo tipo;
	final String? categoriaId;
	final double? montoObjetivo;
	final String? organizationId;
	final String? portadaUrl;
	final String? qrOriginalUrl;
	final bool esAnonimo;

	Map<String, dynamic> toInsertMap({required String userId}) {
		return {
			'user_id': userId,
			'titulo': titulo,
			'descripcion': descripcion,
			'tipo': tipo.code,
			'categoria_id': categoriaId,
			'monto_objetivo': montoObjetivo,
			'organizacion_id': organizationId,
			'portada_url': portadaUrl,
			'qr_original_url': qrOriginalUrl,
			'es_anonimo': esAnonimo,
		}..removeWhere((_, value) => value == null);
	}
}

class SolicitudCategory {
	const SolicitudCategory({
		required this.id,
		required this.name,
		this.description,
	});

	final String id;
	final String name;
	final String? description;

	factory SolicitudCategory.fromJson(Map<String, dynamic> json) {
		return SolicitudCategory(
			id: json['id'] as String,
			name: json['nombre'] as String,
			description: json['descripcion'] as String?,
		);
	}
}

class SolicitudOrganization {
	const SolicitudOrganization({
		required this.id,
		required this.name,
		required this.status,
	});

	final String id;
	final String name;
	final String status;

	bool get isApproved => status == 'aprobada';

	factory SolicitudOrganization.fromJson(Map<String, dynamic> json) {
		return SolicitudOrganization(
			id: json['id'] as String,
			name: json['nombre'] as String,
			status: json['estado'] as String,
		);
	}
}
