# 📊 Diagramas del Sistema - Manos Solidarias

Esta carpeta contiene todos los diagramas UML del proyecto.

## 📁 Archivos disponibles

### 1. Casos de Uso
- **`caso_uso_nivel_0.puml`** - Diagrama general sin extends/includes (21 casos de uso principales)

## 🔧 Cómo visualizar los diagramas

### Opción 1: PlantUML Online
1. Ve a http://www.plantuml.com/plantuml/uml/
2. Copia el contenido del archivo `.puml`
3. Pégalo y genera el diagrama

### Opción 2: VS Code con extensión
1. Instala la extensión "PlantUML" en VS Code
2. Abre el archivo `.puml`
3. Presiona `Alt + D` para ver la vista previa

### Opción 3: Exportar como imagen
En VS Code con PlantUML instalado:
- `Ctrl + Shift + P` → "PlantUML: Export Current Diagram"
- Elige formato: PNG, SVG, PDF

## 📋 Resumen de Casos de Uso

### Usuario (15 casos de uso)
**Como donante y/o creador de campañas:**

Generales:
1. Registrarse
2. Iniciar Sesión
3. Completar Perfil KYC

Exploración:
4. Ver Campañas Activas
5. Filtrar por Categoría
6. Agregar a Favoritos
7. Compartir Campaña
8. Ver Ranking Solidario

Como Donante:
9. Realizar Donación
10. Ver Historial de Donaciones

Como Creador:
11. Crear Solicitud de Campaña
12. Ver Mis Solicitudes
13. Eliminar Solicitud Pendiente
14. Subir Evidencias
15. Ver Progreso de Campaña

### Administrador (6 casos de uso)
1. Iniciar Sesión
2. Ver Panel de Control
3. Aprobar/Rechazar Solicitudes
4. Validar Donaciones
5. Verificar Evidencias
6. Gestionar Organizaciones
7. Suspender Campañas

## 🎨 Colores en el diagrama

- � **Azul claro**: Usuario (puede ser donante y/o creador)
- 🟢 **Verde claro**: Administrador

---

**Nota:** Los diagramas están en formato PlantUML (.puml) para facilitar edición y versionado.
