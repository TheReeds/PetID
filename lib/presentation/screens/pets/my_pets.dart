import 'package:flutter/material.dart';

// Modelos de datos
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String role;
  final String profilePhotoUrl;
  final DateTime memberSince;
  final List<String> emergencyContacts;
  final UserPreferences preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    required this.role,
    required this.profilePhotoUrl,
    required this.memberSince,
    this.emergencyContacts = const [],
    required this.preferences,
  });
}

class UserPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final String language;
  final String currency;
  final bool shareLocation;
  final bool shareHealthData;

  UserPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.language = 'es',
    this.currency = 'PEN',
    this.shareLocation = false,
    this.shareHealthData = false,
  });
}

class Pet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final DateTime birthDate;
  final String sex;
  final double weight;
  final String photoUrl;
  final String description;
  final bool isLost;
  final HealthInfo healthInfo;
  final List<Activity> activities;
  final List<Reminder> reminders;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthDate,
    required this.sex,
    required this.weight,
    required this.photoUrl,
    this.description = '',
    this.isLost = false,
    required this.healthInfo,
    this.activities = const [],
    this.reminders = const [],
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  Pet copyWith({bool? isLost}) {
    return Pet(
      id: id,
      name: name,
      species: species,
      breed: breed,
      birthDate: birthDate,
      sex: sex,
      weight: weight,
      photoUrl: photoUrl,
      description: description,
      isLost: isLost ?? this.isLost,
      healthInfo: healthInfo,
      activities: activities,
      reminders: reminders,
    );
  }
}

class HealthInfo {
  final List<Vaccination> vaccinations;
  final List<String> allergies;
  final List<String> medications;
  final String? veterinarian;
  final DateTime? lastCheckup;
  final String generalHealth;

  HealthInfo({
    this.vaccinations = const [],
    this.allergies = const [],
    this.medications = const [],
    this.veterinarian,
    this.lastCheckup,
    this.generalHealth = 'Buena',
  });
}

class Vaccination {
  final String name;
  final DateTime date;
  final DateTime? nextDue;

  Vaccination({
    required this.name,
    required this.date,
    this.nextDue,
  });
}

class Activity {
  final String id;
  final String type;
  final DateTime date;
  final String description;
  final int? duration;

  Activity({
    required this.id,
    required this.type,
    required this.date,
    required this.description,
    this.duration,
  });
}

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String type;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.type,
    this.isCompleted = false,
  });
}

class Service {
  final String id;
  final String name;
  final String type;
  final double rating;
  final String contact;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.contact,
    this.isActive = true,
  });
}

