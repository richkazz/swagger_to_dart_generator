import 'dart:convert';
import 'package:http/http.dart' as http;

class SwaggerParser {
  final String swaggerUrl;

  SwaggerParser(this.swaggerUrl);

  Future<Map<String, dynamic>> fetchSwaggerJson() async {
    final response = await http.get(Uri.parse(swaggerUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load Swagger JSON');
    }
  }

  Future<SwaggerData> parseSwaggerJson() async {
    final json = await fetchSwaggerJson();
    return SwaggerData.fromJson(json);
  }
}

class SwaggerData {
  final Map<String, dynamic> info;
  final Map<String, dynamic> paths;
  final Map<String, dynamic> components;

  SwaggerData(
      {required this.info, required this.paths, required this.components});

  factory SwaggerData.fromJson(Map<String, dynamic> json) {
    return SwaggerData(
      info: json['info'] as Map<String, dynamic>,
      paths: json['paths'] as Map<String, dynamic>,
      components: json['components'] as Map<String, dynamic>,
    );
  }
}
