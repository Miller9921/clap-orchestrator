# UI Layer - Payment Processing Module

This directory contains documentation for UI generic widgets implementation.

## Structure

```
ui/
├── widgets/
│   ├── payment_method_selector.dart
│   ├── payment_form_widget.dart
│   ├── payment_history_list.dart
│   └── payment_status_card.dart
└── exports.dart
```

## Widget Patterns

All UI widgets follow these principles:
- Generic with type parameter `<T>`
- No model imports (only generic types)
- Callbacks for data extraction
- No state management (only setState)
- Theme.of(context) for styling
- ClapColors for custom colors

### 1. Payment Method Selector

```dart
// payment_method_selector.dart
class PaymentMethodSelector<T> extends StatelessWidget {
  final List<T> methods;
  final T? selectedMethod;
  final String Function(T) getDisplayName;
  final String Function(T)? getSubtitle;
  final void Function(T) onMethodSelected;
  final bool Function(T)? isEnabled;

  // Implementation with Card list, selection highlighting
}
```

### 2. Payment Form Widget

```dart
// payment_form_widget.dart
class PaymentFormWidget<T> extends StatefulWidget {
  final T? initialData;
  final void Function(double amount, String currency) onSubmit;
  final List<String> availableCurrencies;
  final double? Function(T)? getAmount;
  final String? Function(T)? getCurrency;

  // StatefulWidget with TextEditingController
  // Amount input, currency dropdown, submit button
}
```

### 3. Payment History List

```dart
// payment_history_list.dart
class PaymentHistoryList<T> extends StatelessWidget {
  final List<T> payments;
  final String Function(T) getTitle;
  final String Function(T) getSubtitle;
  final String Function(T)? getAmount;
  final Widget? Function(T)? getStatusWidget;
  final void Function(T)? onItemTap;
  final String? emptyMessage;

  // ListView with empty state, status chips
}
```

### 4. Payment Status Card

```dart
// payment_status_card.dart
class PaymentStatusCard<T> extends StatelessWidget {
  final T payment;
  final String Function(T) getStatus;
  final String Function(T) getAmount;
  final String Function(T) getDate;
  final Color? Function(T)? getStatusColor;
  final IconData? Function(T)? getStatusIcon;
  final void Function(T)? onViewDetails;

  // Card with status indicator, amount, date, optional button
}
```

## Widgetbook Stories

```dart
// widgetbook/payment/payment_method_selector_story.dart
@UseCase(name: 'Default', type: PaymentMethodSelector)
Widget paymentMethodSelectorDefault(BuildContext context) {
  return Scaffold(
    body: PaymentMethodSelector<MockPaymentMethod>(
      methods: mockMethods,
      getDisplayName: (m) => m.name,
      onMethodSelected: (m) => print(m.name),
    ),
  );
}
```

## Key Features

### Generic Type Safety
```dart
// Works with any type
PaymentMethodSelector<PaymentMethodModel>(...)
PaymentMethodSelector<Map<String, dynamic>>(...)
PaymentMethodSelector<CustomType>(...)
```

### Callback Pattern
```dart
// Extract data via callbacks
getDisplayName: (method) => method.type,
getSubtitle: (method) => '****  ${method.last4}',
onMethodSelected: (method) => handleSelection(method),
```

### Styling
```dart
// Use Theme
final theme = Theme.of(context);
style: theme.textTheme.titleMedium

// Use ClapColors
color: ClapColors.primary
borderSide: BorderSide(color: ClapColors.primary)
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  ui_widgets_clap:
    path: ../flutter-ui-core

dev_dependencies:
  widgetbook: ^3.0.0
  widgetbook_annotation: ^3.0.0
```

## Target Repository

Place these files in `Miller9921/flutter-ui-components`:
```
/lib/payment/
  ├── widgets/
  └── exports.dart

/widgetbook/payment/
  └── [widget]_story.dart
```

## Testing

```dart
testWidgets('PaymentMethodSelector displays methods', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PaymentMethodSelector<String>(
        methods: ['Card', 'PayPal'],
        getDisplayName: (m) => m,
        onMethodSelected: (_) {},
      ),
    ),
  );

  expect(find.text('Card'), findsOneWidget);
  expect(find.text('PayPal'), findsOneWidget);
});
```
