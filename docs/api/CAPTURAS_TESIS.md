# Guía de capturas para la tesis — figuras de la API REST

Esta guía te lleva paso a paso por las **7 capturas** que tenés que sacar de
Swagger UI para las figuras de la tesis. Cada bloque te dice:

- **Qué endpoint** abrir
- **Qué pegar** en el body o headers
- **Qué Execute hacer**
- **Qué mostrar** en la captura

> Antes de empezar: **doble click en `docs/api/index.html`** y se abre Swagger UI
> en tu navegador. Eso es todo — no hace falta servidor ni Docker.
> Apuntate también `auth.users` en Supabase Studio por si necesitás copiar el
> `user_id` del usuario demo que vas a crear.

---

## Variables que vas a llenar mientras avanzás

Llevá esto a mano (papel/post-it):

| Variable | De dónde sale |
|---|---|
| `EMAIL_DEMO` | El que inventes en el paso 1 (ej: `tesis-demo@ejemplo.com`) |
| `ACCESS_TOKEN` | Response del paso 1 o 2 |
| `USER_ID` | Response del paso 1, campo `user.id` |
| `CAMPANIA_ID` | Lo sacás del listado del paso 4 |

---

## 📸 Figura 65 — Swagger: registro de usuario exitoso

**Objetivo:** mostrar que el endpoint de signup funciona y devuelve un token.

1. En Swagger UI, expandí el tag **Autenticación**.
2. Abrí **`POST /auth/v1/signup`** → **Try it out**.
3. En el body, dejá el ejemplo "registroBasico" pero cambiá el email a algo
   único (ej: `tesis-demo+f65@ejemplo.com`):

   ```json
   {
     "email": "tesis-demo+f65@ejemplo.com",
     "password": "Tesis2026!",
     "data": { "display_name": "Demo Tesis F65" }
   }
   ```

4. Click **Execute**.
5. **CAPTURA:** asegurate que se vea en la misma toma:
   - el path `POST /auth/v1/signup`
   - el request body (panel "Curl" o "Request URL")
   - el response **200** con el JSON que contiene `access_token`, `user.id`, `user.email`

6. **Copiá** el `access_token` y el `user.id` — los necesitás después.

---

## 📸 Figura 66 — Swagger: error en login con credenciales incorrectas

**Objetivo:** mostrar que el sistema rechaza credenciales mal puestas con
un **400** claro (importante para defender seguridad).

1. Abrí **`POST /auth/v1/token`** → **Try it out**.
2. Verificá que el query param `grant_type` esté en `password`.
3. En el body, pegá:

   ```json
   {
     "email": "tesis-demo+f65@ejemplo.com",
     "password": "estoEstaMal"
   }
   ```

4. Click **Execute**.
5. **CAPTURA:** que se vea:
   - el path `POST /auth/v1/token?grant_type=password`
   - el response **400** con `error_code: invalid_credentials`
   - el mensaje `"Invalid login credentials"`

---

## 📸 Figura 67 — Swagger: login exitoso (popula token)

**Objetivo:** mostrar el flujo correcto de login y cómo se autoriza la sesión.

1. Mismo endpoint, **`POST /auth/v1/token`** → **Try it out**.
2. Esta vez con la password correcta:

   ```json
   {
     "email": "tesis-demo+f65@ejemplo.com",
     "password": "Tesis2026!"
   }
   ```

3. **Execute**.
4. **CAPTURA:** response **200** con `access_token`, `expires_in: 3600`,
   `refresh_token` y objeto `user`.
5. **AHORA:** Click en **Authorize** (candado arriba a la derecha) → pegá el
   `access_token` en `bearerAuth` → Authorize → Close.
   (Esto deja la sesión activa para las próximas capturas.)

---

## 📸 Figura 68 — Endpoint protegido SIN token → 401

**Objetivo:** demostrar que sin sesión no se accede a datos privados (defiende RLS).

1. **Antes:** desautorizate. Click en **Authorize** → **Logout** → Close.
2. Abrí **`POST /rest/v1/solicitudes`** → Try it out.
3. Pegá body:

   ```json
   {
     "titulo": "Test sin token",
     "descripcion": "Esto NO deberia entrar",
     "tipo": "campania"
   }
   ```

4. Execute.
5. **CAPTURA:** response **401** con:
   ```json
   {
     "code": "42501",
     "message": "new row violates row-level security policy for table \"donaciones\""
   }
   ```
   (Este es el código de Postgres `42501` — violación de RLS. Si en cambio
   intentás un GET protegido sin Bearer, vas a ver `PGRST301`.)

> Tip: si ves un 200, es que olvidaste hacer logout en Swagger.
> Verificá el botón Authorize.

---

