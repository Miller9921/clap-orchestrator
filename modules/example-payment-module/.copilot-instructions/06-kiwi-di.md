# Kiwi Dependency Injection Setup Instructions

## Overview
Complete guide for setting up Kiwi DI across all layers of the CLAP architecture.

## Kiwi Registration Pattern

Kiwi uses a container to register and resolve dependencies. The pattern is:
1. Register dependencies in order (dependencies first, dependents later)
2. Use `registerFactory` for stateless instances
3. Use `registerSingleton` for shared state (rarely needed)
4. Resolve dependencies with `container.resolve<Type>()`

## Dependency Chain

```
┌─────────────────────────────────────────┐
│         Frontend Applications           │
│    (Admin App / User App)               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         Cubits/BLoCs            │   │
│  │  - Depend on Services           │   │
│  │  - Registered as Factory        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│           Domain Layer                  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │          Services               │   │
│  │  - Depend on Repositories       │   │
│  │  - Registered as Factory        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│      Infrastructure Layer               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │       Repositories              │   │
│  │  - Depend on APIs & Adapters    │   │
│  │  - Registered as Factory        │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │           APIs                  │   │
│  │  - Depend on HttpClientApi      │   │
│  │  - Registered as Factory        │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │         Adapters                │   │
│  │  - No dependencies              │   │
│  │  - Registered as Factory        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│         Core Services                   │
│  - HttpClientApi                        │
│  - NetworkVerify                        │
│  - Registered as Singleton              │
└─────────────────────────────────────────┘
```

## 1. Infrastructure Layer Setup

### File: `lib/core/di/injection_container.dart`

```dart
import 'package:kiwi/kiwi.dart';
import 'package:infrastructure_clap/core/network/http_client_api.dart';
import 'package:infrastructure_clap/core/network/network_verify.dart';

// Import your module components
import '../../payment/apis/payment_api.dart';
import '../../payment/adapters/payment_adapter.dart';
import '../../payment/repositories/payment_repository_impl.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

void setupInfrastructureInjection() {
  final container = KiwiContainer();

  // Core services (should be registered once in main infrastructure setup)
  _setupCoreServices(container);

  // Module specific registrations
  _setupPaymentModule(container);
  // Add other modules here
  // _setupUserModule(container);
  // _setupAuthModule(container);
}

void _setupCoreServices(KiwiContainer container) {
  // Register core HTTP and network services
  // These are typically registered as singletons
  container.registerSingleton((c) => HttpClientApi());
  container.registerSingleton((c) => NetworkVerify());
}

void _setupPaymentModule(KiwiContainer container) {
  // Register in order: API → Adapter → Repository
  
  // API (depends on HttpClientApi)
  container.registerFactory(
    (c) => PaymentApi(c.resolve<HttpClientApi>()),
  );

  // Adapter (no dependencies)
  container.registerFactory(
    (c) => PaymentAdapter(),
  );

  // Repository (depends on NetworkVerify, PaymentApi, PaymentAdapter)
  container.registerFactory<IPaymentRepository>(
    (c) => PaymentRepositoryImpl(
      c.resolve<NetworkVerify>(),
      c.resolve<PaymentApi>(),
      c.resolve<PaymentAdapter>(),
    ),
  );
}
```

### Key Points for Infrastructure
- Register APIs with HttpClientApi dependency
- Register Adapters without dependencies
- Register Repositories with interface type `<IRepository>`
- Repositories depend on NetworkVerify, API, and Adapter

## 2. Domain Layer Setup

Domain layer typically doesn't have its own DI file since services are registered in the frontend applications. However, if you want to register services independently:

### File: `lib/core/di/injection_container.dart`

```dart
import 'package:kiwi/kiwi.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

void setupDomainInjection() {
  final container = KiwiContainer();

  _setupPaymentServices(container);
  // Add other service registrations
}

void _setupPaymentServices(KiwiContainer container) {
  // Register Service (depends on Repository interface)
  container.registerFactory(
    (c) => PaymentService(c.resolve<IPaymentRepository>()),
  );
}
```

### Key Points for Domain
- Services depend on repository interfaces
- Use interface types when resolving dependencies
- Keep services stateless (use factory)

## 3. Frontend Admin Setup

### File: `lib/core/di/injection_container.dart`

```dart
import 'package:kiwi/kiwi.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

// Import infrastructure DI
import 'package:infrastructure_clap/core/di/injection_container.dart' 
    as infrastructure_di;

// Import your cubits
import '../../features/payment/cubit/payment_management_cubit.dart';

void setupAdminAppInjection() {
  final container = KiwiContainer();

  // Setup infrastructure layer first
  infrastructure_di.setupInfrastructureInjection();

  // Setup domain services
  _setupDomainLayer(container);

  // Setup feature cubits
  _setupPaymentFeature(container);
  // Add other features
}

void _setupDomainLayer(KiwiContainer container) {
  // Register domain services
  container.registerFactory(
    (c) => PaymentService(c.resolve<IPaymentRepository>()),
  );
}

void _setupPaymentFeature(KiwiContainer container) {
  // Register Cubit (depends on Service)
  container.registerFactory(
    (c) => PaymentManagementCubit(c.resolve<PaymentService>()),
  );
}
```

### Initialization in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'core/di/injection_container.dart';

void main() {
  // Initialize dependency injection
  setupAdminAppInjection();

  runApp(const MyApp());
}
```

### Using Injector in Widgets

```dart
import 'package:admin_app/core/injector/injector.dart';

