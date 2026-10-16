import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/errand_model.dart';

/// Exception thrown when remote HTTP API call returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

/// Remote HTTP API service implementation adhering to P6 Vertical Slice specifications.
class ErrandApiService {
  final http.Client client;
  final Uri baseUrl;
  final Duration timeoutDuration;

  ErrandApiService({
    required this.client,
    required this.baseUrl,
    this.timeoutDuration = const Duration(seconds: 10),
  });

  /// GET /api/v1/errands
  /// Retrieves list of open and active errands from remote backend.
  Future<List<ErrandModel>> fetchErrands() async {
    final uri = baseUrl.replace(
      path: '${baseUrl.path.replaceAll(RegExp(r'/+$'), '')}/errands',
    );

    final response = await client.get(uri).timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Gagal memuat daftar titipan: HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw FormatException('Respons API bukan JSON yang valid: $e');
    }

    if (decoded is! List) {
      throw const FormatException(
        'Format respons API tidak valid: payload harus berupa JSON array.',
      );
    }

    return decoded
        .map((item) => ErrandModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/errands
  /// Submits and publishes a new errand request.
  Future<ErrandModel> createErrand(ErrandModel errand) async {
    final uri = baseUrl.replace(
      path: '${baseUrl.path.replaceAll(RegExp(r'/+$'), '')}/errands',
    );

    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(errand.toJson()),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        response.statusCode,
        'Gagal membuat titipan baru: HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw FormatException('Respons API bukan JSON yang valid: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Format respons pembuatan titipan tidak valid: harus berupa JSON object.',
      );
    }

    return ErrandModel.fromJson(decoded);
  }

  /// PATCH /api/v1/errands/{id}/accept
  /// Claims/accepts an open errand by a runner.
  Future<ErrandModel> acceptErrand(String id, {String runnerName = 'Runner'}) async {
    final uri = baseUrl.replace(
      path: '${baseUrl.path.replaceAll(RegExp(r'/+$'), '')}/errands/$id/accept',
    );

    final response = await client
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'runner': runnerName}),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Gagal mengklaim titipan: HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw FormatException('Respons API bukan JSON yang valid: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Format respons klaim titipan tidak valid: harus berupa JSON object.',
      );
    }

    return ErrandModel.fromJson(decoded);
  }

  /// PATCH /api/v1/errands/{id}/complete
  /// Marks an in-progress errand as completed.
  Future<ErrandModel> completeErrand(String id) async {
    final uri = baseUrl.replace(
      path: '${baseUrl.path.replaceAll(RegExp(r'/+$'), '')}/errands/$id/complete',
    );

    final response = await client
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Gagal menyelesaikan titipan: HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw FormatException('Respons API bukan JSON yang valid: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Format respons penyelesaian titipan tidak valid: harus berupa JSON object.',
      );
    }

    return ErrandModel.fromJson(decoded);
  }

  /// DELETE /api/v1/errands/{id}
  /// Cancels an open errand request.
  Future<void> deleteErrand(String id) async {
    final uri = baseUrl.replace(
      path: '${baseUrl.path.replaceAll(RegExp(r'/+$'), '')}/errands/$id',
    );

    final response = await client.delete(uri).timeout(timeoutDuration);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        response.statusCode,
        'Gagal membatalkan titipan: HTTP ${response.statusCode}',
      );
    }
  }
}
