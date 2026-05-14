# HANDOFF: Reconectar rediseño del Home (Tab Campañas)

> **Este archivo es para el siguiente agente.** Léelo COMPLETO antes de tocar cualquier cosa.
> Contexto: en una sesión previa se perdió accidentalmente el wiring de 5 widgets nuevos
> dentro de `lib/ui/home/menu_inferior/campaign_tab_view.dart`. Los widgets existen y compilan,
> pero el archivo `campaign_tab_view.dart` está en estado del commit `87882c4` (antes del rediseño).
> Tu trabajo: volver a referenciar esos 5 widgets en el feed.

---

## ⚠️ REGLAS DE ORO — NO ROMPER

1. **NO ejecutes `git checkout -- <archivo>` si hay cambios sin commitear.** Destruye trabajo del usuario. Si tenés que revertir algo, usá `git stash` y verificá.
2. **NO uses scripts (PowerShell `Set-Content`, sed, awk) para borrar rangos de líneas.** Usá la herramienta `Edit` quirúrgica con contexto único.
3. **COMMIT ANTES DE EMPEZAR.** Ejecutá esto primero:
   ```bash
   git add -A
   git commit -m "snapshot antes de reconectar home feed" --allow-empty
   ```
4. **NO crees widgets nuevos.** Los 5 ya existen en disco. Solo agregales imports y llamalos.
5. **NO toques nada de Supabase, `.env`, `supabase.sql`, ni `.gitignore`.**
6. **Después de cada edit, ejecutá `flutter analyze --no-pub lib/ui/home/menu_inferior/campaign_tab_view.dart`** — si aparece una línea `error -` (NO confundir con `info` o `warning`), revertí ese edit YA.
7. **Confirmá visualmente con el usuario** antes de dar por terminado.

---

## 📁 Archivos involucrados

### Archivo a editar
- `lib/ui/home/menu_inferior/campaign_tab_view.dart` — la clase `CampaignTabView` (StatelessWidget). Su método `build()` renderiza el feed completo.

### Widgets ya creados (NO crear, solo importar)
Todos están en `lib/ui/home/widgets/`:
- `featured_campaign_hero.dart` → exporta `FeaturedCampaignHero`
- `sponsor_strip.dart` → exporta `SponsorStrip` (constructor sin params obligatorios)
- `promoted_campaign_banner.dart` → exporta `PromotedCampaignBanner`
- `campaign_story_strip.dart` → exporta `CampaignStoryStrip`
- `campaign_near_goal_card.dart` → exporta `CampaignNearGoalCard`

**Antes de usarlos, abrí cada archivo y verificá la firma exacta del constructor.** No asumas — leé.

---

## 🛠 Cambios a aplicar en `campaign_tab_view.dart`

### Paso 1 — Imports
Agregar al bloque de imports al inicio:
```dart
import 'package:flutter/services.dart';
import '../widgets/campaign_near_goal_card.dart';
import '../widgets/campaign_story_strip.dart';
import '../widgets/featured_campaign_hero.dart';
import '../widgets/promoted_campaign_banner.dart';
import '../widgets/sponsor_strip.dart';
```

### Paso 2 — Helper `_pickPromotedCampaign`
Agregar como método privado de `CampaignTabView` o función top-level del archivo:
```dart
CampaignSummary? _pickPromotedCampaign(
  List<CampaignSummary> campaigns,
  String? excludeId,
) {
  final candidates = campaigns
      .where((c) => !c.isCompleted && c.id != excludeId)
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.donorCount.compareTo(a.donorCount));
  return candidates.first;
}
```