## 📸 Figura 69 — Crear solicitud autenticado → 201

**Objetivo:** mostrar el happy path del flujo "soy beneficiario y pido ayuda".

1. Volvé a autorizarte (Authorize → pegá el `ACCESS_TOKEN` del paso 3).
2. Abrí **`POST /rest/v1/solicitudes`** → Try it out.
3. Body:

   ```json
   {
     "titulo": "Operación urgente para mi hija",
     "descripcion": "Mi hija de 8 años necesita una cirugía. Adjunto documentación médica.",
     "tipo": "campania",
     "categoria_id": "8910ddc5-f70e-4984-95a3-2c7d367d7c0e",
     "monto_objetivo": 3000,
     "es_anonimo": false
   }
   ```

   > `categoria_id` arriba es el de "Salud", real de tu BD.

4. Execute.
5. **CAPTURA:** response **201** con el array que contiene la solicitud creada,
   `estado: "pendiente"`.

---

## 📸 Figura 70 — Listar campañas activas (RPC) → 200

**Objetivo:** mostrar el endpoint que efectivamente usa tu app para listar.

1. Abrí **`POST /rest/v1/rpc/list_public_campaigns`** → Try it out.
2. Body (vacío para "todas"):

   ```json
   {}
   ```

3. Execute.
4. **CAPTURA:** response **200** con array de campañas, mostrando columnas
   `titulo`, `porcentaje`, `donadores`, `categoria`, `monto_actual`.
5. **Copiá** el `id` de cualquier campaña → es tu `CAMPANIA_ID`.

> Alternativa: si querés mostrar el patrón PostgREST plano, usá
> **`GET /rest/v1/campanias`** con `estado=eq.activa`. Es más didáctico pero
> menos representativo de lo que hace la app.

---

## 📸 Figura 71 — Crear donación → 201

**Objetivo:** cerrar el flujo end-to-end con el caso de uso central.

1. Asegurate de seguir autorizado (botón Authorize verde).
2. Abrí **`POST /rest/v1/donaciones`** → Try it out.
3. Body (reemplazá `CAMPANIA_ID`):

   ```json
   {
     "campania_id": "<CAMPANIA_ID>",
     "monto": 50,
     "metodo": "qr",
     "mensaje": "¡Mucha fuerza!",
     "anonimo": false
   }
   ```

4. Execute.
5. **CAPTURA:** response **201** con la donación, `estado: "pendiente"`
   (queda pendiente hasta validación admin).

---

## 🎯 Resumen tabular — para el índice de figuras

| Figura | Endpoint | Método | Esperado | Demuestra |
|---|---|---|---|---|
| 65 | `/auth/v1/signup` | POST | 200 + token | Registro de usuario |
| 66 | `/auth/v1/token?grant_type=password` | POST | 400 invalid_credentials | Validación de credenciales |
| 67 | `/auth/v1/token?grant_type=password` | POST | 200 + token | Login exitoso |
| 68 | `/rest/v1/solicitudes` o `/donaciones` | POST | 401 code 42501 (RLS) | Seguridad RLS sin token |
| 69 | `/rest/v1/solicitudes` | POST | 201 | Creación autenticada |
| 70 | `/rest/v1/rpc/list_public_campaigns` | POST | 200 + array | Consulta pública |
| 71 | `/rest/v1/donaciones` | POST | 201 | Donación end-to-end |

---

## Checklist final antes de la defensa

- [ ] Doble click en `docs/api/index.html` abre Swagger UI con el título "Manos Solidarias"
- [ ] El navegador tiene internet (los requests reales van a Supabase)
- [ ] Endpoint público (`GET /rest/v1/campanias?estado=eq.activa`) devuelve **200** sin auth
- [ ] Endpoint protegido (`POST /rest/v1/solicitudes`) sin token devuelve **401**
- [ ] Tenés un email + password de prueba listos para no improvisar
- [ ] Tenés el `CAMPANIA_ID` ya copiado
- [ ] Las 7 capturas están guardadas en alta resolución (PNG, mínimo 1920×1080)
- [ ] Swagger UI está en modo "DOC_EXPANSION: list" para que se vea ordenado

---

## Notas finales

- **No uses la `service_role` key en la defensa.** Si te preguntan por las claves,
  explicá que la documentación usa la **anon key** (clave pública del cliente) y
  que la seguridad real la pone **RLS** en Postgres. Es el modelo correcto
  de Supabase.
- **Si una captura sale mal**, simplemente cambiá el email/sufijo y repetí.
  No estás bloqueando ningún recurso real porque las solicitudes quedan en
  estado `pendiente`.
- **Reset rápido entre capturas:** Authorize → Logout → Authorize → pegá token
  de nuevo. Mucho más rápido que cerrar el navegador.
