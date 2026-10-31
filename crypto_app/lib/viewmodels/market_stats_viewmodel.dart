import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_stats_model.dart';
import '../repositories/crypto_repository.dart';
import 'market_viewmodel.dart';

// ── State ──────────────────────────────────────────────────────────────────

class MarketStatsState {
  final MarketStatsModel? stats;
  final bool isLoading;
  final String? error;

  const MarketStatsState({this.stats, this.isLoading = false, this.error});

  MarketStatsState copyWith({
    MarketStatsModel? stats,
    bool? isLoading,
    String? error,
  }) {
    return MarketStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

class MarketStatsViewModel extends StateNotifier<MarketStatsState> {
  final CryptoRepository _repo;

  MarketStatsViewModel(this._repo) : super(const MarketStatsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final stats = await _repo.getMarketStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final marketStatsViewModelProvider =
    StateNotifierProvider<MarketStatsViewModel, MarketStatsState>(
  (ref) => MarketStatsViewModel(ref.watch(cryptoRepositoryProvider)),
);
