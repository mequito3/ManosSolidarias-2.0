# 🔔 Sistema de Notificaciones con Navegación Contextual

## ✅ Implementación Completada

Se ha implementado un sistema completo de notificaciones con **navegación contextual y énfasis visual** similar a Facebook, donde al hacer clic en una notificación, la app:

1. **Navega automáticamente** al contenido relacionado (campaña, comentario, donación, etc.)
2. **Hace scroll automático** al elemento específico si aplica
3. **Resalta visualmente** el elemento con una animación de borde brillante que pulsa

---

## 🎯 Características Principales

### 1. **HighlightWrapper Widget** (`lib/ui/widgets/highlight_wrapper.dart`)

Widget reutilizable que envuelve cualquier elemento para resaltarlo con:
- ✨ Animación de borde brillante que pulsa
- 📏 Efecto sutil de escala
- 🎨 Color personalizable
- ⚙️ Duración y número de pulsos configurables

```dart
HighlightWrapper(
  shouldHighlight: true,
  highlightColor: Color(0xFF2196F3),
  pulseCount: 3,
  child: YourWidget(),
)
```

### 2. **Navegación Contextual Mejorada**

#### Notificaciones de Comentarios
- Navega a la campaña
- Hace **scroll automático** al comentario específico
- Resalta el comentario con borde azul brillante
- El comentario queda visible y destacado

#### Notificaciones de Donaciones
- Navega a la campaña
- Muestra un **banner verde** en la parte superior
- Mensaje: "¡Donación recibida! Tu generosidad está haciendo la diferencia"
- El banner tiene animación de pulso

#### Notificaciones de Organizaciones
- Navega a la organización
- Muestra un **banner azul** con efecto de resaltado
- Mensaje: "Organización verificada"

---

## 📂 Archivos Modificados

### **Nuevos Archivos:**
- `lib/ui/widgets/highlight_wrapper.dart` - Widget de resaltado reutilizable

### **Archivos Actualizados:**

1. **`lib/utils/notification_navigation_helper.dart`**
   - Extrae `comment_id` y `donation_id` del payload
   - Pasa estos IDs al navegar a las páginas de destino

2. **`lib/ui/home/menu_inferior/campaign_detail/campaign_detail_page.dart`**
   - Agregó parámetros `highlightCommentId` y `highlightDonationId`
   - Pasa estos parámetros a través de la jerarquía de widgets
   - Importa `HighlightWrapper`

3. **`lib/ui/home/menu_inferior/campaign_detail/campaign_detail_view.dart`**
   - Recibe y propaga `highlightCommentId` y `highlightDonationId`
   - Pasa parámetros a `_CommentsSection` y `_SummaryStats`

4. **`lib/ui/home/menu_inferior/campaign_detail/comments_section.dart`**
   - `_CommentsSection` convertida a **StatefulWidget**
   - Implementa **scroll automático** al comentario resaltado
   - Cada comentario se envuelve en `HighlightWrapper` cuando corresponde
   - Usa `GlobalKey` para ubicar comentarios específicos

5. **`lib/pages/organization_detail_page.dart`**
   - Agregó parámetro `fromNotification`
   - Muestra banner de notificación cuando viene desde una notificación

---

## 🔄 Flujo de Funcionamiento

### Ejemplo: Notificación de Nuevo Comentario

```
1. Usuario recibe notificación de comentario
   └─ Payload incluye: { comment_id: "abc123", campaign_id: "xyz789" }

2. Usuario hace clic en la notificación
   └─ NotificationNavigationHelper extrae los IDs

3. Se navega a CampaignDetailPage
   └─ Con parámetro highlightCommentId="abc123"

4. CampaignDetailPage pasa el ID a _CampaignDetailView
   └─ Que lo pasa a _CommentsSection

5. _CommentsSection (StatefulWidget)
   ├─ Crea un GlobalKey para cada comentario
   ├─ Después de construir, ejecuta _scrollToHighlightedComment()
   └─ Hace scroll suave al comentario con ID "abc123"

6. El comentario "abc123" se renderiza envuelto en HighlightWrapper
   └─ Muestra animación de borde azul pulsante (3 pulsos)
```

---

