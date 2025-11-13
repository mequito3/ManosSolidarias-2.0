# 📱 Guía de Implementación: Notificaciones con Navegación Contextual

## 🎯 Objetivo

Esta guía te muestra **cómo crear notificaciones correctamente** para que el nuevo sistema de navegación contextual funcione perfectamente.

---

## 📋 Estructura del Payload

El **payload** es crucial para que la navegación funcione. Debe ser un objeto JSON con los IDs necesarios:

```json
{
  "campaign_id": "uuid-de-la-campaña",
  "comment_id": "uuid-del-comentario",     // Opcional, solo para comentarios
  "donation_id": "uuid-de-la-donación",    // Opcional, solo para donaciones
  "organization_id": "uuid-organización",  // Opcional, solo para organizaciones
  "extra_data": "cualquier-dato-adicional" // Campos extra opcionales
}
```

---

## 🔔 Ejemplos por Tipo de Notificación

### 1️⃣ Notificación de Comentario

**Cuándo:** Alguien comenta en una campaña

```dart
// En Flutter/Dart
await supabase.from('notificaciones').insert({
  'user_id': campaignOwnerId,
  'tipo': 'nuevo_comentario',
  'mensaje': '$commenterName comentó en tu campaña "$campaignTitle"',
  'payload': {
    'campaign_id': campaignId,
    'comment_id': commentId,  // ⭐ Importante para scroll automático
    'commenter_name': commenterName,
    'commenter_avatar': commenterAvatarUrl,
  },
});
```

**SQL equivalente:**
```sql
INSERT INTO notificaciones (user_id, tipo, mensaje, payload)
VALUES (
  'uuid-del-dueño',
  'nuevo_comentario',
  'Juan Pérez comentó en tu campaña "Ayuda a los niños"',
  jsonb_build_object(
    'campaign_id', 'campaign-uuid',
    'comment_id', 'comment-uuid',
    'commenter_name', 'Juan Pérez'
  )
);
```

**Resultado:** 
- ✅ Navega a la campaña
- ✅ Hace scroll al comentario específico
- ✅ Resalta el comentario con borde azul pulsante

---

### 2️⃣ Notificación de Donación

**Cuándo:** Alguien dona a una campaña

```dart
// En Flutter/Dart
await supabase.from('notificaciones').insert({
  'user_id': campaignOwnerId,
  'tipo': 'donacion_confirmada',
  'mensaje': 'Has recibido una donación de Bs ${amount.toStringAsFixed(2)}',
  'payload': {
    'campaign_id': campaignId,
    'donation_id': donationId,  // ⭐ Importante para highlight
    'amount': amount,
    'donor_name': donorName,
  },
});
```

**SQL equivalente:**
```sql
INSERT INTO notificaciones (user_id, tipo, mensaje, payload)
VALUES (
  'uuid-del-dueño',
  'donacion_confirmada',
  'Has recibido una donación de Bs 150.00',
  jsonb_build_object(
    'campaign_id', 'campaign-uuid',
    'donation_id', 'donation-uuid',
    'amount', 150.00,
    'donor_name', 'María García'
  )
);
```

**Resultado:**
- ✅ Navega a la campaña
- ✅ Muestra banner verde "¡Donación recibida!"
- ✅ Banner con animación de pulso

---

### 3️⃣ Notificación de Campaña Aprobada

**Cuándo:** Un admin aprueba una solicitud de campaña

```dart
// En Flutter/Dart
await supabase.from('notificaciones').insert({
  'user_id': creatorId,
  'tipo': 'solicitud_aprobada',
  'mensaje': '¡Tu campaña "$campaignTitle" ha sido aprobada!',
  'payload': {
    'campaign_id': campaignId,
    'solicitud_id': requestId,
  },
});
```

**Resultado:**
- ✅ Navega a la campaña aprobada
- ✅ El usuario puede verla inmediatamente

---

### 4️⃣ Notificación de Organización Aprobada

**Cuándo:** Un admin aprueba una organización

```dart
// En Flutter/Dart
await supabase.from('notificaciones').insert({
  'user_id': creatorId,
  'tipo': 'organizacion_aprobada',
  'mensaje': '¡Tu organización "$orgName" ha sido verificada!',
  'payload': {
    'organization_id': organizationId,
  },
});
```

