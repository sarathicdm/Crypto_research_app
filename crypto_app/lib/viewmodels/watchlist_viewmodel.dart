import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_model.dart';
import '../repositories/crypto_repository.dart';
import 'market_viewmodel.dart';

// ── State ──────────────────────────────────────────────────────────────────

class WatchlistState {
  final List<String> watchlistIds;   // persisted coin IDs
  final List<CoinModel> coins;       // full coin data for those IDs
  final bool isLoading;
  final String? error;

  const WatchlistState({
    this.watchlistIds = const [],
    this.coins = const [],
    this.isLoading = false,
    this.error,
  });

  WatchlistState copyWith({
    List<String>? watchlistIds,
    List<CoinModel>? coins,
    bool? isLoading,
    String? error,
  }) {
    return WatchlistState(
      watchlistIds: watchlistIds ?? this.watchlistIds,
      coins: coins ?? this.coins,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

class WatchlistViewModel extends StateNotifier<WatchlistState> {
  final CryptoRepository _repo;
  static const _prefsKey = 'watchlist_ids';

  WatchlistViewModel(this._repo) : super(const WatchlistState()) {
    _loadFromPrefs();
  }

  // Read saved IDs from disk, then fetch their data from the API
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? [];
    state = state.copyWith(watchlistIds: ids);
    if (ids.isNotEmpty) await _fetchCoins(ids);
  }

  // Fetch full coin data for every ID in the watchlist
  Future<void> _fetchCoins(List<String> ids) async {
    state = state.copyWith(isLoading: true);
    try {
      // Fetch all coins in parallel
      final coins = await Future.wait(ids.map((id) => _repo.getCoinDetail(id)));
      // Convert CoinDetailModel → CoinModel for the shared list widget
      final coinModels = coins.map((detail) => CoinModel(
        id: detail.id,
        symbol: detail.symbol,
        name: detail.name,
        image: detail.imageUrl,
        currentPrice: detail.currentPrice,
        marketCap: detail.marketCap,
        totalVolume: detail.totalVolume,
        priceChangePercentage24h: detail.priceChangePercentage24h,
      )).toList();
      state = state.copyWith(coins: coinModels, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool isFavourite(String coinId) => state.watchlistIds.contains(coinId);

  Future<void> toggle(String coinId) async {
    final ids = List<String>.from(state.watchlistIds);
    if (ids.contains(coinId)) {
      ids.remove(coinId);
    } else {
      ids.add(coinId);
    }
    // Save to disk first, then refresh data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids);
    state = state.copyWith(watchlistIds: ids);
    if (ids.isNotEmpty) {
      await _fetchCoins(ids);
    } else {
      state = state.copyWith(coins: []);
    }
  }

  Future<void> refresh() => _fetchCoins(state.watchlistIds);
}

// ── Provider ──────────────────────────────────────────────────────────────

final watchlistViewModelProvider =
    StateNotifierProvider<WatchlistViewModel, WatchlistState>(
  (ref) => WatchlistViewModel(ref.watch(cryptoRepositoryProvider)),
);
