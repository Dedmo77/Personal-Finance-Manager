import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches live exchange rates from open.er-api.com (free, no API key needed).
/// Rates are cached in-memory for 1 hour to avoid excessive requests.
class CurrencyService {
  static final CurrencyService instance = CurrencyService._();
  CurrencyService._();

  Map<String, double>? _rates;
  String? _ratesBase;
  DateTime? _fetchedAt;

  static const _baseUrl = 'https://open.er-api.com/v6/latest';
  static const _cacheDuration = Duration(hours: 1);

  /// Returns exchange rates with [baseCurrency] as the base (1 unit).
  Future<Map<String, double>> getRates(String baseCurrency) async {
    final now = DateTime.now();
    if (_rates != null &&
        _ratesBase == baseCurrency &&
        _fetchedAt != null &&
        now.difference(_fetchedAt!) < _cacheDuration) {
      return _rates!;
    }

    final response = await http
        .get(Uri.parse('$_baseUrl/$baseCurrency'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Exchange rate fetch failed (HTTP ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['result'] != 'success') {
      throw Exception('Exchange rate API error: ${json['error-type']}');
    }

    final raw = json['rates'] as Map<String, dynamic>;
    _rates     = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    _ratesBase = baseCurrency;
    _fetchedAt = now;
    return _rates!;
  }

  /// Converts [amount] from [fromCurrency] to [toCurrency].
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;
    // Fetch base = toCurrency so we get the 1 toCurrency = X fromCurrency rate.
    final rates    = await getRates(toCurrency);
    final fromRate = rates[fromCurrency];
    if (fromRate == null || fromRate == 0) {
      throw Exception('Unknown currency: $fromCurrency');
    }
    return amount / fromRate;
  }

  /// All currency codes supported by the API, sorted alphabetically.
  Future<List<String>> getSupportedCurrencies() async {
    final rates = await getRates('USD');
    return rates.keys.toList()..sort();
  }

  void clearCache() {
    _rates     = null;
    _ratesBase = null;
    _fetchedAt = null;
  }
}