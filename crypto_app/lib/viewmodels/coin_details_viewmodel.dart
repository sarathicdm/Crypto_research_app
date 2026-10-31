import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coin_detail_model.dart';
import '../models/chart_model.dart';
import '../repositories/crypto_repository.dart';
import 'market_viewmodel.dart';

// ── State ──────────────────────────────────────────────────────────────────

class CoinDetailsState {
  final CoinDetailModel? coin;
  final ChartModel? chart;
  final bool isLoading;
  final String? error;
  final int selectedDays; // 1 | 7 | 30 | 90

  const CoinDetailsState({
    this.coin,
    this.chart,
    this.isLoading = false,
    this.error,
    this.selectedDays = 7,
  });

  CoinDetailsState copyWith({
    CoinDetailModel? coin,
    ChartModel? chart,
    bool? isLoading,
    String? error,
    int? selectedDays,
  }) {
    return CoinDetailsState(
      coin: coin ?? this.coin,
      chart: chart ?? this.chart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

class CoinDetailsViewModel extends StateNotifier<CoinDetailsState> {
  final CryptoRepository _repo;
  final String coinId;

  CoinDetailsViewModel(this._repo, this.coinId) : super(const CoinDetailsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      // Fetch detail and chart in parallel for speed
      final results = await Future.wait([
        _repo.getCoinDetail(coinId),
        _repo.getCoinChart(coinId, days: state.selectedDays),
      ]);
      state = state.copyWith(
        coin: results[0] as CoinDetailModel,
        chart: results[1] as ChartModel,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeChartPeriod(int days) async {
    state = state.copyWith(selectedDays: days, isLoading: true);
    try {
      final chart = await _repo.getCoinChart(coinId, days: days);
      state = state.copyWith(chart: chart, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

// family() lets us create one provider instance per coinId
final coinDetailsViewModelProvider = StateNotifierProvider.family<
    CoinDetailsViewModel, CoinDetailsState, String>(
  (ref, coinId) => CoinDetailsViewModel(ref.watch(cryptoRepositoryProvider), coinId),
);
