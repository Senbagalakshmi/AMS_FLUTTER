import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'http://localhost:8082/api';
  
  try {
    // 1. Login to get token
    print('Logging in...');
    final loginRes = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@example.com',
        'password': 'password',
        'productCode': 'AMS'
      }),
    );
    
    String? token;
    if (loginRes.statusCode == 200) {
      final loginData = jsonDecode(loginRes.body);
      token = loginData['mother_token'];
      if (token != null) {
          final exchangeRes = await http.post(
            Uri.parse('http://localhost:8082/am/exchange-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'productCode': 'AMS'}),
          );
          if (exchangeRes.statusCode == 200) {
              token = jsonDecode(exchangeRes.body)['child_token'] ?? jsonDecode(exchangeRes.body)['access_token'];
          }
      }
    }
    
    // 2. Fetch users
    print('Fetching users...');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final res = await http.get(
      Uri.parse('$baseUrl/users?page=0&size=10'),
      headers: headers,
    );
    
    print('Users status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      print('Is List: ${decoded is List}');
      if (decoded is List) {
        print('Length: ${decoded.length}');
      } else {
        print('Total Elements: ${decoded['totalElements']}');
        print('Content length: ${(decoded['content'] as List).length}');
      }
    } else {
      print('Users body: ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
