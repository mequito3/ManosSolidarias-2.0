# 🎯 Guía para Exposición: Manos Solidarias
**Sistema de Donaciones y Campañas Solidarias**

---

## 📋 ESTRUCTURA DE LA PRESENTACIÓN (15-20 minutos)

### 1. INTRODUCCIÓN (2 minutos)
**¿Qué presentar?**
- Nombre del proyecto: **Manos Solidarias**
- Tipo de aplicación: Plataforma de crowdfunding solidario tipo Kickstarter
- Problema que resuelve: Falta de transparencia en donaciones y dificultad para conectar donantes con causas verificadas

**Frase inicial sugerida:**
> "Manos Solidarias es una plataforma que conecta a personas que necesitan ayuda con donantes solidarios, garantizando transparencia total mediante validación de campañas, verificación de identidad y comprobantes de uso de fondos."

---

## 🎭 2. DEMOSTRACIÓN DE ROLES (8-10 minutos)

### **ROL 1: Usuario Donante** (3 minutos)
**Flujo a mostrar:**

1. **Registro/Login**
   - Autenticación con Supabase
   - Validación de correo electrónico

2. **Explorar Campañas**
   - Ver campañas activas en el feed principal
   - Filtrar por categorías (Salud, Educación, Vivienda, etc.)
   - Ver progreso en tiempo real (Bs. recaudados / meta)
   - Sistema de ordenamiento (Recientes, Cerca del objetivo, Destacadas)

3. **Realizar Donación**
   - Seleccionar campaña
   - Ingresar monto y datos de contacto
   - Subir comprobante de pago (QR/transferencia)
   - **IMPORTANTE:** Explicar que NO hay custodia de fondos (transparencia)
   - Estado: "Pendiente de validación por administrador"

4. **Funcionalidades Adicionales**
   - Agregar campañas a favoritos ⭐
   - Ver historial de donaciones
   - Recibir notificaciones de progreso (25%, 50%, 75%, 100%)
   - Ver sistema de trofeos por nivel de donaciones:
     * 🥉 Bronce: 100-999 Bs
     * 🥈 Plata: 1,000-4,999 Bs
     * 🥇 Oro: 5,000-9,999 Bs
     * 💎 Platino: 10,000+ Bs

---

### **ROL 2: Creador de Campañas** (3 minutos)
**Flujo a mostrar:**

1. **Completar Perfil**
   - Datos personales completos (nombre, teléfono, ciudad)
   - Documento de identidad (CI/Pasaporte)
   - Datos bancarios (para recibir fondos)
   - **Explicar:** Validación KYC (Know Your Customer)

2. **Crear Solicitud de Campaña**
   - Título y descripción detallada
   - Monto objetivo (Bs)
   - Categoría
   - Imagen de portada
   - QR de pago personal (NO custodia)
   - Documentos de respaldo (certificados médicos, cotizaciones, etc.)

3. **Estados de la Solicitud**
   - 🟠 **Pendiente:** En revisión por el administrador
   - 🟢 **Aprobada:** Publicada y visible para donantes
   - 🔴 **Rechazada:** Con motivo de rechazo
   - **Demostrar:** Página "Mis solicitudes" con badges de estado

4. **Gestionar Campañas Aprobadas**
   - Ver progreso en tiempo real
   - Subir evidencias del uso de fondos (fotos, facturas, recibos)
   - Eliminar solicitudes pendientes sin donaciones

---

### **ROL 3: Administrador** (2-3 minutos)
**Flujo a mostrar:**

1. **Panel de Control**
   - Dashboard con métricas globales:
     * Total de campañas activas/completadas
     * Montos totales recaudados
     * Usuarios registrados
     * Donaciones pendientes de validación

2. **Validación de Solicitudes**
   - Revisar solicitudes pendientes
   - Verificar documentos de respaldo
   - Validar identidad del creador (KYC)
   - **Aprobar** o **Rechazar** con motivo

3. **Validación de Donaciones**
   - Ver donaciones pendientes
   - Verificar comprobantes de pago subidos
   - Aprobar → Se actualiza el progreso de la campaña
   - Rechazar → Se notifica al donante

4. **Gestión de Organizaciones**
   - Verificar organizaciones que crean campañas
   - Validar documentos legales (NIT, estatutos, etc.)

5. **Supervisión de Evidencias**
   - Revisar evidencias subidas por creadores
   - Asegurar uso correcto de fondos