### Paso 3 — Lógica del hero (dentro de `build()`)
Después de calcular `featured` (la lista filtrada de destacadas) y ANTES de armar el `Column`/`ListView` del feed, agregar:
```dart
// Hero protagonista: la destacada con mejor progreso (<100%).
// Fallback: la campaña activa con más % de avance si no hay destacadas.
CampaignSummary? heroCampaign;
if (featured.isNotEmpty) {
  final candidates = featured.where((c) => !c.isCompleted).toList();
  if (candidates.isNotEmpty) {
    candidates.sort(
      (a, b) => b.completionPercentage.compareTo(a.completionPercentage),
    );
    heroCampaign = candidates.first;
  } else {
    heroCampaign = featured.first;
  }
} else {
  final actives = campaigns.where((c) => !c.isCompleted).toList();
  if (actives.isNotEmpty) {
    actives.sort(
      (a, b) => b.completionPercentage.compareTo(a.completionPercentage),
    );
    heroCampaign = actives.first;
  }
}
final heroId = heroCampaign?.id;

final featuredForCarousel =
    featured.where((c) => c.id != heroId).toList();
final featuredIds = {...featured.map((c) => c.id)};
final nearGoal = List<CampaignSummary>.from(
  (categoryFilter != null
          ? controller.nearGoalCampaigns
              .where((c) => c.category == categoryFilter)
              .toList()
          : controller.nearGoalCampaigns)
      .where((c) => !featuredIds.contains(c.id) && c.id != heroId),
);
final seenIds = {
  ...featuredIds,
  ...nearGoal.map((c) => c.id),
  if (heroId != null) heroId,
};
final recent = (categoryFilter != null
        ? controller.recentCampaigns
            .where((c) => c.category == categoryFilter)
            .toList()
        : controller.recentCampaigns)
    .where((c) => !seenIds.contains(c.id))
    .take(8)
    .toList();
```

> Reemplaza la lógica equivalente que hoy hay en el archivo (que calcula `nearGoal` y `recent` sin filtrar por hero y con `take(2)` para recent).

### Paso 4 — Orden del feed
El `Column`/`ListView` del feed debe quedar así, **en este orden**:

1. **Filtro de categoría activo** (si `categoryFilter != null`) — ya está.
2. **Sort chips** — ya está.
3. **Leaderboard link** — solo si `donorTrophyController != null && onViewLeaderboard != null`:
   ```dart
   Padding(
     padding: const EdgeInsets.only(bottom: 20),
     child: _LeaderboardEntryLink(onTap: onViewLeaderboard!),
   )
   ```
   El widget `_LeaderboardEntryLink` **no existe todavía** en el archivo. Crealo como widget privado al final, simple:
   ```dart
   class _LeaderboardEntryLink extends StatelessWidget {
     const _LeaderboardEntryLink({required this.onTap});
     final VoidCallback onTap;
     @override
     Widget build(BuildContext context) {
       return InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(12),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: AppColors.dividerColor),
           ),
           child: Row(
             children: [
               Icon(Icons.emoji_events_rounded, color: AppColors.orangeAction, size: 20),
               const SizedBox(width: 10),
               Expanded(
                 child: Text(
                   'Ver ranking solidario',
                   style: TextStyle(
                     fontWeight: FontWeight.w600,
                     color: AppColors.darkText,
                   ),
                 ),
               ),
               Icon(Icons.chevron_right_rounded, color: AppColors.darkText.withValues(alpha: 0.4)),
             ],
           ),
         ),
       );
     }
   }
   ```
   Y ELIMINAR la referencia actual a `_DonorLeaderboardPreview` (o envolverla en `if (false)`) — el preview viejo era muy grande, el nuevo es un link compacto.

4. **Error banner inline** (si `error != null`) — ya está.

5. **🆕 BLOQUE HERO** (solo si `heroCampaign != null`):
   ```dart
   FeaturedCampaignHero(
     campaign: heroCampaign,
     onTap: () => onOpenCampaign(heroCampaign!),
     onSupport: () => onSupportCampaign(heroCampaign!),
     onToggleFavorite: () => onToggleFavorite(heroCampaign!),
   ),
   const SizedBox(height: 14),
   const SponsorStrip(),
   const SizedBox(height: 14),
   ```

6. **"Otras destacadas"** (carrusel horizontal) — solo si `featuredForCarousel.isNotEmpty`. Reusa el `HomeSection` actual de "Campañas destacadas" pero:
   - Título: `'Otras destacadas'`
   - Subtitle: `'Más proyectos verificados con alto impacto comunitario.'`
   - `iconColor: AppColors.orangeAction`
   - `itemCount: featuredForCarousel.length`
   - En el itemBuilder usá `featuredForCarousel[index]` en vez de `featured[index]`.

