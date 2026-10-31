import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// A simple exception class so the Repository can show meaningful messages.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final String _base = ApiConfig.baseUrl;

  // Internal helper — makes a GET request and returns the decoded JSON body.
  // Throws ApiException for any failure so callers don't deal with raw HTTP.
  Future<dynamic> _get(String path, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw ApiException('Not found.');
      } else if (response.statusCode == 429) {
        throw ApiException('Rate limit reached. Please wait and try again.');
      } else {
        throw ApiException('Server error (${response.statusCode}).');
      }
    } on SocketException {
      throw ApiException('No internet connection. Is the backend running?');
    } on ApiException {
      rethrow; // already typed, pass it up
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // GET /coins?search=...&order=...
  Future<List<dynamic>> getCoins({String? search, String order = 'market_cap_desc'}) async {
    final params = <String, String>{'order': order};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final body = await _get('/coins', queryParams: params);
    return body['coins'] as List<dynamic>;
  }

  // GET /coins/{coin_id}
  Future<Map<String, dynamic>> getCoinDetail(String coinId) async {
    final body = await _get('/coins/$coinId');
    return body['coin'] as Map<String, dynamic>;
  }

  // GET /coins/{coin_id}/chart?days=7
  Future<Map<String, dynamic>> getCoinChart(String coinId, {int days = 7}) async {
    final body = await _get('/coins/$coinId/chart', queryParams: {'days': '$days'});
    return body['chart'] as Map<String, dynamic>;
  }

  // GET /market/stats
  Future<Map<String, dynamic>> getMarketStats() async {
    final body = await _get('/market/stats');
    return body['stats'] as Map<String, dynamic>;
  }
}
