import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'core/network/auth_interceptor.dart';

import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/address_provider.dart';
import 'providers/order_provider.dart';
import 'providers/offer_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/main/main_navigation_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'models/order_model.dart';
import 'screens/order/order_list_screen.dart';
import 'screens/order/order_detail_screen.dart';
import 'screens/order/order_tracker_screen.dart';
import 'screens/address/address_list_screen.dart';
import 'screens/profile/coupons_screen.dart';
import 'screens/checkout/payment_screen.dart';

import 'dart:io';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = DevHttpOverrides();
  runApp(const CartITApp());
}

class CartITApp extends StatefulWidget {
  const CartITApp({super.key});

  @override
  State<CartITApp> createState() =>
      _CartITAppState();
}

class _CartITAppState
    extends State<CartITApp> {
  final GlobalKey<NavigatorState>
      _navigatorKey =
      GlobalKey<NavigatorState>();

  bool _handlingAuthExpiry = false;

  @override
  void initState() {
    super.initState();

    AuthInterceptor.authExpired
        .addListener(_handleAuthExpired);
  }

  @override
  void dispose() {
    AuthInterceptor.authExpired
        .removeListener(_handleAuthExpired);

    super.dispose();
  }

  Future<void> _handleAuthExpired() async {
    if (_handlingAuthExpiry) {
      return;
    }

    _handlingAuthExpiry = true;

    try {
      final navigator =
          _navigatorKey.currentState;

      final context =
          _navigatorKey.currentContext;

      if (navigator == null ||
          context == null) {
        return;
      }

      final authProvider =
          context.read<AuthProvider>();

      await authProvider.logout();

      if (!mounted) {
        return;
      }

      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } finally {
      AuthInterceptor.authExpired.value =
          false;

      _handlingAuthExpiry = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BrandProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AddressProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OfferProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CouponProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],

      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,

            title: 'CartIT',

            debugShowCheckedModeBanner: false,

            themeMode: themeProvider.themeMode,

            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surface,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: false,
              ),
            ),

            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.darkSurface,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: AppColors.darkBackground,
              cardColor: AppColors.darkSurface,
              cardTheme: CardThemeData(
                color: AppColors.darkSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.darkCardBorder, width: 1.0),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: AppColors.darkCardBorder,
                thickness: 1,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.darkBackground,
                elevation: 0,
                centerTitle: false,
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: AppColors.darkTitle),
                titleTextStyle: TextStyle(
                  color: AppColors.darkTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: AppColors.darkSurface,
                modalBackgroundColor: AppColors.darkSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
              ),
            ),

        initialRoute: AppRoutes.splash,

        routes: {
          AppRoutes.splash:
              (context) =>
                  const SplashScreen(),

          AppRoutes.login:
              (context) =>
                  const LoginScreen(),

          AppRoutes.otp:
              (context) =>
                  const OtpScreen(),

          AppRoutes.mainNav:
              (context) =>
                  const MainNavigationScreen(),

          AppRoutes.productList:
              (context) =>
                  const ProductListScreen(),

          AppRoutes.productDetail:
              (context) =>
                  const ProductDetailScreen(),

          AppRoutes.checkout:
              (context) =>
                  const CheckoutScreen(),

          AppRoutes.payment:
              (context) =>
                  const PaymentScreen(),

          AppRoutes.orderList:
              (context) =>
                  const OrderListScreen(),

          AppRoutes.orderDetail:
              (context) =>
                  const OrderDetailScreen(),

          AppRoutes.orderTracker: (context) {
            final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
            return OrderTrackerScreen(order: order);
          },

          AppRoutes.addresses:
              (context) =>
                  const AddressListScreen(),

          AppRoutes.coupons:
              (context) =>
                  const CouponsScreen(),
        },
      );
    },
  ),
);
}
}