import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/organization.dart';
import '../theme/app_colors.dart';
import '../ui/widgets/highlight_wrapper.dart';

class OrganizationDetailPage extends StatelessWidget {
  final OrganizationSummary organization;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onOpenWebsite;
  final bool fromNotification;

  const OrganizationDetailPage({
    super.key,
    required this.organization,
    this.onCall,
    this.onEmail,
    this.onOpenWebsite,
    this.fromNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    String? memberSince;
    if (organization.createdAt != null) {
      memberSince = localizations.formatMediumDate(organization.createdAt!.toLocal());
    }

    // Extraer galería de documentos
    final galleryUrls = <String>[];
    if (organization.description != null && organization.description!.contains('https://')) {
      final lines = organization.description!.split('\n');
      for (final line in lines) {
        if (line.contains('https://') && (line.contains('.jpg') || line.contains('.png'))) {
          final url = line.trim().replaceAll('- ', '');
          if (url.startsWith('https://')) {
            galleryUrls.add(url);
          }
        }
      }
    }

    // Descripción limpia
    String cleanDescription = organization.description ?? 'Esta organización aún no ha compartido su misión e historia.';
    if (galleryUrls.isNotEmpty) {
      final lines = cleanDescription.split('\n');
      final cleanLines = lines.where((line) => !line.contains('https://')).toList();
      cleanDescription = cleanLines.join('\n').trim();
      if (cleanDescription.isEmpty) {
        cleanDescription = 'Esta organización aún no ha compartido su misión e historia.';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkText, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          organization.name,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Banner de notificación de organización
            if (fromNotification)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: HighlightWrapper(
                  shouldHighlight: true,
                  highlightColor: AppColors.bluePrimary,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.bluePrimary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: AppColors.bluePrimary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organización verificada',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.bluePrimary,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Esta organización ha sido aprobada y verificada',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.bluePrimary.withOpacity(0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Header con gradiente sutil
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bluePrimary.withValues(alpha: 0.05),
                    Colors.white,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  // Logo con sombra
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bluePrimary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildLogo(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Nombre
                  Text(
                    organization.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Badges
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Verificada',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (organization.type != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.darkText.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            organization.type!,
                            style: TextStyle(
                              color: AppColors.darkText.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (memberSince != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.darkText.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Miembro desde $memberSince',
                          style: TextStyle(
                            color: AppColors.darkText.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Acciones rápidas
            if (organization.hasDirectContact || organization.hasWebsite)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contacto rápido',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (organization.phone != null && organization.phone!.isNotEmpty)
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Llamar',
                              icon: Icons.phone_rounded,
                              color: AppColors.greenSuccess,
                              onTap: onCall,
                            ),
                          ),
                        if (organization.phone != null && organization.phone!.isNotEmpty && 
                            organization.email != null && organization.email!.isNotEmpty)
                          const SizedBox(width: 10),
                        if (organization.email != null && organization.email!.isNotEmpty)
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Email',
                              icon: Icons.email_rounded,
                              color: AppColors.bluePrimary,
                              onTap: onEmail,
                            ),
                          ),
                        if ((organization.phone != null && organization.phone!.isNotEmpty || 
                            organization.email != null && organization.email!.isNotEmpty) &&
                            organization.website != null && organization.website!.isNotEmpty)
                          const SizedBox(width: 10),
                        if (organization.website != null && organization.website!.isNotEmpty)
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Web',
                              icon: Icons.language_rounded,
                              color: AppColors.orangeAction,
                              onTap: onOpenWebsite,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            
            if (organization.hasDirectContact || organization.hasWebsite)
              const SizedBox(height: 8),
            
            // Descripción mejorada
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icono
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.bluePrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Acerca de la organización',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Contenedor con fondo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.bluePrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Misión/Descripción
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.bluePrimary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nuestra misión',
                                    style: TextStyle(
                                      color: AppColors.bluePrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cleanDescription,
                                    style: TextStyle(
                                      color: AppColors.darkText.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (organization.type != null) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          
                          // Tipo de organización
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.greenSuccess.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.business_center_rounded,
                                  color: AppColors.greenSuccess,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tipo de organización',
                                    style: TextStyle(
                                      color: AppColors.greenSuccess,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    organization.type!,
                                    style: TextStyle(
                                      color: AppColors.darkText.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Galería
            if (galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.greenSuccess,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Galería',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${galleryUrls.length}',
                            style: const TextStyle(
                              color: AppColors.greenSuccess,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: galleryUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            galleryUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.darkText.withValues(alpha: 0.05),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.darkText.withValues(alpha: 0.3),
                                  size: 32,
                                ),
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.darkText.withValues(alpha: 0.05),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.bluePrimary),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            
            // Ubicación con mapa
            if (organization.hasAddress) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.orangeAction,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ubicación',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Dirección con icono
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.orangeAction.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.orangeAction,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dirección',
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                organization.address!,
                                style: TextStyle(
                                  color: AppColors.darkText.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Mapa
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: const LatLng(-16.5000, -68.1500), // La Paz, Bolivia
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.manossolidarias.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: const LatLng(-16.5000, -68.1500),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.orangeAction,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.orangeAction.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.business_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Botón para abrir en mapa
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Abrir en Google Maps
                        },
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Abrir en Google Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.orangeAction,
                          side: BorderSide(
                            color: AppColors.orangeAction.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Contacto
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header simple
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.bluePrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Contacto',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (organization.hasDirectContact || organization.hasWebsite) ...[
                    // Teléfono
                    if (organization.phone != null && organization.phone!.isNotEmpty)
                      _ContactItem(
                        icon: Icons.phone_rounded,
                        iconColor: AppColors.greenSuccess,
                        label: 'Teléfono',
                        value: organization.phone!,
                        actionLabel: 'Llamar',
                        onTap: onCall,
                      ),
                    
                    if (organization.phone != null && organization.phone!.isNotEmpty &&
                        organization.email != null && organization.email!.isNotEmpty)
                      const SizedBox(height: 10),
                    
                    // Email
                    if (organization.email != null && organization.email!.isNotEmpty)
                      _ContactItem(
                        icon: Icons.email_rounded,
                        iconColor: AppColors.bluePrimary,
                        label: 'Correo',
                        value: organization.email!,
                        actionLabel: 'Escribir',
                        onTap: onEmail,
                      ),
                    
                    if ((organization.phone != null && organization.phone!.isNotEmpty ||
                        organization.email != null && organization.email!.isNotEmpty) &&
                        organization.website != null && organization.website!.isNotEmpty)
                      const SizedBox(height: 10),
                    
                    // Website
                    if (organization.website != null && organization.website!.isNotEmpty)
                      _ContactItem(
                        icon: Icons.language_rounded,
                        iconColor: AppColors.orangeAction,
                        label: 'Sitio web',
                        value: organization.website!,
                        actionLabel: 'Visitar',
                        onTap: onOpenWebsite,
                      ),
                  ] else
                    Text(
                      'No hay información de contacto disponible',
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final url = organization.logoUrl;
    final size = 100.0;
    
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bluePrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          Icons.business_rounded,
          size: size * 0.5,
          color: AppColors.bluePrimary.withValues(alpha: 0.5),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.business_rounded,
            size: size * 0.5,
            color: AppColors.bluePrimary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// Widget simple para item de contacto
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.darkText.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Icono simple
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón pequeño
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para botones de acción rápida
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
