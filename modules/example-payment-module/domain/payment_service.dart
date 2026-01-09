// Example Domain Service - PaymentService
// Location: lib/paymentmodule/services/payment_service.dart

import '../entities/payment_model.dart';
import '../repositories/i_payment_repository.dart';

/// Payment service orchestrating payment business logic.
/// 
/// This service follows CLAP conventions:
/// - Depends on repository interfaces (injected via constructor)
/// - Returns Future<T> directly (NO Either)
/// - Uses try/catch for error handling
/// - Contains business logic and validations
/// - Orchestrates multiple repository calls
class PaymentService {
  final IPaymentRepository _paymentRepository;

  PaymentService(this._paymentRepository);

  /// Get payment history for a user, excluding cancelled payments.
  /// 
  /// This demonstrates business logic filtering at the service layer.
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    try {
      final payments = await _paymentRepository.getPaymentsByUserId(userId);
      
      // Business logic: filter out cancelled payments
      return payments.where((p) => p.status != 'cancelled').toList();
    } catch (e) {
      // Simple error handling - let exceptions propagate
      rethrow;
    }
  }

  /// Create a new payment with business validations.
  /// 
  /// Demonstrates:
  /// - Input validation
  /// - Business rules enforcement
  /// - Entity construction
  Future<PaymentModel> createPayment({
    required String userId,
    required double amount,
    required String currency,
    required String paymentMethodId,
    String? description,
  }) async {
    try {
      // Business validation
      if (amount <= 0) {
        throw Exception('Payment amount must be greater than 0');
      }
      
      if (currency.isEmpty) {
        throw Exception('Currency is required');
      }

      // Create payment entity
      final payment = PaymentModel(
        id: '', // Will be assigned by backend
        amount: amount,
        currency: currency,
        status: 'pending',
        createdAt: DateTime.now(),
        userId: userId,
        paymentMethodId: paymentMethodId,
        description: description,
      );

      // Persist via repository
      return await _paymentRepository.createPayment(payment);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single payment by ID.
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      return await _paymentRepository.getPaymentById(paymentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update payment status.
  /// 
  /// Demonstrates business logic for state transitions.
  Future<PaymentModel> updatePaymentStatus(
    String paymentId,
    String newStatus,
  ) async {
    try {
      // Get current payment
      final payment = await _paymentRepository.getPaymentById(paymentId);
      
      if (payment == null) {
        throw Exception('Payment not found');
      }

      // Business rule: cannot change status of refunded payment
      if (payment.status == 'refunded') {
        throw Exception('Cannot modify refunded payment');
      }

      // Create updated payment
      final updatedPayment = payment.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      return await _paymentRepository.updatePayment(updatedPayment);
    } catch (e) {
      rethrow;
    }
  }

  /// Issue a refund for a payment.
  /// 
  /// Demonstrates business process orchestration.
  Future<PaymentModel> refundPayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      
      if (payment == null) {
        throw Exception('Payment not found');
      }

      // Business rule: can only refund completed payments
      if (payment.status != 'completed') {
        throw Exception('Only completed payments can be refunded');
      }

      // Update status to refunded
      return await updatePaymentStatus(paymentId, 'refunded');
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate total amount paid by user in a date range.
  /// 
  /// Demonstrates data aggregation at service layer.
  Future<double> calculateTotalPaid(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<PaymentModel> payments;

      if (startDate != null && endDate != null) {
        // Get payments in date range
        payments = await _paymentRepository.getPaymentsInDateRange(
          startDate,
          endDate,
        );
        // Filter by user
        payments = payments.where((p) => p.userId == userId).toList();
      } else {
        // Get all user payments
        payments = await _paymentRepository.getPaymentsByUserId(userId);
      }

      // Calculate total for completed payments only
      return payments
          .where((p) => p.status == 'completed')
          .fold(0.0, (sum, payment) => sum + payment.amount);
    } catch (e) {
      rethrow;
    }
  }

  /// Get payments by status.
  Future<List<PaymentModel>> getPaymentsByStatus(String status) async {
    try {
      return await _paymentRepository.getPaymentsByStatus(status);
    } catch (e) {
      rethrow;
    }
  }
}
