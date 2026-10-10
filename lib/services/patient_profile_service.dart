import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/patient_health_profile.dart';
import 'auth_service.dart';

class PatientProfileService {
  PatientProfileService._();

  static final PatientProfileService instance = PatientProfileService._();

  Future<Directory> _directory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/smriti_patient_profiles');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  String _safeId(String value) {
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }

  Future<File> _file(String identifier) async {
    final dir = await _directory();
    return File('${dir.path}/${_safeId(identifier)}.json');
  }

  Future<PatientHealthProfile> getProfile(SmritiUser user) async {
    final file = await _file(user.identifier);

    if (await file.exists()) {
      try {
        final raw = await file.readAsString();

        if (raw.trim().isNotEmpty) {
          final profile = PatientHealthProfile.fromEncoded(raw);

          if (profile.name.trim().isNotEmpty) {
            return profile;
          }
        }
      } catch (_) {
        // If the saved profile is corrupted, recreate it below.
      }
    }

    // IMPORTANT:
    // Age is NOT converted into a fake date of birth.
    // The authenticated user's age remains separate in SmritiUser.
    return PatientHealthProfile(
      userIdentifier: user.identifier,
      name: user.name,
      phone: _looksLikePhone(user.identifier) ? user.identifier : null,
      email: _looksLikeEmail(user.identifier) ? user.identifier : null,
    );
  }

  Future<void> saveProfile(PatientHealthProfile profile) async {
    final file = await _file(profile.userIdentifier);

    await file.writeAsString(
      profile.encode(),
      flush: true,
    );
  }

  Future<void> deleteProfile(String identifier) async {
    final file = await _file(identifier);

    if (await file.exists()) {
      await file.delete();
    }
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@');
  }

  bool _looksLikePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s+\-()]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(cleaned);
  }
}