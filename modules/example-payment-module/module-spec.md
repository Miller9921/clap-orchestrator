# Module Specification: Payment Processing

## Module Overview

**Purpose:** Complete payment processing system for handling payment transactions, payment methods, and payment history across the CLAP platform.

**Business Value:** Enables administrators to manage all payment transactions, issue refunds, and generate reports. Allows users to make secure payments, view payment history, and manage payment methods.

**Core Entities:** PaymentModel, PaymentMethodModel

---

## Domain Layer (Miller9921/flutter-domain)

### Entities

#### PaymentModel
Equatable model representing a payment transaction.

**Properties:**
- `id` (String) - Unique payment identifier
- `amount` (double) - Payment amount
- `currency` (String) - Currency code (USD, EUR, etc.)
- `status` (String) - Payment status (pending, completed, failed, refunded)
- `createdAt` (DateTime) - Transaction creation timestamp
- `updatedAt` (DateTime?) - Last update timestamp
- `userId` (String) - ID of the user who made the payment
- `paymentMethodId` (String) - ID of the payment method used
- `description` (String?) - Optional payment description

**Equatable Requirements:**
- const constructor
- final fields
- copyWith method
- props override

#### PaymentMethodModel
Equatable model representing a payment method.

**Properties:**
- `id` (String) - Unique identifier
- `type` (String) - Method type (credit_card, paypal, bank_transfer)
- `provider` (String) - Provider name
- `last4` (String?) - Last 4 digits for cards
- `isDefault` (bool) - Whether this is the default method
- `userId` (String) - Owner user ID
- `createdAt` (DateTime) - Creation timestamp

**Equatable Requirements:**
- const constructor
- final fields
- copyWith method
- props override

### Services

#### PaymentService
Business logic service orchestrating payment operations.

**Dependencies:**
- `IPaymentRepository` - Payment data repository

**Methods:**
- `Future<List<PaymentModel>> getPaymentHistory(String userId)` - Get user's payment history (excluding cancelled)
- `Future<PaymentModel?> getPaymentById(String id)` - Get single payment
- `Future<PaymentModel> createPayment({required String userId, required double amount, required String currency, required String paymentMethodId})` - Create new payment with validation
- `Future<PaymentModel> updatePaymentStatus(String paymentId, String status)` - Update payment status
- `Future<void> refundPayment(String paymentId)` - Issue refund for payment
- `Future<double> calculateTotalPaid(String userId, {DateTime? startDate, DateTime? endDate})` - Calculate total amount paid

### Repository Interfaces

#### IPaymentRepository
Abstract interface for payment data operations.

**Methods:**
- `Future<List<PaymentModel>> getPaymentsByUserId(String userId)`
- `Future<PaymentModel?> getPaymentById(String id)`
- `Future<PaymentModel> createPayment(PaymentModel payment)`
- `Future<PaymentModel> updatePayment(PaymentModel payment)`
- `Future<void> deletePayment(String id)`
- `Future<List<PaymentModel>> getPaymentsByStatus(String status)`
- `Future<List<PaymentModel>> getPaymentsInDateRange(DateTime startDate, DateTime endDate)`

**Note:** NO Either, Failures, or Value Objects

---

## Infrastructure Layer (Miller9921/flutter-infrastructure)

### DTOs

#### PaymentDto
Data Transfer Object with JSON serialization.

**Annotations:** `@JsonSerializable()`

**Properties:**
- `id` (String?)
- `amount` (double?)
- `currency` (String?)
- `status` (String?)
- `@JsonKey(name: 'created_at') createdAt` (String?)
- `@JsonKey(name: 'updated_at') updatedAt` (String?)
- `@JsonKey(name: 'user_id') userId` (String?)
- `@JsonKey(name: 'payment_method_id') paymentMethodId` (String?)
- `description` (String?)

**Methods:**
- `factory PaymentDto.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`

#### PaymentMethodDto
Data Transfer Object for payment methods.

**Annotations:** `@JsonSerializable()`

**Properties:**
- `id` (String?)
- `type` (String?)
- `provider` (String?)
- `@JsonKey(name: 'last_4') last4` (String?)
- `@JsonKey(name: 'is_default') isDefault` (bool?)
- `@JsonKey(name: 'user_id') userId` (String?)
- `@JsonKey(name: 'created_at') createdAt` (String?)

### Adapters

