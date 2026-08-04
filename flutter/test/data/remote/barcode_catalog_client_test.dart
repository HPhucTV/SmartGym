import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/remote/barcode_catalog_client.dart';

void main() {
  test('validates barcode before issuing a request', () async {
    var requested = false;
    final client = _client((options) async {
      requested = true;
      return _jsonResponse({}, 200);
    });

    await expectLater(client.lookup('abc'), throwsFormatException);
    expect(requested, isFalse);
  });

  test('uses the bounded read-only endpoint and parses a product', () async {
    final client = _client((options) async {
      expect(options.method, 'GET');
      expect(
        options.uri.toString(),
        'https://backend.test/api/barcodes/8930000000001',
      );
      return _jsonResponse({
        'dishName': 'Sữa chua',
        'totalCalories': 100,
        'proteinGrams': 4,
        'carbsGrams': 14,
        'fatGrams': 3,
        'fitnessScore': 5,
        'advice': 'Kiểm tra nhãn trước khi lưu.',
        'constituents': <Object?>[],
        'confidence': 0.9,
        'needsUserConfirmation': true,
      }, 200);
    });

    final result = await client.lookup('8930000000001');

    expect(result?.dishName, 'Sữa chua');
    expect(result?.needsUserConfirmation, isTrue);
  });

  test(
    'maps a missing product to null and hides other server errors',
    () async {
      final missing = _client((_) async => _jsonResponse({}, 404));
      expect(await missing.lookup('8930000000001'), isNull);

      final unavailable = _client(
        (_) async => _jsonResponse({'error': 'private-upstream-detail'}, 503),
      );
      await expectLater(
        unavailable.lookup('8930000000001'),
        throwsA(isA<BarcodeLookupException>()),
      );
    },
  );
}

DioBarcodeCatalogClient _client(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio()
    ..httpClientAdapter = _StubAdapter((options, _, __) => handler(options));
  return DioBarcodeCatalogClient(
    dio: dio,
    endpointProvider: () => 'https://backend.test',
  );
}

ResponseBody _jsonResponse(Object? body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _AdapterHandler =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    );

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final _AdapterHandler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
