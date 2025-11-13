# K6 Load Testing para Manos Solidarias

## 📋 Descripción

Este script de K6 realiza pruebas de carga completas sobre la aplicación Manos Solidarias, simulando usuarios reales que:

- Se registran en la aplicación
- Inician sesión
- Crean solicitudes de campaña con imágenes
- Crean organizaciones
- Crean kermesses con ubicaciones geográficas
- Navegan por campañas existentes
- Consultan perfiles de usuario

## 🎯 Escenarios de Prueba

El script incluye tres tipos de flujos de usuario:

1. **Flujo Completo (70% de usuarios)**: Registro → Login → Ver campañas → Crear solicitud con imagen → Crear organización → Crear kermesse → Ver perfil

2. **Flujo de Navegación (20% de usuarios)**: Registro → Ver campañas → Ver perfil

3. **Flujo de Registro Simple (10% de usuarios)**: Solo registro

## 📊 Configuración de Carga

El test simula carga gradual:

- **0-30s**: Ramp-up a 5 usuarios
- **30s-1m30s**: Ramp-up a 10 usuarios
- **1m30s-3m30s**: Mantener 10 usuarios
- **3m30s-4m**: Spike a 20 usuarios
- **4m-5m**: Mantener 20 usuarios
- **5m-5m30s**: Ramp-down a 5 usuarios
- **5m30s-6m**: Ramp-down a 0 usuarios

**Duración total**: ~6 minutos

## 🔧 Requisitos Previos

1. **Instalar K6**:

   Windows (usando Chocolatey):
   ```cmd
   choco install k6
   ```

   O descarga desde: https://k6.io/docs/getting-started/installation/

2. **Obtener credenciales de Supabase**:
   - Abre tu proyecto en Supabase Dashboard
   - Ve a Settings → API
   - Copia el **Project URL** (ej: `https://xxx.supabase.co`)
   - Copia el **anon public** key

## 🚀 Cómo Ejecutar el Test

### Opción 1: Variables de entorno (Recomendado)

```cmd
set SUPABASE_URL=https://tu-proyecto.supabase.co
set SUPABASE_ANON_KEY=tu-anon-key-aqui
k6 run k6\load-test.js
```

### Opción 2: Editar el archivo directamente

Edita `load-test.js` líneas 14-15:
```javascript
const SUPABASE_URL = 'https://tu-proyecto.supabase.co';
const SUPABASE_ANON_KEY = 'tu-anon-key-aqui';
```

Luego ejecuta:
```cmd
k6 run k6\load-test.js
```

### Opción 3: Pasar como argumentos

```cmd
k6 run -e SUPABASE_URL=https://tu-proyecto.supabase.co -e SUPABASE_ANON_KEY=tu-anon-key k6\load-test.js
```

## 📈 Métricas Monitoreadas

### Métricas Estándar de K6:
- **http_req_duration**: Duración de las peticiones HTTP
- **http_req_failed**: Tasa de fallos en peticiones
- **http_reqs**: Número total de peticiones
- **iterations**: Iteraciones completadas
- **vus**: Usuarios virtuales activos

### Métricas Personalizadas:
- **errors**: Tasa de errores general
- **auth_duration**: Tiempo de autenticación (registro/login)
- **campaign_creation_duration**: Tiempo para crear solicitudes
- **organization_creation_duration**: Tiempo para crear organizaciones
- **kermesse_creation_duration**: Tiempo para crear kermesses
- **upload_duration**: Tiempo de subida de imágenes
- **requests_total**: Contador total de peticiones

### Umbrales de Éxito:
- ✅ 95% de peticiones < 2 segundos
- ✅ Tasa de fallos < 5%
- ✅ Tasa de errores < 10%
- ✅ Autenticación < 3 segundos
- ✅ Creación de campañas < 5 segundos

## 📊 Interpretar Resultados

### Ejemplo de salida exitosa:
```
✓ registration status is 200
✓ login returns access token
✓ image upload status is 200 or 201
✓ solicitud creation status is 201
✓ organization creation status is 201
✓ kermesse creation status is 201

checks.........................: 95.00% ✓ 950  ✗ 50
data_received..................: 2.5 MB 417 kB/s
data_sent......................: 1.2 MB 200 kB/s
errors.........................: 5.00%  ✓ 50
http_req_duration..............: avg=850ms min=200ms med=750ms max=1.5s p(95)=1.2s
http_reqs......................: 1000   166.666667/s
iterations.....................: 100    16.666667/s
vus............................: 1      min=1 max=20
```

### Banderas rojas 🚩:
- ❌ `http_req_failed > 5%`: Muchas peticiones fallando
- ❌ `p(95) > 2000ms`: Respuestas muy lentas
- ❌ `errors > 10%`: Lógica de negocio con problemas
- ❌ Checks fallando consistentemente

## 🔍 Debugging

### Ver logs detallados:
```cmd
k6 run --verbose k6\load-test.js
```