#### PaymentAdapter
Extends `ModelAdapter<PaymentModel, PaymentDto, void>`

**Methods:**
- `PaymentModel toModel(PaymentDto dto)` - Convert DTO to Model with DateTime parsing
- `PaymentDto fromModel(PaymentModel model)` - Convert Model to DTO with ISO8601 strings

#### PaymentMethodAdapter
Extends `ModelAdapter<PaymentMethodModel, PaymentMethodDto, void>`

**Methods:**
- `PaymentMethodModel toModel(PaymentMethodDto dto)`
- `PaymentMethodDto fromModel(PaymentMethodModel model)`

### API Clients

#### PaymentApi
API client using HttpClientApi for payment operations.

**Dependencies:**
- `HttpClientApi` - HTTP client service

**Methods:**
- `Future<PaymentDto> getPayment(String id)` - GET /v1/payments/{id}
- `Future<List<PaymentDto>> getAllPayments()` - GET /v1/payments
- `Future<List<PaymentDto>> getPaymentsByUserId(String userId)` - GET /v1/payments?user_id={userId}
- `Future<PaymentDto> createPayment(PaymentDto dto)` - POST /v1/payments
- `Future<PaymentDto> updatePayment(String id, PaymentDto dto)` - PUT /v1/payments/{id}
- `Future<void> deletePayment(String id)` - DELETE /v1/payments/{id}

**Implementation Details:**
- Use `Uri.https('api.example.com', path, queryParameters)`
- Use `HttpClientApi` methods: `getRequestWithToken`, `postRequestWithToken`, etc.
- Use `ExceptionHandlerResponse.responseDataSourceTemplError` for error handling
- Constants: `TYPE_RETURN_METHOD_GET`, `TYPE_RETURN_METHOD_POST`, etc.

### Repository Implementation

#### PaymentRepositoryImpl
Implements `IPaymentRepository` from Domain layer.

**Dependencies:**
- `NetworkVerify` - Network connectivity check
- `PaymentApi` - API client
- `PaymentAdapter` - Model/DTO adapter

**Implementation:**
- Check network before each operation
- Use API for data operations
- Use Adapter to convert between DTOs and Models
- Return null for getById when not found

### Kiwi DI Registration

```dart
// Register API
container.registerFactory((c) => PaymentApi(c.resolve()));

// Register Adapter
container.registerFactory((c) => PaymentAdapter());
container.registerFactory((c) => PaymentMethodAdapter());

// Register Repository
container.registerFactory<IPaymentRepository>(
  (c) => PaymentRepositoryImpl(
    c.resolve(),
    c.resolve(),
    c.resolve(),
  ),
);
```

---

## UI Layer (Miller9921/flutter-ui-components)

### Generic Widgets

#### PaymentMethodSelector<T>
Generic dropdown/list for selecting payment methods.

**Type Parameters:**
- `T` - Generic type for payment method data

**Properties:**
- `List<T> methods` - Available payment methods
- `T? selectedMethod` - Currently selected method
- `String Function(T) getDisplayName` - Extract display name
- `String Function(T)? getSubtitle` - Extract subtitle (e.g., last 4 digits)
- `void Function(T) onMethodSelected` - Selection callback
- `bool Function(T)? isEnabled` - Check if method is enabled
- `IconData Function(T)? getIcon` - Get method icon

**Styling:**
- Card-based list with selection highlighting
- Use Theme.of(context) for colors
- Use ClapColors.primary for selected state
- Check icon for selected method

#### PaymentFormWidget<T>
Generic form for entering payment amount and selecting currency.

**Type Parameters:**
- `T` - Generic type for initial payment data

**Properties:**
- `T? initialData` - Initial payment data
- `void Function(double amount, String currency) onSubmit` - Submit callback
- `List<String> availableCurrencies` - Available currency options
- `double? Function(T)? getAmount` - Extract amount from initial data
- `String? Function(T)? getCurrency` - Extract currency from initial data
- `String? submitButtonText` - Custom submit button text

**Features:**
- TextEditingController for amount input
- Dropdown for currency selection
- Input validation
- Responsive layout
- Uses StatefulWidget for form state

#### PaymentHistoryList<T>
Generic scrollable list for displaying payment history.

**Type Parameters:**
- `T` - Generic type for payment data

