import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../models/coin_model.dart';
import '../../models/market_stats_model.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/market_viewmodel.dart';
import '../../viewmodels/market_stats_viewmodel.dart';
import '../../viewmodels/watchlist_viewmodel.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../coin_details/coin_details_screen.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _searchController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final has = _searchController.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet(
      MarketViewModel vm, MarketFilters current) async {
    final result = await showModalBottomSheet<MarketFilters>(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MarketFilterSheet(initial: current),
    );
    if (!mounted || result == null) return;
    vm.setFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketViewModelProvider);
    final vm = ref.read(marketViewModelProvider.notifier);
    final statsState = ref.watch(marketStatsViewModelProvider);
    final watchlistState = ref.watch(watchlistViewModelProvider);
    final watchlistVm = ref.read(watchlistViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Market Research App'),

      ),
      body: Column(
        children: [
          if (statsState.stats != null)
            _StatsCardsRow(stats: statsState.stats!),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search coins...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                      suffixIcon: _hasText
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                vm.search('');
                              },
                            )
                          : null,
                    ),
                    onChanged: vm.search,
                  ),
                ),
                IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _openFilterSheet(vm, state.filters),
                  icon: Badge(
                    isLabelVisible: state.filters.isActive,
                    smallSize: 8,
                    backgroundColor: AppTheme.accent,
                    child: Icon(
                      Icons.filter_alt_rounded,
                      color: state.filters.isActive
                          ? AppTheme.accent
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  color: AppTheme.card,
                  onSelected: vm.sort,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'market_cap_desc', child: Text('Market Cap ↓')),
                    PopupMenuItem(value: 'market_cap_asc', child: Text('Market Cap ↑')),
                    PopupMenuItem(value: 'price_desc', child: Text('Price ↓')),
                    PopupMenuItem(value: 'price_asc', child: Text('Price ↑')),
                    PopupMenuItem(value: 'volume_desc', child: Text('Volume ↓')),
                  ],
                ),
              ],
            ),
          ),

          if (state.filters.isActive)
            _ActiveFiltersBar(
              labels: state.filters.activeLabels,
              onClear: vm.clearFilters,
            ),

          const _TableHeader(),

          Expanded(
            child: _buildBody(state, watchlistState.watchlistIds, vm, watchlistVm),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MarketState state, List<String> watchlistIds,
      MarketViewModel vm, WatchlistViewModel watchlistVm) {
    if (state.isLoading && state.coins.isEmpty) return const LoadingWidget();
    if (state.error != null && state.coins.isEmpty) {
      return AppErrorWidget(message: state.error!, onRetry: vm.loadCoins);
    }
    if (state.coins.isEmpty) {
      return const Center(
        child: Text('No coins found.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.card,
      onRefresh: vm.loadCoins,
      child: ListView.builder(
        itemCount: state.coins.length,
        itemBuilder: (context, index) {
          final coin = state.coins[index];
          return _CoinTableRow(
            rank: index + 1,
            coin: coin,
            isFavourite: watchlistIds.contains(coin.id),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CoinDetailsScreen(coinId: coin.id, coinName: coin.name),
              ),
            ),
            onFavouriteTap: () => watchlistVm.toggle(coin.id),
          );
        },
      ),
    );
  }
}


// Simulated sparkline data — descending for market cap (negative), ascending for volume (positive)
const _capPoints  = [100.0, 98.0, 97.0, 95.0, 93.0, 91.0, 90.0, 88.0, 87.0, 86.0];
const _volPoints  = [60.0,  62.0, 61.0, 64.0, 66.0, 68.0, 70.0, 73.0, 75.0, 78.0];

class _StatsCardsRow extends StatelessWidget {
  final MarketStatsModel stats;
  const _StatsCardsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final capChange = stats.marketCapChange24h;
    final capChangeColor = capChange >= 0 ? AppTheme.positive : AppTheme.negative;
    final capChangeIcon = capChange >= 0 ? '▲' : '▼';

    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        children: [
          _StatCard(
            label: 'Global Market Cap',
            value: Formatters.compactCurrency(stats.totalMarketCap),
            subtitle: '$capChangeIcon ${capChange.abs().toStringAsFixed(1)}%',
            subtitleColor: capChangeColor,
            lineColor: capChangeColor,
            sparkPoints: _capPoints,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: '24H Volume',
            value: Formatters.compactCurrency(stats.totalVolume),
            subtitle: 'BTC ${stats.btcDominance.toStringAsFixed(1)}%  '
                'ETH ${stats.ethDominance.toStringAsFixed(1)}%',
            subtitleColor: AppTheme.textSecondary,
            lineColor: AppTheme.positive,
            sparkPoints: _volPoints,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final Color lineColor;
  final List<double> sparkPoints;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.lineColor,
    required this.sparkPoints,
  });

