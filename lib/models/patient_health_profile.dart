import 'dart:convert';

enum HealthSource {
  patient,
  doctor,
  prescription,
  report,
  unknown,
}

enum HealthStatus {
  confirmed,
  needsConfirmation,
  historical,
}

String _sourceLabel(HealthSource source) {
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

String _statusLabel(HealthStatus status) {
  switch (status) {
    case HealthStatus.confirmed:
      return 'Confirmed';
    case HealthStatus.needsConfirmation:
      return 'Needs confirmation';
    case HealthStatus.historical:
      return 'Historical';
  }
}

HealthSource _sourceFrom(String? value) {
  return HealthSource.values.firstWhere(
        (e) => e.name == value,
    orElse: () => HealthSource.unknown,
  );
}

HealthStatus _statusFrom(String? value) {
  return HealthStatus.values.firstWhere(
        (e) => e.name == value,
    orElse: () => HealthStatus.needsConfirmation,
  );
}

class HealthItem {
  String name;
  String? notes;
  HealthSource source;
  HealthStatus status;

  HealthItem({
    required this.name,
    this.notes,
    this.source = HealthSource.patient,
    this.status = HealthStatus.needsConfirmation,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'notes': notes,
    'source': source.name,
    'status': status.name,
  };

  factory HealthItem.fromJson(Map<String, dynamic> json) {
    return HealthItem(
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString(),
      source: _sourceFrom(json['source']?.toString()),
      status: _statusFrom(json['status']?.toString()),
    );
  }

  String get sourceText => _sourceLabel(source);
  String get statusText => _statusLabel(status);
}

class PatientMedicine {
  String name;
  String? dose;
  String? frequency;
  String? instruction;
  String? startDate;
  String? endDate;
  String? prescriber;
  List<String> reminderTimes;

  PatientMedicine({
    required this.name,
    this.dose,
    this.frequency,
    this.instruction,
    this.startDate,
    this.endDate,
    this.prescriber,
    List<String>? reminderTimes,
  }) : reminderTimes = reminderTimes ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'dose': dose,
    'frequency': frequency,
    'instruction': instruction,
    'startDate': startDate,
    'endDate': endDate,
    'prescriber': prescriber,
    'reminderTimes': reminderTimes,
  };

  factory PatientMedicine.fromJson(Map<String, dynamic> json) {
    return PatientMedicine(
      name: json['name']?.toString() ?? '',
      dose: json['dose']?.toString(),
      frequency: json['frequency']?.toString(),
      instruction: json['instruction']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      prescriber: json['prescriber']?.toString(),
      reminderTimes: (json['reminderTimes'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}

class EmergencyContact {
  String name;
  String relationship;
  String phone;
  String? notes;

  EmergencyContact({
    this.name = '',
    this.relationship = '',
    this.phone = '',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    'phone': phone,
    'notes': notes,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}

class DoctorInfo {
  String name;
  String specialty;
  String? hospital;
  String? phone;
  String? notes;

  DoctorInfo({
    required this.name,
    this.specialty = '',
    this.hospital,
    this.phone,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'specialty': specialty,
    'hospital': hospital,
    'phone': phone,
    'notes': notes,
  };

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      name: json['name']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      hospital: json['hospital']?.toString(),
      phone: json['phone']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class VaccinationRecord {
  String vaccine;
  String? date;
  String? dose;
  String? notes;

  VaccinationRecord({
    required this.vaccine,
    this.date,
    this.dose,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'vaccine': vaccine,
    'date': date,
    'dose': dose,
    'notes': notes,
  };

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    return VaccinationRecord(
      vaccine: json['vaccine']?.toString() ?? '',
      date: json['date']?.toString(),
      dose: json['dose']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class HealthMeasurement {
  String date;
  String? bloodPressure;
  String? bloodSugar;
  String? weight;
  String? height;
  String? bmi;
  String? notes;

  HealthMeasurement({
    required this.date,
    this.bloodPressure,
    this.bloodSugar,
    this.weight,
    this.height,
    this.bmi,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'bloodPressure': bloodPressure,
    'bloodSugar': bloodSugar,
    'weight': weight,
    'height': height,
    'bmi': bmi,
    'notes': notes,
  };

  factory HealthMeasurement.fromJson(Map<String, dynamic> json) {
    return HealthMeasurement(
      date: json['date']?.toString() ?? '',
      bloodPressure: json['bloodPressure']?.toString(),
      bloodSugar: json['bloodSugar']?.toString(),
      weight: json['weight']?.toString(),
      height: json['height']?.toString(),
      bmi: json['bmi']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class LifestyleInfo {
  String smoking;
  String alcohol;
  String activity;
  String diet;
  String sleep;

  LifestyleInfo({
    this.smoking = '',
    this.alcohol = '',
    this.activity = '',
    this.diet = '',
    this.sleep = '',
  });

  Map<String, dynamic> toJson() => {
    'smoking': smoking,
    'alcohol': alcohol,
    'activity': activity,
    'diet': diet,
    'sleep': sleep,
  };

  factory LifestyleInfo.fromJson(Map<String, dynamic> json) {
    return LifestyleInfo(
      smoking: json['smoking']?.toString() ?? '',
      alcohol: json['alcohol']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      diet: json['diet']?.toString() ?? '',
      sleep: json['sleep']?.toString() ?? '',
    );
  }
}

class PatientHealthProfile {
  final String userIdentifier;

  String name;
  String? dateOfBirth;
  String? gender;
  String? bloodGroup;
  String? phone;
  String? email;
  String? address;

  EmergencyContact emergencyContact;

  String? allergies;
  String? foodAllergies;
  String? drugAllergies;
  String? otherAllergies;

  List<HealthItem> currentConditions;
  List<HealthItem> pastConditions;
  List<HealthItem> surgeries;
  List<HealthItem> hospitalizations;
  List<HealthItem> familyHistory;

  List<PatientMedicine> medicines;
  List<DoctorInfo> doctors;
  List<VaccinationRecord> vaccinations;
  List<HealthMeasurement> measurements;

  LifestyleInfo lifestyle;

  PatientHealthProfile({
    required this.userIdentifier,
    required this.name,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.phone,
    this.email,
    this.address,
    EmergencyContact? emergencyContact,
    this.allergies,
    this.foodAllergies,
    this.drugAllergies,
    this.otherAllergies,
    List<HealthItem>? currentConditions,
    List<HealthItem>? pastConditions,
    List<HealthItem>? surgeries,
    List<HealthItem>? hospitalizations,
    List<HealthItem>? familyHistory,
    List<PatientMedicine>? medicines,
    List<DoctorInfo>? doctors,
    List<VaccinationRecord>? vaccinations,
    List<HealthMeasurement>? measurements,
    LifestyleInfo? lifestyle,
  })  : emergencyContact = emergencyContact ?? EmergencyContact(),
        currentConditions = currentConditions ?? [],
        pastConditions = pastConditions ?? [],
        surgeries = surgeries ?? [],
        hospitalizations = hospitalizations ?? [],
        familyHistory = familyHistory ?? [],
        medicines = medicines ?? [],
        doctors = doctors ?? [],
        vaccinations = vaccinations ?? [],
        measurements = measurements ?? [],
        lifestyle = lifestyle ?? LifestyleInfo();

  Map<String, dynamic> toJson() => {
    'userIdentifier': userIdentifier,
    'name': name,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'bloodGroup': bloodGroup,
    'phone': phone,
    'email': email,
    'address': address,
    'emergencyContact': emergencyContact.toJson(),
    'allergies': allergies,
    'foodAllergies': foodAllergies,
    'drugAllergies': drugAllergies,
    'otherAllergies': otherAllergies,
    'currentConditions':
    currentConditions.map((e) => e.toJson()).toList(),
    'pastConditions': pastConditions.map((e) => e.toJson()).toList(),
    'surgeries': surgeries.map((e) => e.toJson()).toList(),
    'hospitalizations':
    hospitalizations.map((e) => e.toJson()).toList(),
    'familyHistory': familyHistory.map((e) => e.toJson()).toList(),
    'medicines': medicines.map((e) => e.toJson()).toList(),
    'doctors': doctors.map((e) => e.toJson()).toList(),
    'vaccinations': vaccinations.map((e) => e.toJson()).toList(),
    'measurements': measurements.map((e) => e.toJson()).toList(),
    'lifestyle': lifestyle.toJson(),
  };

  String encode() => jsonEncode(toJson());

  factory PatientHealthProfile.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(
        dynamic value,
        T Function(Map<String, dynamic>) parser,
        ) {
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((e) => parser(Map<String, dynamic>.from(e)))
          .toList();
    }

    return PatientHealthProfile(
      userIdentifier: json['userIdentifier']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      emergencyContact: json['emergencyContact'] is Map
          ? EmergencyContact.fromJson(
        Map<String, dynamic>.from(json['emergencyContact']),
      )
          : EmergencyContact(),
      allergies: json['allergies']?.toString(),
      foodAllergies: json['foodAllergies']?.toString(),
      drugAllergies: json['drugAllergies']?.toString(),
      otherAllergies: json['otherAllergies']?.toString(),
      currentConditions:
      list(json['currentConditions'], HealthItem.fromJson),
      pastConditions: list(json['pastConditions'], HealthItem.fromJson),
      surgeries: list(json['surgeries'], HealthItem.fromJson),
      hospitalizations:
      list(json['hospitalizations'], HealthItem.fromJson),
      familyHistory: list(json['familyHistory'], HealthItem.fromJson),
      medicines: list(json['medicines'], PatientMedicine.fromJson),
      doctors: list(json['doctors'], DoctorInfo.fromJson),
      vaccinations:
      list(json['vaccinations'], VaccinationRecord.fromJson),
      measurements:
      list(json['measurements'], HealthMeasurement.fromJson),
      lifestyle: json['lifestyle'] is Map
          ? LifestyleInfo.fromJson(
        Map<String, dynamic>.from(json['lifestyle']),
      )
          : LifestyleInfo(),
    );
  }

  factory PatientHealthProfile.fromEncoded(String value) {
    return PatientHealthProfile.fromJson(
      Map<String, dynamic>.from(jsonDecode(value)),
    );
  }
}