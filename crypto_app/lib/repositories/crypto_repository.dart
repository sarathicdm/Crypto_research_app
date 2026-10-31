import '../models/coin_model.dart';
import '../models/coin_detail_model.dart';
import '../models/chart_model.dart';
import '../models/market_stats_model.dart';
import '../services/api_service.dart';

class CryptoRepository {
  final ApiService _api;

  CryptoRepository(this._api);

  Future<List<CoinModel>> getCoins({String? search, String order = 'market_cap_desc'}) async {
    final raw = await _api.getCoins(search: search, order: order);
    return raw.map((json) => CoinModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<CoinDetailModel> getCoinDetail(String coinId) async {
    final raw = await _api.getCoinDetail(coinId);
    return CoinDetailModel.fromJson(raw);
  }

  Future<ChartModel> getCoinChart(String coinId, {int days = 7}) async {
    final raw = await _api.getCoinChart(coinId, days: days);
    return ChartModel.fromJson(raw);
  }

  Future<MarketStatsModel> getMarketStats() async {
    final raw = await _api.getMarketStats();
    return MarketStatsModel.fromJson(raw);
  }
}