  @override
  Widget build(BuildContext context) {
    final spots = sparkPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      width: 185,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(subtitle,
                    style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),overflow: TextOverflow.ellipsis,maxLines: 1,),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 1.8,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withAlpha(80),
                          lineColor.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ActiveFiltersBar extends StatelessWidget {
  final List<String> labels;
  final VoidCallback onClear;

  const _ActiveFiltersBar({required this.labels, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: labels
                    .map((label) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              label,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppTheme.surface,
                            side: const BorderSide(color: AppTheme.divider),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _MarketFilterSheet extends StatefulWidget {
  final MarketFilters initial;

  const _MarketFilterSheet({required this.initial});

  @override
  State<_MarketFilterSheet> createState() => _MarketFilterSheetState();
}

class _MarketFilterSheetState extends State<_MarketFilterSheet> {
  late MarketFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter market',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _FilterGroup(
              title: '24H Change',
              options: const [
                ('all', 'All'),
                ('gainers', 'Gainers'),
                ('losers', 'Losers'),
              ],
              selected: _filters.change24h,
              onSelected: (value) =>
                  setState(() => _filters = _filters.copyWith(change24h: value)),
            ),
            _FilterGroup(
              title: 'Market Cap',
              options: const [
                ('all', 'All'),
                ('large', 'Large ≥ \$10B'),
                ('mid', 'Mid \$1B–\$10B'),
                ('small', 'Small < \$1B'),
              ],
              selected: _filters.marketCap,
              onSelected: (value) =>
                  setState(() => _filters = _filters.copyWith(marketCap: value)),
            ),
            _FilterGroup(
              title: 'Price',
              options: const [
                ('all', 'All'),
                ('under1', '< \$1'),
                ('oneTo100', '\$1–\$100'),
                ('over100', '> \$100'),
              ],
              selected: _filters.price,
              onSelected: (value) =>
                  setState(() => _filters = _filters.copyWith(price: value)),
            ),
            _FilterGroup(
              title: '24H Volume',
              options: const [
                ('all', 'All'),
                ('high', 'High ≥ \$1B'),
                ('medium', 'Mid \$100M–\$1B'),
                ('low', 'Low < \$100M'),
              ],
              selected: _filters.volume,
              onSelected: (value) =>
                  setState(() => _filters = _filters.copyWith(volume: value)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const MarketFilters()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _filters),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected == option.$1;
              return GestureDetector(
                onTap: () => onSelected(option.$1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.black : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.accent : AppTheme.divider,
                    ),
                  ),
                  child: Text(
                    option.$2,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: const Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('#',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text('Coin',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              flex: 3,
              child: Text('Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              flex: 2,
              child: Text('24H',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              flex: 4,
              child: Text('Market Cap',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}


class _CoinTableRow extends StatelessWidget {
  final int rank;
  final CoinModel coin;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  const _CoinTableRow({
    required this.rank,
    required this.coin,
    required this.isFavourite,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.priceChangePercentage24h >= 0;
    final changeColor = isPositive ? AppTheme.positive : AppTheme.negative;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('$rank',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _CoinIcon(imageUrl: coin.image),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      coin.symbol.toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                Formatters.price(coin.currentPrice),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${isPositive ? '▲' : '▼'} ${coin.priceChangePercentage24h.abs().toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                Formatters.compactCurrency(coin.marketCap),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12),
              ),
            ),
            GestureDetector(
              onTap: onFavouriteTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isFavourite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavourite ? Colors.amber : AppTheme.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinIcon extends StatelessWidget {
  final String imageUrl;
  const _CoinIcon({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const _FallbackIcon();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) => const _FallbackIcon(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const _FallbackIcon(),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) => const CircleAvatar(
        radius: 14,
        backgroundColor: AppTheme.divider,
        child: Icon(Icons.currency_bitcoin, color: AppTheme.textSecondary, size: 14),
      );
}