**Properties:**
- `List<T> payments` - Payment items
- `String Function(T) getTitle` - Extract title (e.g., amount)
- `String Function(T) getSubtitle` - Extract subtitle (e.g., date)
- `String Function(T)? getAmount` - Extract formatted amount
- `Widget? Function(T)? getStatusWidget` - Get status indicator widget
- `void Function(T)? onItemTap` - Item tap callback
- `String? emptyMessage` - Message for empty list

**Features:**
- Empty state with icon and message
- Separated list items
- Status chips/badges
- Tap handling

#### PaymentStatusCard<T>
Generic card for displaying detailed payment status.

**Type Parameters:**
- `T` - Generic type for payment data

**Properties:**
- `T payment` - Payment data
- `String Function(T) getStatus` - Extract status text
- `String Function(T) getAmount` - Extract amount text
- `String Function(T) getDate` - Extract date text
- `Color? Function(T)? getStatusColor` - Get status color
- `IconData? Function(T)? getStatusIcon` - Get status icon
- `void Function(T)? onViewDetails` - View details callback

**Features:**
- Status indicator with icon and color
- Amount prominently displayed
- Date information
- Optional action button
- Card elevation and rounded corners

---

## Frontend Admin (Miller9921/flutter-admin-app)

### State Management

#### PaymentManagementState
Equatable state class for payment management.

**Properties:**
- `bool initialLoad` - Initial loading flag (default: true)
- `bool error` - Error flag (default: false)
- `String? errorMessage` - Error message
- `List<PaymentModel> payments` - All payments (default: [])
- `PaymentModel? selectedPayment` - Currently selected payment
- `bool errorAction` - Action error flag (default: false)
- `bool successAction` - Action success flag (default: false)
- `String? successMessage` - Success message

**Methods:**
- `copyWith()` - Create copy with modified properties
- `props` - Equatable props override

#### PaymentManagementCubit
Cubit for payment management operations.

**Dependencies:**
- `PaymentService` (injected via Kiwi)

**Methods:**
- `initialLoad()` - Load all payments on init
- `loadAllPayments()` - Reload payment list
- `selectPayment(String id)` - Select specific payment
- `issueRefund(String paymentId)` - Issue refund for payment
- `generateReport(DateTime start, DateTime end)` - Generate payment report
- `clearSelectedPayment()` - Clear selection
- `clearMessages()` - Clear error/success messages

**Error Handling:**
- All methods use `customTryCatch`
- Emit error states on failure
- Emit success states on completion

### Screen

#### PaymentManagementScreen
Main admin screen for payment management.

**Structure:**
- `@RoutePage()` annotation for auto_route
- StatefulWidget
- `late final PaymentManagementCubit bloc`
- `initState`: `bloc = injector.resolve()..initialLoad()`
- `dispose`: close bloc

**UI Structure:**
```dart
AppSectionTemplateAdmin(
  title: 'Payment Management',
  child: BlocListener<PaymentManagementCubit, PaymentManagementState>(
    // Handle errors with Utils.alertToastError
    // Handle success with Utils.alertToastSuccess
    child: BlocBuilder<PaymentManagementCubit, PaymentManagementState>(
      // Loading: Utils().loadingWidget()
      // Error: Utils().errorWidget()
      // Success: Main content with PaymentHistoryList
    ),
  ),
)
```

**Features:**
- View all payments in list
- Select payment to view details
- Issue refunds with confirmation dialog
- Generate reports with date range picker
- Refresh payment list
- Export functionality

### Routing

```dart
AutoRoute(page: PaymentManagementRoute.page, path: '/payments'),
```

### Kiwi DI Registration

```dart
// Domain Service
container.registerFactory((c) => PaymentService(c.resolve()));

// Admin Cubit
container.registerFactory((c) => PaymentManagementCubit(c.resolve()));
```

---

## Frontend User (Miller9921/flutter-frontuser-app)

### State Management

#### UserPaymentState
Equatable state class for user payment operations.

**Properties:**
- `bool initialLoad` - Initial loading flag
- `bool error` - Error flag
- `String? errorMessage` - Error message
- `List<PaymentModel> paymentHistory` - User's payment history
- `List<PaymentMethodModel> paymentMethods` - User's payment methods
- `PaymentMethodModel? selectedMethod` - Selected payment method
- `bool processing` - Payment processing flag
- `bool successAction` - Success flag
- `String? successMessage` - Success message

