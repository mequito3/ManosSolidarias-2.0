# Navegación Contextual desde Notificaciones

## 📱 Resumen

Implementamos **navegación contextual inteligente** desde notificaciones, similar a WhatsApp, Instagram y otras apps profesionales. Cuando el usuario hace **tap en una notificación**, la app lo lleva directamente al contexto específico:

- 💬 Mensaje → Chat con esa persona
- 💰 Donación → Campaña donde se hizo la donación
- ✅ Campaña aprobada → Detalle de la campaña
- 🏢 Organización aprobada → Perfil de la organización
- 💬 Nuevo comentario → Campaña con enfoque en comentarios

---

## 🎯 Tipos de Notificación Soportados

### 1. **Mensajes** (`new_message`, `message`)
```json
{
  "conversation_id": "uuid",
  "message_id": "uuid",
  "sender_id": "uuid",
  "sender_name": "Juan Pérez"
}
```
**Acción**: Abre el chat con el remitente (próximamente cuando ChatPage esté implementado)

---

### 2. **Donaciones** (`donation_received`, `new_donation`)
```json
{
  "campaign_id": "uuid",
  "monto": 500,
  "donante": "María González"
}
```
**Acción**: Navega al detalle de la campaña donde se recibió la donación

---

### 3. **Campañas** (`campaign_approved`, `campaign_rejected`, `campaign_goal_reached`)
```json
{
  "campaign_id": "uuid",
  "titulo": "Ayuda para Juan",
  "estado": "aprobada"
}
```
**Acción**: Abre el detalle completo de la campaña

---

### 4. **Organizaciones** (`organization_approved`, `organization_rejected`)
```json
{
  "organization_id": "uuid",
  "organizacion": "Cruz Roja"
}
```
**Acción**: Navega al perfil de la organización

---

### 5. **Comentarios** (`new_comment`, `comment_reply`)
```json
{
  "campaign_id": "uuid",
  "comment_id": "uuid",
  "autor": "Pedro López"
}
```
**Acción**: Abre la campaña (en el futuro con scroll automático al comentario)

---

### 6. **Solicitudes** (`solicitud_approved`, `solicitud_rejected`)
```json
{
  "solicitud_id": "uuid",
  "campaign_id": "uuid"
}
```
**Acción**: Navega a la campaña creada (si fue aprobada)

---

## 🏗️ Arquitectura

### Componentes Principales

```
lib/
├── utils/
│   └── notification_navigation_helper.dart  ← Helper principal
├── ui/home/notifications/
│   └── notifications_page.dart              ← UI de notificaciones
└── models/
    └── notification_entry.dart              ← Modelo de notificación
```

### Flujo de Navegación

```
Usuario tap en notificación
         ↓
NotificationsPage._openDetail()
         ↓
markAsRead() → Marca como leída
         ↓
NotificationNavigationHelper.navigateFromNotification()
         ↓
Switch según notification.type
         ↓
_navigateToCampaign() / _navigateToOrganization() / etc.
         ↓
Carga datos necesarios (CampaignSummary, UserProfile, etc.)
         ↓
Navigator.push() → Página de destino
```

---

## 💡 Ejemplos de Uso

### Caso 1: Donación Recibida
```dart
// Notificación creada en Supabase
{
  "tipo": "donation_received",
  "mensaje": "¡Recibiste una donación de $500 en tu campaña!",
  "payload": {
    "campaign_id": "abc-123",
    "monto": 500,
    "donante": "María González"
  }
}

// Usuario tap → Se ejecuta:
await NotificationNavigationHelper.navigateFromNotification(
  context: context,
  notificationType: "donation_received",
  payload: {
    "campaign_id": "abc-123",
    "monto": 500,
    "donante": "María González"
  },
);

// Resultado: Abre CampaignDetailPage de la campaña "abc-123"
```

---

### Caso 2: Campaña Aprobada
```dart
// Notificación
{
  "tipo": "campaign_approved",
  "mensaje": "✅ Tu campaña 'Ayuda para Juan' fue aprobada",
  "payload": {
    "campaign_id": "def-456",
    "titulo": "Ayuda para Juan",
    "estado": "aprobada"
  }
}

// Usuario tap → Navega a CampaignDetailPage
```

---

### Caso 3: Nuevo Comentario
```dart
// Notificación
{
  "tipo": "new_comment",
  "mensaje": "Pedro López comentó en tu campaña",
  "payload": {
    "campaign_id": "ghi-789",
    "comment_id": "xyz-111",
    "autor": "Pedro López",
    "comentario": "¡Excelente iniciativa!"
  }
}

// Usuario tap → Abre la campaña
// (En el futuro: scroll automático al comentario)
```

---

## 🛠️ Implementación Técnica

### `NotificationNavigationHelper`

```dart
class NotificationNavigationHelper {
  static Future<void> navigateFromNotification({
    required BuildContext context,
    required String notificationType,
    required Map<String, dynamic> payload,
  }) async {
    switch (notificationType) {
      case 'donation_received':
        await _navigateToCampaign(context, payload);
        break;
      
      case 'organization_approved':
        await _navigateToOrganization(context, payload);
        break;
      
      // ... más casos
    }
  }
}
```

### Navegación a Campaña (con carga de datos)

