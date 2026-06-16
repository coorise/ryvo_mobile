/// Landing page data — mirrors web `configs/const.ts`.
class LandingCity {
  const LandingCity({
    required this.name,
    required this.province,
    required this.imageUrl,
    required this.drivers,
    required this.status,
  });

  final String name;
  final String province;
  final String imageUrl;
  final int drivers;
  final String status; // live | soon
}

class LandingFeature {
  const LandingFeature({
    required this.title,
    required this.description,
    required this.iconName,
  });

  final String title;
  final String description;
  final String iconName;
}

class LandingNavLink {
  const LandingNavLink({required this.label, required this.sectionId});

  final String label;
  final String sectionId;
}

class LandingConst {
  LandingConst._();

  static const fallbackCityImage =
      'https://images.unsplash.com/photo-1514905552197-0610a4d8fd73?w=800&q=80';

  static const navLinks = [
    LandingNavLink(label: 'Features', sectionId: 'features'),
    LandingNavLink(label: 'Cities', sectionId: 'cities'),
    LandingNavLink(label: 'Drivers', sectionId: 'drivers'),
    LandingNavLink(label: 'Safety', sectionId: 'safety'),
  ];

  static const features = [
    LandingFeature(
      iconName: 'shield_check',
      title: 'End-to-end safety',
      description: 'Verified drivers, live tracking, and 24/7 support when you need it.',
    ),
    LandingFeature(
      iconName: 'zap',
      title: 'Match in under 4 min',
      description: 'Smart dispatch sends offers to nearby drivers instantly.',
    ),
    LandingFeature(
      iconName: 'badge_dollar',
      title: 'Transparent pricing',
      description: 'See the fare upfront — no surprises at the end of your trip.',
    ),
  ];

  static const safetyPoints = [
    (
      title: 'Verified drivers',
      description: 'KYC and document checks before anyone can accept rides on the platform.',
    ),
    (
      title: 'Live trip tracking',
      description: 'Share your route in real time with trusted contacts when you travel.',
    ),
    (
      title: '24/7 support',
      description: 'In-app chat with our team for billing, safety, or account issues.',
    ),
  ];

  static const landingCities = [
    LandingCity(
      name: 'Montréal',
      province: 'Québec',
      imageUrl: 'https://images.unsplash.com/photo-1519178614-68673b201f36?w=600&q=80',
      drivers: 2840,
      status: 'live',
    ),
    LandingCity(
      name: 'Toronto',
      province: 'Ontario',
      imageUrl: 'https://images.unsplash.com/photo-1517090504586-fde19ea6066f?w=600&q=80',
      drivers: 4120,
      status: 'live',
    ),
    LandingCity(
      name: 'Vancouver',
      province: 'B.C.',
      imageUrl: 'https://images.unsplash.com/photo-1559511260-66a654ae982a?w=600&q=80',
      drivers: 1980,
      status: 'live',
    ),
    LandingCity(
      name: 'Québec',
      province: 'Québec',
      imageUrl: 'https://images.unsplash.com/photo-1519832979-6fa011b87667?w=600&q=80',
      drivers: 740,
      status: 'live',
    ),
    LandingCity(
      name: 'Ottawa',
      province: 'Ontario',
      imageUrl: 'https://images.unsplash.com/photo-1565876427310-71a4500ea814?w=600&q=80',
      drivers: 880,
      status: 'live',
    ),
    LandingCity(
      name: 'Calgary',
      province: 'Alberta',
      imageUrl: 'https://images.unsplash.com/photo-1558584673-c834fb1cc3ca?w=600&q=80',
      drivers: 1240,
      status: 'live',
    ),
    LandingCity(
      name: 'Edmonton',
      province: 'Alberta',
      imageUrl: 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=600&q=80',
      drivers: 920,
      status: 'live',
    ),
    LandingCity(
      name: 'Winnipeg',
      province: 'Manitoba',
      imageUrl: 'https://images.unsplash.com/photo-1593691509543-c55fb32e3b1b?w=600&q=80',
      drivers: 540,
      status: 'live',
    ),
    LandingCity(
      name: 'Halifax',
      province: 'N.S.',
      imageUrl: 'https://images.unsplash.com/photo-1569696251872-5dcf39dcc60e?w=600&q=80',
      drivers: 410,
      status: 'live',
    ),
    LandingCity(
      name: 'Gatineau',
      province: 'Québec',
      imageUrl: 'https://images.unsplash.com/photo-1606298855672-3efb63017be8?w=600&q=80',
      drivers: 320,
      status: 'live',
    ),
    LandingCity(
      name: 'Sherbrooke',
      province: 'Québec',
      imageUrl: 'https://images.unsplash.com/photo-1565717893783-32932d82e11e?w=600&q=80',
      drivers: 220,
      status: 'soon',
    ),
    LandingCity(
      name: 'Trois-Rivières',
      province: 'Québec',
      imageUrl: 'https://images.unsplash.com/photo-1514905552197-0610a4d8fd73?w=600&q=80',
      drivers: 180,
      status: 'soon',
    ),
  ];

  static int get totalDrivers =>
      landingCities.fold(0, (sum, city) => sum + city.drivers);
}
