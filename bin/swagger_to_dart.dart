import 'dart:io';

import 'package:swagger_to_dart/swagger_parser.dart';
import 'package:swagger_to_dart/generator.dart';

//dart compile exe bin/swagger_to_dart.dart

void main(List<String> arguments) async {
  stdout.write("Enter the Swagger URL:");
  //final swaggerUrl = stdin.readLineSync()!;
  final swaggerUrl = 'http://localhost:5047/swagger/v1/swagger.json';
  SwaggerParser parser = SwaggerParser(swaggerUrl);
  final swaggerData = await parser.parseSwaggerJson();

  String filePathToGenerate = 'C:\\Projects\\dart\\swagger_to_dart\\lib';
  //final filePathToGenerate = await getDirectoryPathToGenerateFiles();
  await Directory('$filePathToGenerate\\generated').create();
  await Directory('$filePathToGenerate\\generated\\models').create();
  await Directory('$filePathToGenerate\\generated\\enums').create();

  DartGenerator generator =
      DartGenerator(swaggerData, '$filePathToGenerate\\generated');
  String quitReGeneration = 'y';
  generator.generate();
  while (quitReGeneration == 'y') {
    stdout.write('Do you want to re-generate files? (y/n):');
    quitReGeneration = stdin.readLineSync()!;
    if (quitReGeneration == 'y') {
      final swaggerData = await parser.parseSwaggerJson();
      generator = DartGenerator(swaggerData, '$filePathToGenerate\\generated');
      generator.generate();
    }
  }

  print('Dart files generated successfully.');
  stdout.write('Press any key to exit...');
  stdin.readLineSync();
  exit(0);
}

Future<String> getDirectoryPathToGenerateFiles() async {
  bool dosePathExist;
  stdout.write("Enter the path to generate dart files:");
  do {
    final filePathToGenerate = stdin.readLineSync()!;
    if (filePathToGenerate == 'q') {
      exit(0);
    }
    dosePathExist = await Directory(filePathToGenerate).exists();
    if (dosePathExist) {
      return filePathToGenerate;
    }
    stdout.write(
        'The path does not exist. Please enter a valid path, or enter q to quit:');
  } while (!dosePathExist);
  return '';
}
