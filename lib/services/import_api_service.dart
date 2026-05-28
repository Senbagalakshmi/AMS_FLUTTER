import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';

class ImportApiService {
  Future<Map<String, dynamic>?> importCompanyGlData(
      Uint8List bytes, String filename, String eUser) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/imports/company?eUser=$eUser');
      final request = http.MultipartRequest('POST', uri);
      
      // Copy headers from apiService
      apiService.headers.forEach((key, value) {
        request.headers[key] = value;
      });

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('text', 'csv'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = response.body;
        if (body.startsWith('{')) {
          return jsonDecode(body);
        }
        return {'status': 'ERROR', 'message': body};
      }
    } catch (e) {
      print('importCompanyGlData Error: $e');
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }
}

final importApiService = ImportApiService();
