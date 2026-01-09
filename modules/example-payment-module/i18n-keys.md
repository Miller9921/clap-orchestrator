# i18n Keys for Payment Processing Module

## Module: Payment Processing

This file lists all internationalization keys that need to be manually added to the `Miller9921/clap_i18n` repository.

## Admin Frontend Keys

Add these keys to the admin app translation files:

```
# Module Title and Navigation
[module].title
[module].subtitle
[module].menu_item

# List/Table Headers
[module].list.title
[module].list.empty
[module].list.loading

# Actions
[module].action.create
[module].action.edit
[module].action.delete
[module].action.save
[module].action.cancel
[module].action.refresh
[module].action.export
[module].action.import

# Confirmation Messages
[module].confirm.delete
[module].confirm.save

# Success Messages
[module].success.created
[module].success.updated
[module].success.deleted

# Error Messages
[module].error.load_failed
[module].error.create_failed
[module].error.update_failed
[module].error.delete_failed
[module].error.validation_failed

# Entity Fields
[module].[entity].id
[module].[entity].[field1]
[module].[entity].[field2]
[module].[entity].[field3]
[module].[entity].created_at
[module].[entity].updated_at

# Validation Messages
[module].validation.[field1]_required
[module].validation.[field1]_invalid
[module].validation.[field2]_required
[module].validation.[field2]_invalid
```

## User Frontend Keys

Add these keys to the user app translation files:

```
# Module Title and Navigation
[module].title
[module].subtitle
[module].description

# Empty States
[module].empty.title
[module].empty.message
[module].empty.action

# List View
[module].list.title
[module].list.empty
[module].list.loading

# Detail View
[module].detail.title
[module].detail.loading

# Actions
[module].action.submit
[module].action.cancel
[module].action.retry
[module].action.close
[module].action.view_more

# Success Messages
[module].success.submitted
[module].success.completed

# Error Messages
[module].error.load_failed
[module].error.submit_failed
[module].error.network_error
[module].error.unknown_error

# Entity Fields (User-friendly labels)
[module].[entity].[field1]
[module].[entity].[field2]
[module].[entity].[field3]

# Status Labels
[module].status.pending
[module].status.completed
[module].status.failed
[module].status.cancelled

# Help Text
[module].help.[field1]
[module].help.[field2]
```

## Example: Payment Module Keys

### Admin App Keys

```
# Module
payment.title = Payment Management
payment.subtitle = Manage all payment transactions
payment.menu_item = Payments

# List
payment.list.title = All Payments
payment.list.empty = No payments found
payment.list.loading = Loading payments...

# Actions
payment.action.refund = Issue Refund
payment.action.export = Export Report
payment.action.refresh = Refresh

# Confirmation
payment.confirm.refund = Are you sure you want to issue a refund for this payment?

# Success
payment.success.refund_issued = Refund issued successfully
payment.success.report_generated = Report generated successfully

# Error
payment.error.load_failed = Failed to load payments
payment.error.refund_failed = Failed to issue refund

# Fields
payment.payment.id = Payment ID
payment.payment.amount = Amount
payment.payment.currency = Currency
payment.payment.status = Status
payment.payment.user_id = User ID
payment.payment.created_at = Date
```

### User App Keys

```
# Module
payment.title = Payments
payment.checkout.title = Checkout
payment.history.title = Payment History

# Empty States
payment.empty.title = No Payments
payment.empty.message = You haven't made any payments yet
payment.empty.action = Make a Payment

# Actions
payment.action.pay = Pay Now
payment.action.view_history = View History

# Success
payment.success.payment_completed = Payment completed successfully

# Error
payment.error.payment_failed = Payment failed. Please try again
payment.error.invalid_amount = Please enter a valid amount

# Fields
payment.amount = Amount
payment.currency = Currency
payment.method = Payment Method
payment.method.card = Credit Card
payment.method.paypal = PayPal
payment.method.bank = Bank Transfer

# Status
payment.status.pending = Pending
payment.status.completed = Completed
payment.status.failed = Failed
```

## Translation Guidelines

1. **Keep keys consistent** across admin and user apps where applicable
2. **Use descriptive names** that indicate the context
3. **Group related keys** using dot notation
4. **Provide default English values** as shown above
5. **Consider pluralization** for list items if needed
6. **Think about context** - same word might need different translations in different contexts

## Adding Keys to clap_i18n Repository

1. Navigate to `Miller9921/clap_i18n` repository
2. Locate the translation files:
   - Admin: `/admin/translations/[language].json`
   - User: `/user/translations/[language].json`
3. Add the keys in alphabetical order within their sections
4. Provide translations for all supported languages
5. Commit and push changes
6. Update both frontend apps to use the new keys

## Usage in Code

### Admin App
```dart
import 'package:clap_i18n/admin_translations.dart';

Text(AdminTranslations.of(context).translate('payment.title'))
```

### User App
```dart
import 'package:clap_i18n/user_translations.dart';

Text(UserTranslations.of(context).translate('payment.title'))
```

---

**Note:** Keys must be added manually to the i18n repository. This is not automated by the orchestrator.
