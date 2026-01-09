# Domain Layer - Payment Processing Module

This directory contains example implementations for the Domain layer of the Payment Processing module.

## Structure

```
domain/
├── entities/
│   ├── payment_model.dart
│   └── payment_method_model.dart
├── services/
│   └── payment_service.dart
├── repositories/
│   └── i_payment_repository.dart
├── exports.dart
└── README.md
```

## Implementation Files

### Entities
- **payment_model.dart** - PaymentModel with Equatable, const constructor, copyWith
- **payment_method_model.dart** - PaymentMethodModel with Equatable pattern

### Services
- **payment_service.dart** - PaymentService with business logic orchestration

### Repositories
- **i_payment_repository.dart** - IPaymentRepository interface with Future<T> methods

### Exports
- **exports.dart** - Single export file for all domain components

## Key Patterns Demonstrated

1. **Equatable Models**
   - const constructor
   - final fields
   - copyWith method
   - props override

2. **Service Layer**
   - Business logic orchestration
   - Repository dependency injection
   - try/catch error handling
   - NO Either/Failure types

3. **Repository Interfaces**
   - Abstract class pattern
   - Future<T> return types
   - Clear method signatures
   - NO implementation details

## Usage

These files should be placed in `Miller9921/flutter-domain` repository:
```
/lib/paymentmodule/
  ├── entities/
  ├── services/
  ├── repositories/
  └── exports.dart
```

## Dependencies

```yaml
dependencies:
  equatable: ^2.0.5
```
