import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishi_sech/app/theme/app_colors.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';
import 'package:krishi_sech/l10n/l10n.dart';

class MandiPricesView extends StatefulWidget {
  const MandiPricesView({super.key, required this.repository});

  final MandiPriceRepository repository;

  @override
  State<MandiPricesView> createState() => _MandiPricesViewState();
}

class _MandiPricesViewState extends State<MandiPricesView> {
  List<MandiPrice> _prices = const [];
  MandiCrop? _crop;
  String? _district;
  String? _market;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prices = await widget.repository.getPrices();
      if (!mounted) return;
      setState(() => _prices = prices);
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
            (_crop == null || price.crop == _crop) &&
            (_district == null || price.district == _district) &&
            (_market == null || price.marketName == _market),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _MandiState(
        icon: Icons.cloud_off_outlined,
        message: context.l10n.mandiLoadError,
        actionLabel: context.l10n.retry,
        onAction: _load,
      );
    }

    final districts = _prices.map((price) => price.district).toSet().toList()
      ..sort();
    final markets = _prices.map((price) => price.marketName).toSet().toList()
      ..sort();
    final prices = _filtered;

    return ListView(
      key: const Key('mandi_prices_list'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
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
                  child: _FilterMenu<MandiCrop>(
                    key: const Key('mandi_crop_filter'),
                    label: context.l10n.mandiCropFilter,
                    valueLabel: _crop == null
                        ? context.l10n.all
                        : _cropName(context, _crop!),
                    values: MandiCrop.values,
                    itemLabel: (crop) => _cropName(context, crop),
                    onSelected: (crop) => setState(() => _crop = crop),
                    onClear: () => setState(() => _crop = null),
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
            message: context.l10n.noMandiPrices,
          )
        else
          for (final price in prices) ...[
            _MandiPriceCard(price: price),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  String _cropName(BuildContext context, MandiCrop crop) => switch (crop) {
    MandiCrop.paddy => context.l10n.paddy,
    MandiCrop.wheat => context.l10n.wheat,
    MandiCrop.maize => context.l10n.maize,
    MandiCrop.mustard => context.l10n.mustard,
    MandiCrop.tomato => context.l10n.tomato,
    MandiCrop.potato => context.l10n.potato,
    MandiCrop.onion => context.l10n.onion,
  };
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
                        _cropLabel(context, price.crop),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        price.marketName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(price.district),
                    ],
                  ),
                ),
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
              context.l10n.mandiUpdatedAt(
                DateFormat('dd MMM, h:mm a').format(price.updatedAt),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _cropLabel(BuildContext context, MandiCrop crop) => switch (crop) {
    MandiCrop.paddy => context.l10n.paddy,
    MandiCrop.wheat => context.l10n.wheat,
    MandiCrop.maize => context.l10n.maize,
    MandiCrop.mustard => context.l10n.mustard,
    MandiCrop.tomato => context.l10n.tomato,
    MandiCrop.potato => context.l10n.potato,
    MandiCrop.onion => context.l10n.onion,
  };
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