### Ejecutar con menos usuarios (prueba rápida):
```cmd
k6 run --vus 2 --duration 30s k6\load-test.js
```

### Exportar resultados a JSON:
```cmd
k6 run --out json=resultado.json k6\load-test.js
```

### Exportar a InfluxDB (para análisis avanzado):
```cmd
k6 run --out influxdb=http://localhost:8086/k6 k6\load-test.js
```

## 🎨 Personalización

### Cambiar la duración del test:

Edita la sección `options.stages` en `load-test.js`:
```javascript
stages: [
  { duration: '1m', target: 10 },   // 1 minuto con 10 usuarios
  { duration: '3m', target: 50 },   // 3 minutos con 50 usuarios
  { duration: '1m', target: 0 },    // 1 minuto ramp-down
],
```

### Cambiar los umbrales:

Edita la sección `options.thresholds`:
```javascript
thresholds: {
  http_req_duration: ['p(95)<3000'], // Más permisivo: 3 segundos
  http_req_failed: ['rate<0.10'],    // Permitir 10% de fallos
},
```

### Usar imágenes diferentes:

Cambia la constante `TEST_IMAGE_URL` (línea 17):
```javascript
const TEST_IMAGE_URL = 'https://source.unsplash.com/800x600/?charity';
```

## 🛡️ Consideraciones de Seguridad

⚠️ **IMPORTANTE**: 
- Este test crea datos reales en tu base de datos
- Los usuarios de prueba tienen emails como `test_user_*@example.com`
- Se recomienda ejecutar en un ambiente de prueba, NO en producción
- Después del test, puedes limpiar usuarios de prueba con:

```sql
-- Ejecutar en Supabase SQL Editor
DELETE FROM auth.users WHERE email LIKE '%@example.com';
```

## 📝 Datos Generados

Durante el test se crean:
- ✉️ Usuarios con emails `test_user_[timestamp]_[random]@example.com`
- 📸 Imágenes en Storage: `users/[userId]/solicitudes/covers/`
- 📋 Solicitudes con títulos "Campaña de Prueba [timestamp]"
- 🏢 Organizaciones con nombres "Organización Test [timestamp]"
- 🎪 Kermesses con nombres "Kermesse Test [timestamp]"
- 📍 Ubicaciones con coordenadas aleatorias (área de Bolivia)

## 🎓 Para tu Tesis

Este test demuestra:

1. **Escalabilidad**: La app puede manejar múltiples usuarios concurrentes
2. **Rendimiento**: Tiempos de respuesta bajo carga
3. **Estabilidad**: Tasa de errores bajo diferentes niveles de carga
4. **Capacidad**: Picos de tráfico (spike testing)
5. **Experiencia de usuario**: Métricas de latencia percibida

### Incluir en documentación:

```
Pruebas de Carga (K6):
- Usuarios concurrentes máximos: 20
- Duración del test: 6 minutos
- Peticiones totales: ~1000
- Tasa de éxito: >95%
- Tiempo de respuesta P95: <2s
- Funcionalidades probadas: Registro, login, CRUD de campañas, organizaciones, kermesses
```

## 🆘 Solución de Problemas

### Error: "Cannot connect to Supabase"
- Verifica que SUPABASE_URL sea correcto
- Verifica conectividad a internet
- Prueba acceder a `${SUPABASE_URL}/rest/v1/` en el navegador

### Error: "401 Unauthorized"
- Verifica que SUPABASE_ANON_KEY sea correcto
- Asegúrate de usar el **anon public** key, no el **service_role** key

### Error: "new row violates row-level security policy"
- Las políticas RLS de Supabase están bloqueando las operaciones
- Revisa los permisos en Supabase Dashboard → Authentication → Policies
- Asegúrate de que los usuarios autenticados puedan crear solicitudes/organizaciones

### Uploads fallan con 403
- Verifica políticas de Storage en Supabase Dashboard → Storage → Policies
- El bucket "documentos" debe permitir INSERT/UPDATE para usuarios autenticados
- Verifica que el usuario tenga permisos en la ruta `users/[userId]/solicitudes/`

### "Image download status is 200" falla
- El servicio picsum.photos puede estar caído
- Cambia TEST_IMAGE_URL a otra URL pública de imagen
- Usa: `https://via.placeholder.com/800x600` como alternativa

## 📚 Recursos Adicionales

- [K6 Documentation](https://k6.io/docs/)
- [K6 Examples](https://k6.io/docs/examples/)
- [Supabase Rate Limits](https://supabase.com/docs/guides/platform/going-into-prod#rate-limiting-resource-allocation--abuse-prevention)
- [Best Practices for Load Testing](https://k6.io/docs/testing-guides/load-testing-websites/)

## 📧 Soporte

Si encuentras problemas:
1. Revisa los logs con `--verbose`
2. Verifica las políticas RLS en Supabase
3. Prueba con un solo usuario: `--vus 1 --duration 10s`
4. Revisa la consola de Supabase para errores del lado del servidor
