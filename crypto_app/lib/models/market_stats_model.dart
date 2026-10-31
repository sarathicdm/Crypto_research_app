// Matches the "stats" object from GET /market/stats
// Backend JSON shape:
// { "active_cryptocurrencies": 10000,
//   "total_market_cap": { "usd": 2500000000000 },
//   "total_volume":     { "usd": 100000000000 },
//   "market_cap_percentage": { "btc": 52.0, "eth": 17.0 },
//   "market_cap_change_percentage_24h_usd": 1.5 }

class MarketStatsModel {
  final int activeCryptocurrencies;
  final double totalMarketCap;
  final double totalVolume;
  final double btcDominance;
  final double ethDominance;
  final double marketCapChange24h;

  MarketStatsModel({
    required this.activeCryptocurrencies,
    required this.totalMarketCap,
    required this.totalVolume,
    required this.btcDominance,
    required this.ethDominance,
    required this.marketCapChange24h,
  });

  factory MarketStatsModel.fromJson(Map<String, dynamic> json) {
    final dominance = json['market_cap_percentage'] as Map<String, dynamic>? ?? {};

    return MarketStatsModel(
      activeCryptocurrencies: (json['active_cryptocurrencies'] as num?)?.toInt() ?? 0,
      totalMarketCap: (json['total_market_cap']?['usd'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (json['total_volume']?['usd'] as num?)?.toDouble() ?? 0.0,
      btcDominance: (dominance['btc'] as num?)?.toDouble() ?? 0.0,
      ethDominance: (dominance['eth'] as num?)?.toDouble() ?? 0.0,
      marketCapChange24h:
          (json['market_cap_change_percentage_24h_usd'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
