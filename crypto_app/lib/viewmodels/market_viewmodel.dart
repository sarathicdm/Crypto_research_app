import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coin_model.dart';
import '../repositories/crypto_repository.dart';
import '../services/api_service.dart';

// ── Filters ────────────────────────────────────────────────────────────────

class MarketFilters {
  final String change24h; // all | gainers | losers
  final String marketCap; // all | large | mid | small
  final String price; // all | under1 | oneTo100 | over100
  final String volume; // all | high | medium | low

  const MarketFilters({
    this.change24h = 'all',
    this.marketCap = 'all',
    this.price = 'all',
    this.volume = 'all',
  });

  bool get isActive =>
      change24h != 'all' ||
      marketCap != 'all' ||
      price != 'all' ||
      volume != 'all';

  List<String> get activeLabels {
    final labels = <String>[];
    if (change24h == 'gainers') labels.add('Gainers');
    if (change24h == 'losers') labels.add('Losers');
    if (marketCap == 'large') labels.add('Large cap');
    if (marketCap == 'mid') labels.add('Mid cap');
    if (marketCap == 'small') labels.add('Small cap');
    if (price == 'under1') labels.add('Price < \$1');
    if (price == 'oneTo100') labels.add('Price \$1–\$100');
    if (price == 'over100') labels.add('Price > \$100');
    if (volume == 'high') labels.add('High volume');
    if (volume == 'medium') labels.add('Medium volume');
    if (volume == 'low') labels.add('Low volume');
    return labels;
  }

  MarketFilters copyWith({
    String? change24h,
    String? marketCap,
    String? price,
    String? volume,
  }) {
    return MarketFilters(
      change24h: change24h ?? this.change24h,
      marketCap: marketCap ?? this.marketCap,
      price: price ?? this.price,
      volume: volume ?? this.volume,
    );
  }
}

// ── State ──────────────────────────────────────────────────────────────────

class MarketState {
  final List<CoinModel> coins;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String sortOrder;
  final MarketFilters filters;

  const MarketState({
    this.coins = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.sortOrder = 'market_cap_desc',
    this.filters = const MarketFilters(),
  });

  MarketState copyWith({
    List<CoinModel>? coins,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? sortOrder,
    MarketFilters? filters,
  }) {
    return MarketState(
      coins: coins ?? this.coins,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      filters: filters ?? this.filters,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

class MarketViewModel extends StateNotifier<MarketState> {
  final CryptoRepository _repo;
  List<CoinModel> _allCoins = [];

  MarketViewModel(this._repo) : super(const MarketState()) {
    loadCoins();
  }

  Future<void> loadCoins() async {
    state = state.copyWith(isLoading: true);
    try {
      _allCoins = await _repo.getCoins();
      state = state.copyWith(coins: _applyFilters(), isLoading: false);
    } catch (e) {
      state = MarketState(
        coins: state.coins,
        isLoading: false,
        error: e.toString(),
        searchQuery: state.searchQuery,
        sortOrder: state.sortOrder,
        filters: state.filters,
      );
    }
  }

  void search(String query) {
    state = MarketState(
      coins: _applyFilters(search: query),
      isLoading: state.isLoading,
      searchQuery: query,
      sortOrder: state.sortOrder,
      filters: state.filters,
    );
  }

  void sort(String order) {
    state = MarketState(
      coins: _applyFilters(sort: order),
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      sortOrder: order,
      filters: state.filters,
    );
  }

  void setFilters(MarketFilters filters) {
    state = MarketState(
      coins: _applyFilters(filters: filters),
      isLoading: state.isLoading,
      searchQuery: state.searchQuery,
      sortOrder: state.sortOrder,
      filters: filters,
    );
  }

  void clearFilters() => setFilters(const MarketFilters());

  List<CoinModel> _applyFilters({
    String? search,
    String? sort,
    MarketFilters? filters,
  }) {
    final q = (search ?? state.searchQuery).toLowerCase().trim();
    final order = sort ?? state.sortOrder;
    final f = filters ?? state.filters;

    var list = q.isEmpty
        ? List<CoinModel>.from(_allCoins)
        : _allCoins
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.symbol.toLowerCase().contains(q))
            .toList();

    list = list.where((c) {
      if (f.change24h == 'gainers' && c.priceChangePercentage24h < 0) {
        return false;
      }
      if (f.change24h == 'losers' && c.priceChangePercentage24h >= 0) {
        return false;
      }

      if (f.marketCap == 'large' && c.marketCap < 10e9) return false;
      if (f.marketCap == 'mid' && (c.marketCap < 1e9 || c.marketCap >= 10e9)) {
        return false;
      }
      if (f.marketCap == 'small' && c.marketCap >= 1e9) return false;

      if (f.price == 'under1' && c.currentPrice >= 1) return false;
      if (f.price == 'oneTo100' &&
          (c.currentPrice < 1 || c.currentPrice > 100)) {
        return false;
      }
      if (f.price == 'over100' && c.currentPrice <= 100) return false;

      if (f.volume == 'high' && c.totalVolume < 1e9) return false;
      if (f.volume == 'medium' &&
          (c.totalVolume < 1e8 || c.totalVolume >= 1e9)) {
        return false;
      }
      if (f.volume == 'low' && c.totalVolume >= 1e8) return false;

      return true;
    }).toList();

    switch (order) {
      case 'market_cap_asc':
        list.sort((a, b) => a.marketCap.compareTo(b.marketCap));
        break;
      case 'market_cap_desc':
        list.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        break;
      case 'price_asc':
        list.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case 'price_desc':
        list.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'volume_desc':
        list.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
        break;
    }
    return list;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final cryptoRepositoryProvider = Provider<CryptoRepository>(
  (ref) => CryptoRepository(ref.watch(apiServiceProvider)),
);

final marketViewModelProvider =
    StateNotifierProvider<MarketViewModel, MarketState>(
  (ref) => MarketViewModel(ref.watch(cryptoRepositoryProvider)),
);
