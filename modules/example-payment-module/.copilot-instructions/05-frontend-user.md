# Frontend User Implementation Instructions

## Overview
Create Frontend User features with Cubit state management, BlocListener/BlocBuilder patterns, and auto_route navigation. Similar to Admin but focused on end-user experiences.

## Repository
**Target:** Miller9921/flutter-frontuser-app

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

class UserPaymentState extends Equatable {
  final bool initialLoad;
  final bool error;
  final String? errorMessage;
  final List<PaymentModel> paymentHistory;
  final List<PaymentMethodModel> paymentMethods;
  final PaymentMethodModel? selectedMethod;
  final bool processing;
  final bool successAction;
  final String? successMessage;

  const UserPaymentState({
    this.initialLoad = true,
    this.error = false,
    this.errorMessage,
    this.paymentHistory = const [],
    this.paymentMethods = const [],
    this.selectedMethod,
    this.processing = false,
    this.successAction = false,
    this.successMessage,
  });

  UserPaymentState copyWith({
    bool? initialLoad,
    bool? error,
    String? errorMessage,
    List<PaymentModel>? paymentHistory,
    List<PaymentMethodModel>? paymentMethods,
    PaymentMethodModel? selectedMethod,
    bool? processing,
    bool? successAction,
    String? successMessage,
    bool clearSelectedMethod = false,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return UserPaymentState(
      initialLoad: initialLoad ?? this.initialLoad,
      error: error ?? this.error,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      paymentHistory: paymentHistory ?? this.paymentHistory,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedMethod: clearSelectedMethod ? null : (selectedMethod ?? this.selectedMethod),
      processing: processing ?? this.processing,
      successAction: successAction ?? this.successAction,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        initialLoad,
        error,
        errorMessage,
        paymentHistory,
        paymentMethods,
        selectedMethod,
        processing,
        successAction,
        successMessage,
      ];
}
```

## 2. Creating Cubit

### Requirements
- Extend Cubit<State>
- Inject dependencies via constructor
- Use customTryCatch for error handling
- Emit states for loading, success, error
- Focus on user-centric operations

### Cubit Template

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain_clap/paymentmodule/exports.dart';
import 'package:user_app/core/utils/custom_try_catch.dart';

import 'user_payment_state.dart';

class UserPaymentCubit extends Cubit<UserPaymentState> {
  final PaymentService _paymentService;

  UserPaymentCubit(this._paymentService)
      : super(const UserPaymentState());

  Future<void> initialLoad() async {
    await loadUserData();
  }

  Future<void> loadUserData() async {
    await customTryCatch(
      tryFunction: () async {
        emit(state.copyWith(initialLoad: true, error: false));

        // Get current user ID from auth service
        final userId = 'current-user-id'; // Replace with actual user ID

        // Load payment history and payment methods in parallel
        final results = await Future.wait([
          _paymentService.getPaymentHistory(userId),
          // If there's a payment method service:
          // _paymentMethodService.getUserPaymentMethods(userId),
        ]);

        emit(state.copyWith(
          initialLoad: false,
          error: false,
          paymentHistory: results[0] as List<PaymentModel>,
          // paymentMethods: results[1] as List<PaymentMethodModel>,
        ));
      },
      catchFunction: (error) {
        emit(state.copyWith(
          initialLoad: false,
          error: true,
          errorMessage: 'Failed to load payment data',
        ));
      },
    );
  }

  Future<void> selectPaymentMethod(PaymentMethodModel method) async {
    emit(state.copyWith(selectedMethod: method));
  }

  Future<void> makePayment({
    required double amount,
    required String currency,
  }) async {
    await customTryCatch(
      tryFunction: () async {
        if (state.selectedMethod == null) {
          throw Exception('Please select a payment method');
        }

        emit(state.copyWith(processing: true));

        // Get current user ID
        final userId = 'current-user-id'; // Replace with actual user ID

        await _paymentService.createPayment(
          userId: userId,
          amount: amount,
          currency: currency,
          paymentMethodId: state.selectedMethod!.id,
        );

        emit(state.copyWith(
          processing: false,
          successAction: true,
          successMessage: 'Payment processed successfully',
        ));

        // Reload payment history
        await loadUserData();
      },
      catchFunction: (error) {
        emit(state.copyWith(
          processing: false,
          error: true,
          errorMessage: 'Payment failed: ${error.toString()}',
        ));
      },
    );
  }

  Future<void> loadPaymentHistory() async {
    await customTryCatch(
      tryFunction: () async {
        final userId = 'current-user-id'; // Replace with actual user ID
        final history = await _paymentService.getPaymentHistory(userId);

        emit(state.copyWith(
          paymentHistory: history,
          error: false,
        ));
      },
      catchFunction: (error) {
        emit(state.copyWith(
          error: true,
          errorMessage: 'Failed to load payment history',
        ));
      },
    );
  }

  void clearMessages() {
    emit(state.copyWith(
      successAction: false,
      error: false,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
  }

  void clearSelectedMethod() {
    emit(state.copyWith(clearSelectedMethod: true));
  }
}
```

## 3. Creating Screens

### Checkout Screen Template

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_app/core/injector/injector.dart';
import 'package:user_app/core/utils/utils.dart';
import 'package:user_app/core/widgets/app_section_template_user.dart';
import 'package:ui_widgets_clap/payment/exports.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

import '../cubit/user_payment_cubit.dart';
import '../cubit/user_payment_state.dart';

@RoutePage()
class CheckoutScreen extends StatefulWidget {
  final double? amount;
  final String? currency;

  const CheckoutScreen({
    Key? key,
    this.amount,
    this.currency,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final UserPaymentCubit bloc;

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
    return AppSectionTemplateUser(
      title: 'Checkout',
      showBackButton: true,
      child: BlocListener<UserPaymentCubit, UserPaymentState>(
        bloc: bloc,
        listener: (context, state) {
          if (state.error) {
            Utils.alertToastError(
              context,
              state.errorMessage ?? 'An error occurred',
            );
            bloc.clearMessages();
          }

          if (state.successAction) {
            Utils.alertToastSuccess(
              context,
              state.successMessage ?? 'Payment successful',
            );
            bloc.clearMessages();
            
            // Navigate back or to success screen
            context.router.pop();
          }
        },
        child: BlocBuilder<UserPaymentCubit, UserPaymentState>(
          bloc: bloc,
          builder: (context, state) {
            if (state.initialLoad) {
              return Utils().loadingWidget();
            }

            if (state.processing) {
              return _buildProcessingView();
            }

            return _buildCheckoutForm(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildCheckoutForm(BuildContext context, UserPaymentState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment amount form
          PaymentFormWidget<PaymentModel>(
            availableCurrencies: const ['USD', 'EUR', 'GBP'],
            onSubmit: (amount, currency) {
              if (state.selectedMethod == null) {
                Utils.alertToastError(context, 'Please select a payment method');
                return;
              }
              bloc.makePayment(amount: amount, currency: currency);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Payment method selector
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          if (state.paymentMethods.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.payment, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No payment methods available'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Navigate to add payment method screen
                      },
                      child: const Text('Add Payment Method'),
                    ),
                  ],
                ),
              ),
            )
          else
            PaymentMethodSelector<PaymentMethodModel>(
              methods: state.paymentMethods,
              selectedMethod: state.selectedMethod,
              getDisplayName: (method) => method.type,
              getSubtitle: (method) => method.provider,
              onMethodSelected: (method) => bloc.selectPaymentMethod(method),
              isEnabled: (method) => true,
            ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing payment...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Payment History Screen Template

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_app/core/injector/injector.dart';
import 'package:user_app/core/utils/utils.dart';
import 'package:user_app/core/widgets/app_section_template_user.dart';
import 'package:ui_widgets_clap/payment/exports.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

import '../cubit/user_payment_cubit.dart';
import '../cubit/user_payment_state.dart';

@RoutePage()
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late final UserPaymentCubit bloc;

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
    return AppSectionTemplateUser(
      title: 'Payment History',
      actions: [
        IconButton(
          onPressed: () => bloc.loadPaymentHistory(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      child: BlocListener<UserPaymentCubit, UserPaymentState>(
        bloc: bloc,
        listener: (context, state) {
          if (state.error) {
            Utils.alertToastError(
              context,
              state.errorMessage ?? 'Failed to load payments',
            );
            bloc.clearMessages();
          }
        },
        child: BlocBuilder<UserPaymentCubit, UserPaymentState>(
          bloc: bloc,
          builder: (context, state) {
            if (state.initialLoad) {
              return Utils().loadingWidget();
            }

            if (state.error && state.paymentHistory.isEmpty) {
              return Utils().errorWidget(
                onRetry: () => bloc.loadPaymentHistory(),
              );
            }

            return PaymentHistoryList<PaymentModel>(
              payments: state.paymentHistory,
              getTitle: (payment) => '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
              getSubtitle: (payment) => _formatDate(payment.createdAt),
              getAmount: (payment) => '\$${payment.amount.toStringAsFixed(2)}',
              getStatusWidget: (payment) => _buildStatusChip(payment.status),
              onItemTap: (payment) => _showPaymentDetails(context, payment),
              emptyMessage: 'No payment history',
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPaymentDetails(BuildContext context, PaymentModel payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentStatusCard<PaymentModel>(
        payment: payment,
        getStatus: (p) => p.status,
        getAmount: (p) => '\$${p.amount.toStringAsFixed(2)} ${p.currency}',
        getDate: (p) => _formatDate(p.createdAt),
        getStatusColor: (p) {
          switch (p.status.toLowerCase()) {
            case 'completed':
              return Colors.green;
            case 'pending':
              return Colors.orange;
            case 'failed':
              return Colors.red;
            default:
              return Colors.grey;
          }
        },
        getStatusIcon: (p) {
          switch (p.status.toLowerCase()) {
            case 'completed':
              return Icons.check_circle;
            case 'pending':
              return Icons.pending;
            case 'failed':
              return Icons.error;
            default:
              return Icons.info;
          }
        },
      ),
    );
  }
}
```

## 4. Routing Configuration

```dart
// In your router configuration file (e.g., app_router.dart)

import 'package:auto_route/auto_route.dart';
import 'features/payment/screens/checkout_screen.dart';
import 'features/payment/screens/payment_history_screen.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
    // ... other routes
    AutoRoute(
      page: CheckoutRoute.page,
      path: '/checkout',
    ),
    AutoRoute(
      page: PaymentHistoryRoute.page,
      path: '/payment-history',
    ),
  ];
}
```

## 5. Kiwi DI Registration

```dart
// In your DI setup file

import 'package:kiwi/kiwi.dart';
import 'features/payment/cubit/user_payment_cubit.dart';

void setupPaymentFeature() {
  final container = KiwiContainer();

  // Register Cubit
  container.registerFactory(
    (c) => UserPaymentCubit(c.resolve()),
  );
}
```

## Important Rules

### ✅ DO
- Use customTryCatch in all Cubit methods
- Focus on user-friendly experiences
- Use AppSectionTemplateUser wrapper
- Handle loading and error states gracefully
- Provide clear feedback to users
- Use UI widgets from ui_widgets_clap
- Validate user input before submission

### ❌ DON'T
- DON'T expose admin-level operations
- DON'T show technical error messages to users
- DON'T skip loading indicators for async operations
- DON'T forget to close bloc in dispose

## Naming Conventions

- **Cubits:** `User[Feature]Cubit` or `[Feature]Cubit` (e.g., UserPaymentCubit, CheckoutCubit)
- **States:** `User[Feature]State` or `[Feature]State` (e.g., UserPaymentState, CheckoutState)
- **Screens:** `[Feature]Screen` (e.g., CheckoutScreen, PaymentHistoryScreen)
- **Files:** snake_case (e.g., user_payment_cubit.dart, checkout_screen.dart)

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

---

**Follow these patterns exactly for consistent Frontend User implementation across the CLAP architecture.**
