import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/event_model.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controladores de texto
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceDescriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _externalLinkController = TextEditingController();

  // Variables de estado
  EventType _selectedType = EventType.meetup;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 3));
  LocationData? _selectedLocation;
  List<File> _selectedImages = [];
  bool _isPetFriendly = true;
  List<String> _allowedPetTypes = [];
  bool _isFree = true;
  bool _isPrivate = false;
  List<String> _tags = [];
  bool _isLoading = false;

  final List<String> _availablePetTypes = [
    'Perros', 'Gatos', 'Aves', 'Conejos', 'Hámsters', 'Peces', 'Reptiles'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _priceController.dispose();
    _priceDescriptionController.dispose();
    _requirementsController.dispose();
    _contactInfoController.dispose();
    _externalLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Crear evento'),
        backgroundColor: const Color(0xFF4A7AA7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createEvent,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Crear',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Básico'),
            Tab(text: 'Detalles'),
            Tab(text: 'Configuración'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicTab(),
            _buildDetailsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          _buildSectionTitle('Información básica'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _titleController,
            label: 'Título del evento *',
            hint: 'Ej: Encuentro canino en el parque',
            validator: (value) => value?.isEmpty == true ? 'El título es requerido' : null,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _descriptionController,
            label: 'Descripción *',
            hint: 'Describe tu evento...',
            maxLines: 4,
            validator: (value) => value?.isEmpty == true ? 'La descripción es requerida' : null,
          ),

          const SizedBox(height: 20),

          // Tipo de evento
          _buildSectionTitle('Tipo de evento'),
          const SizedBox(height: 12),
          _buildEventTypeSelector(),

          const SizedBox(height: 20),

          // Imágenes
          _buildSectionTitle('Fotos del evento'),
          const SizedBox(height: 12),
          _buildImageSelector(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha y hora
          _buildSectionTitle('Fecha y hora'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  'Inicio *',
                  _startDate,
                      (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateTimeField(
                  'Fin *',
                  _endDate,
                      (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Ubicación
          _buildSectionTitle('Ubicación'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _locationController,
            label: 'Dirección *',
            hint: 'Ej: Parque Central, Calle 123',
            validator: (value) => value?.isEmpty == true ? 'La ubicación es requerida' : null,
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
            ),
          ),

          const SizedBox(height: 20),

          // Capacidad
          _buildSectionTitle('Capacidad'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _maxParticipantsController,
            label: 'Máximo de participantes',
            hint: 'Dejar vacío para sin límite',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 20),

          // Precio
          _buildSectionTitle('Precio'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Gratis'),
                  value: true,
                  groupValue: _isFree,
                  onChanged: (value) => setState(() => _isFree = value!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('De pago'),
                  value: false,
                  groupValue: _isFree,
                  onChanged: (value) => setState(() => _isFree = value!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          if (!_isFree) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Precio (\$)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _priceDescriptionController,
                    label: 'Descripción del precio',
                    hint: 'Ej: Incluye materiales',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet-friendly
          _buildSectionTitle('Mascotas'),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Pet-friendly'),
            subtitle: const Text('¿Se permiten mascotas en el evento?'),
            value: _isPetFriendly,
            onChanged: (value) => setState(() => _isPetFriendly = value),
            activeColor: const Color(0xFF4A7AA7),
            contentPadding: EdgeInsets.zero,
          ),

          if (_isPetFriendly) ...[
            const SizedBox(height: 12),
            Text(
              'Tipos de mascotas permitidas:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availablePetTypes.map((type) => FilterChip(
                label: Text(type),
                selected: _allowedPetTypes.contains(type),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _allowedPetTypes.add(type);
                    } else {
                      _allowedPetTypes.remove(type);
                    }
                  });
                },
                selectedColor: const Color(0xFF4A7AA7).withOpacity(0.2),
                checkmarkColor: const Color(0xFF4A7AA7),
              )).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // Privacidad
          _buildSectionTitle('Privacidad'),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Evento privado'),
            subtitle: const Text('Solo personas invitadas pueden ver el evento'),
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            activeColor: const Color(0xFF4A7AA7),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 20),

          // Requisitos
          _buildSectionTitle('Requisitos adicionales'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _requirementsController,
            label: 'Requisitos',
            hint: 'Ej: Traer correa, vacunas al día...',
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Información de contacto
          _buildSectionTitle('Contacto'),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _contactInfoController,
            label: 'Información de contacto',
            hint: 'Teléfono, email, etc.',
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _externalLinkController,
            label: 'Enlace externo',
            hint: 'https://...',
          ),

          const SizedBox(height: 20),

          // Tags
          _buildSectionTitle('Etiquetas'),
          const SizedBox(height: 16),
          _buildTagsInput(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A7AA7)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildEventTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: EventType.values.map((type) {
          final typeData = _getEventTypeData(type);
          return RadioListTile<EventType>(
            title: Row(
              children: [
                Icon(typeData['icon'], color: typeData['color'], size: 20),
                const SizedBox(width: 8),
                Text(typeData['label']),
              ],
            ),
            value: type,
            groupValue: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
            activeColor: const Color(0xFF4A7AA7),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          if (_selectedImages.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Agregar fotos del evento'),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.add, color: Colors.grey),
                      ),
                    );
                  }

                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
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
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeField(String label, DateTime dateTime, Function(DateTime) onChanged) {
    return GestureDetector(
      onTap: () => _selectDateTime(dateTime, onChanged),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
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
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text('#$tag'),
              onDeleted: () => setState(() => _tags.remove(tag)),
              deleteIcon: const Icon(Icons.close, size: 16),
              backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
              labelStyle: const TextStyle(color: Color(0xFF4A7AA7)),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          decoration: InputDecoration(
            labelText: 'Agregar etiqueta',
            hintText: 'Ej: perros, entrenamiento, diversión',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A7AA7)),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(),
            ),
          ),
          onSubmitted: (value) => _addTag(value),
        ),
      ],
    );
  }

  // Métodos de utilidad
  Map<String, dynamic> _getEventTypeData(EventType type) {
    switch (type) {
      case EventType.meetup:
        return {
          'label': 'Encuentro',
          'icon': Icons.people,
          'color': const Color(0xFF3498DB),
        };
      case EventType.training:
        return {
          'label': 'Entrenamiento',
          'icon': Icons.school,
          'color': const Color(0xFF9B59B6),
        };
      case EventType.veterinary:
        return {
          'label': 'Veterinario',
          'icon': Icons.medical_services,
          'color': const Color(0xFF27AE60),
        };
      case EventType.adoption:
        return {
          'label': 'Adopción',
          'icon': Icons.favorite,
          'color': const Color(0xFFE67E22),
        };
      case EventType.contest:
        return {
          'label': 'Concurso',
          'icon': Icons.emoji_events,
          'color': const Color(0xFFF39C12),
        };
      case EventType.social:
        return {
          'label': 'Social',
          'icon': Icons.celebration,
          'color': const Color(0xFFE74C3C),
        };
      case EventType.other:
        return {
          'label': 'Otro',
          'icon': Icons.event,
          'color': const Color(0xFF95A5A6),
        };
    }
  }

  // Métodos de acción
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seleccionar imágenes')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDateTime(DateTime current, Function(DateTime) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7AA7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      if (!mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4A7AA7),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(newDateTime);
      }
    }
  }

  void _getCurrentLocation() {
    // Implementar obtener ubicación actual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de ubicación próximamente')),
    );
  }

  void _addTag([String? value]) {
    final tagController = TextEditingController();

    if (value != null && value.isNotEmpty) {
      final tag = value.trim().toLowerCase();
      if (tag.isNotEmpty && !_tags.contains(tag)) {
        setState(() {
          _tags.add(tag);
        });
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar etiqueta'),
        content: TextField(
          controller: tagController,
          decoration: const InputDecoration(
            hintText: 'Escribe una etiqueta...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final tag = tagController.text.trim().toLowerCase();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() {
                  _tags.add(tag);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
      );
      return;
    }

    // Validaciones adicionales
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de inicio debe ser anterior a la fecha de fin')),
      );
      return;
    }

    if (_startDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de inicio debe ser futura')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear ubicación
      final location = LocationData(
        latitude: 0.0, // TODO: Implementar coordenadas reales
        longitude: 0.0,
        address: _locationController.text.trim(),
      );

      // Parsear precio si no es gratis
      double? price;
      if (!_isFree && _priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text);
      }

      // Parsear máximo de participantes
      int maxParticipants = 0;
      if (_maxParticipantsController.text.isNotEmpty) {
        maxParticipants = int.tryParse(_maxParticipantsController.text) ?? 0;
      }

      final eventId = await eventProvider.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        creatorId: authProvider.currentUser!.id,
        startDate: _startDate,
        endDate: _endDate,
        location: location,
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        maxParticipants: maxParticipants,
        isPetFriendly: _isPetFriendly,
        allowedPetTypes: _allowedPetTypes,
        price: price,
        priceDescription: _priceDescriptionController.text.trim().isNotEmpty
            ? _priceDescriptionController.text.trim()
            : null,
        isPrivate: _isPrivate,
        requirements: _requirementsController.text.trim().isNotEmpty
            ? _requirementsController.text.trim()
            : null,
        tags: _tags,
        contactInfo: _contactInfoController.text.trim().isNotEmpty
            ? _contactInfoController.text.trim()
            : null,
        externalLink: _externalLinkController.text.trim().isNotEmpty
            ? _externalLinkController.text.trim()
            : null,
      );

      if (eventId != null) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Error al crear el evento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}