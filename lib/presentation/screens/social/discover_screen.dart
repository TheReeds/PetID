// lib/presentation/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = ['Todos', 'Adopción', 'Perdidas', 'Apareamiento', 'Servicios'];
  int _selectedCategory = 0;

  // Datos de ejemplo
  final List<Map<String, dynamic>> _adoptionPets = [
    {
      'name': 'Luna',
      'breed': 'Mestizo',
      'age': '2 años',
      'location': 'Lima, Perú',
      'image': 'https://placedog.net/300/300?id=21',
      'urgent': true,
      'description': 'Luna es una perrita muy cariñosa que busca una familia',
      'contact': '+51 999 888 777',
    },
    {
      'name': 'Rocky',
      'breed': 'Pastor Alemán',
      'age': '3 años',
      'location': 'Callao, Perú',
      'image': 'https://placedog.net/300/300?id=22',
      'urgent': false,
      'description': 'Rocky es muy protector y leal',
      'contact': '+51 988 777 666',
    },
    {
      'name': 'Bella',
      'breed': 'Golden Retriever',
      'age': '1 año',
      'location': 'Arequipa, Perú',
      'image': 'https://placedog.net/300/300?id=23',
      'urgent': false,
      'description': 'Bella es perfecta para familias con niños',
      'contact': '+51 977 666 555',
    },
    {
      'name': 'Coco',
      'breed': 'Chihuahua',
      'age': '4 años',
      'location': 'Cusco, Perú',
      'image': 'https://placedog.net/300/300?id=26',
      'urgent': true,
      'description': 'Coco es pequeño pero con gran personalidad',
      'contact': '+51 966 555 444',
    },
  ];

  final List<Map<String, dynamic>> _lostPets = [
    {
      'name': 'Max',
      'breed': 'Labrador',
      'lastSeen': 'Hace 2 horas',
      'location': 'Miraflores, Lima',
      'image': 'https://placedog.net/300/300?id=24',
      'reward': 'S/. 500',
      'description': 'Max es muy amigable, responde a su nombre',
      'contact': '+51 999 111 222',
    },
    {
      'name': 'Coco',
      'breed': 'Chihuahua',
      'lastSeen': 'Hace 1 día',
      'location': 'San Isidro, Lima',
      'image': 'https://placedog.net/300/300?id=25',
      'reward': 'S/. 200',
      'description': 'Pequeño, color marrón, muy asustadizo',
      'contact': '+51 988 222 333',
    },
    {
      'name': 'Princesa',
      'breed': 'Poodle',
      'lastSeen': 'Hace 3 días',
      'location': 'Surco, Lima',
      'image': 'https://placedog.net/300/300?id=27',
      'reward': 'S/. 300',
      'description': 'Poodle blanco, lleva collar rosa',
      'contact': '+51 977 333 444',
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Veterinaria San Marcos',
      'type': 'Veterinario',
      'rating': 4.8,
      'distance': '1.2 km',
      'image': 'https://via.placeholder.com/300x200/4A7AA7/FFFFFF?text=Veterinaria',
      'price': 'S/. 50 - 150',
      'address': 'Av. Arequipa 123, Lima',
      'phone': '+51 999 111 222',
      'hours': '8:00 AM - 8:00 PM',
    },
    {
      'name': 'Guardería Pet Hotel',
      'type': 'Guardería',
      'rating': 4.5,
      'distance': '2.1 km',
      'image': 'https://via.placeholder.com/300x200/4A7AA7/FFFFFF?text=Guarderia',
      'price': 'S/. 30 - 80',
      'address': 'Jr. Las Flores 456, Lima',
      'phone': '+51 988 222 333',
      'hours': '7:00 AM - 9:00 PM',
    },
    {
      'name': 'Peluquería Canina Glamour',
      'type': 'Peluquería',
      'rating': 4.7,
      'distance': '0.8 km',
      'image': 'https://via.placeholder.com/300x200/4A7AA7/FFFFFF?text=Peluqueria',
      'price': 'S/. 25 - 60',
      'address': 'Calle San Martín 789, Lima',
      'phone': '+51 977 333 444',
      'hours': '9:00 AM - 6:00 PM',
    },
    {
      'name': 'Entrenamiento Canino Pro',
      'type': 'Entrenamiento',
      'rating': 4.9,
      'distance': '3.5 km',
      'image': 'https://via.placeholder.com/300x200/4A7AA7/FFFFFF?text=Entrenamiento',
      'price': 'S/. 80 - 200',
      'address': 'Av. Javier Prado 321, Lima',
      'phone': '+51 966 444 555',
      'hours': '6:00 AM - 8:00 PM',
    },
  ];

  final List<Map<String, dynamic>> _matingPets = [
    {
      'name': 'Thor',
      'breed': 'Pastor Alemán',
      'age': '3 años',
      'location': 'Lima, Perú',
      'image': 'https://placedog.net/300/300?id=28',
      'certified': true,
      'description': 'Thor es un ejemplar puro con excelente pedigree',
      'contact': '+51 999 777 888',
    },
    {
      'name': 'Duchess',
      'breed': 'Golden Retriever',
      'age': '2 años',
      'location': 'Callao, Perú',
      'image': 'https://placedog.net/300/300?id=29',
      'certified': false,
      'description': 'Duchess tiene excelente temperamento',
      'contact': '+51 988 666 777',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(),
              _buildSearchBar(),
              _buildCategoryTabs(),
            ];
          },
          body: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Text(
        'Explorar',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A7AA7),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: Color(0xFF4A7AA7)),
          onPressed: _showFilters,
        ),
        IconButton(
          icon: const Icon(Icons.location_on, color: Color(0xFF4A7AA7)),
          onPressed: _showLocationSettings,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar mascotas, servicios...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Color(0xFF4A7AA7)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF4A7AA7)),
              onPressed: _scanQRCode,
            ),
          ),
          onChanged: (value) {
            // Implementar búsqueda
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedCategory == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedCategory = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4A7AA7) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4A7AA7) : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF4A7AA7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedCategory) {
      case 0:
        return _buildAllContent();
      case 1:
        return _buildAdoptionContent();
      case 2:
        return _buildLostPetsContent();
      case 3:
        return _buildMatingContent();
      case 4:
        return _buildServicesContent();
      default:
        return _buildAllContent();
    }
  }

  Widget _buildAllContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Adopción Urgente', Icons.favorite, Colors.red),
          const SizedBox(height: 12),
          _buildAdoptionGrid(urgent: true),
          const SizedBox(height: 24),
          _buildSectionHeader('Mascotas Perdidas', Icons.search, Colors.orange),
          const SizedBox(height: 12),
          _buildLostPetsCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Servicios Cercanos', Icons.location_on, Colors.green),
          const SizedBox(height: 12),
          _buildServicesList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: const Text('Ver todos'),
        ),
      ],
    );
  }

  Widget _buildAdoptionContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAdoptionGrid(),
        ],
      ),
    );
  }

  Widget _buildAdoptionGrid({bool urgent = false}) {
    final pets = urgent ? _adoptionPets.where((p) => p['urgent'] == true).toList() : _adoptionPets;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _buildAdoptionCard(pet);
      },
    );
  }

  Widget _buildAdoptionCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () => _viewPetDetails(pet, 'adoption'),
      child: Container(
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
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        pet['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (pet['urgent'] == true)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'URGENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Adopción',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet['breed']} • ${pet['age']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pet['location'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostPetsContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lostPets.length,
      itemBuilder: (context, index) {
        return _buildLostPetCard(_lostPets[index]);
      },
    );
  }

  Widget _buildLostPetsCard() {
    return Column(
      children: _lostPets.take(2).map((pet) => _buildLostPetCard(pet)).toList(),
    );
  }

  Widget _buildLostPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () => _viewPetDetails(pet, 'lost'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                pet['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.pets, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pet['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PERDIDA',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet['breed'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        pet['lastSeen'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pet['location'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pet['reward'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Recompensa: ${pet['reward']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  Widget _buildMatingContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite, color: Colors.purple.shade600, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Encuentra la pareja perfecta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Conecta con otros dueños para el apareamiento responsable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _matingPets.length,
            itemBuilder: (context, index) {
              return _buildMatingCard(_matingPets[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatingCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () => _viewPetDetails(pet, 'mating'),
      child: Container(
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
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      pet['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (pet['certified'] == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CERTIFICADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet['breed']} • ${pet['age']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pet['location'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(_services[index]);
      },
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: _services.take(3).map((service) => _buildServiceCard(service)).toList(),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => _viewServiceDetails(service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                service['image'],
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.business, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7AA7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service['type'],
                          style: const TextStyle(
                            color: Color(0xFF4A7AA7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${service['rating']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        service['distance'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        service['price'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A7AA7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        service['hours'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Distancia
            const Text(
              'Distancia máxima',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Slider(
              value: 5.0,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              label: '5 km',
              activeColor: const Color(0xFF4A7AA7),
              onChanged: (value) {},
            ),

            const SizedBox(height: 16),

            // Tipo de mascota
            const Text(
              'Tipo de mascota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Perros', 'Gatos', 'Aves', 'Otros'].map((type) =>
                  FilterChip(
                    label: Text(type),
                    selected: false,
                    onSelected: (selected) {},
                    selectedColor: const Color(0xFF4A7AA7).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF4A7AA7),
                  ),
              ).toList(),
            ),

            const SizedBox(height: 16),

            // Edad
            const Text(
              'Edad',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Cachorro', 'Joven', 'Adulto', 'Senior'].map((age) =>
                  FilterChip(
                    label: Text(age),
                    selected: false,
                    onSelected: (selected) {},
                    selectedColor: const Color(0xFF4A7AA7).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF4A7AA7),
                  ),
              ).toList(),
            ),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7AA7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF4A7AA7)),
            SizedBox(width: 12),
            Text('Configurar Ubicación'),
          ],
        ),
        content: const Text(
          'Para mostrarte resultados más precisos, necesitamos acceso a tu ubicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Función de ubicación próximamente');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  void _scanQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF4A7AA7)),
            SizedBox(width: 12),
            Text('Escanear Código QR'),
          ],
        ),
        content: const Text(
          'Escanea el código QR de una mascota para ver su perfil e información completa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Escáner QR próximamente');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir Escáner'),
          ),
        ],
      ),
    );
  }

  void _viewPetDetails(Map<String, dynamic> pet, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen principal
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        pet['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Información básica
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet['name'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pet['breed'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (pet['age'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  pet['age'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTypeColor(type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getTypeLabel(type),
                            style: TextStyle(
                              color: _getTypeColor(type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Ubicación
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey.shade500, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          pet['location'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    if (pet['description'] != null) ...[
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet['description'],
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Información específica por tipo
                    if (type == 'lost' && pet['reward'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.monetization_on, color: Colors.green.shade600),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recompensa',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  pet['reward'],
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (type == 'lost' && pet['lastSeen'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange.shade600),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Última vez visto',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  pet['lastSeen'],
                                  style: TextStyle(color: Colors.orange.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _contactOwner(pet['contact']),
                            icon: const Icon(Icons.phone),
                            label: const Text('Contactar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7AA7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sharePet(pet),
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4A7AA7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewServiceDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        service['image'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.business, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A7AA7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service['type'],
                            style: const TextStyle(
                              color: Color(0xFF4A7AA7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${service['rating']} (127 reseñas)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildServiceInfo(Icons.location_on, 'Dirección', service['address']),
                    _buildServiceInfo(Icons.access_time, 'Horarios', service['hours']),
                    _buildServiceInfo(Icons.attach_money, 'Precios', service['price']),
                    _buildServiceInfo(Icons.route, 'Distancia', service['distance']),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callService(service['phone']),
                            icon: const Icon(Icons.phone),
                            label: const Text('Llamar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7AA7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _getDirections(service),
                            icon: const Icon(Icons.directions),
                            label: const Text('Ir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4A7AA7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'adoption':
        return Colors.red;
      case 'lost':
        return Colors.orange;
      case 'mating':
        return Colors.purple;
      default:
        return const Color(0xFF4A7AA7);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'adoption':
        return 'ADOPCIÓN';
      case 'lost':
        return 'PERDIDA';
      case 'mating':
        return 'APAREAMIENTO';
      default:
        return 'MASCOTA';
    }
  }

  void _contactOwner(String contact) {
    _showSnackBar('Función de contacto próximamente: $contact');
  }

  void _sharePet(Map<String, dynamic> pet) {
    _showSnackBar('Compartiendo información de ${pet['name']}');
  }

  void _callService(String phone) {
    _showSnackBar('Llamando a $phone');
  }

  void _getDirections(Map<String, dynamic> service) {
    _showSnackBar('Abriendo direcciones a ${service['name']}');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}