# 🔴 HABILITAR REALTIME EN SUPABASE

## ⚠️ IMPORTANTE: Pasos necesarios para que funcione la actualización en tiempo real

El código ya está configurado, pero **DEBES HABILITAR REALTIME** en el Dashboard de Supabase.

---

## 📋 Pasos para habilitar Realtime:

### 1. Ejecutar el script SQL actualizado

Primero, asegúrate de ejecutar el archivo `supabase/supabase.sql` completo en tu base de datos.
Esto configura `REPLICA IDENTITY FULL` en las tablas necesarias.

### 2. Ir al Dashboard de Supabase

1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto **ManosSolidarias**
3. En el menú lateral, ve a **Database** → **Replication**

### 3. Habilitar las tablas para Realtime

En la sección **Replication**, debes **HABILITAR** las siguientes tablas:

- ✅ **campania** (para actualizar campañas en tiempo real)
- ✅ **donacion** (para actualizar donaciones, ranking, progreso)
- ✅ **organizacion** (para actualizar organizaciones)
- ✅ **notificaciones** (ya debería estar habilitado)
- ✅ **comentarios** (para actualizar comentarios)
- ✅ **favoritos** (para actualizar favoritos)

**Cómo habilitar:**
1. Busca cada tabla en la lista
2. Haz clic en el toggle/switch para **habilitarla**
3. Aparecerá en verde cuando esté activa

### 4. Verificar que esté funcionando

Después de habilitar las tablas:

1. Reinicia la app Flutter (Hot Restart completo)
2. Abre la app en 2 dispositivos/ventanas diferentes
3. Haz una donación desde un dispositivo
4. Deberías ver la actualización automática en el otro dispositivo en **1-2 segundos**

---

## 🔍 Logs de verificación

Cuando el realtime esté funcionando correctamente, verás estos logs en la consola:

```
✅ CampaignController: Subscribed to realtime updates
✅ OrganizationController: Subscribed to realtime updates
✅ DonorTrophyController: Subscribed to realtime updates
✅ NotificationController: Subscribed to realtime updates

🔄 CampaignController: Realtime update detected, refreshing...
```

Si NO ves estos logs, significa que el realtime no está habilitado en Supabase.

---

## 🎯 Qué se actualiza automáticamente:

Una vez habilitado Realtime, estos elementos se actualizarán automáticamente:

### En el HOME:
- 💰 **Montos recaudados** de campañas
- 📊 **Porcentaje de progreso** (barras de progreso)
- 👥 **Número de donadores**
- 🏆 **Ranking solidario** (posiciones, niveles, montos totales)
- ⭐ **Campañas cerca de la meta**
- 🆕 **Campañas recién lanzadas**
- 🏢 **Organizaciones nuevas**

### En las páginas individuales:
- 🔔 **Notificaciones** (nuevas aparecen automáticamente)
- 💬 **Comentarios nuevos**
- ❤️ **Favoritos**

---

## ⚡ Optimizaciones implementadas:

### Debounce Timer
Para evitar múltiples refreshes innecesarios:
- **Campañas**: 500ms de espera antes de refrescar
- **Ranking**: 1 segundo de espera (cálculos más complejos)

Esto significa que si hay varios cambios seguidos, se agrupa en una sola actualización.

### Suscripciones automáticas
Los controladores se suscriben automáticamente al iniciar la app y se desuscriben al cerrarla.

---

## 🐛 Troubleshooting

### Problema: "No se actualiza en tiempo real"
**Solución:**
1. Verifica que las tablas estén habilitadas en Database → Replication
2. Ejecuta el SQL completo (especialmente la sección 18)
3. Reinicia la app completamente (no solo hot reload)

### Problema: "Demasiadas actualizaciones"
**Solución:**
- El debounce timer ya está implementado
- Si aún es un problema, aumenta el tiempo en los controladores

### Problema: "No veo los logs de suscripción"
**Solución:**
- Verifica que `subscribeToRealtime()` se esté llamando en `home_page.dart`
- Revisa la consola de Supabase por errores de permisos

---

## 📝 Notas adicionales

- El realtime funciona a través de **PostgreSQL LISTEN/NOTIFY**
- Supabase usa **WebSockets** para mantener la conexión
- No consume datos excesivos (solo envía cambios, no todo el dataset)
- Es instantáneo (latencia típica: 100-500ms)

---

## ✅ Checklist final

- [ ] SQL ejecutado con la sección 18 (REPLICA IDENTITY)
- [ ] Tablas habilitadas en Supabase Dashboard → Database → Replication
- [ ] App reiniciada completamente
- [ ] Logs de suscripción visibles en consola
- [ ] Prueba con 2 dispositivos funcionando correctamente

---

🎉 **¡Listo!** Ahora tu app se actualiza en tiempo real sin necesidad de pull-to-refresh.