7. **"Cerca de la meta"** — solo si `nearGoal.isNotEmpty`. Reemplazá `CampaignProgressTile` por:
   ```dart
   CampaignNearGoalCard(
     campaign: campaign,
     onTap: () => onOpenCampaign(campaign),
   )
   ```
   Con padding bottom 12 entre cada una, `.take(4)` campañas.

8. **🆕 Promoted Campaign Banner** — solo si `_pickPromotedCampaign(campaigns, heroId) != null`:
   ```dart
   const SizedBox(height: 4),
   PromotedCampaignBanner(
     campaign: _pickPromotedCampaign(campaigns, heroId)!,
     sponsorName: 'Banco Andino',
     sponsorColor: const Color(0xFFC8102E),
     onTap: () => onOpenCampaign(
       _pickPromotedCampaign(campaigns, heroId)!,
     ),
   ),
   const SizedBox(height: 24),
   ```

9. **"Recién lanzadas"** — solo si `recent.isNotEmpty`. Reemplazá la lista actual de tiles por:
   ```dart
   HomeSection(
     title: 'Recién lanzadas',
     subtitle: 'Ideas frescas que necesitan sus primeros aliados.',
     iconColor: AppColors.bluePrimary,
     child: CampaignStoryStrip(
       campaigns: recent,
       onOpenCampaign: onOpenCampaign,
     ),
   )
   ```

10. **"Todas las campañas"** — dejar como está actualmente, sin tocar.

---

## ✅ Verificación

Después de cada paso significativo, correr:
```bash
flutter analyze --no-pub lib/ui/home/menu_inferior/campaign_tab_view.dart
```

Esperado al final: `No issues found!` o solo `info`/`warning` (NUNCA `error`).

Luego:
```bash
flutter run -d 09934403AC105647
```

(Ese es el ID del Infinix del usuario. Si no responde, listar con `flutter devices` y usar otro.)

Una vez corriendo, el usuario abre el tab de **Campañas** y debe ver, de arriba a abajo:
- Filtro/sort chips
- Link compacto a ranking solidario
- **HERO grande con foto** (`FeaturedCampaignHero`)
- **Strip de 6 chips de sponsors** (`SponsorStrip` con "CON EL RESPALDO DE")
- Carrusel horizontal "Otras destacadas"
- "Cerca de la meta" con `CampaignNearGoalCard`
- **Banner "IMPULSADO POR BANCO ANDINO"** (`PromotedCampaignBanner`)
- "Recién lanzadas" como story strip horizontal
- "Todas las campañas"

---

## 🚨 Si algo se rompe

- `git diff` para ver qué cambió.
- Si el estado se ensució: `git stash` (no `git checkout`).
- **Preguntar al usuario** antes de seguir si hay duda.
- El usuario tiene defensa de tesis en pocos días — priorizar estabilidad sobre features.

---

## 📋 Otras notas útiles

- El proyecto es Flutter + Supabase. Backend: proyecto `ManosSolidarias3` (`gvdlsypoqstbifdbhafv`), ya tiene RLS y policies aplicadas. **NO tocar la base de datos.**
- Modelo de monetización: las dos secciones publicitarias (`SponsorStrip` + `PromotedCampaignBanner`) son parte del modelo RSE corporativa defendible para tesis. El usuario las quiere ahí.
- Si el usuario pide cambiar el ESTILO visual de esos sponsors, ofrecé alternativas concretas ANTES de implementar — ya hubo un intento previo de "estilo nativo discreto" que fue rechazado.
- El archivo `campaign_tab_view.dart` tiene un montón de widgets privados auxiliares (`_LeaderboardContainer`, `_DonorLeaderboardPreview`, `_LeaderboardPreviewTile`, `_EmptyPodiumBar`, `_SortChip`, etc.). Los del leaderboard viejo quedan como código muerto después del rediseño. **NO los borres en este pase** — déjalos. Borrarlos es una limpieza separada y peligrosa porque hay referencias entrelazadas.
