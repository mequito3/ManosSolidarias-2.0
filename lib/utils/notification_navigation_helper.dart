import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/campaign_service.dart';
import '../services/organization_service.dart';
import '../services/profile_service.dart';
import '../services/donor_trophy_service.dart';
import '../controllers/donor_trophy_controller.dart';
import '../ui/home/menu_inferior/campaign_detail/campaign_detail_page.dart';
import '../pages/organization_detail_page.dart';
import '../ui/rewards/donor_trophies_page.dart';

/// Helper para navegar desde notificaciones a la pantalla correspondiente
class NotificationNavigationHelper {
  /// Navega al contexto de la notificación basado en su tipo y payload
  static Future<void> navigateFromNotification({
    required BuildContext context,
    required String notificationType,
    required Map<String, dynamic> payload,
  }) async {
    debugPrint('========================================');
    debugPrint('NAVEGACION DESDE NOTIFICACION');
    debugPrint('Tipo: "$notificationType"');
    debugPrint('Payload: $payload');
    debugPrint('========================================');

    // Normalizar el tipo (eliminar espacios, convertir a minúsculas)
    final normalizedType = notificationType.trim().toLowerCase().replaceAll(' ', '_');
    debugPrint('🔔 Tipo normalizado: "$normalizedType"');

    switch (normalizedType) {
      // Notificaciones de mensajes -> abrir chat
      case 'new_message':
      case 'message':
      case 'mensaje':
      case 'nuevo_mensaje':
        await _navigateToChat(context, payload);
        break;

      // Notificaciones de donaciones -> abrir campaña donde se hizo la donación
      case 'donation_received':
      case 'new_donation':
      case 'donacion_recibida':
      case 'nueva_donacion':
      case 'donacion':
      case 'donacion_confirmada':
      case 'donation_confirmed':
      case 'donaciones_confirmada': // Typo común
      case 'donacion_aprobada':
      case 'donation_approved':
        debugPrint('🎯 Navegando a campaña por donación');
        await _navigateToCampaign(context, payload);
        break;

      // Notificaciones de campañas -> abrir detalle de campaña
      case 'campaign_approved':
      case 'campaign_rejected':
      case 'campaign_created':
      case 'campaign_updated':
      case 'campaign_goal_reached':
      case 'campana_aprobada':
      case 'campana_rechazada':
      case 'campaña_aprobada':
      case 'campaña_rechazada':
      case 'solicitud_aprobada':
      case 'solicitud_rechazada':
        debugPrint('🎯 Navegando a detalle de campaña');
        await _navigateToCampaign(context, payload);
        break;

      // Notificaciones de organizaciones -> abrir detalle de organización
      case 'organization_approved':
      case 'organization_rejected':
      case 'organization_created':
      case 'organizacion_aprobada':
      case 'organizacion_rechazada':
      case 'nueva_organizacion':
        debugPrint('🏢 Navegando a organización');
        await _navigateToOrganization(context, payload);
        break;

      // Notificaciones de comentarios -> abrir campaña con enfoque en comentarios
      case 'new_comment':
      case 'comment_reply':
      case 'nuevo_comentario':
      case 'respuesta_comentario':
      case 'comentario':
        debugPrint('💬 Navegando a campaña con comentarios');
        await _navigateToCampaign(context, payload);
        break;

      // Notificaciones de hitos de campaña (25%, 50%, 75%, 100%)
      case 'campania_25':
      case 'campania_50':
      case 'campania_75':
      case 'campania_100':
      case 'campaign_25':
      case 'campaign_50':
      case 'campaign_75':
      case 'campaign_100':
      case 'meta_alcanzada':
      case 'goal_reached':
        debugPrint('🎯 Navegando a campaña por hito alcanzado');
        await _navigateToCampaign(context, payload);
        break;

      // Notificaciones de reconocimientos/trofeos -> abrir perfil o trofeos
      case 'trophy_unlocked':
      case 'achievement':
      case 'trofeo_desbloqueado':
      case 'logro':
        await _navigateToProfile(context, payload);
        break;

      // Notificaciones de ranking -> abrir ranking
      case 'ranking_entrada':
      case 'ranking_mejora':
      case 'ranking_podio':
      case 'ranking_top_1':
      case 'ranking_top_2':
      case 'ranking_top_3':
        debugPrint('🏆 Navegando a ranking');
        await _navigateToRanking(context, payload);
        break;

      default:
        debugPrint('⚠️ ========================================');
        debugPrint('⚠️ TIPO DE NOTIFICACIÓN NO RECONOCIDO');
        debugPrint('⚠️ Tipo original: "$notificationType"');
        debugPrint('⚠️ Tipo normalizado: "$normalizedType"');
        debugPrint('⚠️ Payload: $payload');
        debugPrint('⚠️ ========================================');
        
        // Mostrar mensaje al usuario con el tipo de notificación
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación: $notificationType\n(Tipo no configurado para navegación)'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        break;
    }
  }

