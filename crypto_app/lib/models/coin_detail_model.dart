// Matches the "coin" object from GET /coins/{coin_id}
// Backend JSON shape:
// { "id": "bitcoin", "symbol": "btc", "name": "Bitcoin",
//   "description": "...",
//   "image": { "large": "https://..." },
//   "market_data": {
//     "current_price": { "usd": 67000 },
//     "market_cap":    { "usd": 1300000000000 },
//     "total_volume":  { "usd": 30000000000 },
//     "price_change_percentage_24h": 2.5,
//     "high_24h": { "usd": 68000 },
//     "low_24h":  { "usd": 66000 },
//     "circulating_supply": 19700000,
//     "total_supply": 21000000
//   }
// }

class CoinDetailModel {
  final String id;
  final String symbol;
  final String name;
  final String description;
  final String imageUrl;
  final double currentPrice;
  final double marketCap;
  final double totalVolume;
  final double priceChangePercentage24h;
  final double high24h;
  final double low24h;
  final double circulatingSupply;
  final double? totalSupply;

  CoinDetailModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.currentPrice,
    required this.marketCap,
    required this.totalVolume,
    required this.priceChangePercentage24h,
    required this.high24h,
    required this.low24h,
    required this.circulatingSupply,
    this.totalSupply,
  });

  factory CoinDetailModel.fromJson(Map<String, dynamic> json) {
    final marketData = json['market_data'] as Map<String, dynamic>;

    return CoinDetailModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      description: json['description'] is Map
          ? ((json['description'] as Map)['en'] as String? ?? '')
          : json['description'] as String? ?? '',
      imageUrl: json['image'] is Map
          ? ((json['image'] as Map)['large'] as String? ?? '')
          : json['image'] as String? ?? '',
      currentPrice: (marketData['current_price']?['usd'] as num?)?.toDouble() ?? 0.0,
      marketCap: (marketData['market_cap']?['usd'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (marketData['total_volume']?['usd'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (marketData['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      high24h: (marketData['high_24h']?['usd'] as num?)?.toDouble() ?? 0.0,
      low24h: (marketData['low_24h']?['usd'] as num?)?.toDouble() ?? 0.0,
      circulatingSupply: (marketData['circulating_supply'] as num?)?.toDouble() ?? 0.0,
      totalSupply: (marketData['total_supply'] as num?)?.toDouble(),
    );
  }
}