**Resultado:**
- ✅ Navega a la organización
- ✅ Muestra banner azul "Organización verificada"

---

### 5️⃣ Notificación de Respuesta a Comentario

**Cuándo:** Alguien responde a tu comentario

```dart
// En Flutter/Dart
await supabase.from('notificaciones').insert({
  'user_id': originalCommenterId,
  'tipo': 'respuesta_comentario',
  'mensaje': '$replierName respondió a tu comentario',
  'payload': {
    'campaign_id': campaignId,
    'comment_id': replyCommentId,  // ID del comentario de respuesta
    'replier_name': replierName,
  },
});
```

**Resultado:**
- ✅ Navega a la campaña
- ✅ Hace scroll al comentario de respuesta
- ✅ Resalta la respuesta

---

## 🛠️ Implementación en el Backend

### Opción 1: Trigger Automático (Recomendado)

Crear un trigger que automáticamente crea la notificación cuando ocurre un evento:

```sql
-- Trigger para notificar cuando hay un nuevo comentario
CREATE OR REPLACE FUNCTION notify_new_comment()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar notificación para el dueño de la campaña
  INSERT INTO notificaciones (user_id, tipo, mensaje, payload)
  SELECT 
    c.user_id,
    'nuevo_comentario',
    format('%s comentó en tu campaña', NEW.author_name),
    jsonb_build_object(
      'campaign_id', NEW.campaign_id,
      'comment_id', NEW.id,
      'commenter_name', NEW.author_name
    )
  FROM campaigns c
  WHERE c.id = NEW.campaign_id
    AND c.user_id != NEW.author_id; -- No notificar si es el propio dueño

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_comment
  AFTER INSERT ON comentarios
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_comment();
```

### Opción 2: Función Reutilizable

```sql
-- Función para crear notificación de comentario
CREATE OR REPLACE FUNCTION create_comment_notification(
  p_campaign_id uuid,
  p_comment_id uuid,
  p_commenter_name text
)
RETURNS void AS $$
BEGIN
  INSERT INTO notificaciones (user_id, tipo, mensaje, payload)
  SELECT 
    c.user_id,
    'nuevo_comentario',
    format('%s comentó en tu campaña', p_commenter_name),
    jsonb_build_object(
      'campaign_id', p_campaign_id,
      'comment_id', p_comment_id,
      'commenter_name', p_commenter_name
    )
  FROM campaigns c
  WHERE c.id = p_campaign_id;
END;
$$ LANGUAGE plpgsql;

-- Uso:
SELECT create_comment_notification(
  'campaign-uuid'::uuid,
  'comment-uuid'::uuid,
  'Juan Pérez'
);
```

### Opción 3: Desde Flutter (Manual)

```dart
Future<void> createCommentNotification({
  required String campaignId,
  required String commentId,
  required String campaignOwnerId,
  required String commenterName,
}) async {
  await supabase.from('notificaciones').insert({
    'user_id': campaignOwnerId,
    'tipo': 'nuevo_comentario',
    'mensaje': '$commenterName comentó en tu campaña',
    'payload': {
      'campaign_id': campaignId,
      'comment_id': commentId,
      'commenter_name': commenterName,
    },
  });
}

// Llamar después de crear el comentario:
await createCommentNotification(
  campaignId: campaign.id,
  commentId: newComment.id,
  campaignOwnerId: campaign.creatorId,
  commenterName: currentUser.displayName,
);
```

---

## 📊 Tipos de Notificación Soportados

| Tipo | Campos Requeridos | Navegación |
|------|-------------------|------------|
| `nuevo_comentario` | `campaign_id`, `comment_id` | Campaña → Scroll a comentario |
| `respuesta_comentario` | `campaign_id`, `comment_id` | Campaña → Scroll a respuesta |
| `donacion_confirmada` | `campaign_id`, `donation_id` | Campaña → Banner verde |
| `nueva_donacion` | `campaign_id`, `donation_id` | Campaña → Banner verde |
| `solicitud_aprobada` | `campaign_id` | Campaña aprobada |
| `solicitud_rechazada` | `campaign_id` | Campaña rechazada |
| `organizacion_aprobada` | `organization_id` | Organización → Banner azul |
| `campaign_goal_reached` | `campaign_id` | Campaña completada |