  /// Navega al chat específico
  static Future<void> _navigateToChat(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final conversationId = payload['conversation_id'] as String?;
    final senderId = payload['sender_id'] as String?;
    final senderName = payload['sender_name'] as String?;

    if (conversationId == null || senderId == null) {
      debugPrint('❌ Faltan datos para navegar al chat: $payload');
      _showErrorSnackbar(context, 'No se pudo abrir el chat');
      return;
    }

    debugPrint('💬 Navegando al chat: conversationId=$conversationId');

    // TODO: Implementar navegación a ChatPage cuando esté disponible
    // Por ahora mostrar mensaje informativo
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💬 Nuevo mensaje de ${senderName ?? "un usuario"}'),
        action: SnackBarAction(
          label: 'VER',
          onPressed: () {
            // Aquí irá la navegación cuando ChatPage esté implementado
            debugPrint('Abrir chat con conversationId: $conversationId');
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    /* Código para cuando ChatPage esté implementado:
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversationId,
          otherUserId: senderId,
          otherUserName: senderName ?? 'Usuario',
          // Si tenemos messageId, podríamos hacer scroll hasta ese mensaje
          highlightedMessageId: messageId,
        ),
      ),
    );
    */
  }

  /// Navega al detalle de una campaña
  static Future<void> _navigateToCampaign(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    debugPrint('🔍 ========================================');
    debugPrint('🔍 _navigateToCampaign - Analizando payload:');
    debugPrint('🔍 Payload completo: $payload');
    debugPrint('🔍 Keys disponibles: ${payload.keys.toList()}');
    
    final campaignId = payload['campaign_id'] as String?;
    final solicitudId = payload['solicitud_id'] as String?;
    
    // Extraer IDs específicos para highlight
    final commentId = payload['comment_id'] as String?;
    final donationId = payload['donation_id'] as String?;
    
    debugPrint('🔍 campaign_id extraído: $campaignId');
    debugPrint('🔍 solicitud_id extraído: $solicitudId');
    debugPrint('🔍 comment_id extraído: $commentId');
    debugPrint('🔍 donation_id extraído: $donationId');

    // Intentar obtener el ID de diferentes formas
    final id = campaignId ?? solicitudId;
    
    debugPrint('🔍 ID final seleccionado: $id');
    debugPrint('🔍 ========================================');

    if (id == null) {
      debugPrint('❌ ERROR: No se encontró campaign_id ni solicitud_id en el payload');
      debugPrint('❌ Esta notificación fue creada antes de la actualización.');
      debugPrint('❌ Las nuevas notificaciones sí tendrán el campaign_id.');
      _showErrorSnackbar(
        context, 
        'Esta notificación no contiene el ID de la campaña.\nSolo las notificaciones nuevas podrán abrirse.',
      );
      return;
    }

    if (!context.mounted) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
        ),
      ),
    );

