import 'package:flutter/material.dart';

import '../models/patient_health_profile.dart';
import '../services/auth_service.dart';
import '../services/patient_profile_service.dart';
import '../theme.dart';

class PatientProfileScreen extends StatefulWidget {
  final SmritiUser user;

  const PatientProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  PatientHealthProfile? _profile;
  bool _loading = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile =
    await PatientProfileService.instance.getProfile(widget.user);

    if (!mounted) return;

    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;

    await PatientProfileService.instance.saveProfile(profile);

    if (!mounted) return;

    setState(() {
      _editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patient profile saved successfully'),
      ),
    );
  }

  Future<void> _editBasicDetails() async {
    final profile = _profile;
    if (profile == null) return;

    final name = TextEditingController(text: profile.name);
    final dob = TextEditingController(text: profile.dateOfBirth ?? '');
    final gender = TextEditingController(text: profile.gender ?? '');
    final blood = TextEditingController(text: profile.bloodGroup ?? '');
    final phone = TextEditingController(text: profile.phone ?? '');
    final email = TextEditingController(text: profile.email ?? '');
    final address = TextEditingController(text: profile.address ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Basic patient details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField(name, 'Full name'),
              _dialogField(dob, 'Date of birth'),
              _dialogField(gender, 'Gender'),
              _dialogField(blood, 'Blood group'),
              _dialogField(phone, 'Phone'),
              _dialogField(email, 'Email'),
              _dialogField(address, 'Address', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              profile.name = name.text.trim();
              profile.dateOfBirth = _nullIfEmpty(dob.text);
              profile.gender = _nullIfEmpty(gender.text);
              profile.bloodGroup = _nullIfEmpty(blood.text);
              profile.phone = _nullIfEmpty(phone.text);
              profile.email = _nullIfEmpty(email.text);
              profile.address = _nullIfEmpty(address.text);

              Navigator.pop(context);

              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editAllergies() async {
    final profile = _profile;
    if (profile == null) return;

    final a = TextEditingController(text: profile.allergies ?? '');
    final f = TextEditingController(text: profile.foodAllergies ?? '');
    final d = TextEditingController(text: profile.drugAllergies ?? '');
    final o = TextEditingController(text: profile.otherAllergies ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Allergies'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField(a, 'Known allergies', maxLines: 3),
              _dialogField(f, 'Food allergies', maxLines: 3),
              _dialogField(d, 'Drug allergies', maxLines: 3),
              _dialogField(o, 'Other allergies', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              profile.allergies = _nullIfEmpty(a.text);
              profile.foodAllergies = _nullIfEmpty(f.text);
              profile.drugAllergies = _nullIfEmpty(d.text);
              profile.otherAllergies = _nullIfEmpty(o.text);

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addHealthItem(
      String title,
      List<HealthItem> target,
      ) async {
    if (!_editing) return;

    final name = TextEditingController();
    final notes = TextEditingController();

    HealthSource source = HealthSource.patient;
    HealthStatus status = HealthStatus.needsConfirmation;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: Text('Add $title'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _dialogField(name, 'Name'),
                  _dialogField(notes, 'Notes', maxLines: 3),
                  DropdownButtonFormField<HealthSource>(
                    initialValue: source,
                    decoration:
                    const InputDecoration(labelText: 'Source'),
                    items: HealthSource.values
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_sourceText(e)),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      dialogSetState(() => source = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<HealthStatus>(
                    initialValue: status,
                    decoration:
                    const InputDecoration(labelText: 'Status'),
                    items: HealthStatus.values
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_statusText(e)),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      dialogSetState(() => status = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) return;

                  target.add(
                    HealthItem(
                      name: name.text.trim(),
                      notes: _nullIfEmpty(notes.text),
                      source: source,
                      status: status,
                    ),
                  );

                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addMedicine() async {
    final profile = _profile;
    if (profile == null || !_editing) return;

    final name = TextEditingController();
    final dose = TextEditingController();
    final frequency = TextEditingController();
    final instruction = TextEditingController();
    final prescriber = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add medicine'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField(name, 'Medicine name'),
              _dialogField(dose, 'Dose'),
              _dialogField(frequency, 'Frequency'),
              _dialogField(
                instruction,
                'Prescription instruction',
                maxLines: 3,
              ),
              _dialogField(prescriber, 'Prescribed by'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;

              profile.medicines.add(
                PatientMedicine(
                  name: name.text.trim(),
                  dose: _nullIfEmpty(dose.text),
                  frequency: _nullIfEmpty(frequency.text),
                  instruction: _nullIfEmpty(instruction.text),
                  prescriber: _nullIfEmpty(prescriber.text),
                ),
              );

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDoctor() async {
    final profile = _profile;
    if (profile == null || !_editing) return;

    final name = TextEditingController();
    final specialty = TextEditingController();
    final hospital = TextEditingController();
    final phone = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add doctor / care team member'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField(name, 'Doctor name'),
              _dialogField(specialty, 'Specialty'),
              _dialogField(hospital, 'Hospital / clinic'),
              _dialogField(phone, 'Phone'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;

              profile.doctors.add(
                DoctorInfo(
                  name: name.text.trim(),
                  specialty: specialty.text.trim(),
                  hospital: _nullIfEmpty(hospital.text),
                  phone: _nullIfEmpty(phone.text),
                ),
              );

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEmergency() async {
    final profile = _profile;
    if (profile == null) return;

    final c = profile.emergencyContact;

    final name = TextEditingController(text: c.name);
    final relation = TextEditingController(text: c.relationship);
    final phone = TextEditingController(text: c.phone);
    final notes = TextEditingController(text: c.notes ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emergency contact'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField(name, 'Name'),
              _dialogField(relation, 'Relationship'),
              _dialogField(phone, 'Phone'),
              _dialogField(notes, 'Notes', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              c.name = name.text.trim();
              c.relationship = relation.text.trim();
              c.phone = phone.text.trim();
              c.notes = _nullIfEmpty(notes.text);

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editLifestyle() async {
    final profile = _profile;
    if (profile == null) return;

    final l = profile.lifestyle;

    final smoking = TextEditingController(text: l.smoking);
    final alcohol = TextEditingController(text: l.alcohol);
    final activity = TextEditingController(text: l.activity);
    final diet = TextEditingController(text: l.diet);
    final sleep = TextEditingController(text: l.sleep);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lifestyle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _dialogField(smoking, 'Smoking'),
              _dialogField(alcohol, 'Alcohol'),
              _dialogField(activity, 'Physical activity'),
              _dialogField(diet, 'Diet'),
              _dialogField(sleep, 'Sleep'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              l.smoking = smoking.text.trim();
              l.alcohol = alcohol.text.trim();
              l.activity = activity.text.trim();
              l.diet = diet.text.trim();
              l.sleep = sleep.text.trim();

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    if (_loading || profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Profile')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          IconButton(
            tooltip: _editing ? 'Save profile' : 'Edit profile',
            onPressed: _editing ? _save : () => setState(() => _editing = true),
            icon: Icon(_editing ? Icons.check : Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _hero(profile),

          _section(
            title: 'Basic Information',
            icon: Icons.person_outline,
            action: _editing ? _editBasicDetails : null,
            children: [
              _info('Name', profile.name),
              _info('Age', widget.user.age?.toString() ?? 'Not recorded'),
              _info('Date of birth', profile.dateOfBirth),
              _info('Gender', profile.gender),
              _info('Blood group', profile.bloodGroup),
              _info('Phone', profile.phone),
              _info('Email', profile.email),
              _info('Address', profile.address),
            ],
          ),

          _section(
            title: 'Emergency Contact',
            icon: Icons.emergency_outlined,
            action: _editing ? _editEmergency : null,
            children: [
              _info('Name', profile.emergencyContact.name),
              _info(
                'Relationship',
                profile.emergencyContact.relationship,
              ),
              _info('Phone', profile.emergencyContact.phone),
              _info('Notes', profile.emergencyContact.notes),
            ],
          ),

          _section(
            title: 'Allergies',
            icon: Icons.warning_amber_outlined,
            action: _editing ? _editAllergies : null,
            children: [
              _info('Known allergies', profile.allergies),
              _info('Food allergies', profile.foodAllergies),
              _info('Drug allergies', profile.drugAllergies),
              _info('Other allergies', profile.otherAllergies),
            ],
          ),

          _healthSection(
            title: 'Current Conditions',
            items: profile.currentConditions,
            onAdd: () =>
                _addHealthItem('current condition', profile.currentConditions),
          ),

          _healthSection(
            title: 'Past Medical History',
            items: profile.pastConditions,
            onAdd: () =>
                _addHealthItem('past condition', profile.pastConditions),
          ),

          _healthSection(
            title: 'Surgeries / Procedures',
            items: profile.surgeries,
            onAdd: () =>
                _addHealthItem('surgery / procedure', profile.surgeries),
          ),

          _healthSection(
            title: 'Hospitalizations',
            items: profile.hospitalizations,
            onAdd: () => _addHealthItem(
              'hospitalization',
              profile.hospitalizations,
            ),
          ),

          _healthSection(
            title: 'Family History',
            items: profile.familyHistory,
            onAdd: () =>
                _addHealthItem('family history item', profile.familyHistory),
          ),

          _section(
            title: 'Medicines',
            icon: Icons.medication_outlined,
            action: _editing ? _addMedicine : null,
            children: [
              if (profile.medicines.isEmpty)
                _empty('No medicines recorded yet.')
              else
                ...profile.medicines.map(
                      (medicine) => _medicineCard(medicine),
                ),
            ],
          ),

          _section(
            title: 'Doctors & Care Team',
            icon: Icons.medical_services_outlined,
            action: _editing ? _addDoctor : null,
            children: [
              if (profile.doctors.isEmpty)
                _empty('No doctors recorded yet.')
              else
                ...profile.doctors.map(_doctorCard),
            ],
          ),

          _section(
            title: 'Vaccination History',
            icon: Icons.vaccines_outlined,
            children: [
              if (profile.vaccinations.isEmpty)
                _empty('No vaccination records yet.')
              else
                ...profile.vaccinations.map(
                      (v) => _info(
                    v.vaccine,
                    [
                      v.date,
                      v.dose,
                      v.notes,
                    ].where((e) => e != null && e.isNotEmpty).join(' • '),
                  ),
                ),
            ],
          ),

          _section(
            title: 'Health Measurements',
            icon: Icons.monitor_heart_outlined,
            children: [
              if (profile.measurements.isEmpty)
                _empty('No measurements recorded yet.')
              else
                ...profile.measurements.map(
                      (m) => _measurementCard(m),
                ),
            ],
          ),

          _section(
            title: 'Lifestyle',
            icon: Icons.favorite_border,
            action: _editing ? _editLifestyle : null,
            children: [
              _info('Smoking', profile.lifestyle.smoking),
              _info('Alcohol', profile.lifestyle.alcohol),
              _info('Activity', profile.lifestyle.activity),
              _info('Diet', profile.lifestyle.diet),
              _info('Sleep', profile.lifestyle.sleep),
            ],
          ),

          _section(
            title: 'Care Connections',
            icon: Icons.account_tree_outlined,
            children: [
              _connection(
                Icons.medication_outlined,
                'Medicines',
                'Medicine information can be connected to Reminders.',
              ),
              _connection(
                Icons.description_outlined,
                'Reports',
                'Uploaded medical reports remain available through Report Analysis.',
              ),
              _connection(
                Icons.restaurant_outlined,
                'Doctor instructions',
                'Instructions can feed into Diet Rules and care guidance.',
              ),
              _connection(
                Icons.notifications_active_outlined,
                'Reminders',
                'Medicine reminder times can be managed from Reminders.',
              ),
            ],
          ),

          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SmritiColors.petal,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Safety: Information extracted from reports or consultations '
                  'should not automatically become a confirmed diagnosis. '
                  'The source and confirmation status are stored with medical history.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(PatientHealthProfile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SmritiColors.blush,
            SmritiColors.roseLight,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: SmritiColors.rose,
            child: Text(
              profile.name.isEmpty
                  ? '?'
                  : profile.name.trim()[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PATIENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete care information in one place.',
                  style: TextStyle(
                    color: SmritiColors.ink.withOpacity(.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? action,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 21, color: SmritiColors.plum),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (action != null)
                  IconButton(
                    onPressed: action,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _healthSection({
    required String title,
    required List<HealthItem> items,
    required VoidCallback onAdd,
  }) {
    return _section(
      title: title,
      icon: Icons.history_edu_outlined,
      action: _editing ? onAdd : null,
      children: [
        if (items.isEmpty)
          _empty('No information recorded yet.')
        else
          ...items.map(_healthCard),
      ],
    );
  }

  Widget _healthCard(HealthItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmritiColors.petal.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.notes!),
          ],
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              Chip(
                label: Text(item.sourceText),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(item.statusText),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medicineCard(PatientMedicine medicine) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        child: Icon(Icons.medication_outlined),
      ),
      title: Text(
        medicine.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          medicine.dose,
          medicine.frequency,
          medicine.instruction,
          medicine.prescriber == null
              ? null
              : 'Prescribed by ${medicine.prescriber}',
        ].where((e) => e != null && e.isNotEmpty).join(' • '),
      ),
    );
  }

  Widget _doctorCard(DoctorInfo doctor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        child: Icon(Icons.person_outline),
      ),
      title: Text(
        doctor.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          doctor.specialty,
          doctor.hospital,
          doctor.phone,
        ].where((e) => e != null && e.isNotEmpty).join(' • '),
      ),
    );
  }

  Widget _measurementCard(HealthMeasurement m) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.monitor_heart_outlined),
      title: Text(
        m.date.isEmpty ? 'Measurement' : m.date,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          m.bloodPressure == null ? null : 'BP: ${m.bloodPressure}',
          m.bloodSugar == null ? null : 'Sugar: ${m.bloodSugar}',
          m.weight == null ? null : 'Weight: ${m.weight}',
          m.height == null ? null : 'Height: ${m.height}',
          m.bmi == null ? null : 'BMI: ${m.bmi}',
          m.notes,
        ].where((e) => e != null && e.isNotEmpty).join(' • '),
      ),
    );
  }

  Widget _connection(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: SmritiColors.plum),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
    );
  }

  Widget _info(String label, String? value) {
    final display = value == null || value.trim().isEmpty
        ? 'Not recorded'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: SmritiColors.mauve,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: SmritiColors.mauve,
        ),
      ),
    );
  }

  Widget _dialogField(
      TextEditingController controller,
      String label, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _sourceText(HealthSource source) {
    switch (source) {
      case HealthSource.patient:
        return 'Patient entered';
      case HealthSource.doctor:
        return 'Doctor consultation';
      case HealthSource.prescription:
        return 'Prescription';
      case HealthSource.report:
        return 'Medical report';
      case HealthSource.unknown:
        return 'Unknown source';
    }
  }

  String _statusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.confirmed:
        return 'Confirmed';
      case HealthStatus.needsConfirmation:
        return 'Needs confirmation';
      case HealthStatus.historical:
        return 'Historical';
    }
  }
}