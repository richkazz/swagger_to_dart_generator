import 'dart:io';
import 'swagger_parser.dart';

class DartGenerator {
  final SwaggerData swaggerData;
  final String fileLocation;
  DartGenerator(this.swaggerData, this.fileLocation);

  void generate() {
    generateModels();
    generateService();
  }

  void generateModels() {
    final bufferModel = StringBuffer();
    final bufferEnum = StringBuffer();

    final components =
        swaggerData.components['schemas'] as Map<String, dynamic>;
    components.forEach((name, schema) {
      String fileName;
      if (schema.containsKey('enum')) {
        fileName = generateEnum(name, schema);
        bufferEnum.writeln('export \'$fileName\';');
      } else {
        fileName = generateModel(name, schema);
        bufferModel.writeln('export \'$fileName\';');
      }
    });
    final file = File('$fileLocation\\models\\models.dart');
    file.writeAsStringSync(bufferModel.toString());
    final fileEnum = File('$fileLocation\\enums\\enums.dart');
    fileEnum.writeAsStringSync(bufferEnum.toString());
  }

  bool isFieldTypeNull(dynamic fieldSchema) {
    late bool isNull;
    final fieldType = mapSwaggerTypeToDart(fieldSchema['type']);
    if (fieldType == 'int') {
      isNull = fieldSchema['format'] != 'int64';
    } else {
      isNull = fieldSchema['nullable'] == true;
    }
    return isNull;
  }

  String generateEnum(String name, Map<String, dynamic> schema) {
    final className = name.capitalize();
    final buffer = StringBuffer();
    buffer.writeln('enum $className {');
    buffer.writeln('}');
    final file = File('$fileLocation\\enums\\${name.snakeCase()}.dart');
    file.writeAsStringSync(buffer.toString());
    return '${name.snakeCase()}.dart';
  }

  String getFieldType(Map<String, dynamic> fieldSchema) {
    if (fieldSchema.containsKey('\$ref')) {
      return fieldSchema['\$ref'].split('/').last;
    } else {
      return mapSwaggerTypeToDart(fieldSchema['type']);
    }
  }

  String generateModel(String name, Map<String, dynamic> schema) {
    final className = name.capitalize();
    final fields = schema['properties'] as Map<String, dynamic>;

    final buffer = StringBuffer();
    buffer.writeln('import \'dart:convert\';');
    buffer.writeln();
    buffer.writeln('class $className {');

    // Define fields
    fields.forEach((fieldName, fieldSchema) {
      final fieldType = getFieldType(fieldSchema);
      final nullable = isFieldTypeNull(fieldSchema) ? '?' : '';
      buffer.writeln('  final $fieldType$nullable $fieldName;');
    });

    // Constructor
    buffer.writeln();
    buffer.writeln('  $className({');
    fields.forEach((fieldName, fieldSchema) {
      final isRequired = isFieldTypeNull(fieldSchema) ? '' : 'required ';
      buffer.writeln('    $isRequired this.$fieldName,');
    });
    buffer.writeln('  });');

    // fromMap factory constructor
    buffer.writeln();
    buffer.writeln('  factory $className.fromMap(Map<String, dynamic> map) {');
    buffer.writeln('    return $className(');
    fields.forEach((fieldName, fieldSchema) {
      final fieldType = getFieldType(fieldSchema);
      final nullable = isFieldTypeNull(fieldSchema) ? '?' : '';
      buffer.writeln(
          '      $fieldName: map[\'$fieldName\'] as $fieldType$nullable,');
    });
    buffer.writeln('    );');
    buffer.writeln('  }');

    // fromJson factory constructor
    buffer.writeln();
    buffer.writeln(
        '  factory $className.fromJson(String source) => $className.fromMap(json.decode(source) as Map<String, dynamic>);');

    // toMap method
    buffer.writeln();
    buffer.writeln('  Map<String, dynamic> toMap() {');
    buffer.writeln('    return {');
    fields.forEach((fieldName, fieldSchema) {
      buffer.writeln('      \'$fieldName\': $fieldName,');
    });
    buffer.writeln('    };');
    buffer.writeln('  }');

    // toJson method
    buffer.writeln();
    buffer.writeln('  String toJson() => json.encode(toMap());');

    // copyWith method
    buffer.writeln();
    buffer.writeln('  $className copyWith({');
    fields.forEach((fieldName, fieldSchema) {
      final fieldType = getFieldType(fieldSchema);
      buffer.writeln('    $fieldType? $fieldName,');
    });
    buffer.writeln('  }) {');
    buffer.writeln('    return $className(');
    fields.forEach((fieldName, fieldSchema) {
      buffer.writeln('      $fieldName: $fieldName ?? this.$fieldName,');
    });
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');

    final file = File('$fileLocation\\models\\${name.snakeCase()}.dart');
    file.writeAsStringSync(buffer.toString());

    return '${name.snakeCase()}.dart';
  }

