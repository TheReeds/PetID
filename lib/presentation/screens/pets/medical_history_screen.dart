import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/pet_model.dart';
import '../../providers/pet_provider.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final PetModel pet;

  const MedicalHistoryScreen({
    super.key,
    required this.pet,
  });

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildVaccinationsTab(),
                  _buildMedicalRecordsTab(),
                  _buildVeterinarianTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Historial Médico - ${widget.pet.name}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.teal.shade600,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareReport,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportReport();
                break;
              case 'print':
                _printReport();
                break;
              case 'edit':
                _editHealthInfo();
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
                  Text('Editar información'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 12),
                  Text('Exportar reporte'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, size: 20),
                  SizedBox(width: 12),
                  Text('Imprimir'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade600,
            Colors.teal.shade400,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: widget.pet.profilePhoto != null
                      ? Image.network(
                    widget.pet.profilePhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPetPlaceholder(),
                  )
                      : _buildPetPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.pet.breed} • ${widget.pet.displayAge}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildHealthBadge(
                          widget.pet.healthInfo?.generalHealth ?? 'Sin datos',
                          _getHealthColor(widget.pet.healthInfo?.generalHealth),
                        ),
                        const SizedBox(width: 8),
                        if (widget.pet.isVaccinated)
                          _buildHealthBadge('Vacunado', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetPlaceholder() {
    return Container(
      color: Colors.white,
      child: Icon(
        Icons.pets,
        size: 40,
        color: Colors.teal.shade300,
      ),
    );
  }

  Widget _buildHealthBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getHealthColor(String? health) {
    switch (health?.toLowerCase()) {
      case 'excelente':
        return Colors.green;
      case 'buena':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'mala':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.teal.shade600,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.teal.shade600,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard, size: 20),
            text: 'Resumen',
          ),
          Tab(
            icon: Icon(Icons.vaccines, size: 20),
            text: 'Vacunas',
          ),
          Tab(
            icon: Icon(Icons.history, size: 20),
            text: 'Historial',
          ),
          Tab(
            icon: Icon(Icons.local_hospital, size: 20),
            text: 'Veterinario',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final healthInfo = widget.pet.healthInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjetas de resumen rápido
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Estado General',
                  healthInfo?.generalHealth ?? 'Sin datos',
                  Icons.health_and_safety,
                  _getHealthColor(healthInfo?.generalHealth),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Vacunas',
                  '${healthInfo?.vaccinations.length ?? 0}',
                  Icons.vaccines,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Alergias',
                  '${healthInfo?.allergies.length ?? 0}',
                  Icons.warning_amber,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Medicamentos',
                  '${healthInfo?.medications.length ?? 0}',
                  Icons.medication,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Información detallada
          if (healthInfo != null) ...[
            // Próximas citas
            _buildInfoCard(
              'Próximas Citas',
              Icons.calendar_today,
              Colors.indigo,
              [
                if (healthInfo.nextCheckup != null)
                  _buildInfoRow(
                    'Próximo chequeo',
                    _formatDate(healthInfo.nextCheckup!),
                    Icons.event,
                  ),
                if (_getNextVaccination() != null)
                  _buildInfoRow(
                    'Próxima vacuna',
                    '${_getNextVaccination()!.name} - ${_formatDate(_getNextVaccination()!.nextDue!)}',
                    Icons.vaccines,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Información médica básica
            _buildInfoCard(
              'Información Médica',
              Icons.medical_services,
              Colors.teal,
              [
                if (healthInfo.lastCheckup != null)
                  _buildInfoRow(
                    'Último chequeo',
                    _formatDate(healthInfo.lastCheckup!),
                    Icons.event_note,
                  ),
                if (healthInfo.veterinarian != null)
                  _buildInfoRow(
                    'Veterinario',
                    healthInfo.veterinarian!,
                    Icons.person,
                  ),
                if (healthInfo.temperature != null)
                  _buildInfoRow(
                    'Última temperatura',
                    '${healthInfo.temperature}°C',
                    Icons.thermostat,
                  ),
                if (healthInfo.bloodType != null)
                  _buildInfoRow(
                    'Tipo de sangre',
                    healthInfo.bloodType!,
                    Icons.bloodtype,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Alergias y medicamentos
            if (healthInfo.allergies.isNotEmpty || healthInfo.medications.isNotEmpty)
              _buildInfoCard(
                'Alergias y Medicamentos',
                Icons.warning,
                Colors.red,
                [
                  if (healthInfo.allergies.isNotEmpty)
                    _buildInfoRow(
                      'Alergias',
                      healthInfo.allergies.join(', '),
                      Icons.warning_amber,
                    ),
                  if (healthInfo.medications.isNotEmpty)
                    _buildInfoRow(
                      'Medicamentos actuales',
                      healthInfo.medications.join(', '),
                      Icons.medication,
                    ),
                ],
              ),
          ] else
            _buildEmptyState(
              'Sin información médica',
              'Agrega información médica para un mejor seguimiento',
              Icons.medical_services,
            ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsTab() {
    final vaccinations = widget.pet.healthInfo?.vaccinations ?? [];

    return vaccinations.isEmpty
        ? _buildEmptyState(
      'Sin vacunas registradas',
      'Agrega las vacunas de tu mascota para llevar un control',
      Icons.vaccines,
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vaccinations.length,
      itemBuilder: (context, index) {
        final vaccination = vaccinations[index];
        final isExpired = vaccination.nextDue != null &&
            vaccination.nextDue!.isBefore(DateTime.now());
        final isDueSoon = vaccination.nextDue != null &&
            vaccination.nextDue!
                .difference(DateTime.now())
                .inDays <= 30 &&
            !isExpired;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildVaccinationCard(vaccination, isExpired, isDueSoon),
        );
      },
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination, bool isExpired, bool isDueSoon) {
    Color statusColor = Colors.green;
    String statusText = 'Al día';
    IconData statusIcon = Icons.check_circle;

    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Vencida';
      statusIcon = Icons.error;
    } else if (isDueSoon) {
      statusColor = Colors.orange;
      statusText = 'Próxima';
      statusIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccination.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          _buildDetailRow('Fecha aplicada', _formatDate(vaccination.date)),
          if (vaccination.nextDue != null)
            _buildDetailRow('Próxima dosis', _formatDate(vaccination.nextDue!)),
          if (vaccination.veterinarian != null)
            _buildDetailRow('Veterinario', vaccination.veterinarian!),
          if (vaccination.manufacturer != null)
            _buildDetailRow('Fabricante', vaccination.manufacturer!),
          if (vaccination.batchNumber != null)
            _buildDetailRow('Lote', vaccination.batchNumber!),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    final records = widget.pet.healthInfo?.medicalHistory ?? [];

    return records.isEmpty
        ? _buildEmptyState(
      'Sin historial médico',
      'Los registros médicos aparecerán aquí',
      Icons.history,
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildMedicalRecordCard(record),
        );
      },
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    Color typeColor = _getRecordTypeColor(record.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.3)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getRecordTypeIcon(record.type), color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(record.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.description,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (record.veterinarian != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dr. ${record.veterinarian}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (record.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: record.attachments.map((attachment) =>
                  Chip(
                    label: const Text('Adjunto'),
                    avatar: const Icon(Icons.attachment, size: 16),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVeterinarianTab() {
    final healthInfo = widget.pet.healthInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (healthInfo?.veterinarian != null) ...[
            _buildInfoCard(
              'Veterinario Principal',
              Icons.local_hospital,
              Colors.blue,
              [
                _buildInfoRow(
                  'Nombre',
                  'Dr. ${healthInfo!.veterinarian!}',
                  Icons.person,
                ),
                if (healthInfo.veterinarianPhone != null)
                  _buildInfoRow(
                    'Teléfono',
                    healthInfo.veterinarianPhone!,
                    Icons.phone,
                    onTap: () => _callVeterinarian(healthInfo.veterinarianPhone!),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Contacto de emergencia
          if (widget.pet.emergencyContact != null) ...[
            _buildInfoCard(
              'Contacto de Emergencia',
              Icons.emergency,
              Colors.red,
              [
                _buildInfoRow(
                  'Nombre',
                  widget.pet.emergencyContact!.name,
                  Icons.person,
                ),
                _buildInfoRow(
                  'Teléfono',
                  widget.pet.emergencyContact!.phone,
                  Icons.phone,
                  onTap: () => _callEmergency(widget.pet.emergencyContact!.phone),
                ),
                if (widget.pet.emergencyContact!.email != null)
                  _buildInfoRow(
                    'Email',
                    widget.pet.emergencyContact!.email!,
                    Icons.email,
                  ),
                if (widget.pet.emergencyContact!.relationship != null)
                  _buildInfoRow(
                    'Relación',
                    widget.pet.emergencyContact!.relationship!,
                    Icons.family_restroom,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          'Llamar Veterinario',
          Icons.phone,
          Colors.blue,
          widget.pet.healthInfo?.veterinarianPhone != null
              ? () => _callVeterinarian(widget.pet.healthInfo!.veterinarianPhone!)
              : null,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Agendar Cita',
          Icons.calendar_today,
          Colors.green,
              () => _scheduleAppointment(),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Buscar Veterinarios Cercanos',
          Icons.location_on,
          Colors.orange,
              () => _findNearbyVets(),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text,
      IconData icon,
      Color color,
      VoidCallback? onPressed,
      ) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Row(
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...children,
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Sin información disponible',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.grey.shade50 : null,
          borderRadius: onTap != null ? BorderRadius.circular(8) : null,
        ),
        child: Row(
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
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addMedicalInfo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar información'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddOptions(),
      backgroundColor: Colors.teal.shade600,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Agregar',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Helper methods
  Vaccination? _getNextVaccination() {
    final vaccinations = widget.pet.healthInfo?.vaccinations ?? [];
    final upcomingVaccinations = vaccinations
        .where((v) => v.nextDue != null && v.nextDue!.isAfter(DateTime.now()))
        .toList();

    if (upcomingVaccinations.isEmpty) return null;

    upcomingVaccinations.sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    return upcomingVaccinations.first;
  }

  Color _getRecordTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'consulta':
        return Colors.blue;
      case 'cirugía':
        return Colors.red;
      case 'emergencia':
        return Colors.orange;
      case 'chequeo':
        return Colors.green;
      case 'vacuna':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'consulta':
        return Icons.medical_services;
      case 'cirugía':
        return Icons.healing;
      case 'emergencia':
        return Icons.emergency;
      case 'chequeo':
        return Icons.health_and_safety;
      case 'vacuna':
        return Icons.vaccines;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  // Action methods
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
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
            const Text(
              'Agregar información médica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAddOption(
              'Vacuna',
              'Registrar una nueva vacuna',
              Icons.vaccines,
              Colors.blue,
                  () => _addVaccination(),
            ),
            _buildAddOption(
              'Consulta médica',
              'Agregar registro de consulta',
              Icons.medical_services,
              Colors.green,
                  () => _addMedicalRecord('Consulta'),
            ),
            _buildAddOption(
              'Medicamento',
              'Registrar medicamento',
              Icons.medication,
              Colors.purple,
                  () => _addMedication(),
            ),
            _buildAddOption(
              'Emergencia',
              'Registro de emergencia',
              Icons.emergency,
              Colors.red,
                  () => _addMedicalRecord('Emergencia'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  void _addVaccination() {
    _showSnackBar('Función para agregar vacuna próximamente');
  }

  void _addMedicalRecord(String type) {
    _showSnackBar('Función para agregar $type próximamente');
  }

  void _addMedication() {
    _showSnackBar('Función para agregar medicamento próximamente');
  }

  void _addMedicalInfo() {
    _showAddOptions();
  }

  void _editHealthInfo() {
    _showSnackBar('Función para editar información médica próximamente');
  }

  void _shareReport() {
    _showSnackBar('Función para compartir reporte próximamente');
  }

  void _exportReport() {
    _showSnackBar('Función para exportar reporte próximamente');
  }

  void _printReport() {
    _showSnackBar('Función para imprimir reporte próximamente');
  }

  void _callVeterinarian(String phone) {
    _showSnackBar('Llamando a $phone...');
    // Implementar llamada telefónica
  }

  void _callEmergency(String phone) {
    _showSnackBar('Llamando a emergencia: $phone...');
    // Implementar llamada telefónica
  }

  void _scheduleAppointment() {
    _showSnackBar('Función para agendar cita próximamente');
  }

  void _findNearbyVets() {
    _showSnackBar('Buscando veterinarios cercanos...');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
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
        backgroundColor: isError ? Colors.red.shade600 : Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}