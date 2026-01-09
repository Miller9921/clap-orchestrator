# Infrastructure Layer Implementation Instructions

## Overview
Create Infrastructure layer with DTOs, Adapters, API clients, and Repository implementations.

## Repository
**Target:** Miller9921/flutter-infrastructure

## Structure
```
/lib/
  └── [module]/
      ├── dtos/
      │   ├── [entity]_dto.dart
      │   └── [entity]_dto.g.dart (generated)
      ├── adapters/
      │   └── [entity]_adapter.dart
      ├── apis/
      │   └── [entity]_api.dart
      ├── repositories/
      │   └── [entity]_repository_impl.dart
      └── exports.dart
```

## 1. Creating DTOs

### Requirements
- Use @JsonSerializable() annotation
- Include part directive for generated code
- Nullable fields (String?, int?, etc.)
- fromJson factory constructor
- toJson method

### DTO Template

```dart
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

  PaymentDto({
    this.id,
    this.amount,
    this.currency,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.userId,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDtoToJson(this);
}
```

### Key Points
- All fields should be nullable
- Use @JsonKey for field name mapping (snake_case → camelCase)
- Part directive must match filename with .g.dart
- Run `flutter pub run build_runner build` to generate

## 2. Creating Adapters

### Requirements
- Extend ModelAdapter<Model, Dto, void>
- Implement toModel (DTO → Model)
- Implement fromModel (Model → DTO)
- Handle nullable fields
- Convert date formats

### Adapter Template

```dart
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
    );
  }
}
```

### Key Points
- Import domain models from domain_clap package
- Handle null safety with ?? operators
- Convert DateTime to/from ISO8601 strings
- Provide sensible defaults for required fields
- No business logic in adapters (pure conversion)

## 3. Creating API Clients

### Requirements
- Inject HttpClientApi dependency
- Use Uri.https for URL construction
- Use HttpClientApi methods (getRequestWithToken, postRequestWithToken, etc.)
- Use ExceptionHandlerResponse.responseDataSourceTemplError for errors
- Define TYPE_RETURN_METHOD_* constants

### API Template

```dart
import 'package:infrastructure_clap/core/error/exception_handler_response.dart';
import 'package:infrastructure_clap/core/network/http_client_api.dart';

import '../dtos/payment_dto.dart';

class PaymentApi {
  final HttpClientApi _httpClient;

  // Constants for return type methods
  static const String TYPE_RETURN_METHOD_GET = 'get';
  static const String TYPE_RETURN_METHOD_POST = 'post';
  static const String TYPE_RETURN_METHOD_PUT = 'put';
  static const String TYPE_RETURN_METHOD_DELETE = 'delete';

  PaymentApi(this._httpClient);

  Future<PaymentDto> getPayment(String id) async {
    try {
      final uri = Uri.https(
        'api.example.com',
        '/v1/payments/$id',
      );

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

  Future<List<PaymentDto>> getAllPayments() async {
    try {
      final uri = Uri.https(
        'api.example.com',
        '/v1/payments',
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
      final uri = Uri.https(
        'api.example.com',
        '/v1/payments',
      );

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

  Future<PaymentDto> updatePayment(String id, PaymentDto dto) async {
    try {
      final uri = Uri.https(
        'api.example.com',
        '/v1/payments/$id',
      );

      final response = await _httpClient.putRequestWithToken(
        uri: uri,
        body: dto.toJson(),
        typeReturnMethod: TYPE_RETURN_METHOD_PUT,
      );

      return PaymentDto.fromJson(response);
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_PUT,
      );
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      final uri = Uri.https(
        'api.example.com',
        '/v1/payments/$id',
      );

      await _httpClient.deleteRequestWithToken(
        uri: uri,
        typeReturnMethod: TYPE_RETURN_METHOD_DELETE,
      );
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_DELETE,
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
}
```

### Key Points
- Always wrap in try/catch
- Use ExceptionHandlerResponse for consistent error handling
- Use Uri.https with proper paths and query parameters
- Use appropriate HttpClientApi methods based on HTTP verb
- Return DTOs, not Models

## 4. Creating Repository Implementations

### Requirements
- Implement Domain repository interface
- Inject NetworkVerify, API, Adapter dependencies
- Check network connectivity before operations
- Use API for data operations
- Use Adapter for DTO ↔ Model conversion

### Repository Implementation Template

