import 'package:flutter/material.dart';
import 'package:krishi_sech/core/localization/app_date_format.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/market/data/datasources/remote_mandi_price_data_source.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';
import 'package:krishi_sech/features/market/presentation/mandi_price_text.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class MandiPricesView extends StatefulWidget {
  const MandiPricesView({
    super.key,
    required this.repository,
    required this.location,
  });

  final MandiPriceRepository repository;

  /// AGMARKNET is published per state, so without a saved farm location there
  /// is nothing to query — the view asks for one instead of guessing a state.
  final FarmLocation? location;

  @override
  State<MandiPricesView> createState() => _MandiPricesViewState();
}

class _MandiPricesViewState extends State<MandiPricesView> {
  List<MandiPrice> _prices = const [];
  bool _isLive = true;
  String? _commodity;
  String? _district;
  String? _market;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MandiPricesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location?.state != widget.location?.state) {
      // Filters name markets in the old state, so they cannot survive a move.
      _commodity = null;
      _district = null;
      _market = null;
      _load();
    }
  }

  Future<void> _load() async {
    final state = widget.location?.state.trim();
    if (state == null || state.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _prices = const [];
        _isLive = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final board = await widget.repository.getPrices(state: state);
      if (!mounted) return;
      setState(() {
        _prices = board.prices;
        _isLive = board.isLive;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MandiPrice> get _filtered => _prices
      .where(
        (price) =>
            (_commodity == null || price.commodity == _commodity) &&
            (_district == null || price.district == _district) &&
            (_market == null || price.marketName == _market),
      )
      .toList(growable: false);

  String _errorMessage(BuildContext context) {
    final error = _error;
    if (error is! MandiRemoteFailure) return context.l10n.mandiLoadError;
    return switch (error.type) {
      MandiRemoteFailureType.offline => context.l10n.mandiOffline,
      // Both mean the price service itself is down, which a retry now will
      // not fix — say so rather than inviting an immediate second attempt.
      MandiRemoteFailureType.notConfigured ||
      MandiRemoteFailureType.upstream => context.l10n.mandiUnavailable,
      _ => context.l10n.mandiLoadError,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final state = widget.location?.state.trim();
    if (state == null || state.isEmpty) {
      return _MandiState(
        key: const Key('mandi_location_missing'),
        icon: Icons.location_off_outlined,
        message: context.l10n.mandiLocationMissing,
      );
    }
    if (_error != null) {
      return _MandiState(
        icon: Icons.cloud_off_outlined,
        message: _errorMessage(context),
        actionLabel: context.l10n.retry,
        onAction: _load,
      );
    }

    final commodities = _prices.map((price) => price.commodity).toSet().toList()
      ..sort();
    final districts = _prices.map((price) => price.district).toSet().toList()
      ..sort();
    final markets = _prices.map((price) => price.marketName).toSet().toList()
      ..sort();
    final prices = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('mandi_prices_list'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          if (!_isLive && _prices.isNotEmpty) ...[
            _PartialListNotice(count: _prices.length),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final filterWidth = constraints.maxWidth < 420
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: filterWidth,
                    child: _FilterMenu<String>(
                      key: const Key('mandi_crop_filter'),
                      label: context.l10n.mandiCropFilter,
                      valueLabel: _commodity == null
                          ? context.l10n.all
                          : mandiCommodityLabel(context, _commodity!),
                      // Built from what the feed actually returned, so the
                      // filter can never offer a crop with no prices behind it.
                      values: commodities,
                      itemLabel: (value) => mandiCommodityLabel(context, value),
                      onSelected: (value) =>
                          setState(() => _commodity = value),
                      onClear: () => setState(() => _commodity = null),
                    ),
                  ),
                  SizedBox(
                    width: filterWidth,
                    child: _FilterMenu<String>(
                      key: const Key('mandi_district_filter'),
                      label: context.l10n.mandiDistrictFilter,
                      valueLabel: _district ?? context.l10n.all,
                      values: districts,
                      itemLabel: (value) => value,
                      onSelected: (value) => setState(() => _district = value),
                      onClear: () => setState(() => _district = null),
                    ),
                  ),
                  SizedBox(
                    width: filterWidth,
                    child: _FilterMenu<String>(
                      key: const Key('mandi_market_filter'),
                      label: context.l10n.mandiMarketFilter,
                      valueLabel: _market ?? context.l10n.all,
                      values: markets,
                      itemLabel: (value) => value,
                      onSelected: (value) => setState(() => _market = value),
                      onClear: () => setState(() => _market = null),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (prices.isEmpty)
            _MandiState(
              key: const Key('mandi_empty_state'),
              icon: Icons.search_off,
              // No rows at all means the state had no arrivals published,
              // which is different from filters excluding everything.
              message: _prices.isEmpty
                  ? context.l10n.noMandiPricesPublished
                  : context.l10n.noMandiPrices,
            )
          else
            for (final price in prices) ...[
              _MandiPriceCard(price: price),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// Shown when AGMARKNET was unreachable and the list is admin-entered rows
/// only. Without this the farmer reads a handful of real prices as the whole
/// market, which is the same wrong conclusion a fabricated list would produce.
class _PartialListNotice extends StatelessWidget {
  const _PartialListNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('mandi_partial_notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.mandiPartialList(count),
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.values,
    required this.itemLabel,
    required this.onSelected,
    required this.onClear,
  });

  final String label;
  final String valueLabel;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      onSelected: (value) {
        if (value == _clearFilter) {
          onClear();
        } else {
          onSelected(value as T);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: _clearFilter, child: Text(context.l10n.all)),
        for (final value in values)
          PopupMenuItem(value: value, child: Text(itemLabel(value))),
      ],
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                valueLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

const _clearFilter = '__all__';

class _MandiPriceCard extends StatelessWidget {
  const _MandiPriceCard({required this.price});

  final MandiPrice price;

  @override
  Widget build(BuildContext context) {
    // `unknown` gets no indicator at all: the backend has no earlier price for
    // this market yet, so any arrow would be invented.
    final trend = switch (price.trend) {
      PriceTrend.up => (Icons.trending_up, Colors.green, context.l10n.trendUp),
      PriceTrend.down => (
        Icons.trending_down,
        Colors.red,
        context.l10n.trendDown,
      ),
      PriceTrend.stable => (
        Icons.trending_flat,
        Colors.orange,
        context.l10n.trendStable,
      ),
      PriceTrend.unknown => null,
    };
    return Card(
      key: Key('mandi_price_${price.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.commodityLabel(context),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (price.variety != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          price.variety!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        price.marketName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(price.district),
                    ],
                  ),
                ),
                if (trend != null)
                  Semantics(
                    label: trend.$3,
                    child: Icon(trend.$1, color: trend.$2),
                  ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _PriceValue(
                  label: context.l10n.minimumPrice,
                  value: '₹${price.minPrice}',
                ),
                _PriceValue(
                  label: context.l10n.maximumPrice,
                  value: '₹${price.maxPrice}',
                ),
                _PriceValue(
                  label: context.l10n.modalPrice,
                  value: '₹${price.modalPrice}',
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.mandiPriceUnit(price.unit),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              // The arrival date, not the fetch time: a price belongs to the
              // day the produce reached the mandi.
              context.l10n.mandiArrivalDate(
                AppDateFormat.pattern(
                  'dd MMM yyyy',
                  Localizations.localeOf(context).languageCode,
                ).format(price.arrivalDate),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceValue extends StatelessWidget {
  const _PriceValue({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.primary : null,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MandiState extends StatelessWidget {
  const _MandiState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