---

## 🏗️ 3. ARQUITECTURA TÉCNICA (3-4 minutos)

### **Frontend**
```
Flutter 3.8.1 (Multiplataforma)
├── Android
├── iOS
└── Web (Firebase Hosting)
```

**Características:**
- UI moderna con Material Design 3
- Responsive (móvil, tablet, web)
- Widgets reutilizables y modulares
- Manejo de estado con ChangeNotifier

### **Backend**
```
Supabase (PostgreSQL + Auth + Storage)
├── Authentication (correo/contraseña)
├── Base de datos relacional
├── Row Level Security (RLS)
└── Storage para imágenes
```

**Tablas principales:**
- `profiles`: Usuarios y datos KYC
- `solicitudes`: Peticiones de campañas
- `campanias`: Campañas aprobadas y publicadas
- `donaciones`: Registro de donaciones con comprobantes
- `organizaciones`: ONGs verificadas
- `evidencias`: Comprobantes de uso de fondos

### **Seguridad**
- ✅ RLS (Row Level Security) en todas las tablas
- ✅ Validación de permisos por rol
- ✅ Autenticación con tokens JWT
- ✅ No custodia de fondos (usuarios donan directamente)
- ✅ Sistema de QR Proxy (protección del QR real)

---

## 🎨 4. FUNCIONALIDADES DESTACADAS (2 minutos)

### **RF01-RF25: Requerimientos Funcionales Implementados**

**Básicos:**
- ✅ RF01: Registro y autenticación
- ✅ RF02: Perfil completo con validación KYC
- ✅ RF03: Crear solicitudes de campaña
- ✅ RF04: Aprobar/rechazar campañas (admin)
- ✅ RF05: Eliminar solicitudes pendientes

**Donaciones:**
- ✅ RF06: Realizar donación con comprobante
- ✅ RF07: Validar donaciones (admin)
- ✅ RF08: Sistema de favoritos
- ✅ RF09: Historial de donaciones
- ✅ RF10: Ranking solidario con trofeos

**Transparencia:**
- ✅ RF11: Subir evidencias de uso de fondos
- ✅ RF12: Validar evidencias (admin)
- ✅ RF13: Progreso en tiempo real
- ✅ RF14: Notificaciones de hitos (25%, 50%, 75%, 100%)

**Avanzadas:**
- ✅ RF15: Filtros por categoría
- ✅ RF16: Ordenamiento de campañas
- ✅ RF17: Búsqueda de campañas
- ✅ RF18: Panel administrativo completo
- ✅ RF19: Gestión de organizaciones verificadas
- ✅ RF20: Sistema de trofeos por nivel
- ✅ RF21: Campañas completadas (archivo)
- ✅ RF22: Notificaciones push
- ✅ RF23: Compartir campañas
- ✅ RF24: Mensajería consistente (AppSnackBar)
- ✅ RF25: Información de sistema de trofeos

---

## 📊 5. DEMO EN VIVO (si es posible)

**URL de la aplicación:**
🌐 https://manos-solidarias-9a648.web.app

**Cuentas de prueba recomendadas:**
1. **Usuario donante:** `donante@test.com`
2. **Creador de campaña:** `creador@test.com`
3. **Administrador:** `admin@test.com`

*(Prepara estas cuentas antes de la exposición)*

---

## 💡 6. CASOS DE USO REALES

**Ejemplo 1: Campaña de Salud**
> María necesita una cirugía urgente que cuesta 15,000 Bs. Crea una solicitud con certificado médico y cotizaciones. El admin verifica los documentos y aprueba la campaña. Los donantes pueden ver el progreso en tiempo real y María sube fotos del hospital como evidencia.

**Ejemplo 2: Proyecto Educativo**
> Una escuela necesita computadoras. Crea la campaña con cotizaciones de equipos. Los donantes aportan, el admin valida cada donación, y la escuela sube fotos de las computadoras instaladas como evidencia.

---

## 🎯 7. DIFERENCIADORES CLAVE

**¿Qué hace única a Manos Solidarias?**

1. **NO custodia de fondos**
   - Transparencia total
   - Donantes transfieren directo al beneficiario
   - Menos riesgo legal y financiero

2. **Validación manual estricta**
   - Admin revisa cada campaña
   - KYC obligatorio
   - Documentos de respaldo requeridos

