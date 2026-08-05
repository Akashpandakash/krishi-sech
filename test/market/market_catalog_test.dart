import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';
import 'package:krishi_sech/features/market/domain/repositories/mandi_price_repository.dart';
import 'package:krishi_sech/features/market/domain/repositories/market_repository.dart';
import 'package:krishi_sech/features/market/presentation/pages/market_page.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('Mandi Prices is the default Market tab', (tester) async {
    await _pumpMarket(tester);

    expect(find.byKey(const Key('mandi_prices_list')), findsOneWidget);
    expect(find.text('Wheat'), findsOneWidget);
    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsNothing);
  });

  testWidgets('Market switches between Mandi Prices and Shop', (tester) async {
    await _pumpMarket(tester);

    await _openShop(tester);
    expect(find.text('Premium Wheat Seeds'), findsOneWidget);

    await tester.tap(find.byKey(const Key('market_mandi_tab')));
    await tester.pumpAndSettle();
    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
  });

  testWidgets('crop filter narrows mandi prices', (tester) async {
    await _pumpMarket(tester);

    await tester.tap(find.byKey(const Key('mandi_crop_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wheat').last);
    await tester.pumpAndSettle();

    expect(find.text('Burdwan Krishak Bazar'), findsOneWidget);
    expect(find.text('Koley Market'), findsNothing);
  });

  testWidgets('district filter narrows mandi prices', (tester) async {
    await _pumpMarket(tester);

    await tester.tap(find.byKey(const Key('mandi_district_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kolkata').last);
    await tester.pumpAndSettle();

    expect(find.text('Koley Market'), findsNWidgets(2));
    expect(find.text('Burdwan Krishak Bazar'), findsNothing);
  });

  testWidgets('empty mandi state is shown', (tester) async {
    await _pumpMarket(
      tester,
      mandiRepository: const _EmptyMandiPriceRepository(),
    );

    expect(find.byKey(const Key('mandi_empty_state')), findsOneWidget);
    expect(find.text('No mandi prices match these filters.'), findsOneWidget);
  });

  testWidgets('Mandi Prices fits a small physical-phone layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpMarket(tester);

    expect(find.byKey(const Key('mandi_prices_list')), findsOneWidget);
    expect(find.byKey(const Key('mandi_crop_filter')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product card opens Product Details and back returns to Market', (
    tester,
  ) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.tap(
      find.byKey(const Key('market_product_premium-wheat-seeds')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Krishi Market'), findsOneWidget);
  });

  testWidgets('Product Details renders complete catalog information', (
    tester,
  ) async {
    await _pumpMarket(tester);
    await _openShop(tester);
    await tester.tap(
      find.byKey(const Key('market_product_premium-wheat-seeds')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seeds'), findsOneWidget);
    expect(find.text('₹1250 / bag'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('In stock (48 available)'), findsOneWidget);
    expect(find.text('Krishi Sech Seeds Cooperative'), findsOneWidget);
    expect(
      find.byKey(const Key('market_product_image_placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('search filters the product catalog', (tester) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.enterText(
      find.byKey(const Key('market_search_field')),
      'tomato',
    );
    await tester.pump();

    expect(find.text('Tomato Seeds'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsNothing);
    expect(find.text('Garden Sprayer'), findsNothing);
  });

  testWidgets('category chip filters the product catalog', (tester) async {
    await _pumpMarket(tester);
    await _openShop(tester);

    await tester.tap(find.byKey(const Key('market_category_fertilizers')));
    await tester.pump();

    expect(find.text('Organic Fertilizer'), findsOneWidget);
    expect(find.text('Premium Wheat Seeds'), findsNothing);
    expect(find.text('Garden Sprayer'), findsNothing);
  });

  testWidgets('empty catalog state is shown', (tester) async {
    await _pumpMarket(tester, repository: const _EmptyMarketRepository());
    await _openShop(tester);

    expect(find.byKey(const Key('market_empty_state')), findsOneWidget);
    expect(find.text('No products match your search.'), findsOneWidget);
  });
}

Future<void> _pumpMarket(
  WidgetTester tester, {
  MarketRepository? repository,
  MandiPriceRepository? mandiRepository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: Scaffold(
        body: MarketPage(
          repository: repository,
          mandiRepository: mandiRepository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openShop(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('market_shop_tab')));
  await tester.pumpAndSettle();
}

class _EmptyMarketRepository implements MarketRepository {
  const _EmptyMarketRepository();

  @override
  Future<List<MarketProduct>> getProducts() async => const [];
}

class _EmptyMandiPriceRepository implements MandiPriceRepository {
  const _EmptyMandiPriceRepository();

  @override
  Future<List<MandiPrice>> getPrices() async => const [];
}
