# Documentación API REST — Manos Solidarias

Documentación interactiva de la API REST del proyecto **Manos Solidarias**, servida
con **Swagger UI**. Sirve para la defensa de tesis (figuras 65, 66, 67…) y como
referencia técnica del backend.

## ¿Qué hay acá?

| Archivo | Para qué sirve |
|---|---|
| **`index.html`** | **Swagger UI listo para usar — doble click y listo** |
| `openapi.yaml` | Spec OpenAPI 3.1 "limpia" (si querés importarla en Postman, Insomnia, etc.) |
| `docker-compose.yml` | Alternativa offline con Docker (opcional) |
| `CAPTURAS_TESIS.md` | Guía paso a paso de las capturas para la tesis |
| `README.md` | Este archivo |

---

## 🚀 Cómo correrlo — la forma fácil

**Doble click en `index.html`.**

Eso es todo. Se abre en tu navegador, Swagger UI se renderiza, y podés
empezar a probar endpoints directo.

Requisitos:
- Tener internet (los assets de Swagger UI cargan desde un CDN público)
- Cualquier navegador moderno (Chrome, Edge, Firefox)

> El `openapi.yaml` está **embebido dentro del `index.html`**, así que no
> hay que levantar servidor, ni Docker, ni Python. Por eso funciona con
> `file://` sin problemas de CORS.

### Para la defensa

1. Antes de subir al estrado: abrí `index.html` en tu navegador.
2. Dejá la pestaña abierta. Si la cerrás sin querer, doble click otra vez.
3. Los requests reales (Try it out) van directo a Supabase — necesitás
   internet sí o sí porque la base de datos vive en la nube.

---

## Alternativa: Docker (si no tenés internet)

Si vas a defender en un aula sin internet, levantá esto la noche anterior
y dejá el contenedor corriendo:

```powershell
cd docs\api
docker compose up -d
```

Abrí: **<http://localhost:8080>**

> ⚠️ Igual los requests "Try it out" no van a funcionar sin internet (Supabase
> está en la nube). Lo único que Docker te asegura es que Swagger UI cargue
> visualmente para mostrarlo en pantalla.

---

## Cómo usar la documentación

### 1. Autenticarse

1. Abrí el endpoint **`POST /auth/v1/signup`** o **`POST /auth/v1/token`**.
2. Click en **Try it out** → pegá el body de ejemplo (ya viene cargado).
3. Click en **Execute**.
4. Copiá el `access_token` del response.
5. Click en el botón **Authorize** (candado, arriba a la derecha).
6. En el campo `bearerAuth`, pegá el token. Click **Authorize** → **Close**.

Listo: ahora todos los endpoints protegidos enviarán el `Authorization: Bearer …`
automáticamente.

### 2. La `apikey` (anon key)

Ya viene **embebida en la spec** como valor por defecto del esquema `apiKey`.
No tenés que tocarla. Si por alguna razón el botón Authorize te la pide:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...JYqNlbGkVSgAuTKhmGCNwsQYGkrk3y0d3z1-gmr91EY
```

> ⚠️ Esta es la **anon key pública** del proyecto Supabase. Está pensada para ser
> visible en clientes (es lo mismo que la app Flutter usa). La `service_role`
> key **nunca** se documenta acá.

---

## Variables de entorno (cómo cambiarlas)

Si rotás el proyecto Supabase o cambiás región, editá en `openapi.yaml`:

| Qué cambiar | Dónde |
|---|---|
| URL del backend | `servers[0].url` (línea ~40) |
| Anon key | Buscá `eyJhbGci…` en los ejemplos y reemplazala |
| Email/password de ejemplo | Sección `components.schemas.SignupRequest` y `LoginRequest` |

Después de editar, recargá `http://localhost:8080` (F5).

---

## Probarlo sin Swagger UI (sanity check)

Si querés verificar que el backend responde antes de la defensa:

```powershell
# Endpoint público — debería devolver array JSON
curl.exe -H "apikey: eyJhbGci...gmr91EY" `
  "https://gvdlsypoqstbifdbhafv.supabase.co/rest/v1/campanias?estado=eq.activa&select=id,titulo,estado&limit=3"

# Endpoint protegido SIN token — debería devolver 401
curl.exe -H "apikey: eyJhbGci...gmr91EY" `
  "https://gvdlsypoqstbifdbhafv.supabase.co/rest/v1/donaciones?select=*"
```

---

## Estructura de seguridad documentada

| Capa | Cómo se documenta |
|---|---|
| `apikey` header (anon) | `securitySchemes.apiKey` — global, obligatorio en todas |
| JWT del usuario | `securitySchemes.bearerAuth` — sólo donde se requiere login |
| RLS de Postgres | Se ve en el response 401 (`PGRST301`) de endpoints protegidos |

> **Importante para la defensa:** el modelo de seguridad NO es "auth en el backend"
> al estilo Django/Express. Es PostgREST + RLS: el JWT viaja en el header, Supabase
> lo valida, y las políticas RLS de cada tabla deciden qué filas devolver/aceptar.

---

## Troubleshooting

**Swagger UI no abre / "site can't be reached"**
- Verificá que Docker Desktop esté corriendo
- `docker compose ps` → debería mostrar el contenedor como `Up`
- `docker compose logs` para ver errores

**"Failed to fetch" al hacer Execute**
- Es CORS. Supabase tiene CORS abierto, así que esto suele ser por el `apikey`
  faltante o un token caducado.
- Re-autorizate desde el botón Authorize.

**El token expira durante la defensa**
- Hacé login de nuevo (token vive 1h por defecto en Supabase) y re-autorizate.
- Alternativa: usá el `refresh_token` con `POST /auth/v1/token?grant_type=refresh_token`.

---

## ¿Por qué Swagger UI y no Postman?

| | Swagger UI | Postman |
|---|---|---|
| Instalación en jurado | Cero (es un browser) | Requiere instalar Postman |
| Estética para defensa | Limpia, profesional | Más cargada |
| Documentación + ejecución | Una sola cosa | Separadas |
| Generar la spec desde código | Sí, OpenAPI estándar | Formato propio |

Si querés *también* la colección Postman, abrí Postman → **Import** → pegá el
archivo `openapi.yaml`. Postman la convierte automáticamente.
