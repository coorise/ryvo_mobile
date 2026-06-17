const personalKycDocTypes = [
  'national_id',
  'passport',
  'selfie_with_id',
  'driver_license',
  'bank_statement',
];

const kycDocLabelKeys = {
  'driver_license': 'drivers.docLicense',
  'vehicle_insurance': 'drivers.docInsurance',
  'vehicle_registration': 'drivers.docRegistration',
  'background_check': 'drivers.docBackground',
  'profile_photo': 'drivers.docPhoto',
  'national_id': 'drivers.docNationalId',
  'passport': 'drivers.docPassport',
  'selfie_with_id': 'drivers.docSelfie',
  'bank_statement': 'drivers.docBank',
};

const kycStatusPending = 'pending';
const kycStatusApproved = 'approved';
const kycStatusRejected = 'rejected';
const kycStatusMissing = 'missing';
