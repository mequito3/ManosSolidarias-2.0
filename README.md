# Manos Solidarias · Flutter + Supabase

Plataforma tipo Kickstarter enfocada en campañas solidarias verificadas, con Supabase como backend y Flutter como cliente móvil/web.

## Configuración rápida

1. **Dependencias**
	```bash
	flutter pub get
	```

2. **Variables de entorno Supabase**
	- Copia `.env.example` a `.env` y coloca las credenciales públicas de tu proyecto:
	  ```env
	  SUPABASE_URL=https://<tu-proyecto>.supabase.co
	  SUPABASE_ANON_KEY=tu_anon_key_publica
	  ```
	- En producción también puedes inyectarlas con `--dart-define`.

3. **Ejecutar la app**
	```bash
	flutter run
	```

### Obtención del anon key
- En Supabase: **Project Settings → API → Project API keys → anon public**.
- El proyecto ya incluye soporte para `.env`; el valor nunca debe ser el `service_role`.

### Proveedor Google
Para habilitar "Continuar con Google" en Supabase ve a **Authentication → Providers → Google** y agrega:
- Client ID y Client secret (OAuth consent de Google Cloud).
- Redirect URL: `supabase://login-callback` (móvil) y tu dominio web si aplica.

## Roles administrativos

Los permisos de administrador se controlan con la columna `is_admin` de la tabla `public.profiles`. Un usuario administrador puede aprobar campañas, donaciones y organizaciones desde el panel correspondiente.

1. Crea el usuario normalmente (email/password o Google). Supabase insertará su registro en `public.profiles` de forma automática.
2. Promuévelo a administrador mediante alguna de las siguientes opciones:

### Opción 1: Supabase Dashboard
- Entra a **Table editor → public → profiles**.
- Busca el `user_id` del usuario.
- Edita el registro y marca `is_admin = true`.
- Guarda los cambios y solicita al usuario que cierre y reabra sesión para recibir el nuevo rol.

### Opción 2: SQL directo
Ejecuta en el editor SQL de Supabase (o mediante el CLI usando la `service_role` fuera de la app):

```sql
update public.profiles
set is_admin = true
where user_id = '00000000-0000-0000-0000-000000000000';
```

Sustituye el `user_id` por el identificador real del usuario. El cambio se refleja en su siguiente sesión.

### Experiencia de administración
- Una vez que el usuario administrador inicia sesión, la app muestra el **Panel administrativo** con métricas y bandejas de pendientes (campañas, donaciones y organizaciones).
- Desde el panel se puede usar *Ver como usuario* para volver al `HomePage` regular y seguir explorando campañas.
- En la experiencia de usuario normal aparecerá un botón **Panel admin** en la barra superior para regresar rápidamente al panel.

## Estructura principal

```
lib/
├── models/          # Entidades y DTOs
├── services/        # Integraciones Supabase/API
├── controllers/     # Estado y lógica de negocio
├── pages/           # Vistas principales (políticas, etc.)
├── ui/              # Widgets específicos de la interfaz
│   ├── auth/
│   ├── onboarding/
│   └── widgets/
└── utils/           # Helpers compartidos (redirects, constantes)
```

## Más documentación
- `docs/dev_log.md`: historial de cambios relevante.
- `supabase/supabase.sql`: esquema de base de datos y políticas RLS.

---

Hecho con ❤️ para conectar donantes y causas confiables.
