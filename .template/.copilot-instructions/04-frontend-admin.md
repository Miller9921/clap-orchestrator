# Frontend Admin Implementation Instructions

## Overview
Create Frontend Admin features with Cubit state management, BlocListener/BlocBuilder patterns, and auto_route navigation.

## Repository
**Target:** Miller9921/flutter-admin-app

## Structure
```
/lib/
  └── features/
      └── [module]/
          ├── cubit/
          │   ├── [feature]_cubit.dart
          │   └── [feature]_state.dart
          ├── screens/
          │   ├── [feature]_screen.dart
          │   └── [other]_screen.dart
          └── exports.dart
```

## 1. Creating State Class

### Requirements
- Extend Equatable
- Include state flags (initialLoad, error, successAction, etc.)
- Include data properties
- Implement copyWith method
- Override props getter

### State Template

```dart
import 'package:equatable/equatable.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

class PaymentManagementState extends Equatable {
  final bool initialLoad;
  final bool error;
  final String? errorMessage;
  final List<PaymentModel> payments;
  final PaymentModel? selectedPayment;
  final bool errorAction;
  final bool successAction;
  final String? successMessage;

  const PaymentManagementState({
    this.initialLoad = true,
    this.error = false,
    this.errorMessage,
    this.payments = const [],
    this.selectedPayment,
    this.errorAction = false,
    this.successAction = false,
    this.successMessage,
  });

  PaymentManagementState copyWith({
    bool? initialLoad,
    bool? error,
    String? errorMessage,
    List<PaymentModel>? payments,
    PaymentModel? selectedPayment,
    bool? errorAction,
    bool? successAction,
    String? successMessage,
    bool clearSelectedPayment = false,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return PaymentManagementState(
      initialLoad: initialLoad ?? this.initialLoad,
      error: error ?? this.error,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      payments: payments ?? this.payments,
      selectedPayment: clearSelectedPayment ? null : (selectedPayment ?? this.selectedPayment),
      errorAction: errorAction ?? this.errorAction,
      successAction: successAction ?? this.successAction,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        initialLoad,
        error,
        errorMessage,
        payments,
        selectedPayment,
        errorAction,
        successAction,
        successMessage,
      ];
}
```

### Key Points
- Default values in constructor for convenience
- copyWith parameters for nullable field clearing
- All state flags and data in one class
- Immutable with const constructor

## 2. Creating Cubit

### Requirements
- Extend Cubit<State>
- Inject dependencies via constructor (Services/Repositories)
- Use customTryCatch for error handling
- Emit states for loading, success, error
- Provide initialLoad method

### Cubit Template

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain_clap/paymentmodule/exports.dart';
import 'package:admin_app/core/utils/custom_try_catch.dart';

import 'payment_management_state.dart';

class PaymentManagementCubit extends Cubit<PaymentManagementState> {
  final PaymentService _paymentService;

  PaymentManagementCubit(this._paymentService)
      : super(const PaymentManagementState());

  Future<void> initialLoad() async {
    await loadAllPayments();
  }

