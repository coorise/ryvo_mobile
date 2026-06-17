import 'dart:math' as math;

enum BandwidthMode { unlimited, metered }

class OpexResource {
  const OpexResource({
    required this.id,
    required this.provider,
    required this.cpus,
    required this.ramGb,
    required this.storageGb,
    required this.bandwidthMode,
    this.bandwidthGb,
    required this.pricePerHour,
    required this.marginDown,
    required this.marginUp,
  });

  final String id;
  final String provider;
  final int cpus;
  final int ramGb;
  final int storageGb;
  final BandwidthMode bandwidthMode;
  final int? bandwidthGb;
  final double pricePerHour;
  final double marginDown;
  final double marginUp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'cpus': cpus,
        'ramGb': ramGb,
        'storageGb': storageGb,
        'bandwidthMode': bandwidthMode.name,
        'bandwidthGb': bandwidthGb,
        'pricePerHour': pricePerHour,
        'marginDown': marginDown,
        'marginUp': marginUp,
      };

  factory OpexResource.fromJson(Map<String, dynamic> json) {
    return OpexResource(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      cpus: (json['cpus'] as num?)?.toInt() ?? 1,
      ramGb: (json['ramGb'] as num?)?.toInt() ?? 1,
      storageGb: (json['storageGb'] as num?)?.toInt() ?? 10,
      bandwidthMode: json['bandwidthMode']?.toString() == 'unlimited'
          ? BandwidthMode.unlimited
          : BandwidthMode.metered,
      bandwidthGb: (json['bandwidthGb'] as num?)?.toInt(),
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0.1,
      marginDown: (json['marginDown'] as num?)?.toDouble() ?? -0.1,
      marginUp: (json['marginUp'] as num?)?.toDouble() ?? 0.15,
    );
  }
}

enum PeriodFilter { weekly, monthly, yearly }

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.opex,
    required this.revenue,
    required this.profit,
    required this.clientsPaid,
    required this.driversEarned,
    required this.platformFee,
  });

  final String label;
  final int opex;
  final int revenue;
  final int profit;
  final int clientsPaid;
  final int driversEarned;
  final int platformFee;

  Map<String, dynamic> toChartRow() => {
        'label': label,
        'revenue': revenue,
        'opex': opex,
        'profit': profit,
      };
}

const defaultOpexResources = [
  OpexResource(
    id: 'supabase-prod',
    provider: 'Supabase (Postgres + Auth)',
    cpus: 4,
    ramGb: 16,
    storageGb: 100,
    bandwidthMode: BandwidthMode.metered,
    bandwidthGb: 500,
    pricePerHour: 0.42,
    marginDown: -0.15,
    marginUp: 0.2,
  ),
  OpexResource(
    id: 'functions-bun',
    provider: 'Ryvo Functions (Bun gateway)',
    cpus: 2,
    ramGb: 4,
    storageGb: 20,
    bandwidthMode: BandwidthMode.metered,
    bandwidthGb: 200,
    pricePerHour: 0.18,
    marginDown: -0.1,
    marginUp: 0.15,
  ),
  OpexResource(
    id: 'kafka-redis',
    provider: 'Kafka + Redis',
    cpus: 2,
    ramGb: 8,
    storageGb: 50,
    bandwidthMode: BandwidthMode.unlimited,
    pricePerHour: 0.12,
    marginDown: -0.08,
    marginUp: 0.12,
  ),
];

class OpexHourlyBand {
  const OpexHourlyBand({required this.low, required this.mid, required this.high});

  final double low;
  final double mid;
  final double high;
}

OpexHourlyBand opexHourlyBand(OpexResource resource) {
  final mid = resource.pricePerHour;
  return OpexHourlyBand(
    low: math.max(0, mid * (1 + resource.marginDown)),
    mid: mid,
    high: mid * (1 + resource.marginUp),
  );
}

OpexHourlyBand totalOpexHourly(List<OpexResource> resources) {
  var low = 0.0;
  var mid = 0.0;
  var high = 0.0;
  for (final r in resources) {
    final b = opexHourlyBand(r);
    low += b.low;
    mid += b.mid;
    high += b.high;
  }
  return OpexHourlyBand(low: low, mid: mid, high: high);
}

class MonthlyOpex {
  const MonthlyOpex({required this.low, required this.mid, required this.high});

  final double low;
  final double mid;
  final double high;
}

MonthlyOpex monthlyOpex(List<OpexResource> resources, {double hours = 730}) {
  final h = totalOpexHourly(resources);
  return MonthlyOpex(
    low: h.low * hours,
    mid: h.mid * hours,
    high: h.high * hours,
  );
}

int _periodPoints(PeriodFilter period) {
  if (period == PeriodFilter.yearly) return 5;
  return 12;
}

String _periodLabel(PeriodFilter period, int index, int total) {
  if (period == PeriodFilter.weekly) return 'W${index + 1}';
  if (period == PeriodFilter.monthly) {
    final d = DateTime.now().subtract(Duration(days: 30 * (total - 1 - index)));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year % 100}';
  }
  final year = DateTime.now().year - (total - 1 - index);
  return '$year';
}

List<TrendPoint> buildFinanceTrend(
  PeriodFilter period,
  List<OpexResource> resources,
  double baseMonthlyRevenue,
  double platformFeePercent,
) {
  final n = _periodPoints(period);
  final opexBase = monthlyOpex(resources).mid;
  final scale = period == PeriodFilter.weekly
      ? opexBase / 4.33
      : period == PeriodFilter.yearly
      ? opexBase * 12
      : opexBase;
  final revScale = period == PeriodFilter.weekly
      ? baseMonthlyRevenue / 4.33
      : period == PeriodFilter.yearly
      ? baseMonthlyRevenue * 12
      : baseMonthlyRevenue;

  return List.generate(n, (i) {
    final growth = 0.92 + i * 0.018 + math.sin(i * 0.7) * 0.04;
    final opex = scale * (0.88 + i * 0.02) * (1 + math.cos(i.toDouble()) * 0.03);
    final revenue = math.max(0, revScale * growth);
    final platformFee = revenue * (platformFeePercent / 100);
    final driversEarned = (revenue - platformFee) * 0.78;
    final clientsPaid = revenue;
    final profit = revenue - opex;
    return TrendPoint(
      label: _periodLabel(period, i, n),
      opex: opex.round(),
      revenue: revenue.round(),
      profit: profit.round(),
      clientsPaid: clientsPaid.round(),
      driversEarned: driversEarned.round(),
      platformFee: platformFee.round(),
    );
  });
}

double roiPercent(double revenue, double opex) {
  if (opex <= 0) return revenue > 0 ? 100 : 0;
  return ((revenue - opex) / opex * 1000).roundToDouble() / 10;
}
