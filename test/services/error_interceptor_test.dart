import 'dart:async';
import 'dart:typed_data';

import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adapter falso que devolve uma resposta com status arbitrário.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.status, this.body = ''});

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter que lança DioException com tipo específico.
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.type);
  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(requestOptions: options, type: type);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Dio buildDio(HttpClientAdapter adapter) {
    return Dio(BaseOptions(baseUrl: 'http://test/'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ArchbaseErrorInterceptor());
  }

  Future<ApiException> captureError(Dio dio) async {
    try {
      await dio.get<dynamic>('/x');
      fail('Esperava DioException');
    } on DioException catch (err) {
      expect(err.error, isA<ApiException>());
      return err.error as ApiException;
    }
  }

  group('ArchbaseErrorInterceptor', () {
    test('500 sem corpo cai em mensagem padrão', () async {
      final dio = buildDio(_FakeAdapter(status: 500));
      final api = await captureError(dio);
      expect(api.statusCode, 500);
      expect(api.message.toLowerCase(), contains('servidor'));
    });

    test('400 com {message} usa a mensagem do backend', () async {
      final dio = buildDio(
        _FakeAdapter(status: 400, body: '{"message":"CPF inválido"}'),
      );
      final api = await captureError(dio);
      expect(api.statusCode, 400);
      expect(api.message, 'CPF inválido');
    });

    test('422 com errors[] vira fieldErrors', () async {
      final dio = buildDio(
        _FakeAdapter(
          status: 422,
          body:
              '{"message":"Validação","errors":[{"field":"cpf","message":"x"},{"propertyPath":"email","message":"y"}]}',
        ),
      );
      final api = await captureError(dio);
      expect(api.fieldErrors, hasLength(2));
      expect(api.fieldErrors.first.field, 'cpf');
      expect(api.fieldErrors.last.field, 'email');
    });

    test('connectionError vira mensagem amigável', () async {
      final dio = buildDio(_ThrowingAdapter(DioExceptionType.connectionError));
      final api = await captureError(dio);
      expect(api.statusCode, isNull);
      expect(api.message.toLowerCase(), contains('conexão'));
    });

    test('connectionTimeout vira mensagem genérica', () async {
      final dio =
          buildDio(_ThrowingAdapter(DioExceptionType.connectionTimeout));
      final api = await captureError(dio);
      expect(api.message.toLowerCase(), contains('tempo'));
    });

    test('404 cai em "não encontrado"', () async {
      final dio = buildDio(_FakeAdapter(status: 404));
      final api = await captureError(dio);
      expect(api.statusCode, 404);
      expect(api.message.toLowerCase(), contains('não encontrado'));
    });
  });
}
