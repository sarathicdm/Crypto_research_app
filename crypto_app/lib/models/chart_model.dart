// Matches the "chart" object from GET /coins/{coin_id}/chart
// Backend JSON shape:
// { "prices": [ [1700000000000, 65000], [1700003600000, 65500], ... ] }
// Each entry is a two-element list: [timestamp_ms, price_usd]

class ChartPoint {
  final DateTime time;
  final double price;

  ChartPoint({required this.time, required this.price});
}

class ChartModel {
  final List<ChartPoint> points;

  ChartModel({required this.points});

  factory ChartModel.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['prices'] as List<dynamic>;

    final points = rawPrices.map((entry) {
      final pair = entry as List<dynamic>;
      final timestampMs = (pair[0] as num).toInt();
      final price = (pair[1] as num).toDouble();
      return ChartPoint(
        time: DateTime.fromMillisecondsSinceEpoch(timestampMs),
        price: price,
      );
    }).toList();

    return ChartModel(points: points);
  }
}
