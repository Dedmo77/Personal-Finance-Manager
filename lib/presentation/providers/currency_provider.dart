import 'package:flutter/material.dart';
import '../../data/services/currency_service.dart';

enum CurrencyStatus { initial, loading, loaded, error }

class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _service = CurrencyService.instance;

  Map<String, double> _rates       = {};
  List<String> _currencies         = ['USD','EUR','GBP','JPY','CAD','AUD','CHF','CNY','EGP','MAD'];
  CurrencyStatus _status           = CurrencyStatus.initial;
  String _errorMessage             = '';
  String _baseCurrency;

  CurrencyProvider({String baseCurrency = 'USD'}) : _baseCurrency = baseCurrency;

  Map<String, double> get rates           => _rates;
  List<String>        get currencies      => _currencies;
  CurrencyStatus      get status          => _status;
  String              get errorMessage    => _errorMessage;
  String              get baseCurrency    => _baseCurrency;
  bool                get isLoading       => _status == CurrencyStatus.loading;
  bool                get hasError        => _status == CurrencyStatus.error;

  Future<void> loadRates() async {
    _status = CurrencyStatus.loading;
    _errorMessage = '';
    notifyListeners();
    try {
      _rates = await _service.getRates(_baseCurrency);
      // Expand currency list from API response on first successful load
      if (_currencies.length <= 12) {
        _currencies = await _service.getSupportedCurrencies();
      }
      _status = CurrencyStatus.loaded;
    } catch (e) {
      _status = CurrencyStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> setBaseCurrency(String currency) async {
    if (_baseCurrency == currency) return;
    _baseCurrency = currency;
    _service.clearCache();
    await loadRates();
  }

  /// Converts [amount] from [from] to the current [baseCurrency].
  /// Falls back to the original amount on error.
  Future<double> convertToBase(double amount, String from) async {
    try {
      return await _service.convert(
          amount: amount, fromCurrency: from, toCurrency: _baseCurrency);
    } catch (_) {
      return amount;
    }
  }

  /// Arbitrary conversion between any two currencies.
  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      return await _service.convert(amount: amount, fromCurrency: from, toCurrency: to);
    } catch (_) {
      return amount;
    }
  }
}