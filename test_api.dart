import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'http://localhost:8085/api'; 
  
  try {
    // 1. Login to get token
    print('Logging in...');
    final loginRes = await http.post(
      Uri.parse('\$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'admin',
        'password': 'password'
      }),
    );
    
    if (loginRes.statusCode != 200) {
      print('Login failed: \${loginRes.statusCode} \${loginRes.body}');
      // Proceed without token to see if it works or fails
    }
    
    String? token;
    try {
      token = jsonDecode(loginRes.body)['jwt'];
      print('Got token: \$token');
    } catch (e) {
      print('Could not parse token');
    }
    
    // 2. Fetch queue
    print('Fetching queue...');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer \$token',
    };
    
    final qRes = await http.get(
      Uri.parse('\$baseUrl/auth/queue'),
      headers: headers,
    );
    
    print('Queue status: \${qRes.statusCode}');
    print('Queue body: \${qRes.body}');
    
  } catch (e) {
    print('Error: \$e');
  }
}