**Methods:**
- `copyWith()` - Copy with modifications
- `props` - Equatable props

#### UserPaymentCubit
Cubit for user payment operations.

**Dependencies:**
- `PaymentService` (injected via Kiwi)

**Methods:**
- `initialLoad()` - Load user data
- `loadUserData()` - Load payment history and methods
- `selectPaymentMethod(PaymentMethodModel method)` - Select payment method
- `makePayment({required double amount, required String currency})` - Process payment
- `loadPaymentHistory()` - Reload payment history
- `clearMessages()` - Clear messages
- `clearSelectedMethod()` - Clear selected method

### Screens

#### CheckoutScreen
Screen for making payments.

**Structure:**
- `@RoutePage()` with optional amount and currency parameters
- StatefulWidget with UserPaymentCubit
- AppSectionTemplateUser wrapper
- BlocListener for error/success handling
- BlocBuilder for UI states

**Features:**
- Payment amount form (PaymentFormWidget)
- Payment method selector (PaymentMethodSelector)
- Processing indicator
- Validation
- Success navigation

#### PaymentHistoryScreen
Screen for viewing payment history.

**Structure:**
- `@RoutePage()` annotation
- StatefulWidget with UserPaymentCubit
- AppSectionTemplateUser wrapper
- BlocListener/BlocBuilder pattern

**Features:**
- Payment history list (PaymentHistoryList)
- Empty state
- Pull to refresh
- Tap to view details (bottom sheet with PaymentStatusCard)
- Status indicators

### Routing

```dart
AutoRoute(page: CheckoutRoute.page, path: '/checkout'),
AutoRoute(page: PaymentHistoryRoute.page, path: '/payment-history'),
```

### Kiwi DI Registration

```dart
// Domain Service
container.registerFactory((c) => PaymentService(c.resolve()));

// User Cubit
container.registerFactory((c) => UserPaymentCubit(c.resolve()));
```

---

## i18n Keys (Miller9921/clap_i18n)

### Admin Frontend Keys
```
payment.title = Payment Management
payment.subtitle = Manage all payment transactions
payment.menu_item = Payments
payment.list.title = All Payments
payment.list.empty = No payments found
payment.action.refund = Issue Refund
payment.action.export = Export Report
payment.action.refresh = Refresh
payment.confirm.refund = Are you sure you want to issue a refund?
payment.success.refund_issued = Refund issued successfully
payment.success.report_generated = Report generated successfully
payment.error.load_failed = Failed to load payments
payment.error.refund_failed = Failed to issue refund
payment.payment.id = Payment ID
payment.payment.amount = Amount
payment.payment.currency = Currency
payment.payment.status = Status
payment.payment.user_id = User ID
payment.payment.created_at = Date
```

### User Frontend Keys
```
payment.title = Payments
payment.checkout.title = Checkout
payment.history.title = Payment History
payment.empty.title = No Payments
payment.empty.message = You haven't made any payments yet
payment.action.pay = Pay Now
payment.action.view_history = View History
payment.success.payment_completed = Payment completed successfully
payment.error.payment_failed = Payment failed. Please try again
payment.error.invalid_amount = Please enter a valid amount
payment.amount = Amount
payment.currency = Currency
payment.method = Payment Method
payment.method.card = Credit Card
payment.method.paypal = PayPal
payment.method.bank = Bank Transfer
payment.status.pending = Pending
payment.status.completed = Completed
payment.status.failed = Failed
```

---

## Kiwi DI Setup Summary

### Dependency Chain

```
Infrastructure Layer:
  PaymentApi (depends on HttpClientApi)
    ↓
  PaymentAdapter (no dependencies)
    ↓
  PaymentRepositoryImpl (depends on NetworkVerify, PaymentApi, PaymentAdapter)

Domain Layer:
  PaymentService (depends on IPaymentRepository)

Frontend Layers:
  PaymentManagementCubit (depends on PaymentService) - Admin
  UserPaymentCubit (depends on PaymentService) - User
```

---

## Testing Considerations

- Unit tests for PaymentService business logic
- Unit tests for PaymentRepositoryImpl
- Widget tests for UI components with mock data
- Integration tests for API client
- Cubit tests with mocked services
- Golden tests for UI widgets

---

**Created by CLAP Orchestrator**
**Module:** Payment Processing
**Version:** 1.0
**Last Updated:** 2026-01-09
