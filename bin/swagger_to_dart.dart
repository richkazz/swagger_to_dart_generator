import 'package:swagger_to_dart/swagger_parser.dart';
import 'package:swagger_to_dart/generator.dart';

void main(List<String> arguments) async {
  final swaggerUrl = 'http://localhost:5198/swagger/v1/swagger.json';
  final parser = SwaggerParser(swaggerUrl);
  final swaggerData = await parser.parseSwaggerJson();

  final generator = DartGenerator(swaggerData);
  generator.generate();

  print('Dart files generated successfully.');
}
// import 'package:swagger_to_dart/api_service.dart';
// import 'package:swagger_to_dart/models/models.dart';

// void main(List<String> arguments) async {
//   final apiService = ApiService('http://localhost:5198');
//   final result = await apiService.register(RegisterRequest(
//     email: 'uqB0j@example.com',
//     password: '12ADmi+-',
//   ));
//   print(result);
//   try {
//     final loginResult = await apiService.login(LoginRequest(
//       email: 'uqB0j@example.com',
//       password: '12ADmi+-',
//     ));
//     apiService.updateToken(loginResult.data!.accessToken!);
//     final weatherForecast = await apiService.weatherforecast();
//     print(weatherForecast);
//     print(loginResult);
//   } catch (e) {
//     print(e);
//   }
// }
