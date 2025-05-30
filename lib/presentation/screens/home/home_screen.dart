import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.home, 'label': 'Alojamiento', 'route': '/alojamiento'},
    {'icon': Icons.child_care, 'label': 'Guardería', 'route': '/guarderia'},
    {'icon': Icons.event_seat, 'label': 'Sentada', 'route': '/sentada'},
    {'icon': Icons.pets, 'label': 'Paseo de Perros', 'route': '/paseo'},
    {'icon': Icons.local_taxi, 'label': 'Taxi', 'route': '/taxi'},
    {'icon': Icons.content_cut, 'label': 'Peluquería', 'route': '/peluqueria'},
    {'icon': Icons.school, 'label': 'Capacitación', 'route': '/capacitacion'},
    {'icon': Icons.more_horiz, 'label': 'Más', 'route': '/mas'},
    {'icon': Icons.medical_services, 'label': 'Veterinaria', 'route': '/veterinaria'},
    {'icon': Icons.assignment, 'label': 'Vacunas', 'route': '/vacunas'},
    {'icon': Icons.schedule, 'label': 'Recordatorios', 'route': '/recordatorios'},
    {'icon': Icons.info, 'label': 'Perfil Mascota', 'route': '/perfil'},
  ];

  final List<String> caretakerImages = [
    'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1507146426996-ef05306b995a?auto=format&fit=crop&w=400&q=80',
  ];

  final List<Map<String, String>> recentActivities = [
    {
      'title': 'Paseo diario completado',
      'time': 'Hace 2 horas',
      'image': 'https://images.unsplash.com/photo-1517423440428-a5a00ad493e8?auto=format&fit=crop&w=80&q=80',
    },
    {
      'title': 'Vacuna actualizada',
      'time': 'Ayer',
      'image': 'https://images.unsplash.com/photo-1525253086316-d0c936c814f8?auto=format&fit=crop&w=80&q=80',
    },
    {
      'title': 'Nuevo registro en guardería',
      'time': 'Hace 3 días',
      'image': 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=80&q=80',
    },
  ];

  final List<Map<String, dynamic>> recommendedProfiles = [
    {
      'name': 'María García',
      'service': 'Veterinaria',
      'rating': 4.9,
      'reviews': 145,
      'distance': '1.2 km',
      'image': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&q=80',
      'speciality': 'Medicina General',
      'isVerified': true,
    },
    {
      'name': 'Carlos Mendoza',
      'service': 'Paseo de Perros',
      'rating': 4.8,
      'reviews': 89,
      'distance': '800 m',
      'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
      'speciality': 'Razas Grandes',
      'isVerified': true,
    },
    {
      'name': 'Ana López',
      'service': 'Peluquería',
      'rating': 4.7,
      'reviews': 67,
      'distance': '1.5 km',
      'image': 'https://images.unsplash.com/photo-1494790108755-2616c9c1e0ae?auto=format&fit=crop&w=400&q=80',
      'speciality': 'Estética Canina',
      'isVerified': false,
    },
  ];

  void _navigateToService(BuildContext context, String service, String route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceScreen(serviceName: service),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buscar'),
          content: const TextField(
            decoration: InputDecoration(
              hintText: 'Buscar servicios...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A5AE2),
        title: const Text(
          'PetsId',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Grid de opciones
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GestureDetector(
                  onTap: () => _navigateToService(context, item['label'], item['route']),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A5AE2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(item['icon'], color: const Color(0xFF6A5AE2), size: 24),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Sección de Perfiles Recomendados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Perfiles Recomendados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecommendedProfilesScreen(),
                      ),
                    );
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedProfiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final profile = recommendedProfiles[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommendedProfileDetailScreen(
                            profile: profile,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.network(
                                  profile['image'],
                                  width: 160,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (profile['isVerified'])
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile['service'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${profile['rating']} (${profile['reviews']})',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.grey[500],
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      profile['distance'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
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
                },
              ),
            ),

            const SizedBox(height: 20),

            // Cuidadores cercanos + ver todos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cuidadores cercanos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CaretakersScreen(),
                      ),
                    );
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: caretakerImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CaretakerDetailScreen(
                            imageUrl: caretakerImages[index],
                            caretakerName: 'Cuidador ${index + 1}',
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            caretakerImages[index],
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cuidador ${index + 1} agregado a favoritos'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.favorite_border,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Sección de últimas actividades
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimos registros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        activity['image']!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(activity['title']!),
                  subtitle: Text(
                    activity['time']!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityDetailScreen(
                          title: activity['title']!,
                          time: activity['time']!,
                          imageUrl: activity['image']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Pantalla de todos los perfiles recomendados
class RecommendedProfilesScreen extends StatelessWidget {
  const RecommendedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles Recomendados'),
        backgroundColor: const Color(0xFF6A5AE2),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Lista completa de perfiles recomendados',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// Pantalla de detalle del perfil recomendado
class RecommendedProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  const RecommendedProfileDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile['name']),
        backgroundColor: const Color(0xFF6A5AE2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  child: Image.network(
                    profile['image'],
                    fit: BoxFit.cover,
                  ),
                ),
                if (profile['isVerified'])
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Verificado',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile['name'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A5AE2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile['service'],
                          style: const TextStyle(
                            color: Color(0xFF6A5AE2),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Especialidad: ${profile['speciality']}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${profile['rating']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${profile['reviews']} reseñas)',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'A ${profile['distance']} de distancia',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sobre el profesional',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profesional con amplia experiencia en ${profile['service'].toLowerCase()}. Comprometido con el bienestar y cuidado de las mascotas. Ofrece servicios de alta calidad con atención personalizada.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Contactando a ${profile['name']}...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5AE2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.phone),
                          label: const Text('Contactar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${profile['name']} agregado a favoritos')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6A5AE2),
                            side: const BorderSide(color: Color(0xFF6A5AE2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Guardar'),
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
}

// Pantalla genérica para servicios
class ServiceScreen extends StatelessWidget {
  final String serviceName;

  const ServiceScreen({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: const Color(0xFF6A5AE2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: const Color(0xFF6A5AE2),
            ),
            const SizedBox(height: 20),
            Text(
              'Servicio de $serviceName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Esta funcionalidad estará disponible pronto',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de todos los cuidadores
class CaretakersScreen extends StatelessWidget {
  const CaretakersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Cuidadores'),
        backgroundColor: const Color(0xFF6A5AE2),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Lista completa de cuidadores',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// Pantalla de detalle del cuidador
class CaretakerDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String caretakerName;

  const CaretakerDetailScreen({
    super.key,
    required this.imageUrl,
    required this.caretakerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(caretakerName),
        backgroundColor: const Color(0xFF6A5AE2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caretakerName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cuidador profesional de mascotas con amplia experiencia.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star_half, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text('4.5 (120 reseñas)'),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contactando cuidador...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5AE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Contactar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de detalle de actividad
class ActivityDetailScreen extends StatelessWidget {
  final String title;
  final String time;
  final String imageUrl;

  const ActivityDetailScreen({
    super.key,
    required this.title,
    required this.time,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Actividad'),
        backgroundColor: const Color(0xFF6A5AE2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              time,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Detalles de la actividad realizada con tu mascota. Aquí puedes ver más información sobre lo que se hizo durante este servicio.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}