// Matches one item inside the "coins" array from GET /coins
// Backend JSON shape:
// { "id": "bitcoin", "symbol": "btc", "name": "Bitcoin",
//   "image": "https://...", "current_price": 67000,
//   "market_cap": 1300000000000, "total_volume": 30000000000,
//   "price_change_percentage_24h": 2.5 }

class CoinModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double marketCap;
  final double totalVolume;
  final double priceChangePercentage24h;

  CoinModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.marketCap,
    required this.totalVolume,
    required this.priceChangePercentage24h,
  });

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    return CoinModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      image: json['image'] is Map
          ? ((json['image'] as Map)['large'] as String? ?? '')
          : json['image'] as String? ?? '',
      // num covers both int and double coming from JSON
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
