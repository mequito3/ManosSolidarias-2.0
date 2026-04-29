# ManosSolidarias 2.0

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-blue)

> Plataforma móvil y web de donaciones para campañas benéficas verificadas, construida con Flutter y Supabase.

---

## ✨ Características

- **Campañas verificadas** — sistema de moderación y aprobación de campañas desde un panel de administración dedicado
- **Donaciones** — los usuarios pueden explorar campañas activas y registrar donaciones de forma segura
- **Panel de administración** — dashboard completo para moderar campañas, gestionar donaciones y supervisar la plataforma
- **Autenticación dual** — Email/contraseña y Google OAuth, con sesiones gestionadas por Supabase Auth
- **Seguridad a nivel de fila (RLS)** — políticas de Row Level Security en PostgreSQL para control de acceso granular
- **Multiplataforma** — una sola base de código corre en Android, iOS, Web y Desktop (Linux, macOS, Windows)
- **Load testing incluido** — suite de pruebas de carga con k6 para validar el comportamiento bajo stress

---

## 📱 Plataformas soportadas

| Plataforma | Estado    |
|------------|-----------|
| Android    | ✅ Testeado en producción |
| iOS        | 🔧 Compilable, no testeado |
| Web        | 🔧 Compilable, no testeado |
| Linux      | 🔧 Compilable, no testeado |
| macOS      | 🔧 Compilable, no testeado |
| Windows    | 🔧 Compilable, no testeado |

---

## 🏗️ Arquitectura

```
Flutter App (Mobile / Web / Desktop)
         │
         ├──► Supabase Auth      (Email/Password · Google OAuth · RLS)
         ├──► Supabase Database  (PostgreSQL · esquema completo 73KB)
         └──► Supabase Storage   (assets de campañas)
```

La aplicación consume directamente la API de Supabase desde Flutter. Las políticas RLS garantizan que cada rol (usuario, admin) acceda únicamente a los datos que le corresponden, sin lógica de permisos duplicada en el cliente.

---

## 🛠️ Stack

| Capa | Tecnología |
|---|---|
| Frontend / Mobile / Desktop | Flutter 3.x · Dart 3.x |
| Backend as a Service | Supabase (PostgreSQL + Auth + Realtime + Storage) |
| Autenticación | Supabase Auth · Google OAuth 2.0 |
| Base de datos | PostgreSQL con RLS (esquema ~73KB) |
| Hosting web | Firebase Hosting |
| Load testing | k6 |

---

---

## 🚀 Instalación

### Requisitos previos

- Flutter SDK 3.x o superior (`flutter --version`)
- Dart 3.x (incluido con Flutter)
- Cuenta en [Supabase](https://supabase.com) con un proyecto activo
- (Opcional) Google Cloud project configurado para OAuth

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/mequito3/ManosSolidarias-2.0.git
cd ManosSolidarias-2.0

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales de Supabase:
# SUPABASE_URL=https://<tu-proyecto>.supabase.co
# SUPABASE_ANON_KEY=<tu-anon-key>

# 4. Correr la app
flutter run                  # dispositivo/emulador detectado automáticamente
flutter run -d chrome        # forzar web
flutter run -d windows       # forzar desktop
```

---

## ⚙️ Configuración de Supabase

1. **Aplicar el esquema de base de datos**

   En el SQL Editor de tu proyecto Supabase, ejecutar el archivo completo:

   ```
   supabase/supabase.sql
   ```

   Este archivo incluye tablas, relaciones, funciones, triggers y políticas RLS.

2. **Verificar las políticas RLS**

   Confirmar que Row Level Security esté habilitado en todas las tablas sensibles desde *Table Editor → RLS*.

3. **Configurar Google OAuth**

   En *Authentication → Providers → Google*, cargar el Client ID y Client Secret de tu proyecto en Google Cloud Console. Agregar la URL de callback de Supabase como redirect URI autorizado.

4. **Variables de entorno**

   | Variable | Descripción |
   |---|---|
   | `SUPABASE_URL` | URL del proyecto Supabase |
   | `SUPABASE_ANON_KEY` | Clave pública anon del proyecto |

---

## 📁 Estructura del proyecto

```
ManosSolidarias-2.0/
├── lib/                  # Código fuente Flutter (Dart)
├── android/              # Configuración Android
├── ios/                  # Configuración iOS
├── web/                  # Entry point web
├── linux/ macos/ windows/# Entry points desktop
├── assets/               # Recursos estáticos
├── supabase/
│   └── supabase.sql      # Esquema completo de base de datos
├── k6/                   # Scripts de load testing
├── docs/                 # Documentación técnica adicional
└── test/                 # Tests unitarios y de widget
```

---

## 🔬 Load Testing

El directorio `k6/` contiene scripts de pruebas de carga para simular tráfico concurrente sobre los endpoints de Supabase. Esto permite validar el comportamiento de la plataforma bajo stress antes de un release.

```bash
# Requisito: k6 instalado (https://k6.io/docs/get-started/installation/)
k6 run k6/<script>.js
```

---

## 📝 Estado

🔧 En desarrollo activo — último commit: diciembre 2025. App funcional con backend real conectado.

---

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor, abrir un issue describiendo el cambio propuesto antes de enviar un pull request.

---

## 📄 Licencia

Este proyecto no especifica licencia explícita. Para cualquier uso o colaboración, contactar al autor.

---

## 👤 Autor

Américo Álvarez · [@mequito3](https://github.com/mequito3) · americooficial23@gmail.com
