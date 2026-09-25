class ApiConstants {
  ApiConstants._();

  static const String serverHost = "cartit-backend-gqg9.onrender.com";
  static const String baseUrl = "https://$serverHost/api";

  static const String activeOffers = '/offers/active';

  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    String cleanUrl = url.trim();

    if (cleanUrl.contains('localhost:8080')) {
      cleanUrl = cleanUrl.replaceAll('localhost:8080', serverHost);
    }

    if (cleanUrl.contains('127.0.0.1:8080')) {
      cleanUrl = cleanUrl.replaceAll('127.0.0.1:8080', serverHost);
    }

    if (!cleanUrl.startsWith('http://') &&
        !cleanUrl.startsWith('https://')) {
      if (cleanUrl.startsWith('/')) {
        return 'https://$serverHost$cleanUrl';
      }

      return 'https://$serverHost/$cleanUrl';
    }

    return cleanUrl;
  }

  // ---------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------

  static const String checkPhone =
      "/auth/check-phone";

  static const String sendOtp =
      "/auth/send-otp";

  static const String verifyOtp =
      "/auth/verify-otp";

  // ---------------------------------------------------------
  // PRODUCTS
  // ---------------------------------------------------------

  static const String products =
      "/products";

  static const String featuredProducts =
      "/products/featured";

  static const String categoryProducts =
      "/products/category";

  static const String brandProducts =
      "/products/brand";

  static String productById(int id) {
    return "/products/$id";
  }

  // ---------------------------------------------------------
  // CATEGORIES & BRANDS
  // ---------------------------------------------------------

  static const String categories =
      "/categories";

  static const String brands =
      "/brands";

  // ---------------------------------------------------------
  // OFFERS
  // ---------------------------------------------------------

  static const String offers =
      "/offers";

  // ---------------------------------------------------------
  // CART
  // ---------------------------------------------------------

  static const String cart =
      "/cart";

  // ---------------------------------------------------------
  // WISHLIST
  // ---------------------------------------------------------

  static const String wishlist =
      "/wishlist";

  // ---------------------------------------------------------
  // ADDRESS
  // ---------------------------------------------------------

  static const String addresses =
      "/addresses";

  // ---------------------------------------------------------
  // ORDERS
  // ---------------------------------------------------------

  static const String checkout =
      "/checkout";

  static const String orders =
      "/orders";

  // ---------------------------------------------------------
  // COUPONS
  // ---------------------------------------------------------

  static const String validateCoupon =
      "/coupons/validate";

  static const String activeCoupons =
      "/coupons/active";

  static const String store =
      "/store";
}