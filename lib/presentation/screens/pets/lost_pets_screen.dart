// lib/presentation/screens/pets/lost_pets_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/lost_pet_model.dart';
import '../../providers/lost_pet_provider.dart';
import '../../providers/auth_provider.dart';

class LostPetsScreen extends StatefulWidget {
  const LostPetsScreen({super.key});

  @override
  State<LostPetsScreen> createState() => _LostPetsScreenState();
}

class _LostPetsScreenState extends State<LostPetsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Position? _currentPosition;
  double _selectedRadius = 10.0; // km
  List<LostPetModel> _nearbyLostPets = [];
  bool _isLoadingLocation = false;

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

    _animationController.forward();

    // Cargar mascotas perdidas activas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lostPetProvider = Provider.of<LostPetProvider>(context, listen: false);
      lostPetProvider.loadActiveLostPets();
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mascotas Perdidas'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildLocationHeader(),
            _buildRadiusSelector(),
            Expanded(child: _buildLostPetsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[600],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isLoadingLocation ? Icons.location_searching : Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLoadingLocation
                      ? 'Obteniendo ubicación...'
                      : _currentPosition != null
                      ? 'Buscando mascotas cerca de ti'
                      : 'Ubicación no disponible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!_isLoadingLocation)
                TextButton(
                  onPressed: _getCurrentLocation,
                  child: const Text(
                    'Actualizar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          if (_nearbyLostPets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_nearbyLostPets.length} mascotas perdidas en ${_selectedRadius.toInt()} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Radio de búsqueda',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _selectedRadius,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  activeColor: Colors.red[600],
                  onChanged: (value) {
                    setState(() {
                      _selectedRadius = value;
                    });
                    _loadNearbyLostPets();
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedRadius.toInt()} km',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLostPetsList() {
    return Consumer<LostPetProvider>(
      builder: (context, lostPetProvider, child) {
        if (lostPetProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text('Cargando mascotas perdidas...'),
              ],
            ),
          );
        }

        if (lostPetProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${lostPetProvider.errorMessage}',
                  style: TextStyle(color: Colors.red[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    lostPetProvider.loadActiveLostPets();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final lostPets = _nearbyLostPets.isNotEmpty
            ? _nearbyLostPets
            : lostPetProvider.activeLostPets;

        if (lostPets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay mascotas perdidas reportadas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentPosition != null
                      ? 'en un radio de ${_selectedRadius.toInt()} km'
                      : 'en este momento',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: lostPets.length,
          itemBuilder: (context, index) => _buildLostPetCard(lostPets[index]),
        );
      },
    );
  }

  Widget _buildLostPetCard(LostPetModel lostPet) {
    final daysSinceLost = DateTime.now().difference(lostPet.lastSeenDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado y tiempo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PERDIDA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  daysSinceLost == 0
                      ? 'Hoy'
                      : daysSinceLost == 1
                      ? 'Ayer'
                      : 'Hace $daysSinceLost días',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto de la mascota
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: lostPet.photos.isNotEmpty
                        ? Image.network(
                      lostPet.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.pets, size: 40, color: Colors.grey),
                    )
                        : const Icon(Icons.pets, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),

                // Información de la mascota
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lostPet.petName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lostPet.lastSeenLocationName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (lostPet.reward != null && lostPet.reward!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Recompensa: \${lostPet.reward}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Descripción
          if (lostPet.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                lostPet.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactOwner(lostPet),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Contactar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPetDetails(lostPet),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Ver detalles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están permanentemente denegados');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _loadNearbyLostPets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error obteniendo ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadNearbyLostPets() async {
    if (_currentPosition == null) return;

    try {
      final lostPetProvider = Provider.of<LostPetProvider>(context, listen: false);
      final nearbyPets = await lostPetProvider.getLostPetsNearLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: _selectedRadius,
      );

      setState(() {
        _nearbyLostPets = nearbyPets;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando mascotas cercanas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Perdidas hoy'),
              onTap: () {
                Navigator.of(context).pop();
                _filterByDate(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Última semana'),
              onTap: () {
                Navigator.of(context).pop();
                _filterByDate(7);
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Con recompensa'),
              onTap: () {
                Navigator.of(context).pop();
                _filterByReward();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Limpiar filtros'),
              onTap: () {
                Navigator.of(context).pop();
                _clearFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _filterByDate(int days) {
    final lostPetProvider = Provider.of<LostPetProvider>(context, listen: false);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    setState(() {
      _nearbyLostPets = lostPetProvider.activeLostPets
          .where((pet) => pet.lastSeenDate.isAfter(cutoffDate))
          .toList();
    });
  }

  void _filterByReward() {
    final lostPetProvider = Provider.of<LostPetProvider>(context, listen: false);

    setState(() {
      _nearbyLostPets = lostPetProvider.activeLostPets
          .where((pet) => pet.reward != null && pet.reward!.isNotEmpty)
          .toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _nearbyLostPets = [];
    });
    if (_currentPosition != null) {
      _loadNearbyLostPets();
    }
  }

  void _contactOwner(LostPetModel lostPet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contactar dueño de ${lostPet.petName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Llamar'),
              subtitle: Text(lostPet.contactPhone),
              onTap: () {
                Navigator.of(context).pop();
                _makePhoneCall(lostPet.contactPhone);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Enviar SMS'),
              subtitle: Text(lostPet.contactPhone),
              onTap: () {
                Navigator.of(context).pop();
                _sendSMS(lostPet.contactPhone, lostPet.petName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('Enviar Email'),
              subtitle: Text(lostPet.contactEmail),
              onTap: () {
                Navigator.of(context).pop();
                _sendEmail(lostPet.contactEmail, lostPet.petName);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPetDetails(LostPetModel lostPet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LostPetDetailScreen(lostPet: lostPet),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede realizar la llamada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSMS(String phoneNumber, String petName) async {
    final message = 'Hola, vi tu anuncio sobre $petName perdida. ¿Puedo ayudar?';
    final uri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede enviar SMS'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendEmail(String email, String petName) async {
    final subject = 'Sobre $petName perdida';
    final body = 'Hola, vi tu anuncio sobre $petName perdida. ¿Puedo ayudar de alguna manera?';
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede enviar email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Pantalla de detalles de mascota perdida
class LostPetDetailScreen extends StatelessWidget {
  final LostPetModel lostPet;

  const LostPetDetailScreen({super.key, required this.lostPet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(lostPet.petName),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Container(
              height: 300,
              width: double.infinity,
              child: lostPet.photos.isNotEmpty
                  ? PageView.builder(
                itemCount: lostPet.photos.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    lostPet.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                        ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              lostPet.petName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[600],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PERDIDA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.location_on, 'Última ubicación', lostPet.lastSeenLocationName),
                        _buildInfoRow(Icons.calendar_today, 'Fecha perdida',
                            '${lostPet.lastSeenDate.day}/${lostPet.lastSeenDate.month}/${lostPet.lastSeenDate.year}'),
                        if (lostPet.reward != null && lostPet.reward!.isNotEmpty)
                          _buildInfoRow(Icons.monetization_on, 'Recompensa', '\${lostPet.reward}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (lostPet.description.isNotEmpty) ...[
                    const Text(
                      'Descripción',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lostPet.description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Contact section
                  const Text(
                    'Información de contacto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildContactButton(
                          'Llamar',
                          Icons.phone,
                          Colors.green,
                              () => _makePhoneCall(context, lostPet.contactPhone),
                        ),
                        const SizedBox(height: 12),
                        _buildContactButton(
                          'Enviar SMS',
                          Icons.message,
                          Colors.blue,
                              () => _sendSMS(context, lostPet.contactPhone, lostPet.petName),
                        ),
                        const SizedBox(height: 12),
                        _buildContactButton(
                          'Enviar Email',
                          Icons.email,
                          Colors.orange,
                              () => _sendEmail(context, lostPet.contactEmail, lostPet.petName),
                        ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede realizar la llamada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSMS(BuildContext context, String phoneNumber, String petName) async {
    final message = 'Hola, vi tu anuncio sobre $petName perdida. ¿Puedo ayudar?';
    final uri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede enviar SMS'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendEmail(BuildContext context, String email, String petName) async {
    final subject = 'Sobre $petName perdida';
    final body = 'Hola, vi tu anuncio sobre $petName perdida. ¿Puedo ayudar de alguna manera?';
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede enviar email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}