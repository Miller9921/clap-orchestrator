# Frontend User - Payment Processing Module

Documentation for User frontend implementation patterns.

## Structure

```
frontend-user/
├── cubit/
│   ├── user_payment_cubit.dart
│   └── user_payment_state.dart
├── screens/
│   ├── checkout_screen.dart
│   └── payment_history_screen.dart
└── exports.dart
```

## Implementation Patterns

### State Class

```dart
// user_payment_state.dart
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

  const UserPaymentState({...});
  
  UserPaymentState copyWith({...});
  
  @override
  List<Object?> get props => [...];
}
```

### Cubit

```dart
// user_payment_cubit.dart
class UserPaymentCubit extends Cubit<UserPaymentState> {
  final PaymentService _paymentService;

  UserPaymentCubit(this._paymentService)
      : super(const UserPaymentState());

  Future<void> makePayment({
    required double amount,
    required String currency,
  }) async {
    await customTryCatch(
      tryFunction: () async {
        emit(state.copyWith(processing: true));
        
        await _paymentService.createPayment(
          userId: 'current-user-id',
          amount: amount,
          currency: currency,
          paymentMethodId: state.selectedMethod!.id,
        );

        emit(state.copyWith(
          processing: false,
          successAction: true,
          successMessage: 'Payment successful',
        ));
      },
      catchFunction: (error) {
        emit(state.copyWith(
          processing: false,
          error: true,
          errorMessage: 'Payment failed',
        ));
      },
    );
  }
}
```

### Checkout Screen

```dart
// checkout_screen.dart
@RoutePage()
class CheckoutScreen extends StatefulWidget {
  final double? amount;
  final String? currency;

  const CheckoutScreen({this.amount, this.currency});

  @override
  State createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final UserPaymentCubit bloc;

  @override
  void initState() {
    super.initState();
    bloc = injector.resolve()..initialLoad();
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionTemplateUser(
      title: 'Checkout',
      child: BlocListener<UserPaymentCubit, UserPaymentState>(
        bloc: bloc,
        listener: (context, state) {
          if (state.successAction) {
            Utils.alertToastSuccess(context, 'Payment successful');
            context.router.pop();
          }
        },
        child: BlocBuilder<UserPaymentCubit, UserPaymentState>(
          bloc: bloc,
          builder: (context, state) {
            if (state.processing) return _buildProcessing();
            return _buildForm(state);
          },
        ),
      ),
    );
  }

  Widget _buildForm(UserPaymentState state) {
    return Column(
      children: [
        PaymentFormWidget<PaymentModel>(
          availableCurrencies: ['USD', 'EUR', 'GBP'],
          onSubmit: (amount, currency) {
            bloc.makePayment(amount: amount, currency: currency);
          },
        ),
        PaymentMethodSelector<PaymentMethodModel>(
          methods: state.paymentMethods,
          selectedMethod: state.selectedMethod,
          getDisplayName: (m) => m.type,
          onMethodSelected: (m) => bloc.selectPaymentMethod(m),
        ),
      ],
    );
  }
}
```

### Payment History Screen

```dart
// payment_history_screen.dart
@RoutePage()
class PaymentHistoryScreen extends StatefulWidget {
  @override
  State createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State {
  late final UserPaymentCubit bloc;

  @override
  void initState() {
    super.initState();
    bloc = injector.resolve()..initialLoad();
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionTemplateUser(
      title: 'Payment History',
      child: BlocBuilder<UserPaymentCubit, UserPaymentState>(
        bloc: bloc,
        builder: (context, state) {
          if (state.initialLoad) return Utils().loadingWidget();
          
          return PaymentHistoryList<PaymentModel>(
            payments: state.paymentHistory,
            getTitle: (p) => '${p.currency} ${p.amount}',
            getSubtitle: (p) => _formatDate(p.createdAt),
            onItemTap: (p) => _showDetails(p),
          );
        },
      ),
    );
  }
}
```

## Features Implemented

1. **Checkout Flow** - Amount form + method selection + payment
2. **Payment History** - Scrollable list with status indicators
3. **Payment Details** - Bottom sheet with full information
4. **Processing State** - Loading indicator during payment
5. **Error Handling** - User-friendly error messages
6. **Success Navigation** - Auto-navigate after successful payment

## Routing

```dart
// In app_router.dart
AutoRoute(page: CheckoutRoute.page, path: '/checkout'),
AutoRoute(page: PaymentHistoryRoute.page, path: '/payment-history'),
```

## DI Registration

```dart
// Domain service
container.registerFactory((c) => PaymentService(c.resolve()));

// User cubit
container.registerFactory((c) => UserPaymentCubit(c.resolve()));
```

## Target Repository

`Miller9921/flutter-frontuser-app`:
```
/lib/features/payment/
  ├── cubit/
  ├── screens/
  └── exports.dart
```
