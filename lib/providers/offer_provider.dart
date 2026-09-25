import 'package:flutter/material.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/offer_model.dart';

class OfferProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OfferModel> _offers = [];

  List<OfferModel> get offers => _offers;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> fetchActiveOffers() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    debugPrint('Fetching active offers...');

    final response = await _apiService.client.get(
      ApiConstants.activeOffers,
    );

    debugPrint('Offer status: ${response.statusCode}');
    debugPrint('Offer response: ${response.data}');

    if (response.statusCode == 200 &&
        response.data['success'] == true) {
      final data = response.data['data'] as List? ?? [];

      _offers = data
          .map(
            (json) => OfferModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();

      debugPrint(
        'Offers loaded: ${_offers.length}',
      );
    } else {
      _offers = [];
      _errorMessage =
          response.data['message'] ?? 'Failed to load offers';

      debugPrint(
        'Offer API failed: $_errorMessage',
      );
    }
  } catch (e, stackTrace) {
    _offers = [];
    _errorMessage = 'Failed to load offers';

    debugPrint('Offer fetch exception: $e');
    debugPrint('$stackTrace');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}