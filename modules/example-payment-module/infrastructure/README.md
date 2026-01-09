# Infrastructure Layer - Payment Processing Module

This directory contains documentation for the Infrastructure layer implementation patterns.

## Structure

```
infrastructure/
├── dtos/
│   ├── payment_dto.dart
│   ├── payment_dto.g.dart (generated)
│   └── payment_method_dto.dart
├── adapters/
│   ├── payment_adapter.dart
│   └── payment_method_adapter.dart
├── apis/
│   └── payment_api.dart
├── repositories/
│   └── payment_repository_impl.dart
└── exports.dart
```

## Implementation Patterns

### DTOs (Data Transfer Objects)

```dart
// payment_dto.dart
import 'package:json_annotation/json_annotation.dart';

part 'payment_dto.g.dart';

@JsonSerializable()
class PaymentDto {
  final String? id;
  final double? amount;
  final String? currency;
  final String? status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'payment_method_id')
  final String? paymentMethodId;
  final String? description;

  PaymentDto({...});

  factory PaymentDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDtoToJson(this);
}
```

**Key Points:**
- All fields nullable
- @JsonKey for snake_case mapping
- part directive for generated code
- Run: `flutter pub run build_runner build`

### Adapters

```dart
// payment_adapter.dart
import 'package:domain_clap/paymentmodule/exports.dart';
import 'package:infrastructure_clap/core/adapter/model_adapter.dart';
import '../dtos/payment_dto.dart';

class PaymentAdapter extends ModelAdapter<PaymentModel, PaymentDto, void> {
  @override
  PaymentModel toModel(PaymentDto dto) {
    return PaymentModel(
      id: dto.id ?? '',
      amount: dto.amount ?? 0.0,
      currency: dto.currency ?? 'USD',
      status: dto.status ?? 'unknown',
      createdAt: dto.createdAt != null
          ? DateTime.parse(dto.createdAt!)
          : DateTime.now(),
      updatedAt: dto.updatedAt != null
          ? DateTime.parse(dto.updatedAt!)
          : null,
      userId: dto.userId ?? '',
      paymentMethodId: dto.paymentMethodId ?? '',
      description: dto.description,
    );
  }

  @override
  PaymentDto fromModel(PaymentModel model) {
    return PaymentDto(
      id: model.id,
      amount: model.amount,
      currency: model.currency,
      status: model.status,
      createdAt: model.createdAt.toIso8601String(),
      updatedAt: model.updatedAt?.toIso8601String(),
      userId: model.userId,
      paymentMethodId: model.paymentMethodId,
      description: model.description,
    );
  }
}
```

**Key Points:**
- Extends ModelAdapter<Model, Dto, void>
- toModel: DTO → Model with null handling
- fromModel: Model → DTO with serialization
- DateTime conversion (ISO8601 strings)

### API Clients

```dart
// payment_api.dart
import 'package:infrastructure_clap/core/error/exception_handler_response.dart';
import 'package:infrastructure_clap/core/network/http_client_api.dart';
import '../dtos/payment_dto.dart';

class PaymentApi {
  final HttpClientApi _httpClient;

  static const String TYPE_RETURN_METHOD_GET = 'get';
  static const String TYPE_RETURN_METHOD_POST = 'post';
  static const String TYPE_RETURN_METHOD_PUT = 'put';
  static const String TYPE_RETURN_METHOD_DELETE = 'delete';

  PaymentApi(this._httpClient);

  Future<PaymentDto> getPayment(String id) async {
    try {
      final uri = Uri.https('api.example.com', '/v1/payments/$id');
      final response = await _httpClient.getRequestWithToken(
        uri: uri,
        typeReturnMethod: TYPE_RETURN_METHOD_GET,
      );
      return PaymentDto.fromJson(response);
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_GET,
      );
    }
  }

  Future<List<PaymentDto>> getPaymentsByUserId(String userId) async {
    try {
      final uri = Uri.https(
        'api.example.com',
        '/v1/payments',
        {'user_id': userId},
      );
      final response = await _httpClient.getRequestWithToken(
        uri: uri,
        typeReturnMethod: TYPE_RETURN_METHOD_GET,
      );
      return (response as List)
          .map((json) => PaymentDto.fromJson(json))
          .toList();
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_GET,
      );
    }
  }

  Future<PaymentDto> createPayment(PaymentDto dto) async {
    try {
      final uri = Uri.https('api.example.com', '/v1/payments');
      final response = await _httpClient.postRequestWithToken(
        uri: uri,
        body: dto.toJson(),
        typeReturnMethod: TYPE_RETURN_METHOD_POST,
      );
      return PaymentDto.fromJson(response);
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_POST,
      );
    }
  }
}
```

**Key Points:**
- Uri.https for URL construction
- HttpClientApi methods (getRequestWithToken, etc.)
- ExceptionHandlerResponse for errors
- TYPE_RETURN_METHOD_* constants

### Repository Implementation

```dart
// payment_repository_impl.dart
import 'package:domain_clap/paymentmodule/exports.dart';
import 'package:infrastructure_clap/core/network/network_verify.dart';
import '../adapters/payment_adapter.dart';
import '../apis/payment_api.dart';

class PaymentRepositoryImpl implements IPaymentRepository {
  final NetworkVerify _networkVerify;
  final PaymentApi _paymentApi;
  final PaymentAdapter _paymentAdapter;

  PaymentRepositoryImpl(
    this._networkVerify,
    this._paymentApi,
    this._paymentAdapter,
  );

  @override
  Future<List<PaymentModel>> getPaymentsByUserId(String userId) async {
    await _networkVerify.verifyConnection();
    final dtos = await _paymentApi.getPaymentsByUserId(userId);
    return dtos.map((dto) => _paymentAdapter.toModel(dto)).toList();
  }

  @override
  Future<PaymentModel?> getPaymentById(String id) async {
    try {
      await _networkVerify.verifyConnection();
      final dto = await _paymentApi.getPayment(id);
      return _paymentAdapter.toModel(dto);
    } catch (e) {
      return null; // Return null if not found
    }
  }

  @override
  Future<PaymentModel> createPayment(PaymentModel payment) async {
    await _networkVerify.verifyConnection();
    final dto = _paymentAdapter.fromModel(payment);
    final resultDto = await _paymentApi.createPayment(dto);
    return _paymentAdapter.toModel(resultDto);
  }
}
```

**Key Points:**
- Implements domain repository interface
- NetworkVerify before operations
- API for data operations
- Adapter for conversions
- Return null for getById when not found

### Kiwi DI Setup

```dart
// In infrastructure DI file
void _setupPaymentModule(KiwiContainer container) {
  // API
  container.registerFactory((c) => PaymentApi(c.resolve()));

  // Adapters
  container.registerFactory((c) => PaymentAdapter());
  container.registerFactory((c) => PaymentMethodAdapter());

  // Repository
  container.registerFactory<IPaymentRepository>(
    (c) => PaymentRepositoryImpl(
      c.resolve(),
      c.resolve(),
      c.resolve(),
    ),
  );
}
```

## Dependencies

```yaml
dependencies:
  json_annotation: ^4.8.1
  domain_clap:
    path: ../flutter-domain
  infrastructure_clap:
    path: ../flutter-infrastructure-core

dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
```

## Build Command

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Target Repository

Place these files in `Miller9921/flutter-infrastructure`:
```
/lib/payment/
  ├── dtos/
  ├── adapters/
  ├── apis/
  ├── repositories/
  └── exports.dart
```
