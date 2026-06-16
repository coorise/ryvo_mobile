String auditActionCategory(String action) {
  if (action.startsWith('user.')) return 'user';
  if (action.startsWith('driver.') || action.startsWith('kyc.')) {
    return 'driver';
  }
  if (action.startsWith('tariff.') ||
      action.startsWith('subscription.') ||
      action.startsWith('paycheck.')) {
    return 'finance';
  }
  if (action.startsWith('role.') ||
      action.startsWith('coupon.') ||
      action.startsWith('campaign.')) {
    return 'admin';
  }
  return 'other';
}
