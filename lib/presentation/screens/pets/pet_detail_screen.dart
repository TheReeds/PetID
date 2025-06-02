// lib/presentation/screens/pet_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/pet_model.dart';
import '../../providers/pet_provider.dart';
import 'medical_history_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final PetModel pet;
  final bool isOwner;

  const PetDetailScreen({
    super.key,
    required this.pet,
    this.isOwner = true,
  });

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _tabController = TabController(length: 3, vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildTabSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (widget.isOwner) // Solo mostrar menú si es el dueño
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editPet();
                  break;
                case 'qr':
                  _showQRCode();
                  break;
                case 'share':
                  _sharePet();
                  break;
                case 'medical':
                  _showMedicalHistory();
                  break;
                case 'delete':
                  _deletePet();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'medical',
                child: Row(
                  children: [
                    Icon(Icons.medical_services, size: 20),
                    SizedBox(width: 12),
                    Text('Historial médico'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code, size: 20),
                    SizedBox(width: 12),
                    Text('Ver código QR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Compartir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        else // Opciones limitadas para visitantes
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _sharePet();
                  break;
                case 'report':
                  _reportPet();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Compartir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Reportar', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            widget.pet.profilePhoto != null
                ? Image.network(
              widget.pet.profilePhoto!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildImagePlaceholder(),
            )
                : _buildImagePlaceholder(),

            // Overlay gradient mejorado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

            // Badges mejorados
            Positioned(
              top: 60,
              right: 20,
              child: Column(
                children: [
                  // Estado principal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.pet.isLost ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.pet.isLost ? 'PERDIDA' : 'EN CASA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Badges adicionales
                  if (widget.pet.isForAdoption)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'EN ADOPCIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (widget.pet.isForMating)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'REPRODUCCIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información principal mejorada
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end, // Alineación mejorada
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pet.name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2, // Permitir 2 líneas
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.pet.breed} • ${widget.pet.displayAge}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12), // Espacio entre texto e ícono
                      Icon(
                        _getPetTypeIcon(widget.pet.type),
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.pet.breed} • ${widget.pet.displayAge}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Indicadores de salud rápidos
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (widget.pet.isVaccinated)
                          _buildHealthBadge(Icons.vaccines, 'Vacunado'),
                        if (widget.pet.isMicrochipped)
                          _buildHealthBadge(Icons.memory, 'Microchip'),
                        if (widget.pet.isNeutered)
                          _buildHealthBadge(Icons.healing, 'Esterilizado'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHealthBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(
          Icons.pets,
          size: 80,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A7AA7), Color(0xFF6B9BD1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información General',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid de información básica
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildInfoCard('Tipo', _getPetTypeName(widget.pet.type), Icons.category),
              _buildInfoCard('Sexo', widget.pet.sex == PetSex.male ? 'Macho' : 'Hembra',
                  widget.pet.sex == PetSex.male ? Icons.male : Icons.female),
              _buildInfoCard('Peso', '${widget.pet.weight} kg', Icons.monitor_weight),
              _buildInfoCard('Tamaño', _getPetSizeName(widget.pet.size), Icons.straighten),
            ],
          ),

          if (widget.pet.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.pet.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],

          // Información adicional
          if (widget.pet.microchipId != null ||
              widget.pet.isVaccinated ||
              widget.pet.isNeutered ||
              widget.pet.isMicrochipped) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Estado de Salud',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.pet.isVaccinated)
                  _buildStatusChip('Vacunado', Icons.vaccines, Colors.green),
                if (widget.pet.isMicrochipped)
                  _buildStatusChip('Microchip', Icons.memory, Colors.blue),
                if (widget.pet.isNeutered)
                  _buildStatusChip('Esterilizado', Icons.healing, Colors.purple),
                if (widget.pet.microchipId != null)
                  _buildStatusChip('ID: ${widget.pet.microchipId}', Icons.qr_code, Colors.orange),
              ],
            ),
          ],

          // Tags personalizados
          if (widget.pet.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Características',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.pet.tags.map((tag) =>
                  _buildTagChip(tag)
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A7AA7), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      height: 450, // Aumentamos la altura
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4A7AA7),
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF4A7AA7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library, size: 16),
                      const SizedBox(width: 4),
                      Text('Fotos (${widget.pet.photos.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services, size: 16),
                      SizedBox(width: 4),
                      Text('Salud'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline, size: 16),
                      SizedBox(width: 4),
                      Text('Historial'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPhotosTab(),
                _buildHealthTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A7AA7), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A7AA7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF4A7AA7),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhotosTab() {
    if (widget.pet.photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin fotos adicionales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOwner
                  ? 'Agrega más fotos editando la mascota'
                  : 'El dueño no ha agregado más fotos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Galería (${widget.pet.photos.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.isOwner)
                TextButton.icon(
                  onPressed: _addMorePhotos,
                  icon: const Icon(Icons.add_photo_alternate, size: 16),
                  label: const Text('Agregar'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: widget.pet.photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  // CORRECCIÓN: Solo pasar la URL de la foto
                  onTap: () => _showPhotoFullScreen(widget.pet.photos[index]),
                  child: Hero(
                    tag: 'photo_${widget.pet.id}_$index',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              widget.pet.photos[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: const Color(0xFF4A7AA7),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error cargando imagen',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Overlay con número de foto
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Indicador si es la foto principal
                            if (index == 0)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A7AA7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Principal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHealthTab() {
    final healthInfo = widget.pet.healthInfo;

    if (healthInfo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin información médica',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOwner
                  ? 'Agrega información médica editando la mascota'
                  : 'El dueño no ha compartido información médica',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado general
          _buildHealthSection(
            'Estado General',
            Icons.health_and_safety,
            Colors.green,
            [
              _buildHealthRow('Salud', healthInfo.generalHealth),
              if (healthInfo.lastCheckup != null)
                _buildHealthRow('Último chequeo', _formatDate(healthInfo.lastCheckup!)),
              if (healthInfo.nextCheckup != null)
                _buildHealthRow('Próximo chequeo', _formatDate(healthInfo.nextCheckup!)),
            ],
          ),

          const SizedBox(height: 16),

          // Vacunas
          _buildHealthSection(
            'Vacunas',
            Icons.vaccines,
            Colors.blue,
            healthInfo.vaccinations.isNotEmpty
                ? healthInfo.vaccinations.map((vaccine) =>
                _buildVaccineRow(vaccine)).toList()
                : [const Text('Sin vacunas registradas')],
          ),

          const SizedBox(height: 16),

          // Veterinario
          if (healthInfo.veterinarian != null)
            _buildHealthSection(
              'Veterinario',
              Icons.local_hospital,
              Colors.teal,
              [
                _buildHealthRow('Nombre', healthInfo.veterinarian!),
                if (healthInfo.veterinarianPhone != null)
                  _buildHealthRow('Teléfono', healthInfo.veterinarianPhone!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHealthSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineRow(Vaccination vaccine) {
    final isExpired = vaccine.nextDue != null &&
        vaccine.nextDue!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vaccine.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                isExpired ? Icons.warning : Icons.check_circle,
                color: isExpired ? Colors.red : Colors.green,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aplicada: ${_formatDate(vaccine.date)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (vaccine.nextDue != null)
            Text(
              'Próxima: ${_formatDate(vaccine.nextDue!)}',
              style: TextStyle(
                fontSize: 12,
                color: isExpired ? Colors.red.shade700 : Colors.grey.shade600,
                fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Actividad Reciente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Próximamente: registro de paseos, alimentación y actividades',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _editPet() {
    // Navegar a pantalla de edición
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de editar próximamente')),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Código QR - ${widget.pet.name}'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: widget.pet.qrCode != null
              ? QrImageView(
            data: widget.pet.qrCode!,
            version: QrVersions.auto,
            size: 200.0,
          )
              : const Center(
            child: Text('Código QR no disponible'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              // Implementar compartir QR
              Navigator.of(context).pop();
              _showSnackBar('Función compartir QR próximamente');
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _sharePet() {
    // Implementar compartir mascota
    _showSnackBar('Función compartir próximamente');
  }

  void _deletePet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Mascota'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${widget.pet.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmDeletePet();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePet() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    final success = await petProvider.deletePet(widget.pet.id, widget.pet.ownerId);

    if (success) {
      _showSnackBar('${widget.pet.name} ha sido eliminada');
      Navigator.of(context).pop();
    } else {
      _showSnackBar(
        petProvider.errorMessage ?? 'Error al eliminar mascota',
        isError: true,
      );
    }
  }

  void _showPhotoFullScreen(String photoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (widget.isOwner) // Solo mostrar si es el dueño
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'download':
                        _downloadPhoto(photoUrl);
                        break;
                      case 'share':
                        _sharePhoto(photoUrl);
                        break;
                      case 'delete':
                        _deletePhoto(photoUrl);
                        break;
                      case 'set_main':
                        _setAsMainPhoto(photoUrl);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'set_main',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 20),
                          SizedBox(width: 12),
                          Text('Hacer principal'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 12),
                          Text('Descargar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 12),
                          Text('Compartir'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'photo_fullscreen',
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error cargando imagen',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _downloadPhoto(String photoUrl) {
    _showSnackBar('Descargando foto...');
    // Implementar descarga de foto
  }

  void _sharePhoto(String photoUrl) {
    _showSnackBar('Compartiendo foto...');
    // Implementar compartir foto
  }

  void _deletePhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de que quieres eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Cerrar fullscreen
              _confirmDeletePhoto(photoUrl);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePhoto(String photoUrl) {
    _showSnackBar('Eliminando foto...');
    // Implementar eliminación de foto
  }

  void _setAsMainPhoto(String photoUrl) {
    _showSnackBar('Estableciendo como foto principal...');
    // Implementar cambio de foto principal
  }

  void _addMorePhotos() {
    _showSnackBar('Función para agregar fotos próximamente');
  }


  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF4A7AA7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  void _showMedicalHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicalHistoryScreen(pet: widget.pet),
      ),
    );
  }

  void _reportPet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar mascota'),
        content: const Text('¿Qué tipo de problema quieres reportar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Reporte enviado');
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

// Helper para formatear fechas
  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

// Helper para obtener nombres de tipos de mascota
  String _getPetTypeName(PetType type) {
    switch (type) {
      case PetType.dog:
        return 'Perro';
      case PetType.cat:
        return 'Gato';
      case PetType.bird:
        return 'Ave';
      case PetType.rabbit:
        return 'Conejo';
      case PetType.hamster:
        return 'Hámster';
      case PetType.fish:
        return 'Pez';
      case PetType.reptile:
        return 'Reptil';
      case PetType.other:
        return 'Otro';
    }
  }

// Helper para obtener nombres de tamaños
  String _getPetSizeName(PetSize size) {
    switch (size) {
      case PetSize.small:
        return 'Pequeño';
      case PetSize.medium:
        return 'Mediano';
      case PetSize.large:
        return 'Grande';
    }
  }

// Helper para obtener iconos de tipos de mascota
  IconData _getPetTypeIcon(PetType type) {
    switch (type) {
      case PetType.dog:
        return Icons.pets;
      case PetType.cat:
        return Icons.pets;
      case PetType.bird:
        return Icons.flutter_dash;
      case PetType.rabbit:
        return Icons.cruelty_free;
      case PetType.hamster:
        return Icons.cruelty_free;
      case PetType.fish:
        return Icons.set_meal;
      case PetType.reptile:
        return Icons.pest_control;
      case PetType.other:
        return Icons.pets;
    }
  }
}