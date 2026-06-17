import 'package:ryvo/lib/storage_keys.dart';

const maxVideoBytes = 30 * 1024 * 1024;
const maxVideoSeconds = 30;
const minGalleryImages = 2;

const tyresTypes = ['summer', 'winter', 'all_season', 'performance', 'other'];
const energyTypes = ['electric', 'fuel', 'hybrid'];

class VehicleFormState {
  VehicleFormState({
    this.brand = '',
    this.name = '',
    this.maxSpeedKmh = '',
    this.ageYears = '',
    this.tyresType = '',
    this.carbonPrint = '',
    this.energyType = 'fuel',
    this.plate = '',
    this.make = '',
    this.model = '',
    int? year,
  }) : year = year ?? DateTime.now().year;

  String brand;
  String name;
  String maxSpeedKmh;
  String ageYears;
  String tyresType;
  String carbonPrint;
  String energyType;
  String plate;
  String make;
  String model;
  int year;

  VehicleFormState copyWith({
    String? brand,
    String? name,
    String? maxSpeedKmh,
    String? ageYears,
    String? tyresType,
    String? carbonPrint,
    String? energyType,
    String? plate,
    String? make,
    String? model,
    int? year,
  }) {
    return VehicleFormState(
      brand: brand ?? this.brand,
      name: name ?? this.name,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      ageYears: ageYears ?? this.ageYears,
      tyresType: tyresType ?? this.tyresType,
      carbonPrint: carbonPrint ?? this.carbonPrint,
      energyType: energyType ?? this.energyType,
      plate: plate ?? this.plate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
    );
  }
}

VehicleFormState vehicleToForm(Map<String, dynamic> vehicle) {
  return VehicleFormState(
    brand: _str(vehicle['brand']),
    name: _str(vehicle['name']),
    maxSpeedKmh: vehicle['max_speed_kmh']?.toString() ?? '',
    ageYears: vehicle['age_years']?.toString() ?? '',
    tyresType: _str(vehicle['tyres_type']),
    carbonPrint: vehicle['carbon_print']?.toString() ?? '',
    energyType: _str(vehicle['energy_type'], 'fuel'),
    plate: _str(vehicle['plate']),
    make: _str(vehicle['make']),
    model: _str(vehicle['model']),
    year: vehicle['year'] is num ? (vehicle['year'] as num).toInt() : DateTime.now().year,
  );
}

Map<String, dynamic> formToBody(VehicleFormState form) {
  final brand = form.brand.trim();
  final name = form.name.trim();
  return {
    'brand': brand.isEmpty ? null : brand,
    'name': name.isEmpty ? null : name,
    'max_speed_kmh': form.maxSpeedKmh.isEmpty ? null : num.tryParse(form.maxSpeedKmh),
    'age_years': form.ageYears.isEmpty ? null : num.tryParse(form.ageYears),
    'tyres_type': form.tyresType.isEmpty ? null : form.tyresType,
    'carbon_print': form.carbonPrint.isEmpty ? null : num.tryParse(form.carbonPrint),
    'energy_type': form.energyType,
    'plate': form.plate.trim().isEmpty ? null : form.plate.trim(),
    'make': form.make.trim().isEmpty ? (brand.isEmpty ? 'Unknown' : brand) : form.make.trim(),
    'model': form.model.trim().isEmpty ? (name.isEmpty ? 'Unknown' : name) : form.model.trim(),
    'year': form.year,
    'category': 'economy',
  };
}

class VehicleProfileChecklist {
  const VehicleProfileChecklist({
    required this.profileComplete,
    required this.hasBanner,
    required this.galleryCount,
    required this.hasRegistration,
    required this.hasInsurance,
    required this.readyForReview,
  });

  final bool profileComplete;
  final bool hasBanner;
  final int galleryCount;
  final bool hasRegistration;
  final bool hasInsurance;
  final bool readyForReview;
}

VehicleProfileChecklist buildVehicleChecklist(
  VehicleFormState form,
  Map<String, dynamic>? vehicle,
) {
  final profileComplete = form.brand.trim().isNotEmpty &&
      form.name.trim().isNotEmpty &&
      form.maxSpeedKmh.isNotEmpty &&
      form.ageYears.isNotEmpty &&
      form.tyresType.isNotEmpty &&
      form.carbonPrint.isNotEmpty &&
      energyTypes.contains(form.energyType) &&
      form.plate.trim().isNotEmpty;

  final hasBanner = isRealStorageKey(vehicle?['banner_key']?.toString());
  final imageKeys = vehicle?['image_keys'];
  final galleryCount = imageKeys is List
      ? imageKeys.where((k) => isRealStorageKey(k?.toString())).length
      : 0;
  final documents = _vehicleDocuments(vehicle);
  final hasRegistration = documents.any(
    (d) => d['doc_type'] == 'registration' && isRealStorageKey(d['s3_key']?.toString()),
  );
  final hasInsurance = documents.any(
    (d) => d['doc_type'] == 'insurance' && isRealStorageKey(d['s3_key']?.toString()),
  );

  return VehicleProfileChecklist(
    profileComplete: profileComplete,
    hasBanner: hasBanner,
    galleryCount: galleryCount,
    hasRegistration: hasRegistration,
    hasInsurance: hasInsurance,
    readyForReview: profileComplete &&
        hasBanner &&
        galleryCount >= minGalleryImages &&
        hasRegistration &&
        hasInsurance,
  );
}

List<Map<String, dynamic>> _vehicleDocuments(Map<String, dynamic>? vehicle) {
  final docs = vehicle?['documents'];
  if (docs is! List) return const [];
  return docs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
}

void validateProfileForm(VehicleFormState form, String Function(String) t) {
  if (form.brand.trim().isEmpty || form.name.trim().isEmpty) {
    throw Exception(t('portal.kyc.requiredBrandName'));
  }
  if (form.plate.trim().isEmpty) throw Exception(t('portal.kyc.requiredPlate'));
  if (form.maxSpeedKmh.isEmpty) throw Exception(t('portal.kyc.requiredSpeed'));
  if (form.ageYears.isEmpty) throw Exception(t('portal.kyc.requiredAge'));
  if (form.tyresType.isEmpty) throw Exception(t('portal.kyc.requiredTyres'));
  if (form.carbonPrint.isEmpty) throw Exception(t('portal.kyc.requiredCarbon'));
}

String _str(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
