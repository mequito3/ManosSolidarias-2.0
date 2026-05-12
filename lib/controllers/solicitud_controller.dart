import 'package:flutter/foundation.dart';

import '../models/solicitud.dart';
import '../services/solicitud_service.dart';

class SolicitudController extends ChangeNotifier {
	SolicitudController(this._service);

	final SolicitudService _service;

	bool _isLoading = false;
	bool _hasLoaded = false;
	bool _isSubmitting = false;
	String? _loadError;
	String? _submitError;
	List<SolicitudCategory> _categories = const [];
	List<SolicitudOrganization> _organizations = const [];

	bool get isLoading => _isLoading;
	bool get hasLoaded => _hasLoaded;
	bool get isSubmitting => _isSubmitting;
	String? get loadError => _loadError;
	String? get submitError => _submitError;
	List<SolicitudCategory> get categories => _categories;
	List<SolicitudOrganization> get organizations => _organizations;

	Future<void> loadInitialData({bool forceRefresh = false}) async {
		if (_isLoading) {
			return;
		}

		if (_hasLoaded && !forceRefresh) {
			return;
		}

		_isLoading = true;
		_loadError = null;
		if (!forceRefresh) {
			notifyListeners();
		}

			try {
				final results = await Future.wait([
					_service.fetchCategories(),
					_service.fetchOrganizationsForCurrentUser(),
				]);

				_categories = results[0] as List<SolicitudCategory>;
				_organizations = results[1] as List<SolicitudOrganization>;
			_hasLoaded = true;
		} on SolicitudServiceException catch (error) {
			_loadError = error.message;
		} catch (error) {
			debugPrint('SolicitudController.loadInitialData error: $error');
			_loadError = 'No pudimos preparar el formulario. Intenta nuevamente.';
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	Future<Solicitud?> submitSolicitud(SolicitudDraft draft) async {
		if (_isSubmitting) {
			return null;
		}

		_isSubmitting = true;
		_submitError = null;
		notifyListeners();

		try {
			final solicitud = await _service.createSolicitud(draft);
			return solicitud;
		} on SolicitudServiceException catch (error) {
			_submitError = error.message;
			return null;
		} catch (error) {
			debugPrint('SolicitudController.submitSolicitud error: $error');
			_submitError = 'No pudimos enviar tu solicitud. Intenta otra vez.';
			return null;
		} finally {
			_isSubmitting = false;
			notifyListeners();
		}
	}

	Future<String> uploadCoverImage({
		required Uint8List data,
		required String contentType,
		required String fileExtension,
	}) {
		return _service.uploadCoverImage(
			data: data,
			contentType: contentType,
			fileExtension: fileExtension,
		);
	}

	Future<String> uploadEvidenceImage({
		required Uint8List data,
		required String contentType,
		required String fileExtension,
	}) {
		return _service.uploadEvidenceImage(
			data: data,
			contentType: contentType,
			fileExtension: fileExtension,
		);
	}

	void clearSubmitError() {
		if (_submitError == null) {
			return;
		}
		_submitError = null;
		notifyListeners();
	}
}
