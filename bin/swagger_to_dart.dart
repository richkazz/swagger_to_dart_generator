import 'dart:io';

import 'package:swagger_to_dart/swagger_parser.dart';
import 'package:swagger_to_dart/generator.dart';

void main(List<String> arguments) async {
  stdout.write("Enter the Swagger URL:");
  //final swaggerUrl = stdin.readLineSync()!;
  final swaggerUrl = 'http://localhost:5047/swagger/v1/swagger.json';
  SwaggerParser parser;
  try {
    parser = SwaggerParser(swaggerUrl);
  } catch (e) {
    stdout.writeln(
        'Error while parsing Swagger JSON, might be invalid URL, or network error.');
    stdout.writeln(e);
    exit(1);
  }
  final swaggerData = await parser.parseSwaggerJson();
  stdout.write("Enter the path to generate dart files:");
  String filePathToGenerate = 'C:\\Projects\\dart\\swagger_to_dart\\lib';
  //String filePathToGenerate = stdin.readLineSync()!;
  bool dosePathExist = await Directory(filePathToGenerate).exists();
  while (!dosePathExist) {
    stdout.write(
        'The path does not exist. Please enter a valid path, or enter q to quit:');
    filePathToGenerate = stdin.readLineSync()!;
    if (filePathToGenerate == 'q') {
      exit(0);
    }
    dosePathExist = await Directory(filePathToGenerate).exists();
  }
  await Directory('$filePathToGenerate\\generated').create();
  await Directory('$filePathToGenerate\\generated\\models').create();
  await Directory('$filePathToGenerate\\generated\\enums').create();

  final generator =
      DartGenerator(swaggerData, '$filePathToGenerate\\generated');
  generator.generate();

  print('Dart files generated successfully.');
  stdout.write('Press any key to exit...');
  stdin.readLineSync();
  exit(0);
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