    try {
      debugPrint('✅ PASO 1: Obteniendo cliente de Supabase...');
      final client = Supabase.instance.client;
      final campaignService = CampaignService(client);
      final profileService = ProfileService(client);
      debugPrint('✅ Cliente obtenido correctamente');

      debugPrint('✅ PASO 2: Verificando usuario autenticado...');
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      debugPrint('✅ Usuario ID: $userId');
      
      debugPrint('✅ PASO 3: Cargando perfil del usuario...');
      final userProfile = await profileService.fetchProfileByUserId(userId);
      if (userProfile == null) {
        throw Exception('Perfil no encontrado');
      }
      debugPrint('✅ Perfil cargado: ${userProfile.displayName ?? "Sin nombre"}');

      debugPrint('✅ PASO 4: Obteniendo campaña con ID: $id');
      final campaignDetail = await campaignService.fetchCampaignDetail(id);
      
      if (campaignDetail == null) {
        debugPrint('❌ fetchCampaignDetail retornó NULL para ID: $id');
        throw Exception('Campaña no encontrada en la base de datos');
      }
      debugPrint('✅ Campaña obtenida: ${campaignDetail.summary.title}');
      debugPrint('✅ Estado de campaña: ${campaignDetail.summary.status}');

      if (!context.mounted) return;
      
      debugPrint('✅ PASO 5: Cerrando indicador de carga...');
      Navigator.of(context).pop();
      debugPrint('✅ Loading cerrado');
      
      debugPrint('✅ PASO 6: Navegando a CampaignDetailPage...');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CampaignDetailPage(
            campaignSummary: campaignDetail.summary,
            campaignService: campaignService,
            userProfile: userProfile,
            // 🎯 PASAR PARÁMETROS DE HIGHLIGHT
            highlightCommentId: commentId,
            highlightDonationId: donationId,
          ),
        ),
      );
      debugPrint('✅ ========================================');
      debugPrint('✅ NAVEGACIÓN COMPLETADA EXITOSAMENTE');
      debugPrint('✅ ========================================');
    } catch (error, stackTrace) {
      debugPrint('❌ ========================================');
      debugPrint('❌ ERROR AL CARGAR CAMPAÑA');
      debugPrint('❌ Campaign ID intentado: $id');
      debugPrint('❌ Error: $error');
      debugPrint('❌ Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('❌ ========================================');
      
      if (!context.mounted) return;
      
      // Cerrar indicador de carga
      try {
        Navigator.of(context).pop();
      } catch (e) {
        debugPrint('⚠️ No se pudo cerrar el loading dialog: $e');
      }
      
      _showErrorSnackbar(
        context, 
        'No se pudo cargar la campaña.\nMotivo: ${error.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Navega al detalle de una organización
  static Future<void> _navigateToOrganization(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final organizationId = payload['organization_id'] as String?;

    if (organizationId == null) {
      debugPrint('❌ Falta organization_id en el payload: $payload');
      _showErrorSnackbar(context, 'No se pudo abrir la organización');
      return;
    }

    debugPrint('🏢 Navegando a organización: organizationId=$organizationId');

    if (!context.mounted) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Cargar datos necesarios
      final client = Supabase.instance.client;
      final organizationService = OrganizationService(client);

      // Cargar todas las organizaciones aprobadas
      final organizations = await organizationService.fetchApprovedOrganizations();
      final organization = organizations.firstWhere(
        (o) => o.id == organizationId,
        orElse: () => throw Exception('Organización no encontrada'),
      );

      if (!context.mounted) return;
      
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Navegar a la organización
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrganizationDetailPage(
            organization: organization,
            fromNotification: true,
          ),
        ),
      );
    } catch (error) {
      debugPrint('❌ Error al cargar organización: $error');
      if (!context.mounted) return;
      
      // Cerrar indicador de carga
      Navigator.of(context).pop();
      
      _showErrorSnackbar(context, 'No se pudo cargar la organización');
    }
  }

  /// Navega al perfil del usuario (para trofeos, reconocimientos, etc.)
  static Future<void> _navigateToProfile(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    debugPrint('👤 Navegando a perfil/trofeos');

    if (!context.mounted) return;
    
    // Por ahora solo mostrar un mensaje
    // En el futuro podrías navegar a una página de trofeos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🏆 ¡Revisa tus trofeos en tu perfil!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Navega a la página de ranking
  static Future<void> _navigateToRanking(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    debugPrint('🏆 Navegando al ranking solidario');

    if (!context.mounted) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Crear servicios necesarios
      final client = Supabase.instance.client;
      final donorTrophyService = DonorTrophyService(client);
      final controller = DonorTrophyController(donorTrophyService);

      // Pre-cargar el ranking
      await controller.loadLeaderboard();

      if (!context.mounted) return;
      
      // Cerrar indicador de carga
      Navigator.of(context).pop();

      // Navegar a la página de ranking
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DonorTrophiesPage(
            controller: controller,
            scrollToRanking: true,
          ),
        ),
      );
    } catch (error) {
      debugPrint('❌ Error al cargar ranking: $error');
      if (!context.mounted) return;
      
      // Cerrar indicador de carga
      try {
        Navigator.of(context).pop();
      } catch (e) {
        debugPrint('⚠️ No se pudo cerrar el loading dialog: $e');
      }
      
      _showErrorSnackbar(context, 'No se pudo cargar el ranking');
    }
  }

  /// Muestra un error al usuario
  static void _showErrorSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