---

## ⚠️ Errores Comunes

### ❌ Error: "Esta notificación no contiene el ID de la campaña"

**Causa:** El payload no tiene `campaign_id`

**Solución:**
```dart
// ❌ MAL
'payload': {
  'comment_id': commentId,  // Falta campaign_id
}

// ✅ BIEN
'payload': {
  'campaign_id': campaignId,  // Incluir siempre
  'comment_id': commentId,
}
```

### ❌ Error: El scroll no funciona

**Causa:** El `comment_id` no coincide con el ID real del comentario

**Solución:** Verificar que el ID sea correcto:
```dart
print('Comment ID en payload: ${payload['comment_id']}');
print('Comment ID en lista: ${comment.id}');
// Deben ser iguales
```

### ❌ Error: El highlight no aparece

**Causa:** El comentario no se encontró en la lista

**Solución:** Verificar que el comentario exista y sea visible:
```sql
SELECT * FROM comentarios WHERE id = 'comment-uuid';
```

---

## 🧪 Testing

### Test 1: Crear notificación de comentario

```dart
// Crear comentario
final comment = await campaignService.createComment(
  campaignId: campaign.id,
  message: 'Este es un comentario de prueba',
);

// Crear notificación
await supabase.from('notificaciones').insert({
  'user_id': campaign.creatorId,
  'tipo': 'nuevo_comentario',
  'mensaje': 'Alguien comentó en tu campaña',
  'payload': {
    'campaign_id': campaign.id,
    'comment_id': comment.id,
  },
});

// Verificar en la app:
// 1. Ir a notificaciones
// 2. Hacer clic en la notificación
// 3. Debe navegar a la campaña
// 4. Debe hacer scroll al comentario
// 5. El comentario debe tener borde azul pulsante
```

### Test 2: Crear notificación de donación

```dart
// Simular donación confirmada
await supabase.from('notificaciones').insert({
  'user_id': campaign.creatorId,
  'tipo': 'donacion_confirmada',
  'mensaje': 'Has recibido una donación de Bs 100.00',
  'payload': {
    'campaign_id': campaign.id,
    'donation_id': 'test-donation-uuid',
    'amount': 100.0,
  },
});

// Verificar en la app:
// 1. Ir a notificaciones
// 2. Hacer clic en la notificación
// 3. Debe navegar a la campaña
// 4. Debe mostrar banner verde en la parte superior
```

---

## 📈 Mejores Prácticas

### ✅ DO (Hacer)

- ✅ **Siempre incluir** `campaign_id`, `comment_id`, `donation_id` según el tipo
- ✅ **Verificar** que los IDs existen antes de crear la notificación
- ✅ **Usar triggers** para automatizar las notificaciones
- ✅ **Incluir datos extra** útiles (nombres, avatares, montos)
- ✅ **Mensajes descriptivos** y amigables

### ❌ DON'T (No hacer)

- ❌ **No omitir** los IDs requeridos en el payload
- ❌ **No crear notificaciones** para el propio usuario (excepto confirmaciones)
- ❌ **No usar tipos** de notificación incorrectos
- ❌ **No incluir datos sensibles** en el mensaje o payload
- ❌ **No crear notificaciones duplicadas**

---

## 🚀 Próximos Pasos

1. **Implementa los triggers** para automatizar las notificaciones
2. **Actualiza notificaciones antiguas** usando el script SQL proporcionado
3. **Prueba cada tipo** de notificación para asegurar que funcionan
4. **Monitorea errores** en los logs de navegación
5. **Ajusta mensajes** según el feedback de usuarios

---

## 📞 Soporte

Si encuentras problemas:
1. Verifica que el payload tenga todos los campos
2. Revisa los logs en `debugPrint` (busca 🔔 y ⚠️)
3. Consulta `docs/SISTEMA_NOTIFICACIONES_CONTEXTUAL.md`
4. Ejecuta `supabase/actualizar_payloads_notificaciones.sql`

---

¡Tu app ahora tiene notificaciones contextuales como las grandes apps! 🎉
