import '../../../../core/00_base/module_base.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../tools/logging/logger.dart';

class ConnectionsModule extends ModuleBase {
  static ConnectionsModule? _instance;
  final String baseUrl;

  // Map to store any active connections or headers for future extensibility
  final Map<String, String> _customHeaders = {};

  ConnectionsModule._internal(this.baseUrl) {
    _registerConnectionMethods();
  }

  /// Factory method to provide the singleton instance
  factory ConnectionsModule(String baseUrl) {
    if (_instance == null) {
      Logger().info('Initializing ConnectionsModule with baseUrl: $baseUrl');
      _instance = ConnectionsModule._internal(baseUrl);
    } else {
      Logger().info('ConnectionsModule instance already exists.');
    }
    return _instance!;
  }

  /// Registers methods with the module
  void _registerConnectionMethods() {
    Logger().info('Registering connection methods in ConnectionsModule.');
    registerMethod('sendGetRequest', sendGetRequest);
    registerMethod('sendPostRequest', sendPostRequest);
    registerMethod('sendRequest', sendRequest);
  }

  /// Dispose method to clean up resources
  @override
  void dispose() {
    Logger().info('Cleaning up ConnectionsModule resources.');

    // Clear custom headers or state
    _customHeaders.clear();
    Logger().info('Custom headers cleared.');

    // Log if there were any additional cleanup tasks
    Logger().info('ConnectionsModule disposed successfully.');

    super.dispose(); // Call base dispose logic
  }

  /// Validates URLs
  void validateUrl(String url) {
    if (!Uri.tryParse(url)!.isAbsolute ?? true) {
      throw Exception('Invalid URL: $url');
    }
  }

  /// Method to handle GET requests
  Future<dynamic> sendGetRequest(String route) async {
    final url = Uri.parse('$baseUrl$route');
    validateUrl(url.toString());

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json", ..._customHeaders},
      );

      Logger().info('GET $url - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {"message": "GET request failed", "error": e.toString()};
    }
  }

  /// Method to handle POST requests
  Future<dynamic> sendPostRequest(String route, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$route');
    validateUrl(url.toString());

    try {
      Logger().info(" Sending POST request to: $url");
      Logger().debug(" Request Body: ${jsonEncode(data)}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", ..._customHeaders},
        body: jsonEncode(data),
      );

      Logger().info(" Response Status: ${response.statusCode}");
      Logger().debug(" Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        Logger().error(" Server returned error: ${response.body}");
        return jsonDecode(response.body);
      }
    } catch (e) {
      Logger().error(" POST request failed: $e", error: e);
      return {"message": "POST request failed", "error": e.toString()};
    }
  }


  /// Flexible method to handle various HTTP methods
  Future<dynamic> sendRequest(
      String route, {
        required String method,
        Map<String, dynamic>? data,
      }) async {
    final url = Uri.parse('$baseUrl$route');
    validateUrl(url.toString());

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: {"Content-Type": "application/json", ..._customHeaders});
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: {"Content-Type": "application/json", ..._customHeaders},
            body: jsonEncode(data ?? {}),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: {"Content-Type": "application/json", ..._customHeaders},
            body: jsonEncode(data ?? {}),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: {"Content-Type": "application/json", ..._customHeaders});
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      Logger().info('$method $url - Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {"message": "$method request failed", "error": e.toString()};
    }
  }
}
