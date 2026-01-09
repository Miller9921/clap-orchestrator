# Domain Layer Implementation Instructions

## Overview
Create Domain layer components following clean architecture principles with Equatable models, service orchestration, and repository interfaces.

## Repository
**Target:** Miller9921/flutter-domain

## Structure
```
/lib/
  └── [module]module/
      ├── entities/
      │   ├── [entity1]_model.dart
      │   └── [entity2]_model.dart
      ├── services/
      │   └── [service]_service.dart
      ├── repositories/
      │   └── i_[entity]_repository.dart
      └── exports.dart
```

## 1. Creating Entities (Models)

### Requirements
- Extend Equatable
- Use const constructor
- All fields must be final
- Implement copyWith method
- Override props getter

### Entity Template

```dart
import 'package:equatable/equatable.dart';

class PaymentModel extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;

  const PaymentModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
  });

  PaymentModel copyWith({
    String? id,
    double? amount,
    String? currency,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        status,
        createdAt,
        updatedAt,
        userId,
      ];
}
```

### Key Points
- Use descriptive property names
- Include nullable fields with `?`
- createdAt should be required DateTime
- updatedAt should be optional DateTime?
- Always include id as String

## 2. Creating Services

### Requirements
- Orchestrate business logic
- Depend on repository interfaces (injected via constructor)
- Return Future<T> directly (NO Either, NO Failures)
- Use try/catch for error handling
- Keep business logic centralized

### Service Template

```dart
import '../entities/payment_model.dart';
import '../repositories/i_payment_repository.dart';

class PaymentService {
  final IPaymentRepository _paymentRepository;

  PaymentService(this._paymentRepository);

  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    try {
      final payments = await _paymentRepository.getPaymentsByUserId(userId);
      // Apply business logic
      return payments.where((p) => p.status != 'cancelled').toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentModel> createPayment({
    required String userId,
    required double amount,
    required String currency,
    required String paymentMethodId,
  }) async {
    try {
      // Business validation
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      final payment = PaymentModel(
        id: '', // Will be assigned by backend
        amount: amount,
        currency: currency,
        status: 'pending',
        createdAt: DateTime.now(),
        userId: userId,
      );

      return await _paymentRepository.createPayment(payment);
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      return await _paymentRepository.getPaymentById(paymentId);
    } catch (e) {
      rethrow;
    }
  }

  Future<double> calculateTotalPaid(String userId) async {
    try {
      final payments = await getPaymentHistory(userId);
      return payments
          .where((p) => p.status == 'completed')
          .fold(0.0, (sum, payment) => sum + payment.amount);
    } catch (e) {
      rethrow;
    }
  }
}
```

### Key Points
- Services orchestrate multiple repository calls
- Apply business rules and validations
- Transform and aggregate data
- NO direct API calls (use repositories)
- Simple error handling with try/catch

## 3. Creating Repository Interfaces

### Requirements
- Abstract class (interface)
- All methods return Future<T>
- NO Either<L, R> types
- NO Failure classes
- Clear method names

### Repository Interface Template

```dart
import '../entities/payment_model.dart';

abstract class IPaymentRepository {
  Future<List<PaymentModel>> getPaymentsByUserId(String userId);
  
  Future<PaymentModel?> getPaymentById(String id);
  
  Future<PaymentModel> createPayment(PaymentModel payment);
  
  Future<PaymentModel> updatePayment(PaymentModel payment);
  
  Future<void> deletePayment(String id);
  
  Future<List<PaymentModel>> getPaymentsByStatus(String status);
  
  Future<List<PaymentModel>> getPaymentsInDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
```

### Key Points
- Use descriptive method names
- Return nullable types when item might not exist (getById returns T?)
- Return void for delete operations
- Group related operations
- Think about common query patterns

## 4. Creating Exports File

### exports.dart

```dart
// Entities
export 'entities/payment_model.dart';
export 'entities/payment_method_model.dart';

// Services
export 'services/payment_service.dart';

// Repositories
export 'repositories/i_payment_repository.dart';
```

### Key Points
- One export file per module
- Organized by type (entities, services, repositories)
- Makes importing easier for other layers
- Keep alphabetically sorted within sections

## Important Rules

### ✅ DO
- Use Equatable for all models
- Use const constructors
- Implement copyWith for immutability
- Return Future<T> directly
- Keep business logic in services
- Use descriptive names
- Add comments for complex logic

### ❌ DON'T
- DON'T use Either<Failure, T>
- DON'T create Failure classes
- DON'T use Value Objects
- DON'T put business logic in repositories
- DON'T make API calls directly
- DON'T use mutable fields (no late, no var)
- DON'T skip copyWith method

## Naming Conventions

- **Models:** `[Entity]Model` (e.g., PaymentModel, UserModel)
- **Services:** `[Feature]Service` (e.g., PaymentService, AuthService)
- **Repositories:** `I[Entity]Repository` (e.g., IPaymentRepository, IUserRepository)
- **Files:** snake_case (e.g., payment_model.dart, payment_service.dart)
- **Directories:** lowercase (e.g., entities, services, repositories)

## Testing Considerations

- Models should be testable with Equatable
- Services should be unit testable with mocked repositories
- Repositories are interfaces, tested via implementations

## Dependencies

```yaml
dependencies:
  equatable: ^2.0.5
```

## Complete Example: User Profile Module

### user_model.dart
```dart
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatar,
        createdAt,
        updatedAt,
        isActive,
      ];
}
```

### i_user_repository.dart
```dart
import '../entities/user_model.dart';

abstract class IUserRepository {
  Future<UserModel?> getUserById(String id);
  Future<List<UserModel>> getAllUsers();
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<List<UserModel>> searchUsers(String query);
}
```

### user_service.dart
```dart
import '../entities/user_model.dart';
import '../repositories/i_user_repository.dart';

class UserService {
  final IUserRepository _userRepository;

  UserService(this._userRepository);

  Future<List<UserModel>> getActiveUsers() async {
    try {
      final users = await _userRepository.getAllUsers();
      return users.where((user) => user.isActive).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> createUser({
    required String email,
    required String name,
    String? avatar,
  }) async {
    try {
      // Validation
      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      final user = UserModel(
        id: '',
        email: email,
        name: name,
        avatar: avatar,
        createdAt: DateTime.now(),
        isActive: true,
      );

      return await _userRepository.createUser(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      rethrow;
    }
  }
}
```

---

**Follow these patterns exactly for consistent Domain layer implementation across the CLAP architecture.**