class PaymentManagementScreen extends StatefulWidget {
  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  late final PaymentManagementCubit bloc;

  @override
  void initState() {
    super.initState();
    // Resolve from Kiwi container via injector
    bloc = injector.resolve<PaymentManagementCubit>()..initialLoad();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... widget build
  }
}
```

## 4. Frontend User Setup

### File: `lib/core/di/injection_container.dart`

```dart
import 'package:kiwi/kiwi.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

// Import infrastructure DI
import 'package:infrastructure_clap/core/di/injection_container.dart' 
    as infrastructure_di;

// Import your cubits
import '../../features/payment/cubit/user_payment_cubit.dart';

void setupUserAppInjection() {
  final container = KiwiContainer();

  // Setup infrastructure layer first
  infrastructure_di.setupInfrastructureInjection();

  // Setup domain services
  _setupDomainLayer(container);

  // Setup feature cubits
  _setupPaymentFeature(container);
}

void _setupDomainLayer(KiwiContainer container) {
  // Register domain services
  container.registerFactory(
    (c) => PaymentService(c.resolve<IPaymentRepository>()),
  );
}

void _setupPaymentFeature(KiwiContainer container) {
  // Register Cubit (depends on Service)
  container.registerFactory(
    (c) => UserPaymentCubit(c.resolve<PaymentService>()),
  );
}
```

## Complete Example: Payment Module Full DI Chain

### Infrastructure Layer
```dart
void _setupPaymentInfrastructure(KiwiContainer container) {
  // 1. API
  container.registerFactory(
    (c) => PaymentApi(c.resolve<HttpClientApi>()),
  );

  // 2. Adapter
  container.registerFactory(
    (c) => PaymentAdapter(),
  );

  // 3. Repository
  container.registerFactory<IPaymentRepository>(
    (c) => PaymentRepositoryImpl(
      c.resolve<NetworkVerify>(),
      c.resolve<PaymentApi>(),
      c.resolve<PaymentAdapter>(),
    ),
  );
}
```

### Domain Layer
```dart
void _setupPaymentDomain(KiwiContainer container) {
  // Service (depends on repository interface)
  container.registerFactory(
    (c) => PaymentService(c.resolve<IPaymentRepository>()),
  );
}
```

### Frontend Layer (Admin)
```dart
void _setupPaymentFeatureAdmin(KiwiContainer container) {
  // Cubit (depends on service)
  container.registerFactory(
    (c) => PaymentManagementCubit(c.resolve<PaymentService>()),
  );
}
```

### Frontend Layer (User)
```dart
void _setupPaymentFeatureUser(KiwiContainer container) {
  // Cubit (depends on service)
  container.registerFactory(
    (c) => UserPaymentCubit(c.resolve<PaymentService>()),
  );
}
```

## Injector Helper

Create a helper file for easier resolution:

### File: `lib/core/injector/injector.dart`

```dart
import 'package:kiwi/kiwi.dart';

/// Global injector instance for dependency resolution
final injector = KiwiContainer();
```

## Registration Checklist

For each new module, register in this order:

### Infrastructure Layer
- [ ] Register API with HttpClientApi dependency
- [ ] Register Adapter (no dependencies)
- [ ] Register Repository with interface type

### Domain Layer (in Frontend apps)
- [ ] Register Service with repository interface dependencies

### Frontend Layer
- [ ] Register Cubit with service dependencies

## Common Issues and Solutions

### Issue: "Type not found in container"
**Solution:** Ensure dependencies are registered before the dependent classes. Check registration order.

### Issue: "Multiple instances created"
**Solution:** Use `registerSingleton` instead of `registerFactory` if you need a single shared instance.

### Issue: "Cannot resolve interface"
**Solution:** Make sure to register with interface type: `container.registerFactory<IRepository>(...)`

### Issue: "Circular dependencies"
**Solution:** Refactor to break the circular dependency. Consider using a mediator pattern or event bus.

## Best Practices

### ✅ DO
- Register in dependency order (dependencies first)
- Use `registerFactory` for stateless services
- Use interface types for repository registration
- Keep DI setup organized by module
- Document complex dependency chains

### ❌ DON'T
- Don't register classes before their dependencies
- Don't use `registerSingleton` unless necessary
- Don't resolve dependencies in constructors (inject them)
- Don't create multiple DI containers
- Don't register with concrete types when interface exists

## Testing with Kiwi

### Mock Registration for Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi/kiwi.dart';
import 'package:mockito/mockito.dart';

class MockPaymentService extends Mock implements PaymentService {}

void main() {
  late KiwiContainer container;
  late MockPaymentService mockPaymentService;

  setUp(() {
    container = KiwiContainer();
    mockPaymentService = MockPaymentService();

    // Register mock
    container.registerFactory<PaymentService>(
      (c) => mockPaymentService,
    );

    // Register cubit with mock dependency
    container.registerFactory(
      (c) => PaymentManagementCubit(c.resolve<PaymentService>()),
    );
  });

  tearDown(() {
    container.clear();
  });

  test('should load payments on initial load', () async {
    // Arrange
    when(mockPaymentService.getPaymentHistory(any))
        .thenAnswer((_) async => []);

    final cubit = container.resolve<PaymentManagementCubit>();

    // Act
    await cubit.initialLoad();

    // Assert
    verify(mockPaymentService.getPaymentHistory(any)).called(1);
  });
}
```

## Dependencies

```yaml
dependencies:
  kiwi: ^4.1.0
```

---

**Follow this DI setup pattern for consistent dependency management across all layers of the CLAP architecture.**
