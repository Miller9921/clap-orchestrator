# Frontend Admin - Payment Processing Module

Documentation for Admin frontend implementation patterns.

## Structure

```
frontend-admin/
├── cubit/
│   ├── payment_management_cubit.dart
│   └── payment_management_state.dart
├── screens/
│   └── payment_management_screen.dart
└── exports.dart
```

## Implementation Patterns

### State Class

```dart
// payment_management_state.dart
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

  PaymentManagementState copyWith({...});

  @override
  List<Object?> get props => [...];
}
```

### Cubit

```dart
// payment_management_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain_clap/paymentmodule/exports.dart';

class PaymentManagementCubit extends Cubit<PaymentManagementState> {
  final PaymentService _paymentService;

  PaymentManagementCubit(this._paymentService)
      : super(const PaymentManagementState());

  Future<void> initialLoad() async {
    await customTryCatch(
      tryFunction: () async {
        emit(state.copyWith(initialLoad: true));
        final payments = await _paymentService.getPaymentHistory('all');
        emit(state.copyWith(
          initialLoad: false,
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

  Future<void> issueRefund(String paymentId) async {
    await customTryCatch(
      tryFunction: () async {
        await _paymentService.refundPayment(paymentId);
        emit(state.copyWith(
          successAction: true,
          successMessage: 'Refund issued successfully',
        ));
        await loadAllPayments();
      },
      catchFunction: (error) {
        emit(state.copyWith(
          errorAction: true,
          errorMessage: 'Failed to issue refund',
        ));
      },
    );
  }
}
```

### Screen

```dart
// payment_management_screen.dart
@RoutePage()
class PaymentManagementScreen extends StatefulWidget {
  @override
  State createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State {
  late final PaymentManagementCubit bloc;

  @override
  void initState() {
    super.initState();
    bloc = injector.resolve()..initialLoad();
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionTemplateAdmin(
      title: 'Payment Management',
      child: BlocListener<PaymentManagementCubit, PaymentManagementState>(
        bloc: bloc,
        listener: (context, state) {
          if (state.errorAction) {
            Utils.alertToastError(context, state.errorMessage ?? 'Error');
          }
          if (state.successAction) {
            Utils.alertToastSuccess(context, state.successMessage!);
          }
        },
        child: BlocBuilder<PaymentManagementCubit, PaymentManagementState>(
          bloc: bloc,
          builder: (context, state) {
            if (state.initialLoad) return Utils().loadingWidget();
            if (state.error) return Utils().errorWidget();
            return _buildContent(state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(PaymentManagementState state) {
    return PaymentHistoryList<PaymentModel>(
      payments: state.payments,
      getTitle: (p) => 'Payment #${p.id}',
      getSubtitle: (p) => 'User: ${p.userId}',
      onItemTap: (p) => bloc.selectPayment(p.id),
    );
  }
}
```

## Features Implemented

1. **View All Payments** - List with PaymentHistoryList widget
2. **Select Payment** - View details in card
3. **Issue Refunds** - Confirmation dialog + API call
4. **Generate Reports** - Date range picker + export
5. **Refresh** - Reload payment list
6. **Error Handling** - Toast notifications

## Routing

```dart
// In app_router.dart
AutoRoute(page: PaymentManagementRoute.page, path: '/payments'),
```

## DI Registration

```dart
// Domain service
container.registerFactory((c) => PaymentService(c.resolve()));

// Admin cubit
container.registerFactory((c) => PaymentManagementCubit(c.resolve()));
```

## Target Repository

`Miller9921/flutter-admin-app`:
```
/lib/features/payment/
  ├── cubit/
  ├── screens/
  └── exports.dart
```