  String mapSwaggerTypeToDart(String? type) {
    switch (type) {
      case 'string':
        return 'String';
      case 'integer':
        return 'int';
      case 'number':
        return 'double';
      case 'boolean':
        return 'bool';
      case 'array':
        return 'List'; // You might need to handle array of specific types
      default:
        return 'dynamic';
    }
  }

  void generateResultClass(StringBuffer buffer) {
    /*
    class Result<T, E> {
  T? data;
  E? errorData;
  bool isSuccess;

  Result({
    this.data,
    this.errorData,
    required this.isSuccess,
  });

  Result<T,E> copyWith({
    T? data,
    bool? isSuccess,
    E? errorData
  }) {
    return Result<T,E>(
      data: data ?? this.data,
      isSuccess: isSuccess ?? this.isSuccess,
      errorData: errorData ?? this.errorData
    );
  }
}
    */

    buffer.writeln('class Result<T, E> {');
    buffer.writeln('  T? data;');
    buffer.writeln('  E? errorData;');
    buffer.writeln('  bool isSuccess;');
    buffer.writeln();
    buffer.writeln('  Result({');
    buffer.writeln('    this.data,');
    buffer.writeln('    this.errorData,');
    buffer.writeln('    required this.isSuccess,');
    buffer.writeln('  });');
    buffer.writeln();
    buffer.writeln('  Result<T, E> copyWith({');
    buffer.writeln('    T? data,');
    buffer.writeln('    bool? isSuccess,');
    buffer.writeln('    E? errorData');
    buffer.writeln('  }) {');
    buffer.writeln('    return Result<T, E>(');
    buffer.writeln('      data: data ?? this.data,');
    buffer.writeln('      isSuccess: isSuccess ?? this.isSuccess,');
    buffer.writeln('      errorData: errorData ?? this.errorData');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void generateExceptionClass(StringBuffer buffer) {
    buffer.writeln('class UnAuthorizedException implements Exception {}');
  }

  void generateService() {
    final buffer = StringBuffer();
    buffer.writeln('import \'package:http/http.dart\' as http;');
    buffer.writeln('import \'models/models.dart\';');
    generateExceptionClass(buffer);
    generateResultClass(buffer);
    buffer.writeln('class ApiService {');
    buffer.writeln('  ApiService(this.baseUrl, {String? token}){');
    buffer.writeln('  if (token != null) {');
    buffer.writeln('      headers[\'Authorization\'] = \'Bearer \$token\';');
    buffer.writeln('  }');
    buffer.writeln('  }');
    buffer.writeln('  final String baseUrl;');
    buffer.writeln('  void updateToken(String token) {');
    buffer.writeln('      headers[\'Authorization\'] = \'Bearer \$token\';');
    buffer.writeln('  }');
    buffer.writeln('  void removeToken() {');
    buffer.writeln('      headers.remove(\'Authorization\');');
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  Map<String, String> headers = {');
    buffer.writeln('    \'Content-Type\': \'application/json\',');
    buffer.writeln('  };');
    final paths = swaggerData.paths;
    paths.forEach((path, methods) {
      methods.forEach((method, details) {
        generateServiceMethod(buffer, method, path, details);
      });
    });

    buffer.writeln('}');

    final file = File('$fileLocation\\api_service.dart');
    file.writeAsStringSync(buffer.toString());
  }

  void generateServiceMethod(StringBuffer buffer, String method, String path,
      Map<String, dynamic> details) {
    // Clean up the path to create a method name
    String methodName = path.replaceAll('/', '');
    methodName = methodName.replaceAll('-', '').capitalize();
    methodName = methodName[0].toLowerCase() + methodName.substring(1);
    final summary = details['summary'];
    final responses = details['responses'];
    final requestBody = details['requestBody'];

    // Determine the return type based on the response
    String returnType = 'void';
    String throwErrorType = '';
    String parameterType = '';
    bool isArray = false;
    String returnTypeWithoutList = '';
    if (responses.containsKey('200') && responses['200']['content'] != null) {
      final content = responses['200']['content'];
      if (content.containsKey('application/json')) {
        final schema = content['application/json']['schema'];
        if (schema != null && schema['type'] == 'array') {
          isArray = true;
          if (schema != null &&
              schema['items'] != null &&
              schema['items']['\$ref'] != null) {
            returnType = schema['items']['\$ref'].split('/').last;
            returnTypeWithoutList = returnType;
            returnType = 'List<$returnType>';
          }
        }
        if (schema != null && schema['\$ref'] != null) {
          returnType = schema['\$ref'].split('/').last;
        }
      }
    }

    if (requestBody != null && requestBody['content'] != null) {
      final content = requestBody['content'];
      if (content.containsKey('application/json')) {
        final schema = content['application/json']['schema'];
        if (schema != null && schema['\$ref'] != null) {
          parameterType = schema['\$ref'].split('/').last;
        }
      }
    }

    if (responses.containsKey('400') && responses['400']['content'] != null) {
      final content = responses['400']['content'];
      if (content.containsKey('application/problem+json')) {
        final schema = content['application/problem+json']['schema'];
        if (schema != null && schema['\$ref'] != null) {
          throwErrorType = schema['\$ref'].split('/').last;
        }
      }
    }

    if (responses.containsKey('401') && responses['401']['content'] != null) {
      final content = responses['401']['content'];
      if (content.containsKey('application/problem+json')) {
        final schema = content['application/problem+json']['schema'];
        if (schema != null && schema['\$ref'] != null) {
          throwErrorType = schema['\$ref'].split('/').last;
        }
      }
    }

    buffer.writeln('  // $summary');
    if (parameterType.isNotEmpty) {
      buffer.writeln(
          '  Future<${getReturnType(throwErrorType, returnType)}> $methodName($parameterType request) async {');
    } else {
      buffer.writeln(
          '  Future<${getReturnType(throwErrorType, returnType)}> $methodName() async {');
    }
    buffer.writeln('    try {');
    if (parameterType.isNotEmpty) {
      buffer.writeln(
          '      final response = await http.$method(Uri.parse(\'\$baseUrl$path\'),headers: headers,body:request.toJson());');
    } else {
      buffer.writeln(
          '      final response = await http.$method(Uri.parse(\'\$baseUrl$path\'),headers: headers);');
    }

    buffer.writeln('      switch (response.statusCode) {');
    for200(buffer, returnType, returnTypeWithoutList, throwErrorType, isArray);
    for401(buffer, returnType, returnTypeWithoutList, throwErrorType, isArray);
    for400(buffer, returnType, returnTypeWithoutList, throwErrorType, isArray);

    // Handle other responses
    buffer.writeln('        default:');
    buffer.writeln(
        '          throw Exception(\'Unexpected error: \${response.statusCode} \${response.body}\');');
    buffer.writeln('      }');
    buffer.writeln('    } catch (error, stacktrace) {');
    buffer.writeln('      print(\'Error: \$error\');');
    buffer.writeln('      print(\'Stacktrace: \$stacktrace\');');
    buffer.writeln('      rethrow;');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }

  void for401(StringBuffer buffer, String returnType,
      String returnTypeWithoutList, String throwErrorType, bool isArray) {
    buffer.writeln('        case 401:');
    buffer.writeln('          throw UnAuthorizedException();');
  }

  void for400(StringBuffer buffer, String returnType,
      String returnTypeWithoutList, String throwErrorType, bool isArray) {
    if (throwErrorType.isNotEmpty) {
      buffer.writeln('        case 400:');
      buffer.writeln(
          '          final result = $throwErrorType.fromJson(response.body);');
      buffer.writeln(
          '          return ${getReturnType(throwErrorType, returnType)}(errorData: result, isSuccess: true);');
    } else {
      buffer.writeln('        case 400:');
      buffer.writeln(
          '          throw Exception(\'Bad request: \${response.body}\');');
    }
  }

  void for200(StringBuffer buffer, String returnType,
      String returnTypeWithoutList, String throwErrorType, bool isArray) {
    // Handle 200 response
    if (returnType != 'void') {
      buffer.writeln('        case 200:');
      if (isArray) {
        buffer.writeln(
            '          final result = (response.body as List<dynamic>).map((e) => $returnTypeWithoutList.fromMap(e)).toList();');
      } else {
        buffer.writeln(
            '          final result = $returnType.fromJson(response.body);');
      }
      buffer.writeln(
          '          return ${getReturnType(throwErrorType, returnType)}(data: result, isSuccess: true);');
    } else {
      buffer.writeln('        case 200:');
      buffer.writeln(
          '          return ${getReturnType(throwErrorType, returnType)}(isSuccess: true);');
    }
  }

  String getReturnType(String errorType, String returnType) {
    if (returnType == 'void' && errorType.isNotEmpty) {
      return 'Result<Null,$errorType>';
    } else if (returnType == 'void' && errorType.isEmpty) {
      return 'Result<Null,Null>';
    } else if (returnType != 'void' && errorType.isEmpty) {
      return 'Result<$returnType,Null>';
    } else {
      return 'Result<$returnType,$errorType>';
    }
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
  String snakeCase() => replaceAllMapped(
          RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
      .substring(1);
}