## 🎨 Colores de Resaltado

| Tipo | Color | Uso |
|------|-------|-----|
| **Comentarios** | `#2196F3` (Azul) | Resaltar comentario específico |
| **Donaciones** | `#4CAF50` (Verde) | Banner de "¡Donación recibida!" |
| **Organizaciones** | `#2196F3` (Azul) | Banner de "Organización verificada" |

---

## 📱 Tipos de Notificaciones Soportadas

### ✅ Totalmente Implementadas:
- ✅ **Comentarios** - Con scroll y highlight específico
- ✅ **Donaciones** - Con banner verde de confirmación
- ✅ **Organizaciones** - Con banner azul de verificación
- ✅ **Campañas** (aprobadas/rechazadas) - Navegación directa

### ⚠️ Pendientes de Implementar:
- ⏳ **Mensajes/Chat** - Actualmente muestra SnackBar (ChatPage no implementado)
- ⏳ **Trofeos** - Muestra SnackBar informativo

---

## 🔧 Cómo Usar en Nuevas Notificaciones

### 1. En la Base de Datos (Supabase)

Al crear una notificación, asegúrate de incluir los IDs necesarios en el `payload`:

```sql
INSERT INTO notificaciones (user_id, tipo, mensaje, payload)
VALUES (
  'user_uuid',
  'nuevo_comentario',
  'Juan comentó en tu campaña',
  jsonb_build_object(
    'campaign_id', 'campaign_uuid',
    'comment_id', 'comment_uuid'  -- ⭐ Importante para el highlight
  )
);
```

### 2. Configurar en notification_navigation_helper.dart

Agregar el tipo de notificación en el switch si no existe:

```dart
case 'nuevo_tipo':
  await _navigateToCampaign(context, payload);
  break;
```

### 3. Usar HighlightWrapper en tu Widget

```dart
HighlightWrapper(
  shouldHighlight: widget.shouldHighlight,
  child: YourContentWidget(),
)
```

---

## 🎯 Requisitos del Payload

Para que el sistema funcione correctamente, el **payload** de las notificaciones debe incluir:

### Notificaciones de Campañas
```json
{
  "campaign_id": "uuid",
  "comment_id": "uuid",      // Opcional, si es comentario específico
  "donation_id": "uuid"      // Opcional, si es donación específica
}
```

### Notificaciones de Organizaciones
```json
{
  "organization_id": "uuid"
}
```

### Notificaciones de Mensajes (futuro)
```json
{
  "conversation_id": "uuid",
  "sender_id": "uuid",
  "sender_name": "string",
  "message_id": "uuid"       // Opcional, para scroll al mensaje
}
```

---

## 🐛 Solución de Problemas

### Problema: El scroll no funciona
**Causa:** El comentario no tiene un `GlobalKey` asignado  
**Solución:** Verifica que `_commentKeys` se inicialice correctamente en `initState`

### Problema: El highlight no se muestra
**Causa:** `shouldHighlight` es false  
**Solución:** Verifica que el `comment_id` del payload coincida con el `id` del comentario

### Problema: La navegación falla
**Causa:** `campaign_id` falta en el payload  
**Solución:** Actualiza las notificaciones antiguas o crea nuevas con el payload correcto

---

## 📊 Mejoras Futuras Sugeridas

1. **Persistir estado de highlight** - Guardar qué notificaciones ya se abrieron
2. **Deep linking** - Soportar URLs para abrir desde notificaciones push
3. **Lista de donaciones** - Mostrar lista completa de donaciones con scroll a la específica
4. **Historial de notificaciones** - Página de todas las notificaciones con filtros
5. **Notificaciones en tiempo real** - Usar Supabase Realtime para actualizaciones instantáneas

---

## ✨ Resultado Final

El usuario ahora tiene una experiencia **fluida y contextual** al interactuar con notificaciones:

- ✅ Navegación instantánea al contenido
- ✅ Scroll automático al elemento exacto
- ✅ Animación visual llamativa pero no intrusiva
- ✅ Feedback claro de dónde llegó (banners informativos)
- ✅ Similar a la UX de Facebook, Instagram, etc.

¡El sistema está completamente funcional y listo para usar! 🎉