  Future<void> loadAllPayments() async {
    await customTryCatch(
      tryFunction: () async {
        emit(state.copyWith(initialLoad: true, error: false));

        // Mock user ID - in real app, get from auth service
        final payments = await _paymentService.getPaymentHistory('all');

        emit(state.copyWith(
          initialLoad: false,
          error: false,
          payments: payments,
        ));
      },
      catchFunction: (error) {
        emit(state.copyWith(
          initialLoad: false,
          error: true,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> selectPayment(String paymentId) async {
    await customTryCatch(
      tryFunction: () async {
        final payment = await _paymentService.getPaymentById(paymentId);
        
        emit(state.copyWith(
          selectedPayment: payment,
        ));
      },
      catchFunction: (error) {
        emit(state.copyWith(
          errorAction: true,
          errorMessage: 'Failed to load payment details',
        ));
      },
    );
  }

  Future<void> issueRefund(String paymentId) async {
    await customTryCatch(
      tryFunction: () async {
        // Call refund service method
        // await _paymentService.refundPayment(paymentId);

        emit(state.copyWith(
          successAction: true,
          successMessage: 'Refund issued successfully',
        ));

        // Reload payments
        await loadAllPayments();
      },
      catchFunction: (error) {
        emit(state.copyWith(
          errorAction: true,
          errorMessage: 'Failed to issue refund: ${error.toString()}',
        ));
      },
    );
  }

  Future<void> generateReport(DateTime startDate, DateTime endDate) async {
    await customTryCatch(
      tryFunction: () async {
        // Generate report logic
        emit(state.copyWith(
          successAction: true,
          successMessage: 'Report generated successfully',
        ));
      },
      catchFunction: (error) {
        emit(state.copyWith(
          errorAction: true,
          errorMessage: 'Failed to generate report',
        ));
      },
    );
  }

  void clearSelectedPayment() {
    emit(state.copyWith(clearSelectedPayment: true));
  }

  void clearMessages() {
    emit(state.copyWith(
      errorAction: false,
      successAction: false,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
  }
}
```

### Key Points
- All async operations use customTryCatch
- Emit loading states before operations
- Emit success/error states after operations
- Provide methods for user actions
- Keep cubit methods focused and testable

## 3. Creating Screen

### Requirements
- Use @RoutePage() annotation
- StatefulWidget structure
- Initialize cubit in initState with injector.resolve()
- Use AppSectionTemplateAdmin wrapper
- BlocListener for error/success handling
- BlocBuilder for UI state
- Use Utils helpers for loading/error widgets

### Screen Template

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_app/core/injector/injector.dart';
import 'package:admin_app/core/utils/utils.dart';
import 'package:admin_app/core/widgets/app_section_template_admin.dart';
import 'package:ui_widgets_clap/payment/exports.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

import '../cubit/payment_management_cubit.dart';
import '../cubit/payment_management_state.dart';

@RoutePage()
class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({Key? key}) : super(key: key);

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  late final PaymentManagementCubit bloc;

  @override
  void initState() {
    super.initState();
    bloc = injector.resolve()..initialLoad();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionTemplateAdmin(
      title: 'Payment Management',
      child: BlocListener<PaymentManagementCubit, PaymentManagementState>(
        bloc: bloc,
        listener: (context, state) {
          // Handle errors
          if (state.errorAction) {
            Utils.alertToastError(
              context,
              state.errorMessage ?? 'An error occurred',
            );
            bloc.clearMessages();
          }

          // Handle success
          if (state.successAction) {
            Utils.alertToastSuccess(
              context,
              state.successMessage ?? 'Operation completed',
            );
            bloc.clearMessages();
          }
        },
        child: BlocBuilder<PaymentManagementCubit, PaymentManagementState>(
          bloc: bloc,
          builder: (context, state) {
            // Initial loading
            if (state.initialLoad) {
              return Utils().loadingWidget();
            }

            // Error state with no data
            if (state.error && state.payments.isEmpty) {
              return Utils().errorWidget(
                onRetry: () => bloc.initialLoad(),
              );
            }

            // Main content
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentManagementState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with actions
        _buildHeader(context),
        const SizedBox(height: 16),

        // Payments list
        Expanded(
          child: PaymentHistoryList<PaymentModel>(
            payments: state.payments,
            getTitle: (payment) => 'Payment #${payment.id}',
            getSubtitle: (payment) => 
                'User: ${payment.userId} • ${_formatDate(payment.createdAt)}',
            getAmount: (payment) => '\$${payment.amount.toStringAsFixed(2)} ${payment.currency}',
            getStatusWidget: (payment) => _buildStatusChip(payment.status),
            onItemTap: (payment) => bloc.selectPayment(payment.id),
            emptyMessage: 'No payments found',
          ),
        ),

        // Selected payment details
        if (state.selectedPayment != null)
          _buildPaymentDetails(context, state.selectedPayment!),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Payments',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showGenerateReportDialog(context),
              icon: const Icon(Icons.analytics),
              label: const Text('Generate Report'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => bloc.loadAllPayments(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(BuildContext context, PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => bloc.clearSelectedPayment(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('Payment ID', payment.id),
            _buildDetailRow('Amount', '\$${payment.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Currency', payment.currency),
            _buildDetailRow('Status', payment.status),
            _buildDetailRow('User ID', payment.userId),
            _buildDetailRow('Date', _formatDate(payment.createdAt)),
            const SizedBox(height: 16),
            if (payment.status == 'completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmRefund(context, payment.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Issue Refund'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _confirmRefund(BuildContext context, String paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: const Text('Are you sure you want to issue a refund for this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              bloc.issueRefund(paymentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Issue Refund'),
          ),
        ],
      ),
    );
  }

  void _showGenerateReportDialog(BuildContext context) {
    // Show date range picker dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text('Report generation dialog would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              bloc.generateReport(DateTime.now().subtract(const Duration(days: 30)), DateTime.now());
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
```

### Key Points
- @RoutePage() annotation for auto_route
- StatefulWidget with late bloc initialization
- BlocListener for side effects (toasts, dialogs)
- BlocBuilder for UI state
- Use UI widgets from ui_widgets_clap package
- AppSectionTemplateAdmin wrapper
- Clean separation of UI building methods

## 4. Routing Configuration

### Add to auto_router configuration

```dart
// In your router configuration file (e.g., app_router.dart)

import 'package:auto_route/auto_route.dart';
import 'features/payment/screens/payment_management_screen.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
    // ... other routes
    AutoRoute(
      page: PaymentManagementRoute.page,
      path: '/payments',
    ),
  ];
}
```

## 5. Kiwi DI Registration

### Register Cubit

```dart
// In your DI setup file

import 'package:kiwi/kiwi.dart';
import 'features/payment/cubit/payment_management_cubit.dart';

void setupPaymentFeature() {
  final container = KiwiContainer();

  // Register Cubit (depends on Service from domain)
  container.registerFactory(
    (c) => PaymentManagementCubit(c.resolve()),
  );
}
```

## Important Rules

### ✅ DO
- Use customTryCatch in all Cubit methods
- Emit loading states before operations
- Use Utils.alertToastError for errors
- Use Utils.alertToastSuccess for success
- Use AppSectionTemplateAdmin wrapper
- Use BlocListener for side effects
- Use BlocBuilder for UI rendering
- Close bloc in dispose
- Import UI widgets from ui_widgets_clap

### ❌ DON'T
- DON'T handle state in StatefulWidget's setState (use Cubit)
- DON'T make API calls directly in screens
- DON'T skip error handling
- DON'T forget @RoutePage() annotation
- DON'T forget to register Cubit in DI

## Naming Conventions

- **Cubits:** `[Feature]Cubit` (e.g., PaymentManagementCubit, UserProfileCubit)
- **States:** `[Feature]State` (e.g., PaymentManagementState, UserProfileState)
- **Screens:** `[Feature]Screen` (e.g., PaymentManagementScreen, UserProfileScreen)
- **Files:** snake_case (e.g., payment_management_cubit.dart, payment_management_screen.dart)

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  auto_route: ^7.8.4
  equatable: ^2.0.5
  domain_clap:
    path: ../../flutter-domain
  infrastructure_clap:
    path: ../../flutter-infrastructure
  ui_widgets_clap:
    path: ../../flutter-ui-components

dev_dependencies:
  auto_route_generator: ^7.3.2
  build_runner: ^2.4.6
```

## Testing Considerations

- Cubit tests with mocked services
- Screen widget tests
- Integration tests for full flows

---

**Follow these patterns exactly for consistent Frontend Admin implementation across the CLAP architecture.**