```dart
static Future<void> _navigateToCampaign(
  BuildContext context,
  Map<String, dynamic> payload,
) async {
  final campaignId = payload['campaign_id'] as String?;
  
  if (campaignId == null) {
    _showErrorSnackbar(context, 'No se pudo abrir la campaña');
    return;
  }

  // Mostrar loading
  showDialog(
    context: context,
    builder: (context) => CircularProgressIndicator(),
  );

  try {
    // Cargar datos necesarios
    final client = Supabase.instance.client;
    final campaignService = CampaignService(client);
    final campaigns = await campaignService.fetchCampaigns();
    final campaign = campaigns.firstWhere((c) => c.id == campaignId);
    
    // Cargar perfil del usuario
    final profileService = ProfileService(client);
    final userProfile = await profileService.fetchProfile(userId);

    // Cerrar loading y navegar
    Navigator.pop(context); // Close loading
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignDetailPage(
          campaignSummary: campaign,
          campaignService: campaignService,
          userProfile: userProfile,
        ),
      ),
    );
  } catch (error) {
    Navigator.pop(context); // Close loading
    _showErrorSnackbar(context, 'Error al cargar la campaña');
  }
}
```

---

## 🚀 Próximas Mejoras

### 1. **Chat Implementation** (Pendiente)
```dart
// Cuando ChatPage esté disponible:
case 'new_message':
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatPage(
        conversationId: conversationId,
        otherUserId: senderId,
        highlightedMessageId: messageId, // ← Scroll automático
      ),
    ),
  );
```

### 2. **Scroll Automático a Comentarios**
```dart
// Agregar a CampaignDetailPage:
class CampaignDetailPage extends StatefulWidget {
  final String? highlightedCommentId;
  final String? initialTab; // 'comments', 'story', etc.
  
  // En initState():
  if (widget.initialTab == 'comments') {
    _scrollToComments();
    if (widget.highlightedCommentId != null) {
      _highlightComment(widget.highlightedCommentId!);
    }
  }
}
```

### 3. **Deep Links** (Universal Links / App Links)
```dart
// Manejar notificaciones push que abren la app
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final notificationType = message.data['tipo'];
  final payload = message.data['payload'];
  
  NotificationNavigationHelper.navigateFromNotification(
    context: context,
    notificationType: notificationType,
    payload: payload,
  );
});
```

### 4. **Animaciones de Transición**
```dart
await Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
      CampaignDetailPage(...),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  ),
);
```

---

## 📊 Métricas y Testing

### Testing Manual
1. Crear una donación desde un dispositivo
2. Verificar que llegue la notificación al donante
3. **Tap en la notificación**
4. ✅ Verificar que navegue a CampaignDetailPage
5. ✅ Verificar que la notificación se marque como leída

### Testing Unitario (Próximo)
```dart
testWidgets('Tap en notificación de donación navega a campaña', (tester) async {
  // Arrange
  final notification = NotificationEntry(
    type: 'donation_received',
    payload: {'campaign_id': 'test-123'},
  );

  // Act
  await tester.tap(find.byType(NotificationTile));
  await tester.pumpAndSettle();

  // Assert
  expect(find.byType(CampaignDetailPage), findsOneWidget);
});
```

---

## 🎓 Para tu Tesis

### Puntos Clave
- ✅ **UX profesional**: Navegación contextual similar a apps líderes
- ✅ **Arquitectura limpia**: Helper separado, responsabilidad única
- ✅ **Manejo de errores**: Loading states, error feedback
- ✅ **Escalabilidad**: Fácil agregar nuevos tipos de notificaciones
- ✅ **Performance**: Carga lazy de datos, solo cuando se necesita

### Comparación con Otras Apps

| Característica | WhatsApp | Instagram | Manos Solidarias |
|----------------|----------|-----------|------------------|
| Tap en notificación → Contexto | ✅ | ✅ | ✅ |
| Marca como leída automático | ✅ | ✅ | ✅ |
| Highlight del item específico | ✅ | ✅ | 🚧 (próximo) |
| Deep linking | ✅ | ✅ | 🚧 (próximo) |
| Loading states | ✅ | ✅ | ✅ |

---

## 🐛 Troubleshooting

### Problema: "No se pudo abrir la campaña"
**Causa**: `campaign_id` no existe en el payload
**Solución**: Verificar que la notificación se cree con el payload correcto en Supabase

### Problema: Loading infinito
**Causa**: Error al cargar datos, no se cierra el dialog
**Solución**: Siempre cerrar loading en try/catch:
```dart
try {
  // ... código
  Navigator.pop(context); // ✅ Cerrar en success
} catch (e) {
  Navigator.pop(context); // ✅ Cerrar en error también
}
```

### Problema: Navigator no funciona
**Causa**: `context.mounted` es `false`
**Solución**: Siempre verificar `if (!context.mounted) return;`

---

## 📝 Conclusión

La navegación contextual desde notificaciones mejora significativamente la **experiencia del usuario**, haciendo que la app se sienta **profesional** y **fluida**. Cada notificación lleva al usuario exactamente donde necesita estar, sin pasos adicionales.

**Próximos pasos**:
1. Implementar ChatPage para mensajes
2. Agregar scroll automático a comentarios
3. Implementar deep linking
4. Testing exhaustivo de todos los flujos