```dart
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
      // Return null if not found
      return null;
    }
  }

  @override
  Future<PaymentModel> createPayment(PaymentModel payment) async {
    await _networkVerify.verifyConnection();

    final dto = _paymentAdapter.fromModel(payment);
    final resultDto = await _paymentApi.createPayment(dto);
    return _paymentAdapter.toModel(resultDto);
  }

  @override
  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    await _networkVerify.verifyConnection();

    final dto = _paymentAdapter.fromModel(payment);
    final resultDto = await _paymentApi.updatePayment(payment.id, dto);
    return _paymentAdapter.toModel(resultDto);
  }

  @override
  Future<void> deletePayment(String id) async {
    await _networkVerify.verifyConnection();

    await _paymentApi.deletePayment(id);
  }

  @override
  Future<List<PaymentModel>> getPaymentsByStatus(String status) async {
    await _networkVerify.verifyConnection();

    final dtos = await _paymentApi.getAllPayments();
    return dtos
        .where((dto) => dto.status == status)
        .map((dto) => _paymentAdapter.toModel(dto))
        .toList();
  }

  @override
  Future<List<PaymentModel>> getPaymentsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await _networkVerify.verifyConnection();

    final dtos = await _paymentApi.getAllPayments();
    return dtos
        .where((dto) {
          if (dto.createdAt == null) return false;
          final date = DateTime.parse(dto.createdAt!);
          return date.isAfter(startDate) && date.isBefore(endDate);
        })
        .map((dto) => _paymentAdapter.toModel(dto))
        .toList();
  }
}
```