// Pantalla principal del perfil
class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;

  // Datos de ejemplo
  final User currentUser = User(
    id: '1',
    name: 'María González',
    email: 'maria.gonzalez@email.com',
    phone: '+51 987 654 321',
    address: 'Av. Larco 123, Lima, Perú',
    role: 'Dueño',
    profilePhotoUrl: 'https://www.gravatar.com/avatar/?d=mp&s=200',
    memberSince: DateTime(2023, 1, 15),
    emergencyContacts: ['Dr. Veterinario: +51 999 888 777', 'Familiar: +51 955 444 333'],
    preferences: UserPreferences(),
  );

  List<Pet> userPets = [
    Pet(
      id: '1',
      name: 'Firulais',
      species: 'Perro',
      breed: 'Golden Retriever',
      birthDate: DateTime(2020, 5, 15),
      sex: 'Macho',
      weight: 25.5,
      photoUrl: 'https://placedog.net/400/300?id=1',
      description: 'Firulais es un perro muy amigable y activo. Le encanta jugar en el parque.',
      healthInfo: HealthInfo(
        vaccinations: [
          Vaccination(name: 'Rabia', date: DateTime(2024, 1, 15), nextDue: DateTime(2025, 1, 15)),
          Vaccination(name: 'Parvovirus', date: DateTime(2024, 2, 20)),
        ],
        allergies: ['Polen'],
        generalHealth: 'Excelente',
        veterinarian: 'Dr. Pérez',
        lastCheckup: DateTime(2024, 11, 1),
      ),
      activities: [
        Activity(id: '1', type: 'Paseo', date: DateTime.now(), description: 'Paseo matutino', duration: 30),
        Activity(id: '2', type: 'Alimentación', date: DateTime.now(), description: 'Desayuno'),
      ],
      reminders: [
        Reminder(
          id: '1',
          title: 'Vacuna contra rabia',
          description: 'Renovar vacuna anual',
          dueDate: DateTime(2025, 1, 15),
          type: 'Vacuna',
        ),
      ],
    ),
    Pet(
      id: '2',
      name: 'Michi',
      species: 'Gato',
      breed: 'Siamés',
      birthDate: DateTime(2021, 8, 10),
      sex: 'Hembra',
      weight: 4.2,
      photoUrl: 'https://placedog.net/400/300?id=2',
      description: 'Michi es un gato tranquilo y cariñoso. Ama dormir al sol.',
      healthInfo: HealthInfo(
        vaccinations: [
          Vaccination(name: 'Triple felina', date: DateTime(2024, 3, 10)),
        ],
        generalHealth: 'Buena',
      ),
      activities: [],
      reminders: [],
    ),
    Pet(
      id: '3',
      name: 'Max',
      species: 'Perro',
      breed: 'Labrador',
      birthDate: DateTime(2019, 12, 3),
      sex: 'Macho',
      weight: 30.0,
      photoUrl: 'https://placedog.net/400/300?id=4',
      description: 'Max es un golden retriever muy cariñoso.',
      isLost: true,
      healthInfo: HealthInfo(generalHealth: 'Buena'),
      activities: [],
      reminders: [],
    ),
  ];

  final List<Service> services = [
    Service(id: '1', name: 'Veterinaria San Marcos', type: 'Veterinario', rating: 4.8, contact: '+51 999 111 222'),
    Service(id: '2', name: 'Guardería Pet Hotel', type: 'Guardería', rating: 4.5, contact: '+51 988 333 444'),
    Service(id: '3', name: 'Peluquería Canina Glamour', type: 'Peluquería', rating: 4.7, contact: '+51 977 555 666'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    _buildNavigationTabs(),
                    const SizedBox(height: 24),
                    _buildContent(),
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
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade400,
                Colors.purple.shade400,
                Colors.pink.shade300,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(currentUser.profilePhotoUrl),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentUser.role,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    final tabs = ['Mascotas', 'Actividad', 'Servicios', 'Perfil'];

    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildPetsTab();
      case 1:
        return _buildActivityTab();
      case 2:
        return _buildServicesTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildPetsTab();
    }
  }

  Widget _buildPetsTab() {
    final lostPets = userPets.where((pet) => pet.isLost).length;
    final safePets = userPets.length - lostPets;

    return Column(
      children: [
        // Estadísticas
        Row(
          children: [
            Expanded(child: _buildStatCard('En Casa', '$safePets', Icons.home, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Perdidas', '$lostPets', Icons.warning, Colors.red)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total', '${userPets.length}', Icons.pets, Colors.blue)),
          ],
        ),
        const SizedBox(height: 24),

        // Header con botón agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Mascotas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            FloatingActionButton.small(
              onPressed: _addNewPet,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid de mascotas
        if (userPets.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: userPets.length,
            itemBuilder: (context, index) => _buildPetCard(userPets[index]),
          ),
      ],
    );
  }

  Widget _buildActivityTab() {
    final allActivities = userPets
        .expand((pet) => pet.activities.map((activity) => MapEntry(pet, activity)))
        .toList()
      ..sort((a, b) => b.value.date.compareTo(a.value.date));

    final allReminders = userPets
        .expand((pet) => pet.reminders.map((reminder) => MapEntry(pet, reminder)))
        .where((entry) => !entry.value.isCompleted)
        .toList()
      ..sort((a, b) => a.value.dueDate.compareTo(b.value.dueDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recordatorios pendientes
        if (allReminders.isNotEmpty) ...[
          const Text(
            'Recordatorios Pendientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...allReminders.take(3).map((entry) => _buildReminderCard(entry.key, entry.value)),
          const SizedBox(height: 24),
        ],

        // Actividades recientes
        const Text(
          'Actividad Reciente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (allActivities.isEmpty)
          _buildNoActivityState()
        else
          ...allActivities.take(5).map((entry) => _buildActivityCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildServicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Servicios Favoritos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {}, // Implementar búsqueda de servicios
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...services.map((service) => _buildServiceCard(service)),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información personal
        _buildInfoSection('Información Personal', [
          _buildInfoRow('Email', currentUser.email, Icons.email),
          _buildInfoRow('Teléfono', currentUser.phone, Icons.phone),
          if (currentUser.address != null)
            _buildInfoRow('Dirección', currentUser.address!, Icons.location_on),
          _buildInfoRow('Miembro desde',
              '${currentUser.memberSince.day}/${currentUser.memberSince.month}/${currentUser.memberSince.year}',
              Icons.calendar_today),
        ]),

        const SizedBox(height: 24),

        // Contactos de emergencia
        _buildInfoSection('Contactos de Emergencia',
            currentUser.emergencyContacts.map((contact) =>
                _buildInfoRow('Contacto', contact, Icons.emergency)).toList()),

        const SizedBox(height: 24),

        // Configuración
        _buildInfoSection('Configuración', [
          _buildSwitchRow('Notificaciones Push', currentUser.preferences.pushNotifications),
          _buildSwitchRow('Notificaciones Email', currentUser.preferences.emailNotifications),
          _buildSwitchRow('Compartir Ubicación', currentUser.preferences.shareLocation),
          _buildSwitchRow('Compartir Datos de Salud', currentUser.preferences.shareHealthData),
        ]),

        const SizedBox(height: 32),

        // Botón cerrar sesión
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {}, // Implementar cierre de sesión
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () => _showPetDetails(pet),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Imagen
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        pet.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.pets, size: 40, color: Colors.grey),
                        ),
                      ),
                      if (pet.isLost)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.red.withOpacity(0.3), Colors.transparent],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: pet.isLost ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pet.isLost ? 'Perdida' : 'En casa',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Información
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed} • ${pet.ageInMonths ~/ 12} años',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.monitor_weight, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.weight} kg',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

  Widget _buildReminderCard(Pet pet, Reminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(width: 4, color: Colors.orange)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notification_important, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reminder.title} - ${pet.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {}, // Marcar como completado
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Pet pet, Activity activity) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case 'Paseo':
        icon = Icons.directions_walk;
        color = Colors.blue;
        break;
      case 'Alimentación':
        icon = Icons.restaurant;
        color = Colors.green;
        break;
      case 'Juego':
        icon = Icons.sports_esports;
        color = Colors.purple;
        break;
      default:
        icon = Icons.pets;
        color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.type} - ${pet.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${activity.date.hour.toString().padLeft(2, '0')}:${activity.date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (activity.duration != null)
                Text(
                  '${activity.duration} min',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(
              _getServiceIcon(service.type),
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  service.type,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      service.rating.toString(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callService(service.contact),
            icon: const Icon(Icons.phone, color: Colors.green),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'Veterinario':
        return Icons.medical_services;
      case 'Guardería':
        return Icons.hotel;
      case 'Peluquería':
        return Icons.content_cut;
      default:
        return Icons.business;
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Implementar cambio de configuración
            },
            activeColor: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes mascotas registradas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera mascota para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActivityState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay actividades registradas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las actividades de tus mascotas aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewPet() {
    // Implementar navegación a pantalla de agregar mascota
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función agregar mascota en desarrollo')),
    );
  }

  void _showPetDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPetDetailsSheet(pet),
    );
  }

  Widget _buildPetDetailsSheet(Pet pet) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
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
                  // Imagen y estado
                  Center(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            pet.photoUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                            ),
                          ),
                        ),
                        if (pet.isLost)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
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
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información básica
                  Text(
                    pet.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pet.breed} • ${pet.species} • ${pet.sex}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.ageInMonths ~/ 12} años • ${pet.weight} kg',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),

                  if (pet.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Descripción',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Información de salud
                  Text(
                    'Información de Salud',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _buildHealthInfo(pet.healthInfo),

                  const SizedBox(height: 24),

                  // Botones de acción
                  if (pet.isLost)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _markAsFound(pet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Marcar como Encontrada'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _markAsLost(pet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reportar como Perdida'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfo(HealthInfo health) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (health.veterinarian != null) ...[
            Text('Veterinario: ${health.veterinarian}'),
            const SizedBox(height: 8),
          ],
          Text('Estado General: ${health.generalHealth}'),
          if (health.lastCheckup != null) ...[
            const SizedBox(height: 8),
            Text('Último Chequeo: ${health.lastCheckup!.day}/${health.lastCheckup!.month}/${health.lastCheckup!.year}'),
          ],
          if (health.vaccinations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Vacunas:', style: TextStyle(fontWeight: FontWeight.w600)),
            ...health.vaccinations.map((vac) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('• ${vac.name} (${vac.date.day}/${vac.date.month}/${vac.date.year})'),
            )),
          ],
          if (health.allergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Alergias:', style: TextStyle(fontWeight: FontWeight.w600)),
            ...health.allergies.map((allergy) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('• $allergy'),
            )),
          ],
        ],
      ),
    );
  }

  void _callService(String contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Llamando a $contact')),
    );
  }

  void _markAsFound(Pet pet) {
    setState(() {
      final index = userPets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        userPets[index] = pet.copyWith(isLost: false);
      }
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pet.name} marcada como encontrada')),
    );
  }

  void _markAsLost(Pet pet) {
    setState(() {
      final index = userPets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        userPets[index] = pet.copyWith(isLost: true);
      }
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pet.name} reportada como perdida')),
    );
  }
}