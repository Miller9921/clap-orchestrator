// Example Domain Repository Interface - IPaymentRepository
// Location: lib/paymentmodule/repositories/i_payment_repository.dart

import '../entities/payment_model.dart';

/// Payment repository interface defining data operations.
/// 
/// This interface follows CLAP conventions:
/// - Abstract class (interface pattern)
/// - Returns Future<T> directly (NO Either)
/// - Clear method signatures
/// - NO implementation details
/// - NO error handling (implementation responsibility)
abstract class IPaymentRepository {
  /// Get all payments for a specific user.
  Future<List<PaymentModel>> getPaymentsByUserId(String userId);

  /// Get a single payment by its ID.
  /// Returns null if payment not found.
  Future<PaymentModel?> getPaymentById(String id);

  /// Create a new payment.
  /// Returns the created payment with ID assigned by backend.
  Future<PaymentModel> createPayment(PaymentModel payment);

  /// Update an existing payment.
  /// Returns the updated payment.
  Future<PaymentModel> updatePayment(PaymentModel payment);

  /// Delete a payment by ID.
  Future<void> deletePayment(String id);

  /// Get all payments with a specific status.
  Future<List<PaymentModel>> getPaymentsByStatus(String status);

  /// Get payments within a date range.
  Future<List<PaymentModel>> getPaymentsInDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