3. **Sistema de evidencias**
   - Creadores deben probar uso de fondos
   - Fotos, facturas, recibos
   - Aumenta confianza de donantes

4. **Gamificación solidaria**
   - Trofeos por nivel de donaciones
   - Ranking de top donantes
   - Motiva participación continua

5. **Multiplataforma**
   - Android, iOS, Web
   - Una sola base de código (Flutter)

---

## 🚀 8. FUTURAS MEJORAS (mencionar al final)

**Próximas funcionalidades:**
- 📱 Notificaciones push en tiempo real
- 🗺️ Mapa de campañas por ubicación
- 📧 Newsletter de campañas destacadas
- 💬 Chat directo donante-creador
- 📊 Reportes PDF descargables
- 🎫 Sistema de eventos/kermesses
- 🏆 Recompensas para donantes frecuentes
- 🔗 Integración con pasarelas de pago

---

## 📝 9. CONCLUSIÓN (1 minuto)

**Mensaje final:**
> "Manos Solidarias demuestra que es posible crear una plataforma de donaciones transparente, segura y eficiente usando tecnologías modernas. La combinación de Flutter + Supabase permite escalabilidad, mientras que nuestro enfoque en validación manual garantiza confianza y legitimidad en cada campaña."

**Logros alcanzados:**
- ✅ 25 requerimientos funcionales implementados
- ✅ 3 roles de usuario completos
- ✅ Sistema de seguridad robusto
- ✅ Interfaz intuitiva y moderna
- ✅ Desplegado en producción (Firebase Hosting)

---

## 🎤 TIPS PARA LA EXPOSICIÓN

### **Antes de empezar:**
1. ✅ Prueba la app en vivo (que cargue rápido)
2. ✅ Ten cuentas de prueba ya creadas
3. ✅ Prepara campañas de ejemplo (con datos reales)
4. ✅ Prueba el flujo completo al menos 2 veces

### **Durante la exposición:**
1. 🎯 **Sé conciso:** No te detengas en detalles técnicos innecesarios
2. 🖱️ **Muestra, no expliques:** Haz la demo en vivo
3. 💬 **Cuenta historias:** Usa los casos de uso reales
4. ⏱️ **Controla el tiempo:** Practica para no pasarte
5. 🙋 **Interactúa:** Pregunta si tienen dudas

### **Manejo de preguntas:**
- "¿Qué pasa si alguien crea una campaña falsa?"
  → Validación manual estricta + KYC + documentos de respaldo
  
- "¿Cómo garantizan que se use bien el dinero?"
  → Sistema de evidencias obligatorio + validación admin
  
- "¿Por qué no usan pasarela de pago?"
  → Evitar costos de comisiones + NO custodia de fondos = más transparencia
  
- "¿Es escalable?"
  → Sí, Supabase maneja millones de usuarios + Flutter compila a nativo

---

## 📸 CAPTURAS RECOMENDADAS (para diapositivas)

1. **Slide 1:** Logo + nombre del proyecto
2. **Slide 2:** Problema que resuelve (foto de campaña falsa en redes)
3. **Slide 3:** Arquitectura técnica (diagrama Flutter + Supabase)
4. **Slide 4:** Feed de campañas (screenshot)
5. **Slide 5:** Flujo de donación (3 pasos visuales)
6. **Slide 6:** Panel administrativo (screenshot)
7. **Slide 7:** Sistema de trofeos (4 niveles)
8. **Slide 8:** Comparación con competidores
9. **Slide 9:** Estadísticas (si tienes datos de uso)
10. **Slide 10:** Conclusión + contacto

---

## 🎬 ESTRUCTURA DE TIEMPO RECOMENDADA

| Sección | Tiempo | Contenido |
|---------|--------|-----------|
| Introducción | 2 min | Problema + Solución |
| Demo Usuario Donante | 3 min | Explorar + Donar |
| Demo Creador | 3 min | Crear campaña + Evidencias |
| Demo Admin | 2 min | Validar + Aprobar |
| Arquitectura | 3 min | Stack técnico |
| Diferenciadores | 2 min | ¿Por qué es único? |
| Futuras mejoras | 1 min | Roadmap |
| Conclusión | 1 min | Logros + Mensaje final |
| Preguntas | 3 min | Q&A |
| **TOTAL** | **20 min** | |

---

¡Éxito en tu exposición! 🚀💙
