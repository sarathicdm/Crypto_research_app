import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../viewmodels/watchlist_viewmodel.dart';
import '../../widgets/coin_list_item.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../coin_details/coin_details_screen.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistViewModelProvider);
    final vm = ref.read(watchlistViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: _buildBody(context, state, vm, ref),
    );
  }

  Widget _buildBody(BuildContext context, WatchlistState state,
      WatchlistViewModel vm, WidgetRef ref) {
    if (state.isLoading && state.coins.isEmpty) return const LoadingWidget();

    if (state.error != null && state.coins.isEmpty) {
      return AppErrorWidget(message: state.error!, onRetry: vm.refresh);
    }

    if (state.watchlistIds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline_rounded, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('Your watchlist is empty.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('Tap the ★ on any coin to add it here.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.card,
      onRefresh: vm.refresh,
      child: ListView.builder(
        itemCount: state.coins.length,
        itemBuilder: (context, index) {
          final coin = state.coins[index];
          return CoinListItem(
            coin: coin,
            isFavourite: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CoinDetailsScreen(coinId: coin.id, coinName: coin.name),
              ),
            ),
            onFavouriteTap: () => vm.toggle(coin.id),
          );
        },
      ),
    );
  }
}