### Key Points
- Always check network first with _networkVerify.verifyConnection()
- Convert DTO to Model when receiving data
- Convert Model to DTO when sending data
- Let exceptions propagate (don't catch unless specific handling needed)
- For getById, return null on error (item not found)

## 5. Kiwi DI Registration

### Registration Template

```dart
// In your DI setup file (e.g., injection_container.dart)

import 'package:kiwi/kiwi.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

import 'adapters/payment_adapter.dart';
import 'apis/payment_api.dart';
import 'repositories/payment_repository_impl.dart';

void setupPaymentModule() {
  final container = KiwiContainer();

  // Register API
  container.registerFactory((c) => PaymentApi(c.resolve()));

  // Register Adapter
  container.registerFactory((c) => PaymentAdapter());

  // Register Repository
  container.registerFactory<IPaymentRepository>(
    (c) => PaymentRepositoryImpl(
      c.resolve(),
      c.resolve(),
      c.resolve(),
    ),
  );
}
```

### Key Points
- Register in order: API → Adapter → Repository
- Use registerFactory for stateless instances
- Register repository with interface type
- Resolve dependencies with c.resolve()

## 6. Creating Exports File

### exports.dart

```dart
// DTOs
export 'dtos/payment_dto.dart';

// Adapters
export 'adapters/payment_adapter.dart';

// APIs
export 'apis/payment_api.dart';

// Repositories
export 'repositories/payment_repository_impl.dart';
```

## Important Rules

### ✅ DO
- Use @JsonSerializable for all DTOs
- Extend ModelAdapter for adapters
- Use HttpClientApi methods in APIs
- Check network before repository operations
- Use ExceptionHandlerResponse for errors
- Register all components in Kiwi

### ❌ DON'T
- DON'T put business logic in repositories
- DON'T skip network verification
- DON'T catch exceptions without rethrowing (unless specific handling)
- DON'T use Models in API layer (use DTOs)
- DON'T make direct HTTP calls (use HttpClientApi)

## Naming Conventions

- **DTOs:** `[Entity]Dto` (e.g., PaymentDto, UserDto)
- **Adapters:** `[Entity]Adapter` (e.g., PaymentAdapter, UserAdapter)
- **APIs:** `[Entity]Api` (e.g., PaymentApi, UserApi)
- **Repositories:** `[Entity]RepositoryImpl` (e.g., PaymentRepositoryImpl)
- **Files:** snake_case (e.g., payment_dto.dart, payment_adapter.dart)

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

## Build Runner

Generate JSON serialization code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Complete Example: User Module

### user_dto.dart
```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String? id;
  final String? email;
  final String? name;
  final String? avatar;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  UserDto({
    this.id,
    this.email,
    this.name,
    this.avatar,
    this.createdAt,
    this.updatedAt,
    this.isActive,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
```

### user_adapter.dart
```dart
import 'package:domain_clap/usermodule/exports.dart';
import 'package:infrastructure_clap/core/adapter/model_adapter.dart';

import '../dtos/user_dto.dart';

class UserAdapter extends ModelAdapter<UserModel, UserDto, void> {
  @override
  UserModel toModel(UserDto dto) {
    return UserModel(
      id: dto.id ?? '',
      email: dto.email ?? '',
      name: dto.name ?? '',
      avatar: dto.avatar,
      createdAt: dto.createdAt != null
          ? DateTime.parse(dto.createdAt!)
          : DateTime.now(),
      updatedAt: dto.updatedAt != null
          ? DateTime.parse(dto.updatedAt!)
          : null,
      isActive: dto.isActive ?? true,
    );
  }

  @override
  UserDto fromModel(UserModel model) {
    return UserDto(
      id: model.id,
      email: model.email,
      name: model.name,
      avatar: model.avatar,
      createdAt: model.createdAt.toIso8601String(),
      updatedAt: model.updatedAt?.toIso8601String(),
      isActive: model.isActive,
    );
  }
}
```

### user_api.dart
```dart
import 'package:infrastructure_clap/core/error/exception_handler_response.dart';
import 'package:infrastructure_clap/core/network/http_client_api.dart';

import '../dtos/user_dto.dart';

class UserApi {
  final HttpClientApi _httpClient;

  static const String TYPE_RETURN_METHOD_GET = 'get';
  static const String TYPE_RETURN_METHOD_POST = 'post';
  static const String TYPE_RETURN_METHOD_PUT = 'put';
  static const String TYPE_RETURN_METHOD_DELETE = 'delete';

  UserApi(this._httpClient);

  Future<UserDto> getUser(String id) async {
    try {
      final uri = Uri.https('api.example.com', '/v1/users/$id');
      final response = await _httpClient.getRequestWithToken(
        uri: uri,
        typeReturnMethod: TYPE_RETURN_METHOD_GET,
      );
      return UserDto.fromJson(response);
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_GET,
      );
    }
  }

  Future<List<UserDto>> getAllUsers() async {
    try {
      final uri = Uri.https('api.example.com', '/v1/users');
      final response = await _httpClient.getRequestWithToken(
        uri: uri,
        typeReturnMethod: TYPE_RETURN_METHOD_GET,
      );
      return (response as List)
          .map((json) => UserDto.fromJson(json))
          .toList();
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_GET,
      );
    }
  }

  Future<UserDto> createUser(UserDto dto) async {
    try {
      final uri = Uri.https('api.example.com', '/v1/users');
      final response = await _httpClient.postRequestWithToken(
        uri: uri,
        body: dto.toJson(),
        typeReturnMethod: TYPE_RETURN_METHOD_POST,
      );
      return UserDto.fromJson(response);
    } catch (e) {
      throw ExceptionHandlerResponse.responseDataSourceTemplError(
        e,
        TYPE_RETURN_METHOD_POST,
      );
    }
  }
}
```

### user_repository_impl.dart
```dart
import 'package:domain_clap/usermodule/exports.dart';
import 'package:infrastructure_clap/core/network/network_verify.dart';

import '../adapters/user_adapter.dart';
import '../apis/user_api.dart';

class UserRepositoryImpl implements IUserRepository {
  final NetworkVerify _networkVerify;
  final UserApi _userApi;
  final UserAdapter _userAdapter;

  UserRepositoryImpl(
    this._networkVerify,
    this._userApi,
    this._userAdapter,
  );

  @override
  Future<UserModel?> getUserById(String id) async {
    try {
      await _networkVerify.verifyConnection();
      final dto = await _userApi.getUser(id);
      return _userAdapter.toModel(dto);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    await _networkVerify.verifyConnection();
    final dtos = await _userApi.getAllUsers();
    return dtos.map((dto) => _userAdapter.toModel(dto)).toList();
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    await _networkVerify.verifyConnection();
    final dto = _userAdapter.fromModel(user);
    final resultDto = await _userApi.createUser(dto);
    return _userAdapter.toModel(resultDto);
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await _networkVerify.verifyConnection();
    final dto = _userAdapter.fromModel(user);
    final resultDto = await _userApi.updateUser(user.id, dto);
    return _userAdapter.toModel(resultDto);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _networkVerify.verifyConnection();
    await _userApi.deleteUser(id);
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    await _networkVerify.verifyConnection();
    final dtos = await _userApi.searchUsers(query);
    return dtos.map((dto) => _userAdapter.toModel(dto)).toList();
  }
}
```

---

**Follow these patterns exactly for consistent Infrastructure layer implementation across the CLAP architecture.**
